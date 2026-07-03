/// 应用配置（纯前端架构）
///
/// 无后端服务器，所有数据本地存储，B站 API 直连。
class AppConfig {
  static AppConfig? _instance;

  factory AppConfig() => _instance ??= AppConfig._internal();

  AppConfig._internal();

  // ==================== 超时配置 ====================

  int get connectTimeoutSeconds => 30;
  int get receiveTimeoutSeconds => 30;
  int get sendTimeoutSeconds => 30;

  /// 下载连接超时（秒）
  int get downloadConnectTimeoutSeconds => 30;

  /// 下载接收超时（秒）— 客户端 FFmpeg 转换，预留足够时间
  int get downloadReceiveTimeoutSeconds => 300;

  /// 下载发送超时（秒）
  int get downloadSendTimeoutSeconds => 30;

  // ==================== 日志配置 ====================

  bool get enableApiLogging => true;
  bool get enableDebugLogging => true;
  bool get enablePerformanceMonitoring => false;

  // ==================== 功能开关 ====================

  bool get enableErrorReporting => false;
  bool get enableAnalytics => false;
  bool get enableCrashReporting => false;
  bool get isDebugMode => true;

  // ==================== 其他配置 ====================

  int get pageSize => 20;
  int get maxRetryCount => 3;
  int get cacheExpirySeconds => 3600;

  static void reset() {
    _instance = null;
  }
}

final appConfig = AppConfig();
