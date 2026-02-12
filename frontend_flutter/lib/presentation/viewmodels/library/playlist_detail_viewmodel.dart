import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../models/audio.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/playlist.dart';
import '../player/player_viewmodel.dart';
import '../player/queue_viewmodel.dart';
import '../system/download_viewmodel.dart';
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

/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理
@riverpod
class PlaylistDetailViewModel extends _$PlaylistDetailViewModel {
  PlaylistRepository? _repository;

  @override
  Future<PlaylistDetailState> build(String playlistId) async {
    _repository = ref.watch(playlistRepositoryProvider);
    await _loadDetail(playlistId);
    return state.valueOrNull ?? const PlaylistDetailState.initial();
  }

  /// 加载歌单详情
  Future<void> _loadDetail(String playlistId) async {
    state = const AsyncLoading();
    try {
      AppLogger.info('PlaylistDetailViewModel', '加载歌单详情: $playlistId');

      // 直接从 API 获取歌单详情，确保数据是最新的
      // 这样即使歌单不在 PlaylistViewModel 缓存中也能正确加载
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
        if (bvid != null && bvid.isNotEmpty) {
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

      // TODO: 记录队列来源（Phase 3）
      // 替换队列
      await ref.read(queueViewModelProvider.notifier).setQueue(
        queueItems,
        initialIndex: 0,
      );

      // 开始播放第一首
      final firstItem = queueItems.first;
      if (firstItem is OnlinePlayable) {
        await ref.read(playerViewModelProvider.notifier).playOnlineAudio(
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

      // 构建队列（从当前歌曲开始）
      final queueItems = <PlayableAudio>[];
      for (int i = startIndex; i < items.length; i++) {
        final item = items[i];
        final itemBvid = item.bvid;
        final localPath = item.localPath;

        // 跳过本地音乐
        if (localPath != null && localPath.isNotEmpty) {
          continue;
        }

        if (itemBvid != null && itemBvid.isNotEmpty) {
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
        AppLogger.warn('PlaylistDetailViewModel', '没有可播放的在线音频');
        return false;
      }

      // 替换队列
      await ref.read(queueViewModelProvider.notifier).setQueue(
        queueItems,
        initialIndex: 0,
      );

      // 开始播放第一首（即用户点击的歌曲）
      final firstItem = queueItems.first;
      if (firstItem is OnlinePlayable) {
        await ref.read(playerViewModelProvider.notifier).playOnlineAudio(
          audio: firstItem.original,
          proxyUrl: firstItem.proxyUrl,
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
        if (item.bvid == null || item.bvid!.isEmpty) {
          skippedNoBvid++;
          continue;
        }

        // 添加到下载队列
        try {
          final sanitizedTitle = _sanitizeTitle(item.title ?? '未知');
          final savePath = '$downloadDir$sanitizedTitle.mp3';

          await downloadNotifier.addDownload(
            bvid: item.bvid!,
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
}

/// Provider定义
@riverpod
PlaylistRepository playlistRepository(Ref ref) {
  // 使用与 PlaylistViewModel 相同的配置
  return PlaylistRepository(localOnlyMode: true);
}
