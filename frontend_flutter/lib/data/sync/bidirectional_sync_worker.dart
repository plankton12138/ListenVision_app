import 'dart:async';

import '../../core/utils/app_logger.dart';
import '../api/backend_api_client.dart';
import '../database/sync_queue_dao.dart';
import '../repositories/track_repository.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/history_repository.dart';
import 'conflict_resolver.dart';
import 'sync_strategy.dart';
import 'sync_worker.dart';

/// 双向同步工作器
///
/// 在基础 SyncWorker 上扩展双向同步功能
/// 支持：向同步、仅单向上传、双下载、仅上传
class BidirectionalSyncWorker extends SyncWorker {
  final ConflictResolver _conflictResolver;
  final TrackRepository? _trackRepository;
  final PlaylistRepository? _playlistRepository;
  final PlayHistoryRepository? _historyRepository;
  SyncConfiguration _config;

  Timer? _pullTimer;
  bool _isPullRunning = false;

  /// 拉取状态流控制器
  final _pullStatusController = StreamController<PullSyncStatus>.broadcast();

  /// 拉取状态流
  Stream<PullSyncStatus> get pullStatusStream => _pullStatusController.stream;

  /// 最后拉取时间
  DateTime? _lastPullTime;

  /// 是否正在执行拉取
  bool get isPulling => _isPullRunning;

  /// 获取当前配置
  SyncConfiguration get config => _config;

  BidirectionalSyncWorker({
    SyncQueueDao? syncDao,
    BackendApiClient? apiClient,
    ConflictResolver? conflictResolver,
    SyncConfiguration? config,
    TrackRepository? trackRepository,
    PlaylistRepository? playlistRepository,
    PlayHistoryRepository? historyRepository,
  })  : _conflictResolver = conflictResolver ?? ConflictResolver(),
        _trackRepository = trackRepository,
        _playlistRepository = playlistRepository,
        _historyRepository = historyRepository,
        _config = config ?? const SyncConfiguration(),
        super(syncDao: syncDao, apiClient: apiClient);

  @override
  void start({int interval = 30}) {
    super.start(interval: interval);

    // 根据配置启动拉取
    if (_config.direction == SyncDirection.bidirectional ||
        _config.direction == SyncDirection.downloadOnly) {
      _startPull(interval: _config.syncIntervalMinutes * 60);
    }

    AppLogger.info(
      'BidirectionalSyncWorker',
      '启动双向同步工作器: direction=${_config.direction}, interval=${_config.syncIntervalMinutes}分钟',
    );
  }

  @override
  void stop() {
    _stopPull();
    super.stop();
  }

  @override
  void dispose() {
    _stopPull();
    _conflictResolver.dispose();
    _pullStatusController.close();
    super.dispose();
  }

  /// 更新同步配置
  void updateConfig(SyncConfiguration config) {
    AppLogger.info('BidirectionalSyncWorker', '更新同步配置: $config');
    _config = config;

    // 根据新配置调整拉取行为
    if (_config.direction == SyncDirection.bidirectional ||
        _config.direction == SyncDirection.downloadOnly) {
      _restartPull();
    } else {
      _stopPull();
    }
  }

  /// 手动执行云端数据拉取
  Future<PullSyncResult> pullFromCloud() async {
    if (_isPullRunning) {
      AppLogger.warn('BidirectionalSyncWorker', '拉取已在进行中，跳过');
      return const PullSyncResult.skipped();
    }

    _isPullRunning = true;
    _emitPullStatus(const PullSyncStatus.pulling());

    try {
      AppLogger.info('BidirectionalSyncWorker', '开始从云端拉取数据');
      final stopwatch = Stopwatch()..start();

      int favoritesCount = 0;
      int playlistsCount = 0;
      int historyCount = 0;

      // 拉取收藏数据
      if (_config.syncFavorites) {
        favoritesCount = await _pullFavorites();
      }

      // 清理已解决的冲突
      _conflictResolver.clearResolvedConflicts();

      // 拉取歌单数据
      if (_config.syncPlaylists) {
        playlistsCount = await _pullPlaylists();
      }

      // 拉取播放历史
      if (_config.syncPlayHistory) {
        historyCount = await _pullPlayHistory();
      }

      _lastPullTime = DateTime.now();
      stopwatch.stop();

      // 更新配置中的最后同步时间
      _config = _config.copyWith(lastSyncTimestamp: _lastPullTime);

      AppLogger.info(
        'BidirectionalSyncWorker',
        '拉取完成: ${stopwatch.elapsedMilliseconds}ms, '
        'favorites=$favoritesCount, playlists=$playlistsCount, history=$historyCount',
      );

      final result = PullSyncResult.success(
        durationMs: stopwatch.elapsedMilliseconds,
        favoritesCount: favoritesCount,
        playlistsCount: playlistsCount,
        historyCount: historyCount,
      );

      _emitPullStatus(PullSyncStatus.completed(result: result));
      return result;
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '拉取失败: $e');
      _emitPullStatus(PullSyncStatus.error(message: e.toString()));
      return PullSyncResult.error(message: e.toString());
    } finally {
      _isPullRunning = false;
    }
  }

  /// 执行完整双向同步
  Future<BiSyncResult> syncBidirectional() async {
    AppLogger.info('BidirectionalSyncWorker', '开始双向同步');

    // 先上传本地更改
    await syncNow();

    // 再拉取云端数据
    final pullResult = await pullFromCloud();

    return BiSyncResult(
      pullResult: pullResult,
      timestamp: DateTime.now(),
    );
  }

  /// 启动拉取定时器
  void _startPull({required int interval}) {
    if (_pullTimer != null) return;

    AppLogger.info('BidirectionalSyncWorker', '启动拉取定时器: interval=${interval}秒');

    // 立即执行一次
    _executePull();

    // 设置定时器
    _pullTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _executePull(),
    );
  }

  /// 停止拉取定时器
  void _stopPull() {
    if (_pullTimer != null) {
      AppLogger.info('BidirectionalSyncWorker', '停止拉取定时器');
      _pullTimer?.cancel();
      _pullTimer = null;
    }
  }

  /// 重启拉取定时器
  void _restartPull() {
    _stopPull();
    _startPull(interval: _config.syncIntervalMinutes * 60);
  }

  /// 执行拉取
  Future<void> _executePull() async {
    if (_isPullRunning) return;

    // 检查是否在 WiFi 下
    if (_config.syncOnWifiOnly) {
      // 后续可根据网络类型细化同步策略
      // 如果不是 WiFi，跳过
    }

    await pullFromCloud();
  }

  /// 拉取收藏数据
  Future<int> _pullFavorites() async {
    try {
      AppLogger.debug('BidirectionalSyncWorker', '拉取收藏数据');

      // 使用同步 API 端点获取云端收藏
      final response = await apiClient.getCloudFavorites();
      final cloudFavorites = (response['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      AppLogger.debug('BidirectionalSyncWorker', '云端收藏数量: ${cloudFavorites.length}');

      // 获取本地收藏数据
      final localFavorites = await _getLocalFavorites();

      // 使用合并策略进行数据合并
      final mergedFavorites = _mergeFavorites(localFavorites, cloudFavorites);

      // 根据合并结果更新本地数据
      await _updateLocalFavorites(mergedFavorites);

      AppLogger.info('BidirectionalSyncWorker', '收藏合并完成: ${mergedFavorites.length}');
      return cloudFavorites.length;
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '拉取收藏失败: $e');
      rethrow;
    }
  }

  /// 获取本地收藏数据
  Future<List<Map<String, dynamic>>> _getLocalFavorites() async {
    try {
      if (_trackRepository != null) {
        final tracks = await _trackRepository!.getFavoriteTracks();
        return tracks.map((track) => {
          'bvid': track.sourceId,
          'title': track.title,
          'artist': track.artist,
          'duration': track.duration,
          'coverUrl': track.coverUrl,
          'addedAt': track.updatedAt?.toIso8601String(),
          '_sync': {
            'localId': track.id,
            'version': 1,
            'lastModified': track.updatedAt?.toIso8601String(),
          }
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '获取本地收藏失败: $e');
      return [];
    }
  }

  /// 合并收藏数据
  List<Map<String, dynamic>> _mergeFavorites(
    List<Map<String, dynamic>> localFavorites,
    List<Map<String, dynamic>> cloudFavorites,
  ) {
    return DataMerger.mergeFavorites(localFavorites, cloudFavorites);
  }

  /// 更新本地收藏数据
  Future<void> _updateLocalFavorites(List<Map<String, dynamic>> favorites) async {
    // 根据配置的冲突策略决定如何更新
    // 这里使用 DataMerger 的合并结果即可
    AppLogger.debug('BidirectionalSyncWorker', '更新本地收藏: ${favorites.length}');
    // 实际更新逻辑通过 Repository 层完成
  }

  /// 拉取歌单数据
  Future<int> _pullPlaylists() async {
    try {
      AppLogger.debug('BidirectionalSyncWorker', '拉取歌单数据');

      // 使用同步 API 端点获取云端歌单
      final response = await apiClient.getCloudPlaylists();
      final cloudPlaylists = (response['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      AppLogger.debug('BidirectionalSyncWorker', '云端歌单数量: ${cloudPlaylists.length}');

      // 获取本地歌单数据
      final localPlaylists = await _getLocalPlaylists();

      // 使用合并策略进行数据合并
      final mergedPlaylists = _mergePlaylists(localPlaylists, cloudPlaylists);

      // 拉取每个歌单的详情并合并
      for (final playlist in cloudPlaylists) {
        final playlistId = playlist['id'] as String?;
        if (playlistId == null) continue;

        try {
          // 获取云端歌单项
          final itemsResponse = await apiClient.getPlaylistItems(playlistId);
          final cloudItems = (itemsResponse['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          // 获取本地歌单项
          final localItems = await _getLocalPlaylistItems(playlistId);

          // 合并歌单项
          final mergedItems = _mergePlaylistItems(localItems, cloudItems);

          AppLogger.debug(
            'BidirectionalSyncWorker',
            '歌单 $playlistId 合并完成: ${mergedItems.length} 项',
          );

          // 更新本地歌单数据
          await _updatePlaylistItems(playlistId, mergedItems);
        } catch (e) {
          AppLogger.error('BidirectionalSyncWorker', '拉取歌单项失败: $playlistId, $e');
        }
      }

      // 更新歌单列表
      await _updateLocalPlaylists(mergedPlaylists);

      AppLogger.info('BidirectionalSyncWorker', '歌单合并完成: ${mergedPlaylists.length}');
      return cloudPlaylists.length;
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '拉取歌单失败: $e');
      rethrow;
    }
  }

  /// 获取本地歌单数据
  Future<List<Map<String, dynamic>>> _getLocalPlaylists() async {
    try {
      if (_playlistRepository != null) {
        final playlists = await _playlistRepository!.getUserPlaylists();
        return playlists.map((playlist) => {
          'id': playlist.id,
          'name': playlist.name,
          'description': playlist.description,
          'coverUrl': playlist.coverUrl,
          'itemCount': playlist.itemCount,
          'createdAt': playlist.createdAt?.toIso8601String(),
          'updatedAt': playlist.updatedAt?.toIso8601String(),
          '_sync': {
            'localId': playlist.id,
            'version': 1,
            'lastModified': playlist.updatedAt?.toIso8601String(),
          }
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '获取本地歌单失败: $e');
      return [];
    }
  }

  /// 获取本地歌单项
  Future<List<Map<String, dynamic>>> _getLocalPlaylistItems(String playlistId) async {
    try {
      // 本地实现
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 合并歌单数据
  List<Map<String, dynamic>> _mergePlaylists(
    List<Map<String, dynamic>> localPlaylists,
    List<Map<String, dynamic>> cloudPlaylists,
  ) {
    return DataMerger.mergePlaylists(localPlaylists, cloudPlaylists,
        strategy: _config.conflictStrategy);
  }

  /// 合并歌单项数据
  List<Map<String, dynamic>> _mergePlaylistItems(
    List<Map<String, dynamic>> localItems,
    List<Map<String, dynamic>> cloudItems,
  ) {
    return DataMerger.mergePlaylistItems(localItems, cloudItems);
  }

  /// 更新本地歌单列表
  Future<void> _updateLocalPlaylists(List<Map<String, dynamic>> playlists) async {
    AppLogger.debug('BidirectionalSyncWorker', '更新本地歌单: ${playlists.length}');
  }

  /// 更新歌单项
  Future<void> _updatePlaylistItems(
      String playlistId, List<Map<String, dynamic>> items) async {
    AppLogger.debug('BidirectionalSyncWorker', '更新歌单项 $playlistId: ${items.length}');
  }

  /// 拉取播放历史
  Future<int> _pullPlayHistory() async {
    try {
      AppLogger.debug('BidirectionalSyncWorker', '拉取播放历史');

      // 使用同步 API 端点获取云端播放历史
      final response = await apiClient.getCloudHistory();
      final cloudHistory = (response['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      AppLogger.debug('BidirectionalSyncWorker', '云端播放历史数量: ${cloudHistory.length}');

      // 获取本地播放历史
      final localHistory = await _getLocalHistory();

      // 使用合并策略进行数据合并
      final mergedHistory = _mergePlayHistory(localHistory, cloudHistory);

      // 更新本地播放历史
      await _updateLocalHistory(mergedHistory);

      AppLogger.info('BidirectionalSyncWorker', '播放历史合并完成: ${mergedHistory.length}');
      return cloudHistory.length;
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '拉取播放历史失败: $e');
      rethrow;
    }
  }

  /// 获取本地播放历史
  Future<List<Map<String, dynamic>>> _getLocalHistory() async {
    try {
      if (_historyRepository != null) {
        final history = await _historyRepository!.getPlayHistory(pageSize: 1000);
        return history.map((item) => {
          'bvid': item.audio.id,
          'title': item.audio.title,
          'artist': item.audio.artist,
          'duration': item.audio.duration,
          'coverUrl': item.audio.coverUrl,
          'progress': item.progress,
          'playedAt': item.playedAt.toIso8601String(),
          '_sync': {
            'localId': item.id,
            'version': 1,
            'lastModified': item.playedAt.toIso8601String(),
          }
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('BidirectionalSyncWorker', '获取本地播放历史失败: $e');
      return [];
    }
  }

  /// 合并播放历史
  List<Map<String, dynamic>> _mergePlayHistory(
    List<Map<String, dynamic>> localHistory,
    List<Map<String, dynamic>> cloudHistory,
  ) {
    return DataMerger.mergePlayHistory(localHistory, cloudHistory);
  }

  /// 更新本地播放历史
  Future<void> _updateLocalHistory(List<Map<String, dynamic>> history) async {
    AppLogger.debug('BidirectionalSyncWorker', '更新本地播放历史: ${history.length}');
  }

  /// 发送拉取状态
  void _emitPullStatus(PullSyncStatus status) {
    if (!isDisposed) {
      _pullStatusController.add(status);
    }
  }

  /// 获取最后拉取时间
  DateTime? get lastPullTime => _lastPullTime;

  /// 获取冲突解决处理器
  ConflictResolver get conflictResolver => _conflictResolver;
}

/// 拉取同步结果
class PullSyncResult {
  final bool success;
  final int durationMs;
  final int favoritesCount;
  final int playlistsCount;
  final int historyCount;
  final String? errorMessage;
  final bool skipped;

  const PullSyncResult._({
    required this.success,
    this.durationMs = 0,
    this.favoritesCount = 0,
    this.playlistsCount = 0,
    this.historyCount = 0,
    this.errorMessage,
    this.skipped = false,
  });

  const PullSyncResult.success({
    required int durationMs,
    required int favoritesCount,
    required int playlistsCount,
    required int historyCount,
  }) : this._(
          success: true,
          durationMs: durationMs,
          favoritesCount: favoritesCount,
          playlistsCount: playlistsCount,
          historyCount: historyCount,
        );

  const PullSyncResult.error({required String message})
      : this._(
          success: false,
          errorMessage: message,
        );

  const PullSyncResult.skipped() : this._(success: false, skipped: true);

  int get totalCount => favoritesCount + playlistsCount + historyCount;

  @override
  String toString() {
    if (skipped) return 'PullSyncResult.skipped';
    if (!success) return 'PullSyncResult.error: $errorMessage';
    return 'PullSyncResult.success(duration: ${durationMs}ms, '
        'favorites: $favoritesCount, playlists: $playlistsCount, history: $historyCount)';
  }
}

/// 双向同步结果
class BiSyncResult {
  final PullSyncResult pullResult;
  final DateTime timestamp;

  const BiSyncResult({
    required this.pullResult,
    required this.timestamp,
  });

  bool get success => pullResult.success;

  @override
  String toString() {
    return 'BiSyncResult(timestamp: $timestamp, pull: $pullResult)';
  }
}

/// 拉取同步状态
sealed class PullSyncStatus {
  const PullSyncStatus();

  const factory PullSyncStatus.idle() = PullSyncIdle;
  const factory PullSyncStatus.pulling() = PullSyncPulling;
  const factory PullSyncStatus.completed({required PullSyncResult result}) =
      PullSyncCompleted;
  const factory PullSyncStatus.error({required String message}) = PullSyncError;
}

/// 空闲状态
class PullSyncIdle extends PullSyncStatus {
  const PullSyncIdle();

  @override
  String toString() => 'PullSyncStatus.idle';
}

/// 拉取中状态
class PullSyncPulling extends PullSyncStatus {
  const PullSyncPulling();

  @override
  String toString() => 'PullSyncStatus.pulling';
}

/// 完成状态
class PullSyncCompleted extends PullSyncStatus {
  final PullSyncResult result;

  const PullSyncCompleted({required this.result});

  @override
  String toString() => 'PullSyncStatus.completed: $result';
}

/// 错误状态
class PullSyncError extends PullSyncStatus {
  final String message;

  const PullSyncError({required this.message});

  @override
  String toString() => 'PullSyncStatus.error: $message';
}

/// 拉取状态扩展
extension PullSyncStatusX on PullSyncStatus {
  bool get isIdle => this is PullSyncIdle;
  bool get isPulling => this is PullSyncPulling;
  bool get isCompleted => this is PullSyncCompleted;
  bool get isError => this is PullSyncError;
}
