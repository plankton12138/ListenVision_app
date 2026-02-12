import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../models/playlist.dart';

part 'playlist_viewmodel.freezed.dart';
part 'playlist_viewmodel.g.dart';

/// 歌单状态
@freezed
abstract class PlaylistState with _$PlaylistState {
  /// 初始状态
  const factory PlaylistState.initial() = PlaylistStateInitial;

  /// 已加载
  const factory PlaylistState.loaded({
    required List<Playlist> playlists,
    required List<Playlist> userPlaylists,
    required List<Playlist> systemPlaylists,
    Playlist? favoritesPlaylist,
    Playlist? nowPlayingPlaylist,
    @Default([]) List<PlaylistItem> favoritesItems,
    @Default([]) List<PlaylistItem> nowPlayingItems,
  }) = PlaylistStateLoaded;

  /// 错误
  const factory PlaylistState.error({
    required String message,
  }) = PlaylistStateError;
}

/// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责歌单、收藏、播放队列的状态管理
@Riverpod(keepAlive: true)
class PlaylistViewModel extends _$PlaylistViewModel {
  PlaylistRepository? _repository;
  SharedStorageService? _storage;

  /// 收藏缓存（用于快速检查）
  final Set<String> _favoritedBvids = {};

  /// 当前正在查看的歌单ID
  String? _currentPlaylistId;

  String? get currentPlaylistId => _currentPlaylistId;

  @override
  Future<PlaylistState> build() async {
    _repository = ref.watch(playlistRepositoryProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    final token = await _storage!.getString('auth_token');
    if (token != null) {
      return await _initialize(token);
    }

    return const PlaylistState.initial();
  }

  /// 初始化（用户登录后调用）
  Future<PlaylistState> _initialize(String token) async {
    try {
      AppLogger.info('PlaylistViewModel', '初始化歌单管理');

      await _loadPlaylists(token);
      await _loadFavoritesFromLocal();

      // 如果系统歌单已创建，加载播放队列
      final nowPlayingId = this.state.valueOrNull?.nowPlayingPlaylist?.id;
      if (nowPlayingId != null) {
        await loadNowPlaying(token);
      }

      return this.state.valueOrNull ?? const PlaylistState.initial();
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '初始化失败: $e');
      return PlaylistState.error(message: e.toString());
    }
  }

  /// 从服务器加载歌单列表
  Future<void> loadPlaylists(String token) async {
    state = const AsyncLoading();
    await _loadPlaylists(token);
  }

  Future<PlaylistState> _loadPlaylists(String token) async {
    try {
      final playlists = await _repository!.getUserPlaylists();

      // 分离系统歌单和用户歌单
      final systemPlaylists = playlists.where((p) => p.isSystem).toList();
      final userPlaylists = playlists.where((p) => p.isUserPlaylist).toList();

      // 查找系统歌单
      final favoritesPlaylist = systemPlaylists.firstWhere(
        (p) => p.isFavorites,
        orElse: () => Playlist.favorites,
      );

      final nowPlayingPlaylist = systemPlaylists.firstWhere(
        (p) => p.isNowPlaying,
        orElse: () => Playlist.nowPlaying,
      );

      // 保留当前列表数据
      final currentFavorites = state.valueOrNull?.favoritesItems ?? [];
      final currentNowPlaying = state.valueOrNull?.nowPlayingItems ?? [];

      final newState = PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        favoritesPlaylist: favoritesPlaylist,
        nowPlayingPlaylist: nowPlayingPlaylist,
        favoritesItems: currentFavorites,
        nowPlayingItems: currentNowPlaying,
      );

      if (!ref.mounted) return newState;
      state = AsyncData(newState);

      AppLogger.info('PlaylistViewModel', '加载歌单成功: ${playlists.length}个');
      return newState;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载歌单失败: $e');
      // 尝试从本地加载
      return await _loadPlaylistsFromLocal();
    }
  }

  /// 加载收藏列表
  Future<void> loadFavorites(String token) async {
    try {
      final favoritesId = state.valueOrNull?.favoritesPlaylist?.id;
      if (favoritesId == null) return;

      final items = await _repository!.getFavorites();

      final currentState = state.valueOrNull;
      if (currentState != null) {
        final newState = PlaylistState.loaded(
          playlists: currentState.playlists,
          userPlaylists: currentState.userPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: items,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return;
        state = AsyncData(newState);
      }

      _updateFavoritedCache();

      AppLogger.info('PlaylistViewModel', '加载收藏成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载收藏失败: $e');
      await _loadFavoritesFromLocal();
    }
  }

  /// 加载播放队列
  Future<void> loadNowPlaying(String token) async {
    try {
      final nowPlayingId = state.valueOrNull?.nowPlayingPlaylist?.id;
      if (nowPlayingId == null) return;

      final items = await _repository!.getPlaylistItems(nowPlayingId);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        final newState = PlaylistState.loaded(
          playlists: currentState.playlists,
          userPlaylists: currentState.userPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: items,
        );

        if (!ref.mounted) return;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '加载播放队列成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载播放队列失败: $e');
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist(
    String token, {
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '创建歌单: $name');

      final newPlaylist = await _repository!.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      final currentState = state.valueOrNull;
      if (currentState is PlaylistStateLoaded && newPlaylist != null) {
        final newState = currentState.copyWith(
          playlists: [...currentState.playlists, newPlaylist],
          userPlaylists: [...currentState.userPlaylists.whereType<Playlist>(), newPlaylist],
        );

        if (!ref.mounted) return newPlaylist;
        state = AsyncData(newState);
      }

      if (newPlaylist != null) {
        AppLogger.info('PlaylistViewModel', '创建歌单成功: ${newPlaylist.id}');
      }
      return newPlaylist;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '创建歌单失败: $e');
      return null;
    }
  }

  /// 更新歌单
  Future<bool> updatePlaylist(
    String token,
    String id, {
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '更新歌单: $id');

      final updatedPlaylist = await _repository!.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      final currentState = state.valueOrNull;
      if (currentState != null && updatedPlaylist != null) {
        final updatedPlaylists = currentState.playlists.map((p) {
          return p.id == id ? updatedPlaylist : p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          return p.id == id ? updatedPlaylist : p;
        }).toList();

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist?.id == id
              ? updatedPlaylist
              : currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist?.id == id
              ? updatedPlaylist
              : currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      if (updatedPlaylist != null) {
        AppLogger.info('PlaylistViewModel', '更新歌单成功: $id');
      }
      return updatedPlaylist != null;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '更新歌单失败: $e');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String token, String id) async {
    try {
      AppLogger.info('PlaylistViewModel', '删除歌单: $id');

      await _repository!.deletePlaylist(id);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedPlaylists = currentState.playlists.where((p) => p.id != id).toList();
        final updatedUserPlaylists = currentState.userPlaylists.where((p) => p.id != id).toList();

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist?.id == id ? null : currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist?.id == id ? null : currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '删除歌单失败: $e');
      return false;
    }
  }

  /// 添加音频到歌单
  Future<bool> addItem(
    String token,
    String playlistId,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '添加音频到歌单: $bvid -> $playlistId');

      await _repository!.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        title: title,
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
        position: position,
      );

      final currentState = state.valueOrNull;
      if (currentState != null) {
        // 更新歌单的itemCount
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: p.itemCount + 1);
          }
          return p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: p.itemCount + 1);
          }
          return p;
        }).toList();

        List<PlaylistItem> updatedFavorites = currentState.favoritesItems;
        if (playlistId == currentState.favoritesPlaylist?.id) {
          final newItem = PlaylistItem(
            bvid: bvid,
            title: title,
            artist: artist,
            duration: duration,
            coverUrl: coverUrl,
            position: currentState.favoritesItems.length,
            addedAt: DateTime.now(),
          );
          updatedFavorites = [...currentState.favoritesItems, newItem];
          _favoritedBvids.add(bvid);
          _saveFavoritesToLocal();
        }

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: updatedFavorites,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '添加音频到歌单成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '添加音频到歌单失败: $e');
      return false;
    }
  }

  /// 从歌单移除音频
  Future<bool> removeItem(String token, String playlistId, String bvid) async {
    try {
      AppLogger.info('PlaylistViewModel', '从歌单移除音频: $bvid from $playlistId');

      await _repository!.removePlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
      );

      final currentState = state.valueOrNull;
      if (currentState != null) {
        // 更新歌单的itemCount
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
          }
          return p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
          }
          return p;
        }).toList();

        List<PlaylistItem> updatedFavorites = currentState.favoritesItems;
        if (playlistId == currentState.favoritesPlaylist?.id) {
          updatedFavorites = currentState.favoritesItems.where((item) => item.bvid != bvid).toList();
          _favoritedBvids.remove(bvid);
          _saveFavoritesToLocal();
        }

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: updatedFavorites,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '从歌单移除音频成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从歌单移除音频失败: $e');
      return false;
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(
    String token,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '切换收藏状态: $bvid');

      final added = await _repository!.toggleFavorite(bvid);

      if (added) {
        _favoritedBvids.add(bvid);
        await loadFavorites(token);
      } else {
        _favoritedBvids.remove(bvid);

        final currentState = state.valueOrNull;
        if (currentState != null) {
          final updatedItems = currentState.favoritesItems.where((item) => item.bvid != bvid).toList();
          final newState = PlaylistState.loaded(
            playlists: currentState.playlists,
            userPlaylists: currentState.userPlaylists,
            systemPlaylists: currentState.systemPlaylists,
            favoritesPlaylist: currentState.favoritesPlaylist,
            nowPlayingPlaylist: currentState.nowPlayingPlaylist,
            favoritesItems: updatedItems,
            nowPlayingItems: currentState.nowPlayingItems,
          );

          if (!ref.mounted) return added;
          state = AsyncData(newState);
        }
      }

      await _saveFavoritesToLocal();

      AppLogger.info('PlaylistViewModel', '切换收藏状态成功: $bvid, added=$added');
      return added;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '切换收藏状态失败: $e');
      return false;
    }
  }

  /// 检查是否已收藏
  bool isFavorited(String bvid) {
    return _favoritedBvids.contains(bvid) ||
        (state.valueOrNull?.favoritesItems.any((item) => item.bvid == bvid) ?? false);
  }

  /// 设置当前正在查看的歌单ID
  void setCurrentPlaylistId(String? playlistId) {
    _currentPlaylistId = playlistId;
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    _favoritedBvids.clear();
    _currentPlaylistId = null;

    await _storage!.remove('playlists_cache');
    await _storage!.remove('favorites_cache');

    if (!ref.mounted) return;
    state = const AsyncData(PlaylistState.initial());

    AppLogger.info('PlaylistViewModel', '已清空数据');
  }

  // ==================== 私有方法 ====================

  Future<PlaylistState> _loadPlaylistsFromLocal() async {
    try {
      final playlistsJson = await _storage!.getString('playlists_cache');
      if (playlistsJson != null) {
        final data = jsonDecode(playlistsJson) as List;
        final playlists = data
            .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
            .toList();

        final systemPlaylists = playlists.where((p) => p.isSystem).toList();
        final userPlaylists = playlists.where((p) => p.isUserPlaylist).toList();

        final favoritesPlaylist = systemPlaylists.firstWhere(
          (p) => p.isFavorites,
          orElse: () => Playlist.favorites,
        );

        final nowPlayingPlaylist = systemPlaylists.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => Playlist.nowPlaying,
        );

        return PlaylistState.loaded(
          playlists: playlists,
          userPlaylists: userPlaylists,
          systemPlaylists: systemPlaylists,
          favoritesPlaylist: favoritesPlaylist,
          nowPlayingPlaylist: nowPlayingPlaylist,
          favoritesItems: const [],
          nowPlayingItems: const [],
        );
      }

      return const PlaylistState.initial();
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载歌单失败: $e');
      return const PlaylistState.initial();
    }
  }

  Future<void> _loadFavoritesFromLocal() async {
    try {
      final favoritesJson = await _storage!.getString('favorites_cache');
      if (favoritesJson != null) {
        final data = jsonDecode(favoritesJson) as List;
        final items = data
            .map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>))
            .toList();

        final currentState = state.valueOrNull;
        if (currentState != null) {
          final newState = PlaylistState.loaded(
            playlists: currentState.playlists,
            userPlaylists: currentState.userPlaylists,
            systemPlaylists: currentState.systemPlaylists,
            favoritesPlaylist: currentState.favoritesPlaylist,
            nowPlayingPlaylist: currentState.nowPlayingPlaylist,
            favoritesItems: items,
            nowPlayingItems: currentState.nowPlayingItems,
          );

          if (!ref.mounted) return;
          state = AsyncData(newState);
        }

        _updateFavoritedCache();

        AppLogger.info('PlaylistViewModel', '从本地加载收藏成功');
      }
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final json = jsonEncode(state.valueOrNull?.favoritesItems.map((f) => f.toJson()).toList() ?? []);
      await _storage!.setString('favorites_cache', json);
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存本地收藏失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    for (final item in state.valueOrNull?.favoritesItems ?? []) {
      _favoritedBvids.add(item.bvid);
    }
  }
}

/// PlaylistState 扩展方法，方便访问属性
extension PlaylistStateX on PlaylistState {
  List<Playlist> get playlists => maybeWhen(
        loaded: (playlists, _, __, ___, ____, _____, ______) => playlists,
        orElse: () => const [],
      );

  List<Playlist> get userPlaylists => maybeWhen(
        loaded: (_, userPlaylists, __, ___, ____, _____, ______) => userPlaylists,
        orElse: () => const [],
      );

  List<Playlist> get systemPlaylists => maybeWhen(
        loaded: (_, __, systemPlaylists, ___, ____, _____, ______) => systemPlaylists,
        orElse: () => const [],
      );

  Playlist? get favoritesPlaylist => maybeWhen(
        loaded: (_, __, ___, favorites, ____, _____, ______) => favorites,
        orElse: () => null,
  );

  Playlist? get nowPlayingPlaylist => maybeWhen(
        loaded: (_, __, ___, ____, nowPlaying, _____, ______) => nowPlaying,
        orElse: () => null,
      );

  List<PlaylistItem> get favoritesItems => maybeWhen(
        loaded: (_, __, ___, ____, _____, favoritesItems, ______) => favoritesItems,
        orElse: () => const [],
      );

  List<PlaylistItem> get nowPlayingItems => maybeWhen(
        loaded: (_, __, ___, ____, _____, ______, nowPlayingItems) => nowPlayingItems,
        orElse: () => const [],
      );
}

/// Provider定义
@riverpod
PlaylistRepository playlistRepository(Ref ref) {
  // 启用本地优先模式
  return PlaylistRepository(localOnlyMode: true);
}

@riverpod
SharedStorageService sharedStorageService(Ref ref) {
  return SharedStorageService.instance;
}
