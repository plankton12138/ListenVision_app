import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dto/api_dto.dart';
import '../utils/app_logger.dart';
import 'dio_client.dart';
import 'endpoints.dart';

/// 统一 API 客户端 Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// 统一 API 客户端
///
/// 封装所有后端 API 调用，使用 DioClient 单例
/// 替代 BackendApiClient 和 BilibiliApiClient
class ApiClient {
  final DioClient _dioClient = DioClient.instance;

  // ==================== 响应处理 ====================

  /// 解析响应，检查成功状态并返回数据
  dynamic _handleResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return response['data'];
    } else {
      throw ApiException(
        response['error'] ?? response['message'] ?? '请求失败',
        response['statusCode'] ?? 500,
      );
    }
  }

  // ==================== 认证 API ====================

  /// 用户登录
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _dioClient.post(
        Endpoints.authLogin,
        data: request.toJson(),
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      AppLogger.info('ApiClient', '登录成功: ${request.email}');
      return LoginResponseDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '登录失败: $e');
      rethrow;
    }
  }

  /// 用户注册
  Future<void> register(RegisterRequestDto request) async {
    try {
      await _dioClient.post(
        Endpoints.authRegister,
        data: request.toJson(),
      );
      AppLogger.info('ApiClient', '注册验证码已发送: ${request.email}');
    } catch (e) {
      AppLogger.error('ApiClient', '注册失败: $e');
      rethrow;
    }
  }

  /// 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dioClient.get(Endpoints.authMe);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取用户信息失败: $e');
      rethrow;
    }
  }

  // ==================== B站 API ====================

  /// 获取B站QR码
  Future<BilibiliQRCodeDto> getBilibiliQRCode() async {
    try {
      final response = await _dioClient.post(Endpoints.bilibiliQrcode);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return BilibiliQRCodeDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站QR码失败: $e');
      rethrow;
    }
  }

  /// 检查B站QR码登录状态
  Future<BilibiliQRStatusDto> checkBilibiliQRStatus(String qrcodeKey) async {
    try {
      final response = await _dioClient.post(
        Endpoints.bilibiliQrcodeCheck,
        data: {'qrcodeKey': qrcodeKey},
      );
      final data = response['data'] as Map<String, dynamic>?;
      return BilibiliQRStatusDto.fromJson(data ?? {});
    } catch (e) {
      AppLogger.error('ApiClient', '检查B站QR码状态失败: $e');
      rethrow;
    }
  }

  /// 获取B站绑定状态
  Future<Map<String, dynamic>> getBilibiliBindStatus() async {
    try {
      final response = await _dioClient.get(Endpoints.bilibiliStatus);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站绑定状态失败: $e');
      rethrow;
    }
  }

  /// 解绑B站账号
  Future<void> unbindBilibili() async {
    try {
      await _dioClient.delete(Endpoints.bilibiliUnbind);
      AppLogger.info('ApiClient', 'B站账号解绑成功');
    } catch (e) {
      AppLogger.error('ApiClient', '解绑B站账号失败: $e');
      rethrow;
    }
  }

  /// 搜索B站视频
  Future<Map<String, dynamic>> searchBilibili(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        Endpoints.bilibiliSearch,
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '搜索B站失败: $e');
      rethrow;
    }
  }

  /// 获取B站视频信息
  Future<BilibiliVideoDto> getBilibiliVideoInfo(String bvid) async {
    try {
      final response = await _dioClient.get(Endpoints.bilibiliVideo(bvid));
      final data = _handleResponse(response) as Map<String, dynamic>;
      return BilibiliVideoDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站视频信息失败: $e');
      rethrow;
    }
  }

  /// 获取B站音频流
  Future<BilibiliAudioDto> getBilibiliAudio(String bvid) async {
    try {
      final response = await _dioClient.get(Endpoints.bilibiliAudio(bvid));
      final data = _handleResponse(response) as Map<String, dynamic>;
      return BilibiliAudioDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站音频失败: $e');
      rethrow;
    }
  }

  /// 获取B站推荐视频
  Future<Map<String, dynamic>> getBilibiliRecommendations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        Endpoints.bilibiliRecommend,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站推荐失败: $e');
      rethrow;
    }
  }

  // ==================== 网易云 API ====================

  /// 获取网易云QR码
  Future<NeteaseQRCodeDto> getNeteaseQRCode() async {
    try {
      final response = await _dioClient.post(Endpoints.neteaseQrcode);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return NeteaseQRCodeDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云QR码失败: $e');
      rethrow;
    }
  }

  /// 检查网易云QR码状态
  Future<NeteaseQRStatusDto> checkNeteaseQRStatus(String key) async {
    try {
      final response = await _dioClient.post(
        Endpoints.neteaseQrcodeCheck,
        data: {'key': key},
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      return NeteaseQRStatusDto.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '检查网易云QR码状态失败: $e');
      rethrow;
    }
  }

  /// 获取网易云绑定状态
  Future<Map<String, dynamic>> getNeteaseBindStatus() async {
    try {
      final response = await _dioClient.get(Endpoints.neteaseStatus);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云绑定状态失败: $e');
      rethrow;
    }
  }

  /// 解绑网易云账号
  Future<void> unbindNetease() async {
    try {
      await _dioClient.delete(Endpoints.neteaseUnbind);
      AppLogger.info('ApiClient', '网易云账号解绑成功');
    } catch (e) {
      AppLogger.error('ApiClient', '解绑网易云账号失败: $e');
      rethrow;
    }
  }

  /// 网易云手机号登录
  Future<Map<String, dynamic>> loginNeteaseWithCellphone({
    required String phone,
    required String password,
    String countryCode = '86',
  }) async {
    try {
      final response = await _dioClient.post(
        Endpoints.neteaseCellphoneLogin,
        data: {
          'phone': phone,
          'password': password,
          'countrycode': countryCode,
        },
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      AppLogger.info('ApiClient', '网易云手机号登录成功: $phone');
      return data;
    } catch (e) {
      AppLogger.error('ApiClient', '网易云手机号登录失败: $e');
      rethrow;
    }
  }

  /// 搜索网易云
  Future<Map<String, dynamic>> searchNetease(
    String keywords, {
    int? limit,
    int? offset,
    int? type,
  }) async {
    try {
      final response = await _dioClient.get(
        Endpoints.neteaseSearch,
        queryParameters: {
          'keywords': keywords,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
          if (type != null) 'type': type,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '搜索网易云失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌单详情
  Future<Map<String, dynamic>> getNeteasePlaylistDetail(String id) async {
    try {
      final response = await _dioClient.get(Endpoints.neteasePlaylistDetail(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云歌单详情失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌曲详情
  Future<Map<String, dynamic>> getNeteaseSongDetail(String ids) async {
    try {
      final response = await _dioClient.get(Endpoints.neteaseSongDetail(ids));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云歌曲详情失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌曲URL
  Future<Map<String, dynamic>> getNeteaseSongUrl(String id) async {
    try {
      final response = await _dioClient.get(Endpoints.neteaseSongUrl(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云歌曲URL失败: $e');
      rethrow;
    }
  }

  /// 获取网易云歌词
  Future<Map<String, dynamic>> getNeteaseLyric(String id) async {
    try {
      final response = await _dioClient.get(Endpoints.neteaseSongLyric(id));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云歌词失败: $e');
      rethrow;
    }
  }

  // ==================== 通用请求方法（向后兼容） ====================

  /// 通用 GET 请求
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', 'GET 请求失败 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 POST 请求
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      final response = await _dioClient.post(endpoint, data: data);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', 'POST 请求失败 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 PUT 请求
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      final response = await _dioClient.put(endpoint, data: data);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', 'PUT 请求失败 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 DELETE 请求
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dioClient.delete(endpoint);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', 'DELETE 请求失败 ($endpoint): $e');
      rethrow;
    }
  }
}
