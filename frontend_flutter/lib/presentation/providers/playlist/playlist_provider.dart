import 'dart:convert';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 歌单状态管理
///
/// 负责管理用户的歌单、收藏、播放队列
class PlaylistProvider with ChangeNotifier {
  late final DioProvider _dioProvider;

  // 数据状态
  List<Playlist> _playlists = [];
  Playlist? _favoritesPlaylist;
  Playlist? _nowPlayingPlaylist;
  List<PlaylistItem> _favoritesItems = [];
  List<PlaylistItem> _nowPlayingItems = [];
  String? _currentPlaylistId; // 当前正在查看的歌单ID

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 缓存标志（用于收藏状态）
  final Set<String> _favoritedBvids = {};

  PlaylistProvider({DioProvider? dioProvider}) {
    _dioProvider = dioProvider ?? DioProvider.instance;
  }

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Playlist> get userPlaylists => _playlists.where((p) => !p.isSystem).toList();
  List<Playlist> get systemPlaylists => _playlists.where((p) => p.isSystem).toList();
  Playlist? get favoritesPlaylist => _favoritesPlaylist;
  Playlist? get nowPlayingPlaylist => _nowPlayingPlaylist;
  List<PlaylistItem> get favorites => _favoritesItems;
  List<PlaylistItem> get nowPlayingQueue => _nowPlayingItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPlaylists => _playlists.isNotEmpty;
  String? get currentPlaylistId => _currentPlaylistId;

  /// 检查指定bvid是否已收藏
  bool isFavorited(String bvid) {
    return _favoritedBvids.contains(bvid) || _favoritesItems.any((item) => item.bvid == bvid);
  }

  /// 初始化（用户登录后调用）
  Future<void> initialize(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await loadPlaylists(token);
      await _loadFavoritesFromLocal();
      // 加载播放队列（如果系统歌单已创建）
      if (_nowPlayingPlaylist?.id != null) {
        await loadNowPlaying(token);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从服务器加载歌单列表
  Future<void> loadPlaylists(String token) async {
    try {
      final response = await _dioProvider.get(
        '/playlists',
        queryParams: {'token': token},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        // P0 修复: 使用 fromDto 而不是 fromJson，正确处理后端 snake_case 字段名
        _playlists = data.map((json) => Playlist.fromDto(json as Map<String, dynamic>)).toList();

        // 分离系统歌单
        _favoritesPlaylist = _playlists.firstWhere(
          (p) => p.isFavorites,
          orElse: () => _playlists.firstWhere(
            (p) => p.systemType == SystemPlaylistType.favorites,
            orElse: () => const Playlist(
              id: '1',
              userId: '0',
              name: '我喜欢',
              type: PlaylistType.system,
              systemType: SystemPlaylistType.favorites,
            ),
          ),
        );

        _nowPlayingPlaylist = _playlists.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => _playlists.firstWhere(
            (p) => p.systemType == SystemPlaylistType.nowPlaying,
            orElse: () => const Playlist(
              id: '2',
              userId: '0',
              name: '正在播放',
              type: PlaylistType.system,
              systemType: SystemPlaylistType.nowPlaying,
            ),
          ),
        );
      }
    } catch (e) {
      // 服务器获取失败，设置错误信息并使用本地缓存
      _errorMessage = '加载歌单失败：${e.toString()}';
      AppLogger.error('PlaylistProvider', '加载歌单失败: $e');
      await _loadPlaylistsFromLocal();
      // 不再 rethrow，让 UI 显示错误信息
    }
  }

  /// 加载收藏列表
  Future<void> loadFavorites(String token) async {
    if (_favoritesPlaylist?.id == null) return;

    try {
      final response = await _dioProvider.get(
        '/playlists/${_favoritesPlaylist!.id}',
        queryParams: {'token': token},
      );

      if (response['success'] == true && response['data'] != null) {
        // P0 修复: 使用 fromDto 而不是 fromJson
        final detail = PlaylistDetail.fromDto(response['data'] as Map<String, dynamic>);
        _favoritesItems = detail.items;
        _updateFavoritedCache();
      }
    } catch (e) {
      // 加载播放队列失败，使用本地缓存
      AppLogger.error('PlaylistProvider', '加载播放队列失败: $e');
      await _loadNowPlayingFromLocal();
    }
  }

  /// 加载播放队列
  Future<void> loadNowPlaying(String token) async {
    if (_nowPlayingPlaylist?.id == null) return;

    try {
      final response = await _dioProvider.get(
        '/playlists/now-playing',
        queryParams: {'token': token},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        // P0 修复: 使用 fromDto 而不是 fromJson
        _nowPlayingItems = data.map((json) => PlaylistItem.fromDto(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // 静默失败
      AppLogger.error('PlaylistProvider', '加载播放队列失败: $e');
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist(String token, String name, {String? description}) async {
    try {
      final response = await _dioProvider.post(
        '/playlists',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // P0 修复: 使用 fromDto 而不是 fromJson
        final newPlaylist = Playlist.fromDto(response['data'] as Map<String, dynamic>);
        _playlists.add(newPlaylist);
        notifyListeners();
        return newPlaylist;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return null;
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
      final response = await _dioProvider.put(
        '/playlists/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // P0 修复: 使用 fromDto 而不是 fromJson
        final updated = Playlist.fromDto(response['data'] as Map<String, dynamic>);
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _playlists[index] = updated;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String token, String id) async {
    try {
      final response = await _dioProvider.delete('/playlists/$id');

      if (response['success'] == true) {
        _playlists.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  /// 添加音频到歌单
  Future<PlaylistItem?> addItem(
    String token,
    String playlistId,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    try {
      final response = await _dioProvider.post(
        '/playlists/$playlistId/items',
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // P0 修复: 使用 fromDto 而不是 fromJson
        final item = PlaylistItem.fromDto(response['data'] as Map<String, dynamic>);

        // 如果是收藏歌单，更新缓存
        if (playlistId == _favoritesPlaylist?.id) {
          _favoritesItems.add(item);
          _favoritedBvids.add(bvid);
          _saveFavoritesToLocal();
        }

        // 更新歌单的itemCount
        final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
        if (playlistIndex >= 0) {
          final playlist = _playlists[playlistIndex];
          _playlists[playlistIndex] = playlist.copyWith(itemCount: playlist.itemCount + 1);
        }

        notifyListeners();
        return item;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  /// 从歌单移除音频
  Future<bool> removeItem(String token, String playlistId, String bvid) async {
    try {
      final response = await _dioProvider.delete('/playlists/$playlistId/items/$bvid');

      if (response['success'] == true) {
        // 如果是收藏歌单，更新缓存
        if (playlistId == _favoritesPlaylist?.id) {
          _favoritesItems.removeWhere((item) => item.bvid == bvid);
          _favoritedBvids.remove(bvid);
          _saveFavoritesToLocal();
        }

        // 更新歌单的itemCount
        final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
        if (playlistIndex >= 0) {
          final playlist = _playlists[playlistIndex];
          _playlists[playlistIndex] = playlist.copyWith(itemCount: (playlist.itemCount - 1).clamp(0, 999999));
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  /// 调整歌单项顺序
  Future<bool> reorderItems(String token, String playlistId, List<PlaylistItem> items) async {
    try {
      final response = await _dioProvider.put(
        '/playlists/$playlistId/items/reorder',
        data: {
          'items': items.map((item) => {'id': item.id, 'bvid': item.bvid}).toList(),
        },
      );

      if (response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
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
    AppLogger.info('PlaylistProvider', '切换收藏状态: bvid=$bvid');

    try {
      final response = await _dioProvider.post(
        '/playlists/favorites/toggle',
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final added = data['added'] as bool? ?? data['favorited'] as bool? ?? false;

        if (added) {
          _favoritedBvids.add(bvid);
          await loadFavorites(token);
        } else {
          _favoritedBvids.remove(bvid);
          _favoritesItems.removeWhere((item) => item.bvid == bvid);
        }

        _saveFavoritesToLocal();
        notifyListeners();

        AppLogger.info('PlaylistProvider', '收藏状态变更完成: bvid=$bvid, added=$added');
        return added;
      }
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('PlaylistProvider', '切换收藏失败: $e');
    }
    return false;
  }

  /// 保存播放队列
  Future<bool> saveNowPlaying(String token, List<Audio> queue) async {
    try {
      final items = queue.map((audio) => {
        'bvid': audio.id, // 使用 id (BV号)
        'title': audio.title,
        'artist': audio.artist ?? '',
        'duration': audio.duration ?? 0,
        'coverUrl': audio.coverUrl,
      }).toList();

      final response = await _dioProvider.post(
        '/playlists/now-playing',
        data: {'items': items},
      );

      if (response['success'] == true) {
        _nowPlayingItems = items.map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      AppLogger.error('PlaylistProvider', '保存播放队列失败: $e');
    }
    return false;
  }

  /// 增加歌单播放次数
  Future<void> incrementPlayCount(String token, int playlistId) async {
    try {
      await _dioProvider.post('/playlists/$playlistId/play');
    } catch (e) {
      // 静默失败
      AppLogger.error('PlaylistProvider', '记录播放失败: $e');
    }
  }

  // ==================== 本地存储方法 ====================

  static const _playlistsKey = 'playlists_cache';
  static const _favoritesKey = 'favorites_cache';
  static const _nowPlayingKey = 'now_playing_cache';

  Future<void> _loadPlaylistsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString(_playlistsKey);

      if (playlistsJson != null) {
        final data = jsonDecode(playlistsJson) as List;
        _playlists = data.map((json) => Playlist.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('PlaylistProvider', '加载本地歌单失败: $e');
    }
  }

  Future<void> _loadFavoritesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson != null) {
        final data = jsonDecode(favoritesJson) as List;
        _favoritesItems = data.map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>)).toList();
        _updateFavoritedCache();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('PlaylistProvider', '加载本地收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_favoritesItems.map((f) => f.toJson()).toList());
      await prefs.setString(_favoritesKey, json);
    } catch (e) {
      AppLogger.error('PlaylistProvider', '保存本地收藏失败: $e');
    }
  }

  Future<void> _loadNowPlayingFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowPlayingJson = prefs.getString(_nowPlayingKey);

      if (nowPlayingJson != null) {
        final data = jsonDecode(nowPlayingJson) as List;
        _nowPlayingItems = data.map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('PlaylistProvider', '加载本地播放队列失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    for (final item in _favoritesItems) {
      _favoritedBvids.add(item.bvid);
    }
  }

  /// 设置当前正在查看的歌单ID
  void setCurrentPlaylistId(String? playlistId) {
    _currentPlaylistId = playlistId;
    // 不需要notifyListeners，因为这只是一个内部状态
  }

  /// 排序歌单项
  Future<bool> sortPlaylistItems({
    required String playlistId,
    required String sortType,
  }) async {
    try {
      final response = await _dioProvider.put(
        '/playlists/$playlistId/sort',
        data: {'sortType': sortType},
      );

      return response['success'] == true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    _playlists = [];
    _favoritesPlaylist = null;
    _nowPlayingPlaylist = null;
    _favoritesItems = [];
    _nowPlayingItems = [];
    _favoritedBvids.clear();
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playlistsKey);
    await prefs.remove(_favoritesKey);

    notifyListeners();
  }
}
