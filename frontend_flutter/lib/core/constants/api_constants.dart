/// API 常量定义（纯前端架构）
///
/// 不再依赖后端服务器，B站 API 直连，音频通过 BilibiliApiService 获取。
library;

/// API 基础配置
class ApiConstants {
  /// B站 API 基础 URL
  static const String baseUrl = 'https://api.bilibili.com';

  /// 请求超时时间
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// 是否启用日志
  static const bool enableLogging = true;
}

/// B站相关常量
class BilibiliConstants {
  static const String videoUrlPrefix = 'https://www.bilibili.com/video/';
  static const String audioUrlPrefix = 'https://audio.';
}

// ==================== HTTP 头部 ====================

class HttpHeaders {
  static const String contentType = 'Content-Type';
  static const String json = 'application/json';
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

enum AudioFormat {
  m4s('m4s', 'audio/mp4', '原始M4S格式'),
  mp3('mp3', 'audio/mpeg', 'MP3格式 (跨平台兼容)'),
  aac('aac', 'audio/aac', 'AAC格式');

  const AudioFormat(this.value, this.contentType, this.description);

  final String value;
  final String contentType;
  final String description;
}
