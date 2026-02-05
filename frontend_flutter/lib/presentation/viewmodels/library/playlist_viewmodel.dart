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

  /// 操作状态标志
  bool _isOperating = false;
  String? _operationMessage;

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
      final nowPlayingId = state.nowPlayingPlaylist?.id;
      if (nowPlayingId != null) {
        await loadNowPlaying(token);
      }
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

      // 保留当前列表数据
      final currentFavorites = state.favoritesItems;
      final currentNowPlaying = state.nowPlayingItems;

      state = PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        favoritesPlaylist: favoritesPlaylist,
        nowPlayingPlaylist: nowPlayingPlaylist,
        favoritesItems: currentFavorites,
        nowPlayingItems: currentNowPlaying,
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
      final favoritesId = state.favoritesPlaylist?.id;
      if (favoritesId == null) return;

      final items = await _repository.getFavorites();

      // 使用扩展方法获取当前状态，然后构造新状态
      state = PlaylistState.loaded(
        playlists: state.playlists,
        userPlaylists: state.userPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist,
        favoritesItems: items,
        nowPlayingItems: state.nowPlayingItems,
      );

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
      final nowPlayingId = state.nowPlayingPlaylist?.id;
      if (nowPlayingId == null) return;

      final items = await _repository.getPlaylistItems(nowPlayingId);

      state = PlaylistState.loaded(
        playlists: state.playlists,
        userPlaylists: state.userPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist,
        favoritesItems: state.favoritesItems,
        nowPlayingItems: items,
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

      final newPlaylist = await _repository.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      // 更新状态
      final updatedPlaylists = [...state.playlists, newPlaylist];
      final updatedUserPlaylists = [...state.userPlaylists, newPlaylist];

      state = PlaylistState.loaded(
        playlists: updatedPlaylists,
        userPlaylists: updatedUserPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist,
        favoritesItems: state.favoritesItems,
        nowPlayingItems: state.nowPlayingItems,
      );

      AppLogger.info('PlaylistViewModel', '创建歌单成功: ${newPlaylist.id}');
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

      final updatedPlaylist = await _repository.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      final updatedPlaylists = state.playlists.map((p) {
        return p.id == id ? updatedPlaylist : p;
      }).toList();

      final updatedUserPlaylists = state.userPlaylists.map((p) {
        return p.id == id ? updatedPlaylist : p;
      }).toList();

      state = PlaylistState.loaded(
        playlists: updatedPlaylists,
        userPlaylists: updatedUserPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist?.id == id
            ? updatedPlaylist
            : state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist?.id == id
            ? updatedPlaylist
            : state.nowPlayingPlaylist,
        favoritesItems: state.favoritesItems,
        nowPlayingItems: state.nowPlayingItems,
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

      final updatedPlaylists = state.playlists.where((p) => p.id != id).toList();
      final updatedUserPlaylists = state.userPlaylists.where((p) => p.id != id).toList();

      state = PlaylistState.loaded(
        playlists: updatedPlaylists,
        userPlaylists: updatedUserPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist?.id == id ? null : state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist?.id == id ? null : state.nowPlayingPlaylist,
        favoritesItems: state.favoritesItems,
        nowPlayingItems: state.nowPlayingItems,
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
      final updatedPlaylists = state.playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(itemCount: p.itemCount + 1);
        }
        return p;
      }).toList();

      final updatedUserPlaylists = state.userPlaylists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(itemCount: p.itemCount + 1);
        }
        return p;
      }).toList();

      // 如果是收藏歌单，更新缓存
      List<PlaylistItem> updatedFavorites = state.favoritesItems;
      if (playlistId == state.favoritesPlaylist?.id) {
        final newItem = PlaylistItem(
          bvid: bvid,
          title: title,
          artist: artist,
          duration: duration,
          coverUrl: coverUrl,
          position: state.favoritesItems.length,
          addedAt: DateTime.now(),
        );
        updatedFavorites = [...state.favoritesItems, newItem];
        _favoritedBvids.add(bvid);
        _saveFavoritesToLocal();
      }

      state = PlaylistState.loaded(
        playlists: updatedPlaylists,
        userPlaylists: updatedUserPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist,
        favoritesItems: updatedFavorites,
        nowPlayingItems: state.nowPlayingItems,
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
      final updatedPlaylists = state.playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
        }
        return p;
      }).toList();

      final updatedUserPlaylists = state.userPlaylists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
        }
        return p;
      }).toList();

      // 如果是收藏歌单，更新缓存
      List<PlaylistItem> updatedFavorites = state.favoritesItems;
      if (playlistId == state.favoritesPlaylist?.id) {
        updatedFavorites = state.favoritesItems.where((item) => item.bvid != bvid).toList();
        _favoritedBvids.remove(bvid);
        _saveFavoritesToLocal();
      }

      state = PlaylistState.loaded(
        playlists: updatedPlaylists,
        userPlaylists: updatedUserPlaylists,
        systemPlaylists: state.systemPlaylists,
        favoritesPlaylist: state.favoritesPlaylist,
        nowPlayingPlaylist: state.nowPlayingPlaylist,
        favoritesItems: updatedFavorites,
        nowPlayingItems: state.nowPlayingItems,
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

        // 移除收藏项
        final updatedItems = state.favoritesItems.where((item) => item.bvid != bvid).toList();
        state = PlaylistState.loaded(
          playlists: state.playlists,
          userPlaylists: state.userPlaylists,
          systemPlaylists: state.systemPlaylists,
          favoritesPlaylist: state.favoritesPlaylist,
          nowPlayingPlaylist: state.nowPlayingPlaylist,
          favoritesItems: updatedItems,
          nowPlayingItems: state.nowPlayingItems,
        );
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
        state.favoritesItems.any((item) => item.bvid == bvid);
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

  /// 获取当前歌单状态（公开 getter）
  PlaylistState get playlistState => state;

  // ==================== 私有方法 ====================

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

        state = PlaylistState.loaded(
          playlists: state.playlists,
          userPlaylists: state.userPlaylists,
          systemPlaylists: state.systemPlaylists,
          favoritesPlaylist: state.favoritesPlaylist,
          nowPlayingPlaylist: state.nowPlayingPlaylist,
          favoritesItems: items,
          nowPlayingItems: state.nowPlayingItems,
        );

        _updateFavoritedCache();

        AppLogger.info('PlaylistViewModel', '从本地加载收藏成功');
      }
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final json = jsonEncode(state.favoritesItems.map((f) => f.toJson()).toList());
      await _storage.setString('favorites_cache', json);
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存本地收藏失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    for (final item in state.favoritesItems) {
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
