import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/utils/app_logger.dart';
import '../../models/search_suggestion.dart';

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
/// 封装所有后端 API 调用。
/// 新代码应优先直接使用 ApiClient，本类仅作为兼容层保留。
class BackendApiClient {
  final DioClient _dioClient;
  final ApiClient _apiClient;

  BackendApiClient({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance,
        _apiClient = ApiClient();

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

  /// 用户注册 - 发送验证码
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.register,
        data: request.toJson(),
      );
      AppLogger.info('BackendApiClient', '注册验证码已发送: ${request.email}');
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '注册失败: $e');
      rethrow;
    }
  }

  /// 验证邮箱并完成注册
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );
      AppLogger.info('BackendApiClient', '邮箱验证成功: $email');
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('BackendApiClient', '邮箱验证失败: $e');
      rethrow;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      await _dioClient.post(AuthEndpoints.logout);
      AppLogger.info('BackendApiClient', '登出成功');
    } catch (e) {
      AppLogger.error('BackendApiClient', '登出失败: $e');
    }
  }

  /// 注销账号
  Future<void> deleteAccount() async {
    try {
      await _dioClient.delete(AuthEndpoints.deleteAccount);
      AppLogger.info('BackendApiClient', '账号已注销');
    } catch (e) {
      AppLogger.error('BackendApiClient', '注销账号失败: $e');
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
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      final response = await _dioClient.post(
        PlaylistEndpoints.playlistItems(playlistId),
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
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
  Future<Map<String, dynamic>> toggleFavorite(
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    try {
      final response = await _dioClient.post(
        PlaylistEndpoints.favoritesToggle,
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
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
      rethrow;
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
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? progress,
  }) async {
    try {
      final response = await _dioClient.post(
        HistoryEndpoints.history,
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
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

  /// 获取B站音乐区推荐
  Future<Map<String, dynamic>> getRecommend({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _apiClient.getBilibiliRecommendations(
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取B站推荐失败: $e');
      rethrow;
    }
  }

  // ==================== B站搜索 API ====================

  /// B站搜索
  ///
  /// @param keyword 搜索关键词
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  Future<Map<String, dynamic>> searchBilibili(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.debug('BackendApiClient', 'B站搜索: $keyword, page=$page, pageSize=$pageSize');
      return await _apiClient.searchBilibili(
        keyword,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.error('BackendApiClient', 'B站搜索失败: $e');
      rethrow;
    }
  }

  /// 获取B站搜索建议
  Future<List<SearchSuggestion>> getBilibiliSearchSuggestions(String keyword) async {
    try {
      return await _apiClient.getBilibiliSearchSuggestions(keyword);
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取B站搜索建议失败: $e');
      return [];
    }
  }

  /// 获取B站搜索历史
  Future<List<String>> getBilibiliSearchHistory() async {
    try {
      final response = await _dioClient.get(BilibiliEndpoints.searchRecent);
      final data = _handleResponse(response);
      // 后端返回 data.keywords 字段
      final keywords = data['keywords'] as List?;
      return keywords?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取B站搜索历史失败: $e');
      return [];
    }
  }

  /// 添加B站搜索历史
  Future<void> addBilibiliSearchHistory(String keyword) async {
    try {
      await _dioClient.post(
        BilibiliEndpoints.searchRecent,
        data: {'keyword': keyword},
      );
    } catch (e) {
      AppLogger.error('BackendApiClient', '添加B站搜索历史失败: $e');
    }
  }

  /// 清空B站搜索历史
  Future<void> clearBilibiliSearchHistory() async {
    try {
      await _dioClient.delete(BilibiliEndpoints.searchRecent);
    } catch (e) {
      AppLogger.error('BackendApiClient', '清空B站搜索历史失败: $e');
    }
  }

  // ==================== 网易云音乐 API ====================

  /// 获取网易云绑定状态
  Future<Map<String, dynamic>> getNeteaseStatus() async {
    try {
      final response = await _dioClient.get(NeteaseEndpoints.status);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云绑定状态失败: $e');
      rethrow;
    }
  }

  /// 获取网易云二维码
  Future<Map<String, dynamic>> getNeteaseQRCode() async {
    try {
      final response = await _dioClient.post(NeteaseEndpoints.qrcode);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云二维码失败: $e');
      rethrow;
    }
  }

  /// 检查网易云二维码状态
  Future<Map<String, dynamic>> checkNeteaseQRCode(String key) async {
    try {
      final response = await _dioClient.post(
        NeteaseEndpoints.qrcodeCheck,
        data: {'key': key},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '检查网易云二维码状态失败: $e');
      rethrow;
    }
  }

  /// 解绑网易云账号
  Future<void> unbindNetease() async {
    try {
      await _dioClient.delete(NeteaseEndpoints.unbind);
      AppLogger.info('BackendApiClient', '网易云解绑成功');
    } catch (e) {
      AppLogger.error('BackendApiClient', '解绑网易云失败: $e');
      rethrow;
    }
  }

  /// 获取网易云用户歌单
  Future<Map<String, dynamic>> getNeteaseUserPlaylists(String uid) async {
    try {
      final response = await _dioClient.get(NeteaseEndpoints.userPlaylist(uid));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云用户歌单失败: $e');
      rethrow;
    }
  }

  /// 获取网易云每日推荐歌单
  Future<Map<String, dynamic>> getNeteaseRecommendedPlaylists() async {
    try {
      return await _apiClient.getNeteaseRecommendedPlaylists();
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云每日推荐歌单失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌单详情
  Future<Map<String, dynamic>> getNeteasePlaylistDetail(String id) async {
    try {
      return await _apiClient.getNeteasePlaylistDetail(id);
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云歌单详情失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌曲URL
  Future<Map<String, dynamic>> getNeteaseSongUrl(String id) async {
    try {
      final response = await _dioClient.get(
        NeteaseEndpoints.songUrl,
        queryParameters: {'id': id},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取网易云歌曲URL失败: $e');
      rethrow;
    }
  }

  /// 网易云搜索
  Future<Map<String, dynamic>> searchNetease(
    String keywords, {
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        NeteaseEndpoints.search,
        queryParameters: {
          'keywords': keywords,
          'limit': limit,
          'offset': offset,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '网易云搜索失败: $e');
      rethrow;
    }
  }

  // ==================== 同步 API ====================

  /// 获取云端收藏列表（带时间戳）
  Future<Map<String, dynamic>> getCloudFavorites() async {
    try {
      final response = await _dioClient.get(Endpoints.syncFavorites);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取云端收藏列表失败: $e');
      rethrow;
    }
  }

  /// 获取云端歌单列表（带时间戳）
  Future<Map<String, dynamic>> getCloudPlaylists() async {
    try {
      final response = await _dioClient.get(Endpoints.syncPlaylists);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取云端歌单列表失败: $e');
      rethrow;
    }
  }

  /// 获取云端播放历史（带时间戳）
  Future<Map<String, dynamic>> getCloudHistory() async {
    try {
      final response = await _dioClient.get(Endpoints.syncHistory);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取云端播放历史失败: $e');
      rethrow;
    }
  }

  /// 获取增量变更
  Future<Map<String, dynamic>> getCloudChanges({DateTime? since}) async {
    try {
      final response = await _dioClient.get(
        Endpoints.syncChanges,
        queryParameters: since != null
            ? {'since': since.toIso8601String()}
            : null,
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取增量变更失败: $e');
      rethrow;
    }
  }

  /// 获取同步状态
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await _dioClient.get(Endpoints.syncStatus);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取同步状态失败: $e');
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
