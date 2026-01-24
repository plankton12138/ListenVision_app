import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:flutter/foundation.dart';

/// 歌单 CRUD 状态管理
///
/// 负责：
/// 1. 用户歌单列表管理
/// 2. 创建/编辑/删除歌单
/// 3. 添加/移除歌单项
class PlaylistCrudProvider extends ChangeNotifier {
  final DioProvider _dioProvider;
  String? _token;

  // ==================== 状态变量 ====================

  /// 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  /// 歌单列表
  List<Playlist> _playlists = [];

  /// 收藏歌单
  Playlist? _favoritesPlaylist;

  // ==================== Getters ====================

  List<Playlist> get playlists => _playlists;
  Playlist? get favoritesPlaylist => _favoritesPlaylist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPlaylists => _playlists.isNotEmpty;

  // ==================== 初始化 ====================

  PlaylistCrudProvider({DioProvider? dioProvider})
      : _dioProvider = dioProvider ?? DioProvider.instance;

  /// 初始化（用户登录后调用）
  Future<void> initialize(String token) async {
    _token = token;
    await loadPlaylists(token);
    // loadFavorites handled by FavoritesProvider
    debugPrint('【PlaylistCrudProvider】初始化完成');
  }

  // ==================== 歌单 CRUD ====================

  /// 加载所有歌单
  Future<void> loadPlaylists(String token) async {
    if (token.isEmpty) {
      debugPrint('【PlaylistCrudProvider】未登录，跳过服务器加载');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioProvider.get('/playlists', queryParams: {'token': token});

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        // P0 修复: 使用 fromDto 而不是 fromJson
        _playlists = data.map((json) => Playlist.fromDto(json as Map<String, dynamic>)).toList();
        debugPrint('【PlaylistCrudProvider】加载歌单: ${_playlists.length}');
      } else {
        throw Exception(response['message'] ?? '加载歌单失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【PlaylistCrudProvider】加载歌单异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建歌单
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    int? userId,
    String? coverUrl,
    String? description,
    PlaylistType type = PlaylistType.user,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _dioProvider.post(
        '/playlists',
        data: {
          'name': name,
          'userId': userId,
          'coverUrl': coverUrl,
          'description': description,
          'type': type.name,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        debugPrint('【PlaylistCrudProvider】创建歌单成功: $name');
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? '创建歌单失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【PlaylistCrudProvider】创建歌单异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新歌单
  Future<void> updatePlaylist({
    required int playlistId,
    String? name,
    int? userId,
    String? coverUrl,
    String? description,
    required PlaylistType type,
  }) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);

    if (playlist == null) {
      throw Exception('歌单不存在');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioProvider.put(
        '/playlists/$playlistId',
        data: {
          if (name != null) 'name': name,
          if (userId != null) 'userId': userId,
          if (coverUrl != null) 'coverUrl': coverUrl,
          if (description != null) 'description': description,
          'type': type.name,
        },
      );

      if (response['success'] == true) {
        debugPrint('【PlaylistCrudProvider】更新歌单成功');
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? '更新歌单失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【PlaylistCrudProvider】更新歌单异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 删除歌单
  Future<void> deletePlaylist(int playlistId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _dioProvider.delete('/playlists/$playlistId');

      if (response['success'] == true) {
        debugPrint('【PlaylistCrudProvider】删除歌单成功: $playlistId');
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? '删除歌单失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【PlaylistCrudProvider】删除歌单异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Getters ====================

  /// 当前B站
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}