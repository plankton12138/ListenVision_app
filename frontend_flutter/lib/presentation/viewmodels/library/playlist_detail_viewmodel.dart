import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../models/playlist.dart';
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

      // 从 PlaylistViewModel 获取歌单信息
      final playlistState = ref.read(playlistViewModelProvider);
      final playlist = playlistState.valueOrNull?.playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => Playlist.favorites,
      ) ?? Playlist.favorites;

      // 加载歌单项
      final items = await _repository!.getPlaylistItems(playlistId);

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
  Future<bool> playAll() async {
    final items = state.valueOrNull?.maybeWhen(
      loaded: (_, items, __) => items,
      orElse: () => null,
    );
    if (items == null || items.isEmpty) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '播放全部: ${items.length}首');

      // TODO: 实现播放队列逻辑
      // ref.read(queueViewModelProvider.notifier).replaceAll(items);
      // ref.read(playerViewModelProvider.notifier).play();

      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '播放全部失败: $e');
      return false;
    }
  }

  /// 下载全部
  Future<bool> downloadAll() async {
    final items = state.valueOrNull?.maybeWhen(
      loaded: (_, items, __) => items,
      orElse: () => null,
    );
    if (items == null || items.isEmpty) return false;

    try {
      AppLogger.info('PlaylistDetailViewModel', '下载全部: ${items.length}首');

      // TODO: 实现批量下载逻辑
      // for (final item in items) {
      //   ref.read(downloadViewModelProvider.notifier).addDownload(item.bvid);
      // }

      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '下载全部失败: $e');
      return false;
    }
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
