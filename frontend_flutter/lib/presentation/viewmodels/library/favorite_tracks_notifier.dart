import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/repository_providers.dart';
import 'playlist_viewmodel.dart';

part 'favorite_tracks_notifier.g.dart';

/// 收藏状态 Notifier
///
/// 独立管理收藏曲目 ID 集合，返回 Set<String>。
@Riverpod(keepAlive: true)
class FavoriteTracksNotifier extends _$FavoriteTracksNotifier {
  @override
  Future<Set<String>> build() async {
    final repo = ref.watch(playlistRepositoryProvider);
    return repo.getFavoriteTrackIds();
  }

  /// 切换收藏状态，返回操作后的状态
  Future<bool> toggle(
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
  }) async {
    final trackRepo = ref.watch(trackRepositoryProvider);

    final isFav = state.value?.contains(bvid) ?? false;
    final target = !isFav;

    // 切换 tracks.is_favorite
    final track = await ref.read(trackDaoProvider).getBySourceId(bvid);
    if (track != null) {
      await trackRepo.toggleFavorite(track.id, target,
        title: title ?? track.title,
        artist: artist ?? track.artist,
        duration: duration ?? track.duration,
        coverUrl: coverUrl ?? track.coverUrl,
      );
    }

    // 乐观更新内存状态
    final current = Set<String>.from(state.value ?? {});
    if (target) {
      current.add(bvid);
    } else {
      current.remove(bvid);
    }
    state = AsyncData(current);

    AppLogger.info('FavoriteTracksNotifier', '收藏切换: $bvid -> $target');
    return target;
  }

  /// 检查是否已收藏
  bool isFavorited(String bvid) =>
      state.value?.contains(bvid) ?? false;
}
