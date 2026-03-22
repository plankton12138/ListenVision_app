import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../models/audio.dart';
import '../../../models/local_audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/playlist.dart';
import '../player/player_viewmodel.dart';
import '../player/queue_viewmodel.dart';
import '../system/download_viewmodel.dart';
import 'local_music_viewmodel.dart';
import 'playlist_viewmodel.dart';

part 'playlist_detail_viewmodel.freezed.dart';
part 'playlist_detail_viewmodel.g.dart';

/// 歌单详情状态
@freezed
abstract class PlaylistDetailState with _$PlaylistDetailState {
  /// 初始状态
  const factory PlaylistDetailState.initial() = PlaylistDetailStateInitial;

  /// 加载中
  const factory PlaylistDetailState.loading() = PlaylistDetailStateLoading;

  /// 已加载
  const factory PlaylistDetailState.loaded({
    required Playlist playlist,
    required List<PlaylistItem> items,
    @Default(false) bool isOwner,
  }) = PlaylistDetailStateLoaded;

  /// 错误
  const factory PlaylistDetailState.error({
    required String message,
  }) = PlaylistDetailStateError;
}

/// 批量操作状态
@freezed
abstract class BatchOperationState with _$BatchOperationState {
  const factory BatchOperationState({
    @Default(false) bool isInBatchMode,
    @Default({}) Set<String> selectedBvids,
    @Default(0) int totalItems,
  }) = _BatchOperationState;

  const BatchOperationState._();

  bool get hasSelection => selectedBvids.isNotEmpty;
  int get selectedCount => selectedBvids.length;
  bool get isAllSelected => selectedCount == totalItems && totalItems > 0;
}

/// 批量操作结果
@freezed
abstract class BatchOperationResult with _$BatchOperationResult {
  const factory BatchOperationResult({
    required int success,
    required int failed,
    @Default([]) List<String> failedItems,
  }) = _BatchOperationResult;

  const BatchOperationResult._();

  bool get isAllSuccess => failed == 0;
  bool get isPartialSuccess => success > 0 && failed > 0;
  bool get isAllFailed => success == 0 && failed > 0;
}

/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理
@riverpod
class PlaylistDetailViewModel extends _$PlaylistDetailViewModel {
  PlaylistRepository? _repository;

  // 批量操作状态
  final _batchState = ValueNotifier<BatchOperationState>(
    const BatchOperationState(),
  );

  /// 获取批量操作状态监听器
  ValueNotifier<BatchOperationState> get batchStateNotifier => _batchState;

  /// 获取当前批量操作状态
  BatchOperationState get batchState => _batchState.value;

  @override
  Future<PlaylistDetailState> build(String playlistId) async {
    _repository = ref.watch(playlistRepositoryProvider);
    await _loadDetail(playlistId);
    return state.valueOrNull ?? const PlaylistDetailState.initial();
  }

  /// 加载歌单详情
  Future<void> _loadDetail(String playlistId) async {
    state = const AsyncLoading();

    // favorites 系统歌单：优先使用本地 tracks.is_favorite 数据
    // 因为收藏是本地优先的，后端 playlist_items 表可能与本地不一致
    if (playlistId == Playlist.favorites.id) {
      try {
        AppLogger.info('PlaylistDetailViewModel', '加载我喜欢歌单（本地优先）: $playlistId');
        final trackDao = ref.read(trackDaoProvider);
        final tracks = await trackDao.getFavoriteTracks();
        final items = <PlaylistItem>[];
        for (var i = 0; i < tracks.length; i++) {
          final t = tracks[i];
          final bvid = t.bvid ?? t.sourceId;

          // 改进本地音频的元数据显示：如果标题是默认值，尝试从文件名提取
          var title = t.title;
          var artist = t.artist;
          if (t.localPath != null && t.localPath!.isNotEmpty) {
            if (title == '未知标题' || title.isEmpty) {
              // 从文件路径提取文件名（不含扩展名）作为标题
              final fileName = path.basenameWithoutExtension(t.localPath!);
              title = fileName.isNotEmpty ? fileName : '未知标题';
            }
            if (artist == null || artist.isEmpty || artist == '未知艺术家') {
              artist = '未知艺术家';
            }
          }

          items.add(
            PlaylistItem(
              playlistId: playlistId,
              bvid: bvid,
              title: title,
              artist: artist,
              duration: t.duration,
              coverUrl: t.coverUrl,
              localPath: t.localPath,
              position: i,
              addedAt: t.addedAt,
            ),
          );
        }

        final newState = PlaylistDetailState.loaded(
          playlist: Playlist.favorites.copyWith(itemCount: items.length),
          items: items,
          isOwner: false,
        );

        if (!ref.mounted) return;
        state = AsyncData(newState);
        AppLogger.info('PlaylistDetailViewModel', '加载我喜欢成功: ${items.length}首');
        return;
      } catch (e) {
        AppLogger.error('PlaylistDetailViewModel', '加载我喜欢失败: $e');
        if (!ref.mounted) return;
        state = AsyncData(PlaylistDetailState.error(message: e.toString()));
        return;
      }
    }

    // 其他歌单：从 API 获取
    try {
      AppLogger.info('PlaylistDetailViewModel', '加载歌单详情: $playlistId');

      final playlistDetail = await _repository!.getPlaylistDetail(playlistId);
      final playlist = playlistDetail.playlist;
      final items = playlistDetail.items;

      // 检查所有权（用户歌单即为所有者）
      final isOwner = playlist.isUserPlaylist;

      final newState = PlaylistDetailState.loaded(
        playlist: playlist,
        items: items,
        isOwner: isOwner,
      );

      if (!ref.mounted) return;
      state = AsyncData(newState);

      AppLogger.info('PlaylistDetailViewModel', '加载歌单详情成功: ${items.length}首');
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '加载歌单详情失败: $e');
      if (!ref.mounted) return;
      state = AsyncData(PlaylistDetailState.error(message: e.toString()));
    }
  }

  /// 刷新详情
  Future<void> refresh() async {
    final playlistId = state.valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist.id,
      orElse: () => null,
    );
    if (playlistId != null) {
      await _loadDetail(playlistId);
    }
  }

  /// 移除歌单项
  Future<bool> removeItem(String bvid) async {
    final playlistId = state.valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist.id,
      orElse: () => null,
    );
    if (playlistId == null) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '移除歌单项: $bvid');

      await _repository!.removePlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
      );

      // 更新本地状态
      final currentState = state.valueOrNull;
      if (currentState is PlaylistDetailStateLoaded) {
        final updatedItems = currentState.items.where((item) => item.bvid != bvid).toList();
        final updatedPlaylist = currentState.playlist.copyWith(
          itemCount: updatedItems.length,
        );

        final newState = currentState.copyWith(
          playlist: updatedPlaylist,
          items: updatedItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      // 触发 PlaylistViewModel 刷新以同步状态
      ref.invalidate(playlistViewModelProvider);

      AppLogger.info('PlaylistDetailViewModel', '移除歌单项成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '移除歌单项失败: $e');
      return false;
    }
  }

  /// 播放全部
  ///
  /// 返回 Future<bool> 便于页面显示加载状态：
  /// ```dart
  /// onPressed: () async {
  ///   final success = await viewModel.playAll();
  ///   if (!success) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       const SnackBar(content: Text('播放失败')),
  ///     );
  ///   }
  /// }
  /// ```
  Future<bool> playAll() async {
    final items = state.valueOrNull?.maybeWhen(
      loaded: (_, items, __) => items,
      orElse: () => null,
    );
    if (items == null || items.isEmpty) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '播放全部: ${items.length}首');

      // 构建队列（过滤掉本地音乐，只处理在线音频）
      final queueItems = <PlayableAudio>[];

      for (final item in items) {
        final bvid = item.bvid;
        final localPath = item.localPath;

        // 如果有本地路径，跳过（本地音乐由另一套逻辑处理）
        if (localPath != null && localPath.isNotEmpty) {
          continue;
        }

        // 如果有 bvid，创建在线可播放对象
        if (bvid.isNotEmpty) {
          // 创建 Audio 对象
          final audio = Audio(
            id: bvid,
            title: item.title ?? '未知标题',
            artist: item.artist,
            duration: item.duration,
            coverUrl: item.coverUrl,
          );

          // 构建代理 URL
          final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
          final proxyUrl = '$baseUrl/api/v1/bilibili/proxy/audio/$bvid?format=auto';

          final playable = OnlinePlayable(audio, proxyUrl);
          queueItems.add(playable);
        }
      }

      if (queueItems.isEmpty) {
        AppLogger.warn('PlaylistDetailViewModel', '没有可播放的在线音频');
        return false;
      }

      // 后续可补充记录队列来源的能力（Phase 3）
      // 替换队列
      await ref.read(queueViewModelProvider.notifier).setQueue(
        queueItems,
        initialIndex: 0,
      );

      // 开始播放第一首
      final firstItem = queueItems.first;
      if (firstItem is OnlinePlayable) {
        await ref.read(playbackViewModelProvider.notifier).playOnlineAudio(
          audio: firstItem.original,
          proxyUrl: firstItem.proxyUrl,
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '播放全部失败: $e');
      return false;
    }
  }

  /// 点击单首歌曲播放
  ///
  /// 返回 Future<bool> 便于页面显示加载状态：
  /// ```dart
  /// onTap: () async {
  ///   final success = await viewModel.playItem(item.bvid);
  ///   if (!success) {
  ///     // 处理失败情况
  ///   }
  /// }
  /// ```
  Future<bool> playItem(String bvid) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    final items = currentState.maybeWhen(
      loaded: (_, items, _) => items,
      orElse: () => null,
    );
    if (items == null || items.isEmpty) return false;

    // 找到当前点击歌曲的索引
    final startIndex = items.indexWhere((item) => item.bvid == bvid);
    if (startIndex == -1) {
      AppLogger.warn('PlaylistDetailViewModel', '未找到歌曲: bvid=$bvid');
      return false;
    }

    final clickedItem = items[startIndex];

    // 如果是本地音乐，返回 false（由页面层处理）
    if (clickedItem.localPath != null && clickedItem.localPath!.isNotEmpty) {
      AppLogger.debug('PlaylistDetailViewModel', '跳过本地音乐，由页面层处理');
      return false;
    }

    try {
      AppLogger.info('PlaylistDetailViewModel', '播放歌曲: bvid=$bvid, 索引=$startIndex');

      // 获取本地音乐列表（用于匹配本地路径）
      final localMusicState = ref.read(localMusicViewModelProvider);

      // 构建完整队列（包含所有歌曲）
      final queueItems = <PlayableAudio>[];
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemBvid = item.bvid;
        final localPath = item.localPath;

        // 本地音乐：转换为 LocalPlayable
        if (localPath != null && localPath.isNotEmpty) {
          // 从本地音乐库查找对应的 LocalAudio
          final localAudio = localMusicState.whenOrNull(
            data: (data) => data.map(
              initial: (_) => null as LocalAudio?,
              loading: (_) => null as LocalAudio?,
              loaded: (data) {
                // 手动查找匹配的音频
                for (final audio in data.audios) {
                  if (audio.filePath == localPath) {
                    return audio;
                  }
                }
                return null as LocalAudio?;
              },
              importing: (_) => null as LocalAudio?,
              error: (_) => null as LocalAudio?,
            ),
          );

          if (localAudio != null) {
            queueItems.add(LocalPlayable.fromAudio(localAudio));
          }
          continue;
        }

        // 在线音乐：创建 OnlinePlayable
        if (itemBvid.isNotEmpty) {
          final audio = Audio(
            id: itemBvid,
            title: item.title ?? '未知标题',
            artist: item.artist,
            duration: item.duration,
            coverUrl: item.coverUrl,
          );

          final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
          final proxyUrl = '$baseUrl/api/v1/bilibili/proxy/audio/$itemBvid?format=auto';

          final playable = OnlinePlayable(audio, proxyUrl);
          queueItems.add(playable);
        }
      }

      if (queueItems.isEmpty) {
        AppLogger.warn('PlaylistDetailViewModel', '没有可播放的音频');
        return false;
      }

      // 替换队列（从点击的歌曲索引开始）
      await ref.read(queueViewModelProvider.notifier).setQueue(
        queueItems,
        initialIndex: startIndex,
      );

      // 播放点击的歌曲（使用 startIndex）
      final clickedPlayable = queueItems[startIndex];
      if (clickedPlayable is OnlinePlayable) {
        await ref.read(playbackViewModelProvider.notifier).playOnlineAudio(
          audio: clickedPlayable.original,
          proxyUrl: clickedPlayable.proxyUrl,
        );
      } else if (clickedPlayable is LocalPlayable) {
        await ref.read(playbackViewModelProvider.notifier).playLocalAudio(
          clickedPlayable.original.filePath,
          title: clickedPlayable.original.title,
          artist: clickedPlayable.original.artist,
          albumArt: clickedPlayable.original.albumArt,
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '播放歌曲失败: $e');
      return false;
    }
  }

  /// 批量下载歌单中的音频
  ///
  /// 返回成功添加的下载任务数量
  Future<int> downloadAllItems() async {
    final items = state.valueOrNull?.maybeWhen(
      loaded: (_, items, __) => items,
      orElse: () => null,
    );
    if (items == null || items.isEmpty) return 0;

    int addedCount = 0;
    int skippedLocal = 0;
    int skippedNoBvid = 0;

    try {
      AppLogger.info('PlaylistDetailViewModel', '批量下载: ${items.length}首');

      final downloadDir = await _getDownloadDirectory();
      final downloadNotifier = ref.read(downloadViewModelProvider.notifier);

      for (final item in items) {
        // 跳过本地音乐
        if (item.localPath?.isNotEmpty == true) {
          skippedLocal++;
          continue;
        }

        // 跳过没有 bvid 的项
        if (item.bvid.isEmpty) {
          skippedNoBvid++;
          continue;
        }

        // 添加到下载队列
        try {
          final sanitizedTitle = _sanitizeTitle(item.title ?? '未知');
          final savePath = '$downloadDir$sanitizedTitle.mp3';

          await downloadNotifier.addDownload(
            bvid: item.bvid,
            savePath: savePath,
            title: item.title,
            artist: item.artist,
            coverUrl: item.coverUrl,
          );
          addedCount++;
        } catch (e) {
          // 任务已存在或其他错误，继续处理下一项
          AppLogger.debug('PlaylistDetailViewModel', '跳过下载: ${item.bvid} - $e');
        }
      }

      AppLogger.info('PlaylistDetailViewModel',
        '批量下载完成: 添加$addedCount, 跳过本地$skippedLocal, 跳过无BVID$skippedNoBvid');

      return addedCount;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '批量下载失败: $e');
      return addedCount;
    }
  }

  Future<String> _getDownloadDirectory() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception('系统下载目录不可用');
      }

      final appDownloadDir = Directory('${downloadDir.path}${path.separator}ListenVision');
      if (!await appDownloadDir.exists()) {
        await appDownloadDir.create(recursive: true);
      }

      return '${appDownloadDir.path}${path.separator}';
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '获取下载目录失败: $e');
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${docDir.path}${path.separator}Downloads');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return '${fallbackDir.path}${path.separator}';
      } catch (e) {
        AppLogger.error('PlaylistDetailViewModel', '获取备用目录失败: $e');
        return '';
      }
    }
  }

  String _sanitizeTitle(String input) {
    const pattern = r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 更新歌单信息
  Future<bool> updatePlaylist({
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    final playlistId = state.valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist.id,
      orElse: () => null,
    );
    if (playlistId == null) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '更新歌单: $playlistId');

      final updatedPlaylist = await _repository!.updatePlaylist(
        id: playlistId,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      if (updatedPlaylist != null) {
        final currentState = state.valueOrNull;
        if (currentState is PlaylistDetailStateLoaded) {
          final newState = currentState.copyWith(playlist: updatedPlaylist);
          if (!ref.mounted) return true;
          state = AsyncData(newState);
        }

        // 触发 PlaylistViewModel 刷新以同步状态
        ref.invalidate(playlistViewModelProvider);

        AppLogger.info('PlaylistDetailViewModel', '更新歌单成功');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '更新歌单失败: $e');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist() async {
    final playlistId = state.valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist.id,
      orElse: () => null,
    );
    if (playlistId == null) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '删除歌单: $playlistId');

      await _repository!.deletePlaylist(playlistId);

      // 触发 PlaylistViewModel 刷新以同步状态
      ref.invalidate(playlistViewModelProvider);

      AppLogger.info('PlaylistDetailViewModel', '删除歌单成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '删除歌单失败: $e');
      return false;
    }
  }

  // ==================== 批量操作功能 ====================

  /// 进入批量操作模式
  void enterBatchMode() {
    final items = state.valueOrNull?.maybeWhen(
      loaded: (_, items, __) => items,
      orElse: () => <PlaylistItem>[],
    ) ?? [];

    _batchState.value = BatchOperationState(
      isInBatchMode: true,
      totalItems: items.length,
    );
    AppLogger.info('PlaylistDetailViewModel', '进入批量模式: ${items.length}项');
  }

  /// 退出批量操作模式
  void exitBatchMode() {
    _batchState.value = const BatchOperationState();
    AppLogger.info('PlaylistDetailViewModel', '退出批量模式');
  }

  /// 切换项目的选中状态
  void toggleSelection(String bvid) {
    final current = _batchState.value;
    final selected = Set<String>.from(current.selectedBvids);

    if (selected.contains(bvid)) {
      selected.remove(bvid);
    } else {
      selected.add(bvid);
    }

    _batchState.value = current.copyWith(selectedBvids: selected);
  }

  /// 全选/取消全选
  void toggleSelectAll() {
    final current = _batchState.value;

    if (current.isAllSelected) {
      // 取消全选
      _batchState.value = current.copyWith(selectedBvids: {});
    } else {
      // 全选
      final items = state.valueOrNull?.maybeWhen(
        loaded: (_, items, __) => items,
        orElse: () => <PlaylistItem>[],
      ) ?? [];
      final allBvids = items.map((i) => i.bvid).toSet();
      _batchState.value = current.copyWith(selectedBvids: allBvids);
    }
  }

  /// 批量移除选中的项目
  Future<BatchOperationResult> batchRemoveItems(List<String> bvids) async {
    final playlistId = state.valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist.id,
      orElse: () => null,
    );

    if (playlistId == null) {
      return BatchOperationResult(
        success: 0,
        failed: bvids.length,
        failedItems: bvids,
      );
    }

    int success = 0;
    int failed = 0;
    final failedItems = <String>[];

    AppLogger.info('PlaylistDetailViewModel', '开始批量移除: ${bvids.length}项');

    // 逐个移除（后端暂不支持批量删除接口）
    for (final bvid in bvids) {
      try {
        final result = await _repository!.removePlaylistItem(
          playlistId: playlistId,
          bvid: bvid,
        );
        if (result) {
          success++;
        } else {
          failed++;
          failedItems.add(bvid);
        }
      } catch (e) {
        failed++;
        failedItems.add(bvid);
        AppLogger.error('PlaylistDetailViewModel', '批量移除失败: $bvid, $e');
      }
    }

    // 更新本地状态 - 移除成功的项目
    if (success > 0) {
      final currentState = state.valueOrNull;
      if (currentState is PlaylistDetailStateLoaded) {
        final updatedItems = currentState.items
            .where((item) => !bvids.contains(item.bvid))
            .toList();
        final updatedPlaylist = currentState.playlist.copyWith(
          itemCount: updatedItems.length,
        );

        state = AsyncData(currentState.copyWith(
          playlist: updatedPlaylist,
          items: updatedItems,
        ));
      }

      // 同步更新批量状态中的总数和清空选中
      _batchState.value = _batchState.value.copyWith(
        totalItems: _batchState.value.totalItems - success,
        selectedBvids: {},
      );

      // 触发 PlaylistViewModel 刷新
      ref.invalidate(playlistViewModelProvider);
    }

    AppLogger.info(
      'PlaylistDetailViewModel',
      '批量移除完成: 成功$success, 失败$failed',
    );

    return BatchOperationResult(
      success: success,
      failed: failed,
      failedItems: failedItems,
    );
  }
}

/// Provider定义
@riverpod
PlaylistRepository playlistRepository(Ref ref) {
  return PlaylistRepository();
}
