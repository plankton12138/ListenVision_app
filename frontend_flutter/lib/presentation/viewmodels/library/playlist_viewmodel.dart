import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../models/playlist.dart';

part 'playlist_viewmodel.freezed.dart';
part 'playlist_viewmodel.g.dart';

/// 歌单状态
@freezed
class PlaylistState with _$PlaylistState {
  /// 初始状态
  const factory PlaylistState.initial() = PlaylistStateInitial;

  /// 加载中
  const factory PlaylistState.loading() = PlaylistStateLoading;

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

  /// 操作中（创建/更新/删除）
  const factory PlaylistState.operating({
    required List<Playlist> playlists,
    required List<Playlist> userPlaylists,
    required List<Playlist> systemPlaylists,
    Playlist? favoritesPlaylist,
    Playlist? nowPlayingPlaylist,
    @Default([]) List<PlaylistItem> favoritesItems,
    @Default([]) List<PlaylistItem> nowPlayingItems,
    String? operationMessage,
  }) = PlaylistStateOperating;
}

/// 歌单管理 ViewModel
///
/// 负责歌单、收藏、播放队列的状态管理
class PlaylistViewModel extends StateNotifier<PlaylistState> {
  final PlaylistRepository _repository;
  final SharedStorageService _storage;

  /// 收藏缓存（用于快速检查）
  final Set<String> _favoritedBvids = {};

  /// 当前正在查看的歌单ID
  String? _currentPlaylistId;

  String? get currentPlaylistId => _currentPlaylistId;

  PlaylistViewModel(this._repository, this._storage)
      : super(const PlaylistState.initial()) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    final token = await _storage.getString('auth_token');
    if (token != null) {
      await initialize(token);
    }
  }

  /// 初始化（用户登录后调用）
  Future<void> initialize(String token) async {
    try {
      state = const PlaylistState.loading();
      AppLogger.info('PlaylistViewModel', '初始化歌单管理');

      await loadPlaylists(token);
      await _loadFavoritesFromLocal();

      // 如果系统歌单已创建，加载播放队列
      state.maybeWhen(
        loaded: (_, __, ___, favorites, nowPlaying, ____, _____) async {
          if (nowPlaying?.id != null) {
            await loadNowPlaying(token);
          }
        },
        orElse: () {},
      );
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '初始化失败: $e');
      state = PlaylistState.error(message: e.toString());
    }
  }

  /// 从服务器加载歌单列表
  Future<void> loadPlaylists(String token) async {
    try {
      final playlists = await _repository.getUserPlaylists();

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

      state = PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        favoritesPlaylist: favoritesPlaylist,
        nowPlayingPlaylist: nowPlayingPlaylist,
        favoritesItems: state.maybeWhen(
          loaded: (_, __, ___, ____, _____, items, ___) => items,
          operating: (_, __, ___, ____, _____, items, ___) => items,
          orElse: () => const [],
        ),
        nowPlayingItems: state.maybeWhen(
          loaded: (_, __, ___, ____, _____, ___, items) => items,
          operating: (_, __, ___, ____, _____, ___, items) => items,
          orElse: () => const [],
        ),
      );

      AppLogger.info('PlaylistViewModel', '加载歌单成功: ${playlists.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载歌单失败: $e');
      // 尝试从本地加载
      await _loadPlaylistsFromLocal();
    }
  }

  /// 加载收藏列表
  Future<void> loadFavorites(String token) async {
    try {
      final favoritesId = state.maybeWhen(
        loaded: (_, __, ___, favorites, ___, ___, ___) => favorites?.id,
        operating: (_, __, ___, favorites, ___, ___, ___) => favorites?.id,
        orElse: () => null,
      );

      if (favoritesId == null) return;

      final items = await _repository.getFavorites();

      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, _, nowPlayingItems) {
          state = PlaylistState.loaded(
            playlists: playlists,
            userPlaylists: userPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: items,
            nowPlayingItems: nowPlayingItems,
          );
          _updateFavoritedCache();
        },
        orElse: () {},
      );

      AppLogger.info('PlaylistViewModel', '加载收藏成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载收藏失败: $e');
      await _loadFavoritesFromLocal();
    }
  }

  /// 加载播放队列
  Future<void> loadNowPlaying(String token) async {
    try {
      final nowPlayingId = state.maybeWhen(
        loaded: (_, __, ___, ___, nowPlaying, ___, ___) => nowPlaying?.id,
        operating: (_, __, ___, ___, nowPlaying, ___, ___) => nowPlaying?.id,
        orElse: () => null,
      );

      if (nowPlayingId == null) return;

      final items = await _repository.getPlaylistItems(nowPlayingId);

      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, _) {
          state = PlaylistState.loaded(
            playlists: playlists,
            userPlaylists: userPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: favoritesItems,
            nowPlayingItems: items,
          );
        },
        orElse: () {},
      );

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

      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems) {
          state = PlaylistState.operating(
            playlists: playlists,
            userPlaylists: userPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: favoritesItems,
            nowPlayingItems: nowPlayingItems,
            operationMessage: '正在创建歌单...',
          );
        },
        orElse: () {},
      );

      final newPlaylist = await _repository.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      state.maybeWhen(
        operating: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems, _) {
          final updatedPlaylists = [...playlists, newPlaylist];
          final updatedUserPlaylists = [...userPlaylists, newPlaylist];

          state = PlaylistState.loaded(
            playlists: updatedPlaylists,
            userPlaylists: updatedUserPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: favoritesItems,
            nowPlayingItems: nowPlayingItems,
          );
        },
        orElse: () {},
      );

      AppLogger.info('PlaylistViewModel', '创建歌单成功: ${newPlaylist.id}');
      return newPlaylist;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '创建歌单失败: $e');
      _revertToLoadedState();
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

      final updatedPlaylist = await _repository.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems) {
          final updatedPlaylists = playlists.map((p) {
            return p.id == id ? updatedPlaylist : p;
          }).toList();

          final updatedUserPlaylists = userPlaylists.map((p) {
            return p.id == id ? updatedPlaylist : p;
          }).toList();

          state = PlaylistState.loaded(
            playlists: updatedPlaylists,
            userPlaylists: updatedUserPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist?.id == id
                ? updatedPlaylist
                : favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist?.id == id
                ? updatedPlaylist
                : nowPlayingPlaylist,
            favoritesItems: favoritesItems,
            nowPlayingItems: nowPlayingItems,
          );
        },
        orElse: () {},
      );

      AppLogger.info('PlaylistViewModel', '更新歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '更新歌单失败: $e');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String token, String id) async {
    try {
      AppLogger.info('PlaylistViewModel', '删除歌单: $id');

      await _repository.deletePlaylist(id);

      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems) {
          final updatedPlaylists = playlists.where((p) => p.id != id).toList();
          final updatedUserPlaylists = userPlaylists.where((p) => p.id != id).toList();

          state = PlaylistState.loaded(
            playlists: updatedPlaylists,
            userPlaylists: updatedUserPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist?.id == id ? null : favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist?.id == id ? null : nowPlayingPlaylist,
            favoritesItems: favoritesItems,
            nowPlayingItems: nowPlayingItems,
          );
        },
        orElse: () {},
      );

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

      await _repository.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        position: position,
      );

      // 更新歌单的itemCount
      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems) {
          final updatedPlaylists = playlists.map((p) {
            if (p.id == playlistId) {
              return p.copyWith(itemCount: p.itemCount + 1);
            }
            return p;
          }).toList();

          final updatedUserPlaylists = userPlaylists.map((p) {
            if (p.id == playlistId) {
              return p.copyWith(itemCount: p.itemCount + 1);
            }
            return p;
          }).toList();

          // 如果是收藏歌单，更新缓存
          List<PlaylistItem> updatedFavorites = favoritesItems;
          if (playlistId == favoritesPlaylist?.id) {
            final newItem = PlaylistItem(
              bvid: bvid,
              title: title,
              artist: artist,
              duration: duration,
              coverUrl: coverUrl,
              position: favoritesItems.length,
              addedAt: DateTime.now(),
            );
            updatedFavorites = [...favoritesItems, newItem];
            _favoritedBvids.add(bvid);
            _saveFavoritesToLocal();
          }

          state = PlaylistState.loaded(
            playlists: updatedPlaylists,
            userPlaylists: updatedUserPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: updatedFavorites,
            nowPlayingItems: nowPlayingItems,
          );
        },
        orElse: () {},
      );

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

      await _repository.removePlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
      );

      // 更新歌单的itemCount
      state.maybeWhen(
        loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
            nowPlayingPlaylist, favoritesItems, nowPlayingItems) {
          final updatedPlaylists = playlists.map((p) {
            if (p.id == playlistId) {
              return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
            }
            return p;
          }).toList();

          final updatedUserPlaylists = userPlaylists.map((p) {
            if (p.id == playlistId) {
              return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
            }
            return p;
          }).toList();

          // 如果是收藏歌单，更新缓存
          List<PlaylistItem> updatedFavorites = favoritesItems;
          if (playlistId == favoritesPlaylist?.id) {
            updatedFavorites = favoritesItems.where((item) => item.bvid != bvid).toList();
            _favoritedBvids.remove(bvid);
            _saveFavoritesToLocal();
          }

          state = PlaylistState.loaded(
            playlists: updatedPlaylists,
            userPlaylists: updatedUserPlaylists,
            systemPlaylists: systemPlaylists,
            favoritesPlaylist: favoritesPlaylist,
            nowPlayingPlaylist: nowPlayingPlaylist,
            favoritesItems: updatedFavorites,
            nowPlayingItems: nowPlayingItems,
          );
        },
        orElse: () {},
      );

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

      final added = await _repository.toggleFavorite(bvid);

      if (added) {
        _favoritedBvids.add(bvid);
        await loadFavorites(token);
      } else {
        _favoritedBvids.remove(bvid);

        state.maybeWhen(
          loaded: (_, __, ___, ____, _____, favoritesItems, ___) {
            final updatedItems = favoritesItems.where((item) => item.bvid != bvid).toList();
            state = state.copyWith(
              favoritesItems: updatedItems,
            );
          },
          orElse: () {},
        );
      }

      _saveFavoritesToLocal();

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
        state.maybeWhen(
          loaded: (_, __, ___, ____, _____, favoritesItems, ___) {
            return favoritesItems.any((item) => item.bvid == bvid);
          },
          orElse: () => false,
        );
  }

  /// 设置当前正在查看的歌单ID
  void setCurrentPlaylistId(String? playlistId) {
    _currentPlaylistId = playlistId;
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    state = const PlaylistState.initial();
    _favoritedBvids.clear();
    _currentPlaylistId = null;

    await _storage.remove('playlists_cache');
    await _storage.remove('favorites_cache');

    AppLogger.info('PlaylistViewModel', '已清空数据');
  }

  // ==================== 私有方法 ====================

  void _revertToLoadedState() {
    state.maybeWhen(
      operating: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
          nowPlayingPlaylist, favoritesItems, nowPlayingItems, _) {
        state = PlaylistState.loaded(
          playlists: playlists,
          userPlaylists: userPlaylists,
          systemPlaylists: systemPlaylists,
          favoritesPlaylist: favoritesPlaylist,
          nowPlayingPlaylist: nowPlayingPlaylist,
          favoritesItems: favoritesItems,
          nowPlayingItems: nowPlayingItems,
        );
      },
      orElse: () {},
    );
  }

  Future<void> _loadPlaylistsFromLocal() async {
    try {
      final playlistsJson = await _storage.getString('playlists_cache');
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

        state = PlaylistState.loaded(
          playlists: playlists,
          userPlaylists: userPlaylists,
          systemPlaylists: systemPlaylists,
          favoritesPlaylist: favoritesPlaylist,
          nowPlayingPlaylist: nowPlayingPlaylist,
          favoritesItems: const [],
          nowPlayingItems: const [],
        );

        AppLogger.info('PlaylistViewModel', '从本地加载歌单成功');
      }
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载歌单失败: $e');
    }
  }

  Future<void> _loadFavoritesFromLocal() async {
    try {
      final favoritesJson = await _storage.getString('favorites_cache');
      if (favoritesJson != null) {
        final data = jsonDecode(favoritesJson) as List;
        final items = data
            .map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>))
            .toList();

        state.maybeWhen(
          loaded: (playlists, userPlaylists, systemPlaylists, favoritesPlaylist,
              nowPlayingPlaylist, _, nowPlayingItems) {
            state = PlaylistState.loaded(
              playlists: playlists,
              userPlaylists: userPlaylists,
              systemPlaylists: systemPlaylists,
              favoritesPlaylist: favoritesPlaylist,
              nowPlayingPlaylist: nowPlayingPlaylist,
              favoritesItems: items,
              nowPlayingItems: nowPlayingItems,
            );
            _updateFavoritedCache();
          },
          orElse: () {},
        );

        AppLogger.info('PlaylistViewModel', '从本地加载收藏成功');
      }
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      state.maybeWhen(
        loaded: (_, __, ___, ____, _____, favoritesItems, ___) async {
          final json = jsonEncode(favoritesItems.map((f) => f.toJson()).toList());
          await _storage.setString('favorites_cache', json);
        },
        orElse: () {},
      );
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存本地收藏失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    state.maybeWhen(
      loaded: (_, __, ___, ____, _____, favoritesItems, ___) {
        for (final item in favoritesItems) {
          _favoritedBvids.add(item.bvid);
        }
      },
      orElse: () {},
    );
  }
}

/// Provider 定义
@riverpod
PlaylistRepository playlistRepository(PlaylistRepositoryRef ref) {
  return PlaylistRepository();
}

@riverpod
SharedStorageService sharedStorageService(SharedStorageServiceRef ref) {
  return SharedStorageService.instance;
}

@riverpod
PlaylistViewModel playlistViewModel(PlaylistViewModelRef ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  final storage = ref.watch(sharedStorageServiceProvider);
  return PlaylistViewModel(repository, storage);
}
