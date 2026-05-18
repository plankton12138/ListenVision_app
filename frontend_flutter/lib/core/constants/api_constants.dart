/// API 常量定义
///
/// 集中管理所有 API 相关的配置
/// 便于环境切换和配置管理
///
/// 环境切换方式：
/// ```bash
/// # 开发环境（默认）
/// flutter run
///
/// # 测试环境
/// flutter run --dart-define=API_ENV=test
///
/// # 生产环境
/// flutter run --dart-define=API_ENV=prod
/// ```
library;

import 'package:listenvision/core/config/app_config.dart';

/// API 基础配置
class ApiConstants {
  /// 全局应用配置实例
  static final config = appConfig;

  /// API 基础 URL（从 AppConfig 获取）
  static String get baseUrl => config.apiBaseUrl;

  /// API 版本
  static String get apiVersion => config.apiVersion;

  /// 完整的基础 URL
  static String get fullBaseUrl => config.fullApiBaseUrl;

  /// 请求超时时间（从 AppConfig 获取）
  static Duration get connectTimeout => Duration(seconds: config.connectTimeoutSeconds);
  static Duration get receiveTimeout => Duration(seconds: config.receiveTimeoutSeconds);
  static Duration get sendTimeout => Duration(seconds: config.sendTimeoutSeconds);

  /// 是否启用日志（从 AppConfig 获取）
  static bool get enableLogging => config.enableApiLogging;
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
  static String sortPlaylist(dynamic id) => '/playlists/$id/sort';
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
  static String audio(String bvid) => '/bilibili/video/$bvid/audio';
  static String uploader(dynamic mid) => '/bilibili/uploader/$mid';
  static const String search = '/bilibili/search';
  static const String searchSuggest = '/bilibili/search/suggest';
  static const String searchRecent = '/bilibili/search/recent';
  static const String proxyImage = '/bilibili/proxy/image';
  static const String proxyAudio = '/bilibili/proxy/audio';
  static const String recommend = '/bilibili/recommend';
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

// ==================== 音频格式配置 ====================

/// 音频格式类型
enum AudioFormat {
  m4s('m4s', 'audio/mp4', '原始M4S格式'),
  mp3('mp3', 'audio/mpeg', 'MP3格式 (跨平台兼容)'),
  aac('aac', 'audio/aac', 'AAC格式');

  const AudioFormat(this.value, this.contentType, this.description);

  final String value;
  final String contentType;
  final String description;
}

/// 平台特定的音频格式偏好
///
/// Windows: 优先MP3 (just_audio对m4s支持不如移动端)
/// macOS: 优先MP3
/// Linux: 优先MP3
/// Android/iOS: 优先m4s (原生支持)
/// Web: 优先mp3 (浏览器兼容性)
class PlatformAudioFormat {
  /// 判断当前是否需要转换格式
  static bool needsConversion(String platform) {
    return _platformPreferredFormat(platform) != 'm4s';
  }

  /// 获取平台的默认音频格式
  static String getDefaultFormat(String platform) {
    return _platformPreferredFormat(platform);
  }

  /// 获取代理音频的完整URL（带格式参数）
  static String getProxyAudioUrl(String baseUrl, String audioUrl, String platform) {
    final format = _platformPreferredFormat(platform);
    if (format == 'm4s') {
      return '$baseUrl?url=${Uri.encodeComponent(audioUrl)}';
    }
    return '$baseUrl?url=${Uri.encodeComponent(audioUrl)}&format=$format';
  }

  /// 平台首选项映射
  static String _platformPreferredFormat(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
      case 'ios':
      case 'mobile':
        return 'm4s'; // 移动端原生支持m4s
      case 'windows':
      case 'macos':
      case 'linux':
      case 'desktop':
        return 'mp3'; // 桌面端需要转换
      case 'web':
      case 'browser':
        return 'mp3'; // Web浏览器兼容性
      default:
        return 'm4s';
    }
  }
}
