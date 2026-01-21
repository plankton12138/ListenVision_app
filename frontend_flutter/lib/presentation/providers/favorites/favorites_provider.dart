import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:flutter/foundation.dart';

/// 收藏状态管理
///
/// 负责：
/// 1. 管理收藏列表
/// 2. 添加/移除收藏
class FavoritesProvider extends ChangeNotifier {
  late final DioProvider _dioProvider;
  String? _token;

  // ==================== 状态变量 ====================

  /// 收藏列表
  List<String> _favorites = [];

  /// 当前收藏歌单（"我喜欢"）
  Playlist? _favoritesPlaylist;

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  /// ==================== Getters ====================

  List<String> get favorites => _favorites;
  Playlist? get favoritesPlaylist => _favoritesPlaylist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasFavorites => _favorites.isNotEmpty;

  // ==================== 方法 ====================

  /// 初始化（用户登录后调用）
  Future<void> initialize(String? token) async {
    _token = token;
    await loadFavorites();
    debugPrint('【FavoritesProvider】初始化完成');
  }

  /// 从服务器加载收藏列表
  Future<void> loadFavorites() async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('【FavoritesProvider】未登录，跳过服务器加载');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioProvider.get('/favorites', queryParams: {'token': _token});

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _favorites = data.map((item) => item.toString()).toList();

        debugPrint('【FavoritesProvider】加载收藏列表: ${_favorites.length}');
      } else {
        throw Exception(response['message'] ?? '加载收藏列表失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【FavoritesProvider】加载收藏列表异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加到收藏
  Future<void> addToFavorites(String bvid) async {
    if (!_favorites.contains(bvid)) {
      _favorites.add(bvid);
      notifyListeners();
      debugPrint('【FavoritesProvider】添加收藏: $bvid');
    }
  }

  /// 从收藏移除
  Future<void> removeFromFavorites(String bvid) async {
    _favorites.remove(bvid);
    notifyListeners();
    debugPrint('【FavoritesProvider】移除收藏: $bvid');
  }

  /// 清空收藏
  Future<void> clearFavorites() async {
    _favorites.clear();
    notifyListeners();
    debugPrint('【FavoritesProvider】清空收藏列表');
  }

  // 检查指定bvid是否已收藏
  bool isFavorited(String bvid) {
    return _favorites.contains(bvid);
  }

  /// 检查指定歌单是否是收藏列表
  bool isFavoritesList(Playlist playlist) {
    return playlist.systemType == SystemPlaylistType.favorites;
  }

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}
