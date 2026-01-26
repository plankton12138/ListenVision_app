import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 应用环境配置
///
/// 支持多环境切换：dev / test / staging / prod
/// 使用方式：
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

// ==================== 环境类型 ====================

/// 环境类型枚举
enum AppEnvironment {
  dev('开发环境', 'http://127.0.0.1:3000'),
  test('测试环境', 'http://192.168.0.197:3000'),
  staging('预发布环境', 'https://staging-api.listenvision.com'),
  prod('生产环境', 'https://api.listenvision.com');

  final String description;
  final String defaultBaseUrl;

  const AppEnvironment(this.description, this.defaultBaseUrl);
}

/// 应用配置类
class AppConfig {

  // ==================== 单例模式 ====================

  static AppConfig? _instance;

  factory AppConfig() => _instance ??= AppConfig._internal();

  AppConfig._internal() {
    _loadEnvironment();
  }

  // ==================== 环境状态 ====================

  /// 当前环境
  late final AppEnvironment _currentEnv;

  /// 当前环境
  AppEnvironment get currentEnv => _currentEnv;

  /// 当前环境名称
  String get envName => _currentEnv.name;

  /// 当前环境描述
  String get envDescription => _currentEnv.description;

  /// 是否为开发环境
  bool get isDev => _currentEnv == AppEnvironment.dev;

  /// 是否为测试环境
  bool get isTest => _currentEnv == AppEnvironment.test;

  /// 是否为预发布环境
  bool get isStaging => _currentEnv == AppEnvironment.staging;

  /// 是否为生产环境
  bool get isProd => _currentEnv == AppEnvironment.prod;

  /// 是否为非生产环境
  bool get isNotProd => _currentEnv != AppEnvironment.prod;

  // ==================== API 配置 ====================

  /// API 基础 URL
  late final String _apiBaseUrl;

  /// API 基础 URL
  String get apiBaseUrl => _apiBaseUrl;

  /// API 版本前缀
  String get apiVersion => '/api';

  /// 完整的 API 基础 URL
  String get fullApiBaseUrl => '$_apiBaseUrl$apiVersion';

  // ==================== 超时配置 ====================

  /// 连接超时（秒）
  int get connectTimeoutSeconds => _currentEnv == AppEnvironment.prod ? 30 : 60;

  /// 接收超时（秒）
  int get receiveTimeoutSeconds => _currentEnv == AppEnvironment.prod ? 30 : 60;

  /// 发送超时（秒）
  int get sendTimeoutSeconds => _currentEnv == AppEnvironment.prod ? 30 : 60;

  // ==================== 日志配置 ====================

  /// 是否启用 API 日志
  bool get enableApiLogging => _currentEnv != AppEnvironment.prod;

  /// 是否启用调试日志
  bool get enableDebugLogging => _currentEnv != AppEnvironment.prod;

  /// 是否启用性能监控
  bool get enablePerformanceMonitoring => _currentEnv == AppEnvironment.prod;

  // ==================== 功能开关 ====================

  /// 是否启用错误报告（如 Sentry）
  bool get enableErrorReporting => _currentEnv == AppEnvironment.prod;

  /// 是否启用分析（如 Firebase Analytics）
  bool get enableAnalytics => _currentEnv == AppEnvironment.prod || _currentEnv == AppEnvironment.staging;

  /// 是否启用崩溃报告
  bool get enableCrashReporting => _currentEnv == AppEnvironment.prod;

  /// 是否启用调试模式
  bool get isDebugMode => _currentEnv != AppEnvironment.prod;

  // ==================== 其他配置 ====================

  /// 每页数量（分页）
  int get pageSize => 20;

  /// 最大重试次数
  int get maxRetryCount => 3;

  /// 缓存过期时间（秒）
  int get cacheExpirySeconds => 3600; // 1小时

  // ==================== 私有方法 ====================

  /// 从环境变量加载配置
  void _loadEnvironment() {
    // 从编译参数获取环境，默认为 dev
    const envParam = String.fromEnvironment('API_ENV', defaultValue: 'dev');

    // 解析环境
    _currentEnv = AppEnvironment.values.firstWhere(
      (e) => e.name == envParam,
      orElse: () => AppEnvironment.dev,
    );

    // 从编译参数获取 API URL（如果指定）
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');

    _apiBaseUrl = customBaseUrl.isNotEmpty
        ? customBaseUrl
        : _currentEnv.defaultBaseUrl;

    // 打印配置信息
    if (kDebugMode) {
      _printConfig();
    }
  }

  /// 打印配置信息
  void _printConfig() {
    AppLogger.debug('AppConfig', '========================================');
    AppLogger.debug('AppConfig', 'AppConfig 环境配置');
    AppLogger.debug('AppConfig', '----------------------------------------');
    AppLogger.debug('AppConfig', '环境: $_currentEnv (${_currentEnv.description})');
    AppLogger.debug('AppConfig', 'API URL: $_apiBaseUrl');
    AppLogger.debug('AppConfig', 'API 日志: $enableApiLogging');
    AppLogger.error('AppConfig', '错误报告: $enableErrorReporting');
    AppLogger.debug('AppConfig', '分析: $enableAnalytics');
    AppLogger.debug('AppConfig', '========================================');
  }

  // ==================== 工具方法 ====================

  /// 获取完整的 API 端点 URL
  String getEndpointUrl(String endpoint) {
    return '$fullApiBaseUrl$endpoint';
  }

  /// 获取完整的资源 URL
  String getResourceUrl(String path) {
    return '$_apiBaseUrl$path';
  }

  /// 重置配置（用于测试）
  static void reset() {
    _instance = null;
  }

  // ==================== 环境描述 ====================

  @override
  String toString() {
    return 'AppConfig(env: $_currentEnv, apiBaseUrl: $_apiBaseUrl)';
  }
}

// ==================== 全局访问 ====================

/// 全局配置实例
final appConfig = AppConfig();
