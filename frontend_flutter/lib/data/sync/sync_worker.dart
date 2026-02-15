import 'dart:async';
import 'dart:convert';

import '../../core/utils/app_logger.dart';
import '../../models/sync_queue.dart';
import '../api/backend_api_client.dart';
import '../database/app_database.dart';
import '../database/sync_queue_dao.dart';

/// 同步工作器
///
/// 负责在后台处理网络同步重试队列
class SyncWorker {
  final SyncQueueDao _syncDao;
  final BackendApiClient _apiClient;

  Timer? _timer;
  bool _isRunning = false;
  bool _isDisposed = false;

  /// 同步状态变化流
  final _statusController = StreamController<SyncWorkerStatus>.broadcast();

  /// 同步状态流
  Stream<SyncWorkerStatus> get statusStream => _statusController.stream;

  /// 统计变化流（用于通知 UI 刷新）
  final _statsController = StreamController<SyncQueueStats>.broadcast();

  /// 统计变化流
  Stream<SyncQueueStats> get statsStream => _statsController.stream;

  SyncWorker({
    SyncQueueDao? syncDao,
    BackendApiClient? apiClient,
  })  : _syncDao = syncDao ?? SyncQueueDao(AppDatabase.instance),
        _apiClient = apiClient ?? BackendApiClient();

  /// 启动同步工作器
  ///
  /// [interval] 同步间隔（秒），默认 30 秒
  void start({int interval = 30}) {
    if (_isRunning) {
      AppLogger.warn('SyncWorker', '同步工作器已在运行');
      return;
    }

    _isRunning = true;
    _isDisposed = false;

    AppLogger.info('SyncWorker', '启动同步工作器，间隔: $interval秒');

    // 立即发射初始统计数据
    _emitInitialStats();

    // 立即执行一次
    _executeSync();

    // 定期执行
    _timer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _executeSync(),
    );
  }

  /// 发射初始统计数据
  Future<void> _emitInitialStats() async {
    try {
      final stats = await _syncDao.getStats();
      if (!_isDisposed) {
        _statsController.add(stats);
        AppLogger.debug('SyncWorker', '发射初始统计: $stats');
      }
    } catch (e) {
      AppLogger.error('SyncWorker', '获取初始统计失败: $e');
    }
  }

  /// 停止同步工作器
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    AppLogger.info('SyncWorker', '同步工作器已停止');
    _emitStatus(const SyncWorkerStopped());
  }

  /// 手动触发同步
  Future<void> syncNow() async {
    AppLogger.info('SyncWorker', '手动触发同步');
    await _executeSync();
  }

  /// 执行同步
  Future<void> _executeSync() async {
    if (_isDisposed) return;

    try {
      _emitStatus(const SyncWorkerWorking());

      // 获取所有待处理任务
      AppLogger.debug('SyncWorker', '获取待处理任务...');
      final tasks = await _syncDao.getAllPendingTasks(limit: 50);
      AppLogger.debug('SyncWorker', '获取到 ${tasks.length} 个待处理任务');

      if (tasks.isEmpty) {
        _emitStatus(const SyncWorkerIdle());
        return;
      }

      // 打印任务详情
      for (final task in tasks) {
        AppLogger.debug('SyncWorker', '任务: id=${task.id}, type=${task.type}, status=${task.status}, bvid=${task.bvid}, playlistId=${task.playlistId}');
      }

      AppLogger.info('SyncWorker', '开始处理 ${tasks.length} 个同步任务');

      int successCount = 0;
      int failCount = 0;

      AppLogger.debug('SyncWorker', '开始循环，_isDisposed=$_isDisposed');

      for (final task in tasks) {
        AppLogger.debug('SyncWorker', '循环迭代: task.id=${task.id}');
        if (_isDisposed) {
          AppLogger.debug('SyncWorker', 'SyncWorker 已释放，跳过任务');
          break;
        }

        try {
          AppLogger.debug('SyncWorker', '处理任务: ${task.id}, type: ${task.type}');
          await _processTask(task);
          successCount++;
          AppLogger.debug('SyncWorker', '任务成功: ${task.id}');
        } catch (e) {
          AppLogger.error('SyncWorker', '处理同步任务失败: $task - $e');
          failCount++;

          // 标记为失败
          if (task.id != null) {
            await _syncDao.markAsFailed(task.id!, e.toString());
          }
        }
      }

      // 清理已完成的任务
      await _syncDao.clearCompleted();

      // 获取统计信息
      final stats = await _syncDao.getStats();

      _emitStatus(SyncWorkerCompleted(
        successCount: successCount,
        failCount: failCount,
        remaining: stats.active,
      ));

      // 通知统计变化（用于 UI 刷新）
      if (!_isDisposed) {
        _statsController.add(stats);
      }

      AppLogger.info('SyncWorker', '同步完成: 成功 $successCount, 失败 $failCount, 剩余 ${stats.active}');
    } catch (e) {
      AppLogger.error('SyncWorker', '同步执行失败: $e');
      _emitStatus(SyncWorkerError(e.toString()));
    }
  }

  /// 处理单个同步任务
  Future<void> _processTask(SyncTask task) async {
    if (task.id == null) {
      AppLogger.warn('SyncWorker', '任务 ID 为空，跳过处理');
      return;
    }

    AppLogger.debug('SyncWorker', '开始处理任务: id=${task.id}, type=${task.type}');

    // 标记为同步中
    await _syncDao.markAsSyncing(task.id!);
    AppLogger.debug('SyncWorker', '任务已标记为 syncing: ${task.id}');

    // 根据类型执行不同的同步操作
    try {
      switch (task.type) {
        case SyncType.favorite:
          await _syncFavorite(task);
          break;
        case SyncType.unfavorite:
          await _syncUnfavorite(task);
          break;
        case SyncType.playHistory:
          await _syncPlayHistory(task);
          break;
        case SyncType.addPlaylistItem:
          await _syncAddPlaylistItem(task);
          break;
        case SyncType.removePlaylistItem:
          await _syncRemovePlaylistItem(task);
          break;
        case SyncType.createPlaylist:
          await _syncCreatePlaylist(task);
          break;
        case SyncType.updatePlaylist:
          await _syncUpdatePlaylist(task);
          break;
        case SyncType.deletePlaylist:
          await _syncDeletePlaylist(task);
          break;
      }

      // 标记为成功
      await _syncDao.markAsSucceeded(task.id!);
      AppLogger.debug('SyncWorker', '任务已标记为 succeeded: ${task.id}');
    } catch (e) {
      AppLogger.error('SyncWorker', '任务处理失败: id=${task.id}, type=${task.type}, error=$e');
      rethrow;
    }
  }

  /// 同步收藏（幂等）
  Future<void> _syncFavorite(SyncTask task) async {
    if (task.bvid == null) {
      throw ArgumentError('Favorite task missing bvid');
    }

    AppLogger.debug('SyncWorker', '同步收藏: ${task.bvid}');

    final isFavorite = await _apiClient.checkFavorite(task.bvid!);
    if (isFavorite) {
      AppLogger.debug('SyncWorker', '已收藏，跳过: ${task.bvid}');
      return;
    }

    final payload = task.data != null ? _parseDataJson(task.data!) : const <String, dynamic>{};
    final duration = (payload['duration'] as num?)?.toInt();
    await _apiClient.toggleFavorite(
      task.bvid!,
      title: payload['title'] as String?,
      artist: payload['artist'] as String?,
      duration: duration,
      coverUrl: payload['coverUrl'] as String?,
    );
  }

  /// 同步取消收藏（幂等）
  Future<void> _syncUnfavorite(SyncTask task) async {
    if (task.bvid == null) {
      throw ArgumentError('Unfavorite task missing bvid');
    }

    AppLogger.debug('SyncWorker', '同步取消收藏: ${task.bvid}');

    final isFavorite = await _apiClient.checkFavorite(task.bvid!);
    if (!isFavorite) {
      AppLogger.debug('SyncWorker', '未收藏，跳过: ${task.bvid}');
      return;
    }

    final payload = task.data != null ? _parseDataJson(task.data!) : const <String, dynamic>{};
    final duration = (payload['duration'] as num?)?.toInt();
    await _apiClient.toggleFavorite(
      task.bvid!,
      title: payload['title'] as String?,
      artist: payload['artist'] as String?,
      duration: duration,
      coverUrl: payload['coverUrl'] as String?,
    );
  }

  /// 同步播放历史
  Future<void> _syncPlayHistory(SyncTask task) async {
    if (task.bvid == null) {
      throw ArgumentError('PlayHistory task missing bvid');
    }

    AppLogger.debug('SyncWorker', '同步播放历史: ${task.bvid}');
    await _apiClient.addPlayHistory(bvid: task.bvid!);
  }

  /// 同步添加歌单项
  Future<void> _syncAddPlaylistItem(SyncTask task) async {
    if (task.playlistId == null || task.bvid == null) {
      throw ArgumentError('AddPlaylistItem task missing playlistId or bvid');
    }

    AppLogger.debug('SyncWorker', '同步添加歌单项: ${task.bvid} -> ${task.playlistId}');

    // 解析 position
    int? position;
    if (task.data != null) {
      try {
        final dataMap = _parseDataJson(task.data!);
        position = dataMap['position'] as int?;
      } catch (e) {
        AppLogger.warn('SyncWorker', '解析 position 失败: $e');
      }
    }

    await _apiClient.addPlaylistItem(
      playlistId: task.playlistId!,
      bvid: task.bvid!,
      position: position,
    );
  }

  /// 同步删除歌单项
  Future<void> _syncRemovePlaylistItem(SyncTask task) async {
    if (task.playlistId == null || task.bvid == null) {
      throw ArgumentError('RemovePlaylistItem task missing playlistId or bvid');
    }

    AppLogger.debug('SyncWorker', '同步删除歌单项: ${task.bvid} from ${task.playlistId}');
    await _apiClient.removePlaylistItem(
      playlistId: task.playlistId!,
      bvid: task.bvid!,
    );
  }

  /// 同步创建歌单
  Future<void> _syncCreatePlaylist(SyncTask task) async {
    if (task.data == null) {
      throw ArgumentError('CreatePlaylist task missing data');
    }

    AppLogger.debug('SyncWorker', '同步创建歌单');

    final data = _parseDataJson(task.data!);
    await _apiClient.createPlaylist(
      name: data['name'] as String,
      description: data['description'] as String?,
      coverUrl: data['coverUrl'] as String?,
    );
  }

  /// 同步更新歌单
  Future<void> _syncUpdatePlaylist(SyncTask task) async {
    if (task.playlistId == null || task.data == null) {
      throw ArgumentError('UpdatePlaylist task missing playlistId or data');
    }

    AppLogger.debug('SyncWorker', '同步更新歌单: ${task.playlistId}');

    final data = _parseDataJson(task.data!);
    await _apiClient.updatePlaylist(
      id: task.playlistId!,
      name: data['name'] as String?,
      description: data['description'] as String?,
      coverUrl: data['coverUrl'] as String?,
    );
  }

  /// 同步删除歌单
  Future<void> _syncDeletePlaylist(SyncTask task) async {
    if (task.playlistId == null) {
      throw ArgumentError('DeletePlaylist task missing playlistId');
    }

    AppLogger.debug('SyncWorker', '同步删除歌单: ${task.playlistId}');
    await _apiClient.deletePlaylist(task.playlistId!);
  }

  /// 解析 JSON 数据
  Map<String, dynamic> _parseDataJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('SyncWorker', '解析 JSON 失败: $e');
      AppLogger.debug('SyncWorker', '原始数据: $jsonString');
      return {};
    }
  }

  /// 获取同步统计
  Future<SyncQueueStats> getStats() async {
    return await _syncDao.getStats();
  }

  /// 检查是否有待处理任务
  Future<bool> hasPendingTasks() async {
    return await _syncDao.hasPendingTasks();
  }

  /// 发送状态更新
  void _emitStatus(SyncWorkerStatus status) {
    if (!_isDisposed) {
      _statusController.add(status);
    }
  }

  /// 释放资源
  void dispose() {
    _isDisposed = true;
    stop();
    _statusController.close();
    _statsController.close();
    AppLogger.info('SyncWorker', '同步工作器已释放');
  }
}

/// 同步工作器状态
sealed class SyncWorkerStatus {
  const SyncWorkerStatus();
}

/// 空闲状态
class SyncWorkerIdle extends SyncWorkerStatus {
  const SyncWorkerIdle();

  @override
  String toString() => 'SyncWorkerStatus.idle';
}

/// 工作中状态
class SyncWorkerWorking extends SyncWorkerStatus {
  const SyncWorkerWorking();

  @override
  String toString() => 'SyncWorkerStatus.working';
}

/// 完成状态
class SyncWorkerCompleted extends SyncWorkerStatus {
  final int successCount;
  final int failCount;
  final int remaining;

  const SyncWorkerCompleted({
    required this.successCount,
    required this.failCount,
    required this.remaining,
  });

  @override
  String toString() =>
      'SyncWorkerStatus.completed(success: $successCount, failed: $failCount, remaining: $remaining)';
}

/// 错误状态
class SyncWorkerError extends SyncWorkerStatus {
  final String message;

  const SyncWorkerError(this.message);

  @override
  String toString() => 'SyncWorkerStatus.error: $message';
}

/// 停止状态
class SyncWorkerStopped extends SyncWorkerStatus {
  const SyncWorkerStopped();

  @override
  String toString() => 'SyncWorkerStatus.stopped';
}

/// 便捷扩展
extension SyncWorkerStatusX on SyncWorkerStatus {
  bool get isIdle => this is SyncWorkerIdle;
  bool get isWorking => this is SyncWorkerWorking;
  bool get isCompleted => this is SyncWorkerCompleted;
  bool get isError => this is SyncWorkerError;
  bool get isStopped => this is SyncWorkerStopped;
}
