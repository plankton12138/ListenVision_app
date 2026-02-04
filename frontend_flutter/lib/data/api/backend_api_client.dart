import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';

/// 登录请求
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// 注册请求
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? captchaCode;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.captchaCode,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (captchaCode != null) 'captchaCode': captchaCode,
      };
}

/// 后端 API 客户端
///
/// 封装所有后端 API 调用
class BackendApiClient {
  final DioClient _dioClient;

  BackendApiClient({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  // ==================== 响应处理 ====================

  /// 解析响应，检查成功状态
  dynamic _handleResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return response['data'];
    } else {
      throw ApiException(
        response['message'] ?? 'Request failed',
        response['statusCode'] ?? 500,
      );
    }
  }

  // ==================== 认证 API ====================

  /// 用户登录
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.login,
        data: request.toJson(),
      );
      AppLogger.info('BackendApiClient', '登录成功: ${request.email}');
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '登录失败: $e');
      rethrow;
    }
  }

  /// 用户注册
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.register,
        data: request.toJson(),
      );
      AppLogger.info('BackendApiClient', '注册成功: ${request.email}');
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '注册失败: $e');
      rethrow;
    }
  }

  /// 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dioClient.get(AuthEndpoints.me);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取用户信息失败: $e');
      rethrow;
    }
  }

  /// 发送验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.sendCode,
        data: {'email': email},
      );
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '发送验证码失败: $e');
      rethrow;
    }
  }

  /// 重置密码
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.resetPassword,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '重置密码失败: $e');
      rethrow;
    }
  }

  // ==================== 歌单 API ====================

  /// 获取用户歌单列表
  Future<Map<String, dynamic>> getUserPlaylists({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        PlaylistEndpoints.playlists,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取歌单列表失败: $e');
      rethrow;
    }
  }

  /// 获取歌单详情
  Future<Map<String, dynamic>> getPlaylistDetail(String id) async {
    try {
      final response = await _dioClient.get(PlaylistEndpoints.playlistById(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取歌单详情失败: $e');
      rethrow;
    }
  }

  /// 获取歌单项
  Future<Map<String, dynamic>> getPlaylistItems(String id) async {
    try {
      final response = await _dioClient.get(PlaylistEndpoints.playlistItems(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取歌单项失败: $e');
      rethrow;
    }
  }

  /// 创建歌单
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final response = await _dioClient.post(
        PlaylistEndpoints.playlists,
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '创建歌单失败: $e');
      rethrow;
    }
  }

  /// 更新歌单
  Future<Map<String, dynamic>> updatePlaylist({
    required String id,
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final response = await _dioClient.put(
        PlaylistEndpoints.playlistById(id),
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '更新歌单失败: $e');
      rethrow;
    }
  }

  /// 删除歌单
  Future<Map<String, dynamic>> deletePlaylist(String id) async {
    try {
      final response = await _dioClient.delete(PlaylistEndpoints.playlistById(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '删除歌单失败: $e');
      rethrow;
    }
  }

  /// 添加歌单项
  Future<Map<String, dynamic>> addPlaylistItem({
    required String playlistId,
    required String bvid,
    int? position,
  }) async {
    try {
      final response = await _dioClient.post(
        PlaylistEndpoints.playlistItems(playlistId),
        data: {
          'bvid': bvid,
          if (position != null) 'position': position,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '添加歌单项失败: $e');
      rethrow;
    }
  }

  /// 删除歌单项
  Future<Map<String, dynamic>> removePlaylistItem({
    required String playlistId,
    required String bvid,
  }) async {
    try {
      final response = await _dioClient.delete(
        PlaylistEndpoints.playlistItem(playlistId, bvid),
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '删除歌单项失败: $e');
      rethrow;
    }
  }

  /// 获取收藏列表
  Future<Map<String, dynamic>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        PlaylistEndpoints.favorites,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取收藏列表失败: $e');
      rethrow;
    }
  }

  /// 切换收藏状态
  Future<Map<String, dynamic>> toggleFavorite(String bvid) async {
    try {
      final response = await _dioClient.post(
        PlaylistEndpoints.favoritesToggle,
        data: {'bvid': bvid},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '切换收藏失败: $e');
      rethrow;
    }
  }

  /// 检查是否已收藏
  Future<bool> checkFavorite(String bvid) async {
    try {
      final response = await _dioClient.get(PlaylistEndpoints.favoritesCheck(bvid));
      final data = _handleResponse(response) as Map<String, dynamic>;
      return data['isFavorite'] ?? false;
    } catch (e) {
      AppLogger.error('BackendApiClient', '检查收藏状态失败: $e');
      return false;
    }
  }

  // ==================== 播放历史 API ====================

  /// 获取播放历史
  Future<Map<String, dynamic>> getPlayHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        HistoryEndpoints.history,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取播放历史失败: $e');
      rethrow;
    }
  }

  /// 添加播放历史
  Future<Map<String, dynamic>> addPlayHistory({
    required String bvid,
    int? progress,
  }) async {
    try {
      final response = await _dioClient.post(
        HistoryEndpoints.history,
        data: {
          'bvid': bvid,
          if (progress != null) 'progress': progress,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '添加播放历史失败: $e');
      rethrow;
    }
  }

  /// 更新播放历史
  Future<Map<String, dynamic>> updatePlayHistory({
    required String id,
    int? progress,
  }) async {
    try {
      final response = await _dioClient.put(
        HistoryEndpoints.historyById(id),
        data: {
          if (progress != null) 'progress': progress,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '更新播放历史失败: $e');
      rethrow;
    }
  }

  /// 删除播放历史
  Future<Map<String, dynamic>> deletePlayHistory(String id) async {
    try {
      final response = await _dioClient.delete(HistoryEndpoints.historyById(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '删除播放历史失败: $e');
      rethrow;
    }
  }

  // ==================== 搜索 API ====================

  /// 本地搜索
  Future<Map<String, dynamic>> searchLocal({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        SearchEndpoints.searchLocal,
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '本地搜索失败: $e');
      rethrow;
    }
  }

  /// 获取搜索建议
  Future<List<String>> getSearchSuggestions(String keyword) async {
    try {
      final response = await _dioClient.get(
        SearchEndpoints.searchSuggestions,
        queryParameters: {'keyword': keyword},
      );
      final data = _handleResponse(response);
      final suggestions = data['suggestions'] as List?;
      return suggestions?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取搜索建议失败: $e');
      return [];
    }
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    try {
      final response = await _dioClient.get(
        SearchEndpoints.searchHistory,
        queryParameters: {'limit': limit},
      );
      final data = _handleResponse(response);
      final history = data['history'] as List?;
      return history?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取搜索历史失败: $e');
      return [];
    }
  }

  /// 清空搜索历史
  Future<Map<String, dynamic>> clearSearchHistory() async {
    try {
      final response = await _dioClient.delete(SearchEndpoints.searchHistory);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '清空搜索历史失败: $e');
      rethrow;
    }
  }

  // ==================== 推荐 API ====================

  /// 获取热门歌单
  Future<Map<String, dynamic>> getHotPlaylists({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        RecommendationEndpoints.hotPlaylists,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取热门歌单失败: $e');
      rethrow;
    }
  }

  /// 获取热歌榜单
  Future<Map<String, dynamic>> getHotRank({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        RecommendationEndpoints.rank,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取热歌榜单失败: $e');
      rethrow;
    }
  }

  /// 获取个性化推荐
  Future<Map<String, dynamic>> getPersonalizedRecommendations({
    int limit = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        RecommendationEndpoints.personalized,
        queryParameters: {'limit': limit},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取个性化推荐失败: $e');
      rethrow;
    }
  }
}

/// API 异常
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => 'ApiException: $message ($statusCode)';
}
