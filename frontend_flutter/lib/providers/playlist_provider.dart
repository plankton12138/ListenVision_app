import 'dart:convert';
import 'package:demo/models/audio_model.dart';
import 'package:demo/models/playlist.dart';
import 'package:demo/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 歌单状态管理
///
/// 负责管理用户的歌单、收藏、播放队列
class PlaylistProvider with ChangeNotifier {
  final ApiService _apiService;

  // 数据状态
  List<Playlist> _playlists = [];
  Playlist? _favoritesPlaylist;
  Playlist? _nowPlayingPlaylist;
  List<PlaylistItem> _favoritesItems = [];
  List<PlaylistItem> _nowPlayingItems = [];

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 缓存标志（用于收藏状态）
  final Set<String> _favoritedBvids = {};

  PlaylistProvider(this._apiService);

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
      final response = await _apiService.get(
        endpoint: '/playlists',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _playlists = data.map((json) => Playlist.fromJson(json as Map<String, dynamic>)).toList();

        // 分离系统歌单
        _favoritesPlaylist = _playlists.firstWhere(
          (p) => p.isFavorites,
          orElse: () => _playlists.firstWhere(
            (p) => p.systemType == SystemPlaylistType.favorites,
            orElse: () => Playlist(
              id: null,
              userId: 0,
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
            orElse: () => Playlist(
              id: null,
              userId: 0,
              name: '正在播放',
              type: PlaylistType.system,
              systemType: SystemPlaylistType.nowPlaying,
            ),
          ),
        );
      }
    } catch (e) {
      // 服务器获取失败，使用本地缓存
      await _loadPlaylistsFromLocal();
      rethrow;
    }
  }

  /// 加载收藏列表
  Future<void> loadFavorites(String token) async {
    if (_favoritesPlaylist?.id == null) return;

    try {
      final response = await _apiService.get(
        endpoint: '/playlists/${_favoritesPlaylist!.id}',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final detail = PlaylistDetail.fromJson(response['data'] as Map<String, dynamic>);
        _favoritesItems = detail.items;
        _updateFavoritedCache();
      }
    } catch (e) {
      // 加载失败，使用本地缓存
      await _loadFavoritesFromLocal();
    }
  }

  /// 加载播放队列
  Future<void> loadNowPlaying(String token) async {
    if (_nowPlayingPlaylist?.id == null) return;

    try {
      final response = await _apiService.get(
        endpoint: '/playlists/now-playing',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _nowPlayingItems = data.map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // 静默失败
      debugPrint('加载播放队列失败: $e');
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist(String token, String name, {String? description}) async {
    try {
      final response = await _apiService.post(
        endpoint: '/playlists',
        token: token,
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final newPlaylist = Playlist.fromJson(response['data'] as Map<String, dynamic>);
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
  Future<bool> updatePlaylist(String token, int id, {String? name, String? description}) async {
    try {
      final response = await _apiService.put(
        endpoint: '/playlists/$id',
        token: token,
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final updated = Playlist.fromJson(response['data'] as Map<String, dynamic>);
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
  Future<bool> deletePlaylist(String token, int id) async {
    try {
      final response = await _apiService.delete(
        endpoint: '/playlists/$id',
        token: token,
      );

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
    int playlistId,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: '/playlists/$playlistId/items',
        token: token,
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final item = PlaylistItem.fromJson(response['data'] as Map<String, dynamic>);

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
  Future<bool> removeItem(String token, int playlistId, String bvid) async {
    try {
      final response = await _apiService.delete(
        endpoint: '/playlists/$playlistId/items/$bvid',
        token: token,
      );

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
  Future<bool> reorderItems(String token, int playlistId, List<PlaylistItem> items) async {
    try {
      final response = await _apiService.put(
        endpoint: '/playlists/$playlistId/items/reorder',
        token: token,
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
    try {
      final response = await _apiService.post(
        endpoint: '/playlists/favorites/toggle',
        token: token,
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
        return added;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  /// 保存播放队列
  Future<bool> saveNowPlaying(String token, List<Audio> queue) async {
    try {
      final items = queue.map((audio) => {
        'bvid': audio.url ?? '', // 使用 url 作为 bvid
        'title': audio.title,
        'artist': audio.artist,
        'duration': audio.duration,
        'coverUrl': audio.albumArt,
      }).toList();

      final response = await _apiService.post(
        endpoint: '/playlists/now-playing',
        token: token,
        data: {'items': items},
      );

      if (response['success'] == true) {
        _nowPlayingItems = items.map((json) => PlaylistItem.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('保存播放队列失败: $e');
    }
    return false;
  }

  /// 增加歌单播放次数
  Future<void> incrementPlayCount(String token, int playlistId) async {
    try {
      await _apiService.post(
        endpoint: '/playlists/$playlistId/play',
        token: token,
      );
    } catch (e) {
      // 静默失败
      debugPrint('记录播放失败: $e');
    }
  }

  // ==================== 本地存储方法 ====================

  static const _playlistsKey = 'playlists_cache';
  static const _favoritesKey = 'favorites_cache';

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
      debugPrint('加载本地歌单失败: $e');
    }
  }

  Future<void> _savePlaylistsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_playlistsKey, json);
    } catch (e) {
      debugPrint('保存本地歌单失败: $e');
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
      debugPrint('加载本地收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_favoritesItems.map((item) => item.toJson()).toList());
      await prefs.setString(_favoritesKey, json);
    } catch (e) {
      debugPrint('保存本地收藏失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    for (final item in _favoritesItems) {
      _favoritedBvids.add(item.bvid);
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
