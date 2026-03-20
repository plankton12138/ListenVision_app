import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dto/api_dto.dart';
import '../../models/search_suggestion.dart';
import '../../models/subtitle.dart';
import '../errors/exceptions.dart';
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
      // 使用新的异常类型
      final statusCode = response['statusCode'] as int? ?? 500;
      final error = response['error'] as String? ?? response['message'] as String? ?? '请求失败';
      final code = response['code'] as String?;

      throw ApiServerException.fromResponse(
        error: error,
        statusCode: statusCode,
        code: code,
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

  /// 获取 B 站搜索建议
  Future<List<SearchSuggestion>> getBilibiliSearchSuggestions(
    String keyword,
  ) async {
    try {
      final response = await _dioClient.get(
        Endpoints.bilibiliSearchSuggest,
        queryParameters: {'keyword': keyword},
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List? ?? const [];
      return suggestions
          .map((item) => SearchSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('ApiClient', '获取B站搜索建议失败: $e');
      return [];
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

  /// 获取B站视频字幕
  /// [cid] 可选，用于多P视频获取指定分P的字幕
  Future<SubtitleData> getBilibiliSubtitle(String bvid, {int? cid}) async {
    try {
      AppLogger.debug('ApiClient', '请求字幕: $bvid, cid=$cid, token: ${DioClient.instance.currentToken != null ? "已设置" : "未设置"}');
      final response = await _dioClient.get(Endpoints.bilibiliSubtitle(bvid, cid: cid));
      final data = _handleResponse(response) as Map<String, dynamic>;
      AppLogger.info('ApiClient', '获取字幕成功: $bvid, cid=$cid, subtitles: ${(data['subtitles'] as List?)?.length ?? 0}');
      return SubtitleData.fromJson(data);
    } catch (e) {
      AppLogger.error('ApiClient', '获取字幕失败: $e');
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

  /// 获取网易云推荐歌单
  Future<Map<String, dynamic>> getNeteaseRecommendedPlaylists() async {
    try {
      final response = await _dioClient.get(
        Endpoints.neteaseRecommendedPlaylists,
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取网易云推荐歌单失败: $e');
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

  // ==================== 歌单 API ====================

  /// 获取用户歌单列表
  Future<Map<String, dynamic>> getUserPlaylists({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        Endpoints.playlistsList,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取歌单列表失败: $e');
      rethrow;
    }
  }

  /// 获取歌单详情
  Future<Map<String, dynamic>> getPlaylistDetail(String id) async {
    try {
      final response = await _dioClient.get(
        Endpoints.playlistsDetail(int.tryParse(id) ?? int.parse(id)),
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取歌单详情失败: $e');
      rethrow;
    }
  }

  /// 获取歌单项
  Future<Map<String, dynamic>> getPlaylistItems(String id) async {
    try {
      final response = await _dioClient.get(
        Endpoints.playlistsItems(int.tryParse(id) ?? int.parse(id)),
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取歌单项失败: $e');
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
        Endpoints.playlistsList,
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '创建歌单失败: $e');
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
        Endpoints.playlistsDetail(int.tryParse(id) ?? int.parse(id)),
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '更新歌单失败: $e');
      rethrow;
    }
  }

  /// 删除歌单
  Future<void> deletePlaylist(String id) async {
    try {
      await _dioClient.delete(
        Endpoints.playlistsDetail(int.tryParse(id) ?? int.parse(id)),
      );
      AppLogger.info('ApiClient', '删除歌单成功: $id');
    } catch (e) {
      AppLogger.error('ApiClient', '删除歌单失败: $e');
      rethrow;
    }
  }

  /// 添加歌单项
  Future<void> addPlaylistItem({
    required String playlistId,
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      await _dioClient.post(
        Endpoints.playlistsItems(int.tryParse(playlistId) ?? int.parse(playlistId)),
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
          if (position != null) 'position': position,
        },
      );
      AppLogger.info('ApiClient', '添加歌单项成功: $bvid -> $playlistId');
    } catch (e) {
      AppLogger.error('ApiClient', '添加歌单项失败: $e');
      rethrow;
    }
  }

  /// 删除歌单项
  Future<void> removePlaylistItem({
    required String playlistId,
    required String bvid,
  }) async {
    try {
      final playlistIdInt = int.tryParse(playlistId) ?? int.parse(playlistId);
      await _dioClient.delete(
        '${Endpoints.playlistsItems(playlistIdInt)}/$bvid',
      );
      AppLogger.info('ApiClient', '删除歌单项成功: $bvid from $playlistId');
    } catch (e) {
      AppLogger.error('ApiClient', '删除歌单项失败: $e');
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
        Endpoints.playlistsFavorites,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取收藏列表失败: $e');
      rethrow;
    }
  }

  /// 保存播放队列到后端
  Future<void> saveNowPlaying(List<Map<String, dynamic>> items) async {
    try {
      await _dioClient.post(
        Endpoints.playlistsNowPlaying,
        data: {'items': items},
      );
      AppLogger.info('ApiClient', '保存播放队列成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('ApiClient', '保存播放队列失败: $e');
      rethrow;
    }
  }

  /// 切换收藏状态（返回操作结果）
  Future<Map<String, dynamic>> toggleFavorite(String bvid) async {
    try {
      final response = await _dioClient.post(
        Endpoints.playlistsFavoritesToggle,
        data: {'bvid': bvid},
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      AppLogger.info('ApiClient', '切换收藏: $bvid, 结果: ${data['added'] ?? data['is_added']}');
      return data;
    } catch (e) {
      AppLogger.error('ApiClient', '切换收藏失败: $e');
      rethrow;
    }
  }

  /// 检查收藏状态
  Future<bool> checkFavorite(String bvid) async {
    try {
      final response = await _dioClient.get(
        Endpoints.playlistsFavoritesCheck(bvid),
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      return data['is_favorite'] as bool? ?? data['favorited'] as bool? ?? false;
    } catch (e) {
      AppLogger.error('ApiClient', '检查收藏状态失败: $e');
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
      AppLogger.error('ApiClient', '获取云端收藏列表失败: $e');
      rethrow;
    }
  }

  /// 获取云端歌单列表（带时间戳）
  Future<Map<String, dynamic>> getCloudPlaylists() async {
    try {
      final response = await _dioClient.get(Endpoints.syncPlaylists);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取云端歌单列表失败: $e');
      rethrow;
    }
  }

  /// 获取云端播放历史（带时间戳）
  Future<Map<String, dynamic>> getCloudHistory() async {
    try {
      final response = await _dioClient.get(Endpoints.syncHistory);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取云端播放历史失败: $e');
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
      AppLogger.error('ApiClient', '获取增量变更失败: $e');
      rethrow;
    }
  }

  /// 获取同步状态
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await _dioClient.get(Endpoints.syncStatus);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', '获取同步状态失败: $e');
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
