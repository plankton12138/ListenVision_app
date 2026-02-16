import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/errors/exceptions.dart' show ApiException;

/// B站 API 客户端
///
/// 通过后端代理访问B站接口
class BilibiliApiClient {
  final DioClient _dioClient;

  BilibiliApiClient({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

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
  Future<Map<String, dynamic>> getQRCode() async {
    try {
      final response = await _dioClient.post(BilibiliEndpoints.qrcode);
      final data = _handleResponse(response);
      return {
        'qrcodeKey': data['qrcodeKey'] ?? '',
        'qrcodeUrl': data['qrCodeUrl'] ?? '',
        'expiresAt': data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : DateTime.now().add(const Duration(minutes: 3)),
      };
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取QR码失败: $e');
      rethrow;
    }
  }

  /// 检查QR码登录状态
  Future<Map<String, dynamic>> checkQRLoginStatus(String qrcodeKey) async {
    try {
      final response = await _dioClient.post(
        BilibiliEndpoints.qrcodeCheck,
        data: {'qrcodeKey': qrcodeKey},
      );
      final data = response['data'] as Map<String, dynamic>?;
      final status = data?['status'] ?? 'pending';
      return {
        'status': status,
        'userInfo': data?['userInfo'],
      };
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '检查QR码状态失败: $e');
      rethrow;
    }
  }

  // ==================== 账号绑定 ====================

  /// 获取B站账号绑定状态
  Future<Map<String, dynamic>> getBindStatus() async {
    try {
      final response = await _dioClient.get(BilibiliEndpoints.status);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取绑定状态失败: $e');
      rethrow;
    }
  }

  /// 解绑B站账号
  Future<Map<String, dynamic>> unbindAccount() async {
    try {
      final response = await _dioClient.delete(BilibiliEndpoints.unbind);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '解绑账号失败: $e');
      rethrow;
    }
  }

  // ==================== 视频信息 ====================

  /// 获取视频信息
  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    try {
      final response = await _dioClient.get(BilibiliEndpoints.video(bvid));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取视频信息失败: $e');
      rethrow;
    }
  }

  /// 获取音频流URL
  Future<Map<String, dynamic>> getAudioStream(String bvid) async {
    try {
      final response = await _dioClient.get(BilibiliEndpoints.audio(bvid));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取音频流失败: $e');
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
      final response = await _dioClient.get(
        BilibiliEndpoints.uploader(mid),
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取UP主视频失败: $e');
      rethrow;
    }
  }

  // ==================== 搜索 ====================

  /// 搜索B站视频
  Future<Map<String, dynamic>> searchBilibili(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        BilibiliEndpoints.search,
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '搜索失败: $e');
      rethrow;
    }
  }

  /// 获取最近搜索关键词
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    try {
      final response = await _dioClient.get(
        BilibiliEndpoints.searchRecent,
        queryParameters: {'limit': limit},
      );
      final data = _handleResponse(response);
      final keywords = data['keywords'] as List?;
      return keywords?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取最近搜索失败: $e');
      return [];
    }
  }

  // ==================== 音频下载 ====================
  // 注意：下载功能已迁移到前端 BilibiliDownloader 服务
  // 以下方法仅保留用于获取下载 URL（用于流式播放）

  /// 获取音频下载URL（用于流式播放或下载）
  String getDownloadUrl(String bvid, {String format = 'm4a'}) {
    return '${ApiConstants.fullBaseUrl}/bilibili/audio/$bvid';
  }

  // ==================== 资源代理URL ====================

  /// 获取图片代理URL
  String getProxyImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    if (originalUrl.contains('/proxy/image')) return originalUrl;
    return '${ApiConstants.fullBaseUrl}/bilibili/proxy/image?url=${Uri.encodeComponent(originalUrl)}';
  }

  /// 获取音频代理URL
  String getProxyAudioUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    if (originalUrl.contains('/proxy/audio')) return originalUrl;
    return '${ApiConstants.fullBaseUrl}/bilibili/proxy/audio?url=${Uri.encodeComponent(originalUrl)}';
  }

  // ==================== 音频元数据 ====================

  /// 获取缓存的音频元数据
  Future<Map<String, dynamic>?> getAudioMetadata(String bvid) async {
    try {
      final response = await _dioClient.get(AudioEndpoints.metadataById(bvid));
      return _handleResponse(response) as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// 刷新音频元数据缓存
  Future<Map<String, dynamic>> refreshAudioMetadata(String bvid) async {
    try {
      final response = await _dioClient.post(AudioEndpoints.metadataRefresh(bvid));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '刷新元数据失败: $e');
      rethrow;
    }
  }

  /// 批量获取音频元数据
  Future<Map<String, Map<String, dynamic>>> getBatchMetadata(List<String> bvids) async {
    try {
      final response = await _dioClient.post(
        AudioEndpoints.metadataBatch,
        data: {'bvids': bvids},
      );
      final data = _handleResponse(response);
      final metadata = data['metadata'] as Map<String, dynamic>?;
      return metadata?.cast<String, Map<String, dynamic>>() ?? {};
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '批量获取元数据失败: $e');
      return {};
    }
  }

  // ==================== 推荐内容 ====================

  /// 获取热门歌单
  Future<Map<String, dynamic>> getHotPlaylists({int page = 1, int pageSize = 10}) async {
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
      AppLogger.error('BilibiliApiClient', '获取热门歌单失败: $e');
      rethrow;
    }
  }

  /// 获取热歌榜单
  Future<Map<String, dynamic>> getHotRank({int page = 1, int pageSize = 10}) async {
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
      AppLogger.error('BilibiliApiClient', '获取热歌榜单失败: $e');
      rethrow;
    }
  }

  /// 获取个性化推荐
  Future<Map<String, dynamic>> getPersonalizedRecommendations({int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        RecommendationEndpoints.personalized,
        queryParameters: {'limit': limit},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取个性化推荐失败: $e');
      rethrow;
    }
  }

  /// 获取音乐分区推荐
  Future<List<Map<String, dynamic>>> getMusicRecommendation({int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        '/recommendations/music',
        queryParameters: {'limit': limit},
      );
      final data = _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取音乐区推荐失败: $e');
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
      final response = await _dioClient.get(
        '/recommendations/category/$tid',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BilibiliApiClient', '获取分区推荐失败: $e');
      rethrow;
    }
  }

  // ==================== 音频下载 ====================
  // 注意：下载功能已迁移到前端 BilibiliDownloader 服务
  // 以下方法仅保留用于获取下载 URL（用于流式播放）
}
