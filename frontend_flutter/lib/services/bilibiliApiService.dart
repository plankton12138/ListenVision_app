import 'dart:convert';
import 'package:demo/exceptions/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// B站API服务 - 通过后端代理访问B站接口
///
/// 设计说明：
/// 1. 所有B站API调用都通过后端代理，不再直接调用B站
/// 2. 使用JWT token进行用户认证
/// 3. 资源URL通过后端代理解决防盗链问题
class BilibiliApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api/bilibili';
  static const String _audioBaseUrl = 'http://127.0.0.1:3000/api/audio';

  final http.Client _client;
  final String? _token;

  BilibiliApiService({http.Client? client, String? token})
      : _client = client ?? http.Client(),
        _token = token;

  /// 获取请求头（包含JWT认证）
  Map<String, String> _getHeaders({bool isJson = true}) {
    final headers = <String, String>{
      'Content-Type': isJson ? 'application/json' : 'application/x-www-form-urlencoded',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// 解析响应体
  dynamic _parseResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      debugPrint('Parse JSON exception: $e');
      throw FormatException('Invalid server response format');
    }
  }

  /// 处理响应，检查成功状态
  dynamic _handleResponse(http.Response response) {
    final responseBody = _parseResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody['success'] == true) {
        return responseBody['data'];
      } else {
        throw ApiException(
          responseBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } else {
      throw ApiException(
        responseBody['message'] ?? responseBody['error'] ?? 'Request failed',
        response.statusCode,
      );
    }
  }

  // ==================== QR码登录 ====================

  /// 获取QR码登录凭证
  ///
  /// 返回：{ qrcodeKey: String, qrcodeUrl: String, expiresAt: DateTime }
  Future<Map<String, dynamic>> getQRCode() async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/qrcode'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

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
    } on FormatException {
      throw ApiException('Invalid server response format', 500);
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
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/qrcode/check'),
            headers: _getHeaders(),
            body: jsonEncode({'qrcodeKey': qrcodeKey}),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = _parseResponse(response);
      debugPrint('【QR码检查】原始响应: $responseBody');

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          final data = responseBody['data'] as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending';
          debugPrint('【QR码检查】解析状态: $status, userInfo: ${data?['userInfo']}');
          return {
            'status': status,
            'userInfo': data?['userInfo'],
          };
        }
      }
      throw ApiException(
        responseBody['message'] ?? 'Check QR status failed',
        response.statusCode,
      );
    } on FormatException {
      throw ApiException('Invalid server response format', 500);
    } catch (e) {
      debugPrint('checkQRLoginStatus exception: $e');
      rethrow;
    }
  }

  // ==================== 账号绑定 ====================

  /// 获取B站账号绑定状态
  Future<Map<String, dynamic>> getBindStatus() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/status'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getBindStatus exception: $e');
      rethrow;
    }
  }

  /// 解绑B站账号
  Future<Map<String, dynamic>> unbindAccount() async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$_baseUrl/unbind'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

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
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/video/$bvid'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/audio/$bvid'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

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
      final uri = Uri.parse('$_baseUrl/uploader/$mid').replace(
        queryParameters: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      final response = await _client
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

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
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'keyword': keyword,
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      final response = await _client
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('searchBilibili exception: $e');
      rethrow;
    }
  }

  /// 获取最近搜索关键词
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/search/recent').replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await _client
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

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
      final response = await _client
          .get(
            Uri.parse('$_audioBaseUrl/metadata/$bvid'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) return null;
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getAudioMetadata exception: $e');
      return null;
    }
  }

  /// 刷新音频元数据缓存
  Future<Map<String, dynamic>> refreshAudioMetadata(String bvid) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_audioBaseUrl/metadata/$bvid/refresh'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('refreshAudioMetadata exception: $e');
      rethrow;
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_audioBaseUrl/stats'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getCacheStats exception: $e');
      return {'count': 0, 'totalSize': 0};
    }
  }

  /// 批量获取音频元数据
  Future<Map<String, Map<String, dynamic>>> getBatchMetadata(List<String> bvids) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_audioBaseUrl/metadata/batch'),
            headers: _getHeaders(),
            body: jsonEncode({'bvids': bvids}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      final metadata = data['metadata'] as Map<String, dynamic>?;
      return metadata?.cast<String, Map<String, dynamic>>() ?? {};
    } catch (e) {
      debugPrint('getBatchMetadata exception: $e');
      return {};
    }
  }
}
