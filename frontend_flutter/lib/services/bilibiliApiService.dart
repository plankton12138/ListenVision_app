import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart';

/// B站API服务 - 通过后端代理访问B站接口
///
/// 设计说明：
/// 1. 所有B站API调用都通过后端代理，不再直接调用B站
/// 2. 使用JWT token进行用户认证（DioProvider 全局管理）
/// 3. 资源URL通过后端代理解决防盗链问题
class BilibiliApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api/bilibili';

  final DioProvider _dioProvider;

  BilibiliApiService({DioProvider? dioProvider})
      : _dioProvider = dioProvider ?? DioProvider.instance;

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

  // ==================== QR码登录 ====================

  /// 获取QR码登录凭证
  ///
  /// 返回：{ qrcodeKey: String, qrcodeUrl: String, expiresAt: DateTime }
  Future<Map<String, dynamic>> getQRCode() async {
    try {
      final response = await _dioProvider.post('/bilibili/qrcode');

      final data = _handleResponse(response);
      debugPrint('【QR码获取】data keys: ${data.keys.toList()}');
      debugPrint('【QR码获取】qrcodeKey: ${data['qrcodeKey']}');
      debugPrint('【QR码获取】qrCodeUrl: ${data['qrCodeUrl']}');
      return {
        'qrcodeKey': data['qrcodeKey'] ?? '',
        'qrcodeUrl': data['qrCodeUrl'] ?? '',  // 修复：后端返回的是 qrCodeUrl（驼峰式）
        'expiresAt': data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : DateTime.now().add(const Duration(minutes: 3)),
      };
    } catch (e) {
      debugPrint('getQRCode exception: $e');
      rethrow;
    }
  }

  /// 检查QR码登录状态
  ///
  /// 返回：{ status: 'pending'|'scanned'|'success'|'expired', userInfo: Map? }
  Future<Map<String, dynamic>> checkQRLoginStatus(String qrcodeKey) async {
    try {
      final response = await _dioProvider.post('/bilibili/qrcode/check',
          data: {'qrcodeKey': qrcodeKey});

      debugPrint('【QR码检查】原始响应: $response');

      final data = response['data'] as Map<String, dynamic>?;
      final status = data?['status'] ?? 'pending';
      debugPrint('【QR码检查】解析状态: $status, userInfo: ${data?['userInfo']}');
      return {
        'status': status,
        'userInfo': data?['userInfo'],
      };
    } catch (e) {
      debugPrint('checkQRLoginStatus exception: $e');
      rethrow;
    }
  }

  // ==================== 账号绑定 ====================

  /// 获取B站账号绑定状态
  Future<Map<String, dynamic>> getBindStatus() async {
    try {
      final response = await _dioProvider.get('/bilibili/status');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getBindStatus exception: $e');
      rethrow;
    }
  }

  /// 解绑B站账号
  Future<Map<String, dynamic>> unbindAccount() async {
    try {
      final response = await _dioProvider.delete('/bilibili/unbind');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('unbindAccount exception: $e');
      rethrow;
    }
  }

  // ==================== 视频信息 ====================

  /// 获取视频信息
  ///
  /// 返回视频详细信息，包括标题、UP主、时长、封面等
  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    try {
      final response = await _dioProvider.get('/bilibili/video/$bvid');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getVideoInfo exception: $e');
      rethrow;
    }
  }

  /// 获取音频流URL
  ///
  /// 返回：{ url: String, quality: int, codec: String, size: int }
  Future<Map<String, dynamic>> getAudioStream(String bvid) async {
    try {
      final response = await _dioProvider.get('/bilibili/audio/$bvid');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getAudioStream exception: $e');
      rethrow;
    }
  }

  /// 获取UP主视频列表
  Future<Map<String, dynamic>> getUploaderVideos(
    String mid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioProvider.get('/bilibili/uploader/$mid',
          queryParams: {
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getUploaderVideos exception: $e');
      rethrow;
    }
  }

  // ==================== 搜索 ====================

  /// 搜索B站视频
  ///
  /// 返回：{ results: List, total: int, page: int, pageSize: int }
  Future<Map<String, dynamic>> searchBilibili(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioProvider.get('/bilibili/search',
          queryParams: {
            'keyword': keyword,
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('searchBilibili exception: $e');
      rethrow;
    }
  }

  /// 获取最近搜索关键词
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    try {
      final response = await _dioProvider.get('/bilibili/search/recent',
          queryParams: {'limit': limit});

      final data = _handleResponse(response);
      final keywords = data['keywords'] as List?;
      return keywords?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('getRecentSearches exception: $e');
      return [];
    }
  }

  // ==================== 资源代理URL ====================

  /// 获取图片代理URL
  ///
  /// 通过后端代理访问B站图片，解决防盗链问题
  String getProxyImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    // 如果已经是代理URL，直接返回
    if (originalUrl.contains('/proxy/image')) return originalUrl;
    // 使用后端代理
    return '$_baseUrl/proxy/image?url=${Uri.encodeComponent(originalUrl)}';
  }

  /// 获取音频代理URL
  ///
  /// 通过后端代理访问B站音频，解决防盗链问题
  String getProxyAudioUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    // 如果已经是代理URL，直接返回
    if (originalUrl.contains('/proxy/audio')) return originalUrl;
    // 使用后端代理
    return '$_baseUrl/proxy/audio?url=${Uri.encodeComponent(originalUrl)}';
  }

  // ==================== 音频元数据 ====================

  /// 获取缓存的音频元数据
  Future<Map<String, dynamic>?> getAudioMetadata(String bvid) async {
    try {
      final response = await _dioProvider.get('/audio/metadata/$bvid');

      return _handleResponse(response) as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// 刷新音频元数据缓存
  Future<Map<String, dynamic>> refreshAudioMetadata(String bvid) async {
    try {
      final response = await _dioProvider.post('/audio/metadata/$bvid/refresh');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('refreshAudioMetadata exception: $e');
      rethrow;
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final response = await _dioProvider.get('/audio/stats');
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getCacheStats exception: $e');
      return {'count': 0, 'totalSize': 0};
    }
  }

  /// 批量获取音频元数据
  Future<Map<String, Map<String, dynamic>>> getBatchMetadata(List<String> bvids) async {
    try {
      final response = await _dioProvider.post('/audio/metadata/batch',
          data: {'bvids': bvids});

      final data = _handleResponse(response);
      final metadata = data['metadata'] as Map<String, dynamic>?;
      return metadata?.cast<String, Map<String, dynamic>>() ?? {};
    } catch (e) {
      debugPrint('getBatchMetadata exception: $e');
      return {};
    }
  }

  // ==================== 推荐内容 ====================

  /// 获取热门歌单
  Future<Map<String, dynamic>> getHotPlaylists({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioProvider.get('/recommendations/hot-playlists',
          queryParams: {
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getHotPlaylists exception: $e');
      rethrow;
    }
  }

  /// 获取热歌榜单
  Future<Map<String, dynamic>> getHotRank({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioProvider.get('/recommendations/rank',
          queryParams: {
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getHotRank exception: $e');
      rethrow;
    }
  }

  /// 获取个性化推荐
  Future<Map<String, dynamic>> getPersonalizedRecommendations({int limit = 20}) async {
    try {
      final response = await _dioProvider.get('/recommendations/personalized',
          queryParams: {'limit': limit});

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getPersonalizedRecommendations exception: $e');
      rethrow;
    }
  }

  /// 获取音乐分区推荐
  ///
  /// 返回分类推荐数组，每个元素包含 {category, tid, videos}
  Future<List<Map<String, dynamic>>> getMusicRecommendation({int limit = 20}) async {
    try {
      final response = await _dioProvider.get('/recommendations/music',
          queryParams: {'limit': limit});

      final data = _handleResponse(response);
      // 后端返回的是数组
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('getMusicRecommendation exception: $e');
      rethrow;
    }
  }

  /// 获取分区推荐
  Future<Map<String, dynamic>> getByCategory(
    int tid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioProvider.get('/recommendations/category/$tid',
          queryParams: {
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getByCategory exception: $e');
      rethrow;
    }
  }

  /// 获取可用的分区ID列表
  Future<Map<String, int>> getCategoryTids() async {
    try {
      final response = await _dioProvider.get('/recommendations/categories');

      final data = _handleResponse(response);
      final categories = data['categories'] as Map<String, dynamic>?;
      return categories?.cast<String, int>() ?? {};
    } catch (e) {
      debugPrint('getCategoryTids exception: $e');
      return {};
    }
  }

  // ==================== Phase 2B: 音乐区爬虫 ====================

  /// 获取音乐区个性化推荐（爬虫方式）
  ///
  /// 爬取 bilibili.com/c/music 页面获取用户绑定的B站账户的个性化推荐内容
  /// 需要用户已登录并绑定B站账号
  Future<Map<String, dynamic>> getMusicZoneRecommendations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioProvider.get('/recommendations/music-zone',
          queryParams: {
            'page': page,
            'pageSize': pageSize,
          });

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getMusicZoneRecommendations exception: $e');
      rethrow;
    }
  }
}
