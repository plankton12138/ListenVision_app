import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../models/playlist.dart';

part 'playlist_viewmodel.g.dart';

/// 歌单列表 Notifier
///
/// 管理用户歌单列表，使用 Riverpod 内置 AsyncValue<List<Playlist>>
@Riverpod(keepAlive: true)
class PlaylistListNotifier extends _$PlaylistListNotifier {
  PlaylistRepository? _repository;

  /// 当前正在查看的歌单ID
  String? _currentPlaylistId;

  String? get currentPlaylistId => _currentPlaylistId;

  @override
  Future<List<Playlist>> build() async {
    _repository = ref.watch(playlistRepositoryProvider);

    try {
      AppLogger.info('PlaylistListNotifier', '初始化歌单列表');
      final playlists = await _repository!.getUserPlaylists();
      AppLogger.info('PlaylistListNotifier', '加载歌单成功: ${playlists.length}个');
      return playlists;
    } catch (e) {
      AppLogger.error('PlaylistListNotifier', '初始化失败: $e');
      return [];
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistListNotifier', '创建歌单: $name');

      final newPlaylist = await _repository!.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      if (newPlaylist != null && state.value != null) {
        state = AsyncData([...state.value!, newPlaylist]);
      }

      if (newPlaylist != null) {
        AppLogger.info('PlaylistListNotifier', '创建歌单成功: ${newPlaylist.id}');
        // 异步生成封面（不阻塞创建流程）
        _repository!.generatePlaylistCover(newPlaylist.id).then((coverPath) {
          if (coverPath != null) {
            _repository!.updatePlaylist(
              id: newPlaylist.id,
              coverUrl: coverPath,
            );
          }
        });
      }
      return newPlaylist;
    } catch (e) {
      AppLogger.error('PlaylistListNotifier', '创建歌单失败: $e');
      return null;
    }
  }

  /// 更新歌单
  Future<bool> updatePlaylist(
    String id, {
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistListNotifier', '更新歌单: $id');

      final updated = await _repository!.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      if (updated != null && state.value != null) {
        state = AsyncData(
          state.value!.map((p) => p.id == id ? updated : p).toList(),
        );
      }

      if (updated != null) {
        AppLogger.info('PlaylistListNotifier', '更新歌单成功: $id');
      }
      return updated != null;
    } catch (e) {
      AppLogger.error('PlaylistListNotifier', '更新歌单失败: $e');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String id) async {
    try {
      AppLogger.info('PlaylistListNotifier', '删除歌单: $id');

      await _repository!.deletePlaylist(id);

      if (state.value != null) {
        state = AsyncData(
          state.value!.where((p) => p.id != id).toList(),
        );
      }

      AppLogger.info('PlaylistListNotifier', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistListNotifier', '删除歌单失败: $e');
      return false;
    }
  }

  /// 添加音频到歌单
  Future<bool> addItem(
    String playlistId,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      AppLogger.info('PlaylistListNotifier', '添加音频到歌单: $bvid -> $playlistId');

      await _repository!.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        title: title,
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
        position: position,
      );

      if (state.value != null) {
        state = AsyncData(
          state.value!.map((p) {
            if (p.id == playlistId) {
              return p.copyWith(itemCount: p.itemCount + 1);
            }
            return p;
          }).toList(),
        );
      }

      AppLogger.info('PlaylistListNotifier', '添加音频到歌单成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistListNotifier', '添加音频到歌单失败: $e');
      return false;
    }
  }

  /// 设置当前正在查看的歌单ID
  void setCurrentPlaylistId(String? playlistId) {
    _currentPlaylistId = playlistId;
  }

  /// 清空数据（登出时调用）
  void clear() {
    _currentPlaylistId = null;
    state = const AsyncData([]);
    AppLogger.info('PlaylistListNotifier', '已清空数据');
  }
}

/// Provider定义
@riverpod
PlaylistRepository playlistRepository(Ref ref) {
  return PlaylistRepository();
}

@riverpod
SharedStorageService sharedStorageService(Ref ref) {
  return SharedStorageService.instance;
}
