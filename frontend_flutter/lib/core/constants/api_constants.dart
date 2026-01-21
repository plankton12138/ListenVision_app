/// API 常量定义
///
/// 集中管理所有 API 相关的配置
/// 便于环境切换和配置管理

/// API 基础配置
class ApiConstants {
  /// API 基础 URL
  ///
  /// 根据编译模式自动选择环境
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// API 版本
  static const String apiVersion = '/api';

  /// 完整的基础 URL
  static String get fullBaseUrl => '$baseUrl$apiVersion';

  /// 请求超时时间（毫秒）
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// 是否启用日志
  static const bool enableLogging = bool.fromEnvironment(
    'API_LOGGING',
    defaultValue: true,
  );
}

// ==================== 认证端点 ====================

class AuthEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String sendCode = '/auth/send-code';
  static const String verifyCode = '/auth/verify-code';
  static const String resetPassword = '/auth/reset-pwd';  // 修复：与后端一致
}

// ==================== 用户端点 ====================

class UserEndpoints {
  static const String users = '/users';
  static String userById(dynamic id) => '/users/$id';
  static String userProfile(dynamic id) => '/users/$id/profile';
}

// ==================== 歌单端点 ====================

class PlaylistEndpoints {
  static const String playlists = '/playlists';
  static String playlistById(dynamic id) => '/playlists/$id';
  static String playlistItems(dynamic id) => '/playlists/$id/items';
  static String playlistItem(dynamic id, String bvid) => '/playlists/$id/items/$bvid';
  static const String favorites = '/playlists/favorites';
  static const String favoritesToggle = '/playlists/favorites/toggle';
  static String favoritesCheck(String bvid) => '/playlists/favorites/check/$bvid';
}

// ==================== 播放历史端点 ====================

class HistoryEndpoints {
  static const String history = '/history';
  static String historyById(dynamic id) => '/history/$id';
}

// ==================== 搜索端点 ====================

class SearchEndpoints {
  static const String searchLocal = '/search/local';
  static const String searchSuggestions = '/search/suggestions';
  static const String searchTrending = '/search/trending';
  static const String searchHistory = '/search/history';
}

// ==================== 推荐端点 ====================

class RecommendationEndpoints {
  static const String hotPlaylists = '/recommendations/hot-playlists';
  static const String rank = '/recommendations/rank';
  static const String personalized = '/recommendations/personalized';
}

// ==================== B站端点 ====================

class BilibiliEndpoints {
  static const String qrcode = '/bilibili/qrcode';
  static const String qrcodeCheck = '/bilibili/qrcode/check';
  static const String unbind = '/bilibili/unbind';
  static const String status = '/bilibili/status';
  static String video(String bvid) => '/bilibili/video/$bvid';
  static String audio(String bvid) => '/bilibili/audio/$bvid';
  static String uploader(dynamic mid) => '/bilibili/uploader/$mid';
  static const String search = '/bilibili/search';
  static const String searchRecent = '/bilibili/search/recent';
  static const String proxyImage = '/bilibili/proxy/image';
  static const String proxyAudio = '/bilibili/proxy/audio';  // 修复：使用 query 参数
}

/// B站相关常量
class BilibiliConstants {
  /// QR码状态 - 未扫描
  static const String qrStatusNone = 'none';

  /// QR码状态 - 已扫描
  static const String qrStatusScanned = 'scanned';

  /// QR码状态 - 已确认
  static const String qrStatusConfirmed = 'confirmed';

  /// QR码状态 - 已过期
  static const String qrStatusExpired = 'expired';

  /// B站视频URL前缀
  static const String videoUrlPrefix = 'https://www.bilibili.com/video/';

  /// B站音频URL前缀
  static const String audioUrlPrefix = 'https://audio.';
}

/// 端点路径扩展
///
/// 为字符串添加 bvid 替换功能
extension EndpointPathExtension on String {
  /// 替换路径中的 bvid 占位符
  String withBvid(String bvid) {
    return replaceFirst('{bvid}', bvid);
  }
}

// ==================== 音频元数据端点 ====================

class AudioEndpoints {
  static const String metadata = '/audio/metadata';
  static String metadataById(String bvid) => '/audio/metadata/$bvid';
  static String metadataRefresh(String bvid) => '/audio/metadata/$bvid/refresh';
  static String metadataDelete(String bvid) => '/audio/metadata/$bvid';
  static const String metadataBatch = '/audio/metadata/batch';
  static String stream(String bvid) => '/audio/stream/$bvid';
  static const String searchHistory = '/audio/search/history';
  static const String searchRecent = '/audio/search/recent';
  static const String historyDelete = '/audio/search/history';
  static String searchKeywordDelete(String keyword) => '/audio/search/$keyword';
  static const String stats = '/audio/stats';
  static const String clean = '/audio/clean';
}

// ==================== HTTP 头部 ====================

class HttpHeaders {
  /// Content-Type
  static const String contentType = 'Content-Type';
  static const String json = 'application/json';

  /// Authorization
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer ';

  /// Accept
  static const String accept = 'Accept';
}

// ==================== HTTP 状态码 ====================

class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
}
