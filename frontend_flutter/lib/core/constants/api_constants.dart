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
