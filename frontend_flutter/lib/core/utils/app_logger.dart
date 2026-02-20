import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别枚举
enum LogLevel {
  /// 调试信息（最详细）
  debug(0, 'DEBUG'),

  /// 一般信息
  info(1, 'INFO'),

  /// 警告信息
  warn(2, 'WARN'),

  /// 错误信息
  error(3, 'ERROR');

  final int value;
  final String name;

  const LogLevel(this.value, this.name);
}

/// 应用日志系统
///
/// 提供统一的日志记录功能，支持：
/// - 多级别日志（DEBUG, INFO, WARN, ERROR）
/// - 控制台输出（开发环境）
/// - 本地文件持久化（所有环境）
/// - 自动日志轮转（大小限制）
/// - 自动清理过期日志（数量限制）
///
/// 使用示例：
/// ```dart
/// AppLogger.debug('用户操作', '点击登录按钮');
/// AppLogger.info('网络请求', 'GET /api/user');
/// AppLogger.warn('缓存', '缓存未命中');
/// AppLogger.error('数据库', '连接失败', error: e, stackTrace: stackTrace);
/// ```
class AppLogger {
  // ==================== 单例模式 ====================

  AppLogger._internal();

  static final AppLogger _instance = AppLogger._internal();

  /// 获取单例实例
  static AppLogger get instance => _instance;

  // ==================== 常量配置 ====================

  /// 单个日志文件最大大小（5MB）
  static const int _maxLogFileSize = 5 * 1024 * 1024;

  /// 最多保留的日志文件数量
  static const int _maxLogFiles = 5;

  /// 日志文件名前缀
  static const String _logFilePrefix = 'app';

  /// 日志文件扩展名
  static const String _logFileExtension = '.log';

  /// 日志目录名称
  static const String _logDirectoryName = 'logs';

  /// 当前日志级别（可动态调整）
  LogLevel _currentLevel = LogLevel.debug;

  /// 获取当前日志级别
  LogLevel get currentLevel => _currentLevel;

  /// 设置日志级别
  void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  // ==================== 私有状态 ====================

  /// 日志目录
  Directory? _logDirectory;

  /// 当前日志文件
  File? _currentLogFile;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 日志写入队列（避免并发写入导致乱码）
  final List<String> _writeQueue = [];

  /// 是否正在写入
  bool _isWriting = false;

  // ==================== 公开方法 ====================

  /// 初始化日志系统
  ///
  /// 在应用启动时调用（main.dart 中）
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Web 平台：跳过文件日志，仅使用控制台输出
      if (kIsWeb) {
        if (kDebugMode) {
          print('📁 AppLogger: Web 平台，仅使用控制台输出');
        }
        _isInitialized = true;
        return;
      }

      // 获取应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();

      // 创建日志目录
      _logDirectory = Directory('${appDocDir.path}/$_logDirectoryName');
      if (!await _logDirectory!.exists()) {
        await _logDirectory!.create(recursive: true);
      }

      // 清理过期日志文件
      await _cleanOldLogs();

      // 创建或获取当前日志文件
      await _prepareCurrentLogFile();

      _isInitialized = true;

      // 记录初始化成功
      info('AppLogger', '日志系统初始化成功', extra: {
        'logDirectory': _logDirectory!.path,
        'currentLogFile': _currentLogFile!.path,
      });

      // 在开发环境下输出日志目录路径
      if (kDebugMode) {
        print('📁 AppLogger: 日志目录 = ${_logDirectory!.path}');
      }
    } catch (e, stackTrace) {
      // 初始化失败时降级为仅控制台输出
      if (kDebugMode) {
        print('❌ AppLogger 初始化失败: $e\n$stackTrace');
      }
      // 标记为已初始化（避免重复尝试）
      _isInitialized = true;
    }
  }

  /// 记录 DEBUG 级别日志
  static void debug(String tag, String message, {Map<String, dynamic>? extra}) {
    instance._log(LogLevel.debug, tag, message, extra: extra);
  }

  /// 记录 INFO 级别日志
  static void info(String tag, String message, {Map<String, dynamic>? extra}) {
    instance._log(LogLevel.info, tag, message, extra: extra);
  }

  /// 记录 WARN 级别日志
  static void warn(String tag, String message, {Map<String, dynamic>? extra}) {
    instance._log(LogLevel.warn, tag, message, extra: extra);
  }

  /// 记录 ERROR 级别日志
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    instance._log(
      LogLevel.error,
      tag,
      message,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  // ==================== 用户操作追踪 ====================

  /// 记录用户操作
  ///
  /// 用于追踪用户在应用中的关键操作，如点击、导航、表单提交等
  ///
  /// 参数：
  /// - [feature] 功能模块名称（如 'AudioPlayer', 'Auth'）
  /// - [action] 操作描述（如 '播放', '暂停', '登录'）
  /// - [parameters] 操作相关的参数（可选）
  /// - [userId] 用户 ID（可选）
  static void logUserAction(
    String feature,
    String action, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    final data = <String, dynamic>{
      'action': action,
      'feature': feature,
      'timestamp': DateTime.now().toIso8601String(),
      if (userId != null) 'userId': userId,
      if (parameters != null) 'parameters': parameters,
    };

    info(feature, action, extra: data);
  }

  /// 记录页面导航
  ///
  /// 用于追踪用户在应用中的页面跳转行为
  ///
  /// 参数：
  /// - [from] 来源页面名称
  /// - [to] 目标页面名称
  /// - [userId] 用户 ID（可选）
  static void logNavigation(String from, String to, {String? userId}) {
    logUserAction(
      'Navigation',
      '页面跳转',
      parameters: {'from': from, 'to': to},
      userId: userId,
    );
  }

  /// 记录按钮点击
  ///
  /// 用于追踪用户点击按钮的行为
  ///
  /// 参数：
  /// - [button] 按钮名称或标识
  /// - [context] 按钮所在的功能上下文
  /// - [parameters] 操作相关的参数（可选）
  /// - [userId] 用户 ID（可选）
  static void logButtonClick(
    String button,
    String context, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    logUserAction(
      context,
      '点击按钮: $button',
      parameters: {...?parameters, 'button': button},
      userId: userId,
    );
  }

  // ==================== 日志文件管理 ====================

  /// 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    if (_logDirectory == null || !await _logDirectory!.exists()) {
      return [];
    }
    return _logDirectory!
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(_logFileExtension))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // 按时间倒序
  }

  /// 获取当前日志文件内容
  Future<String?> getCurrentLogContent({int maxLines = 500}) async {
    if (_currentLogFile == null || !await _currentLogFile!.exists()) {
      return null;
    }

    try {
      final content = await _currentLogFile!.readAsString();
      final lines = content.split('\n');
      if (lines.length > maxLines) {
        return lines.skip(lines.length - maxLines).join('\n');
      }
      return content;
    } catch (e) {
      return null;
    }
  }

  /// 清空所有日志
  Future<void> clearAllLogs() async {
    if (_logDirectory == null || !await _logDirectory!.exists()) {
      return;
    }

    try {
      final files = await getLogFiles();
      for (final file in files) {
        await file.delete();
      }
      info('AppLogger', '已清空所有日志文件');
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ 清空日志失败: $e');
      }
    }
  }

  // ==================== 私有方法 ====================

  /// 核心日志方法
  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    // 检查日志级别
    if (level.value < _currentLevel.value) {
      return;
    }

    // 格式化日志内容
    final logEntry = _formatLogEntry(level, tag, message, error, stackTrace, extra);

    // 控制台输出（开发环境）
    if (kDebugMode) {
      _printToConsole(level, tag, logEntry, error, stackTrace);
    }

    // 文件持久化（异步，不阻塞）
    _writeToFile(logEntry);
  }

  /// 格式化日志条目
  String _formatLogEntry(
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  ) {
    final buffer = StringBuffer();

    // 时间戳
    final timestamp = DateTime.now().toIso8601String();
    buffer.write('[$timestamp] ');

    // 日志级别
    buffer.write('[${level.name}] ');

    // 标签
    buffer.write('[$tag] ');

    // 消息
    buffer.write(message);

    // 额外信息
    if (extra != null && extra.isNotEmpty) {
      buffer.write(' | ${const JsonEncoder.withIndent(null).convert(extra)}');
    }

    // 错误信息
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    // 堆栈跟踪
    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n${stackTrace.toString().split('\n').take(10).join('\n')}');
    }

    return buffer.toString();
  }

  /// 输出到控制台
  void _printToConsole(
    LogLevel level,
    String tag,
    String logEntry,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // 根据级别选择颜色
    final color = _getConsoleColor(level);
    final emoji = _getLevelEmoji(level);

    // ignore: avoid_print
    print('$color$emoji [$tag] $logEntry\u001B[0m');

    // 单独打印堆栈（便于调试）
    if (stackTrace != null && level == LogLevel.error) {
      // ignore: avoid_print
      print('$color  └─ StackTrace:\n${stackTrace.toString().split('\n').take(5).join('\n')}\u001B[0m');
    }
  }

  /// 获取控制台颜色代码
  String _getConsoleColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\u001B[36m'; // 青色
      case LogLevel.info:
        return '\u001B[32m'; // 绿色
      case LogLevel.warn:
        return '\u001B[33m'; // 黄色
      case LogLevel.error:
        return '\u001B[31m'; // 红色
    }
  }

  /// 获取日志级别对应的 emoji
  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warn:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// 写入文件（带队列机制，避免并发写入乱码）
  Future<void> _writeToFile(String logEntry) async {
    // 如果未初始化，跳过文件写入
    if (!_isInitialized || _currentLogFile == null) {
      return;
    }

    // 加入队列
    _writeQueue.add(logEntry);

    // 如果正在写入，直接返回（等待当前写入完成）
    if (_isWriting) {
      return;
    }

    // 开始处理队列
    _isWriting = true;
    try {
      while (_writeQueue.isNotEmpty) {
        final entry = _writeQueue.removeAt(0);
        await _writeEntryToFile(entry);
      }
    } finally {
      _isWriting = false;
    }
  }

  /// 实际写入单条日志
  Future<void> _writeEntryToFile(String logEntry) async {
    try {
      // 检查文件大小，超过限制则轮转
      if (_currentLogFile != null && await _currentLogFile!.exists()) {
        final fileSize = await _currentLogFile!.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLogFile();
        }
      }

      // 追加写入
      await _currentLogFile!.writeAsString(
        '$logEntry\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // 文件写入失败时不影响应用运行
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ AppLogger 写入文件失败: $e');
      }
    }
  }

  /// 准备当前日志文件
  Future<void> _prepareCurrentLogFile() async {
    if (_logDirectory == null) return;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final logFileName = '$_logFilePrefix-$dateStr$_logFileExtension';
    final logFile = File('${_logDirectory!.path}/$logFileName');

    if (!await logFile.exists()) {
      await logFile.create();
    }

    _currentLogFile = logFile;
  }

  /// 日志轮转
  Future<void> _rotateLogFile() async {
    if (_logDirectory == null) return;

    try {
      // 重命名当前文件（添加时间戳后缀）
      if (_currentLogFile != null && await _currentLogFile!.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${_currentLogFile!.path}.$timestamp';
        await _currentLogFile!.rename(newPath);
      }

      // 创建新的日志文件
      await _prepareCurrentLogFile();

      // 清理超量的旧日志
      await _cleanOldLogs();

      debug('AppLogger', '日志文件已轮转');
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ 日志轮转失败: $e');
      }
    }
  }

  /// 清理过期日志
  Future<void> _cleanOldLogs() async {
    if (_logDirectory == null) return;

    try {
      final files = await getLogFiles();

      // 保留最新的 N 个文件，删除其余的
      if (files.length > _maxLogFiles) {
        final filesToDelete = files.skip(_maxLogFiles);
        for (final file in filesToDelete) {
          await file.delete();
        }
        debug('AppLogger', '已清理 ${filesToDelete.length} 个过期日志文件');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ 清理日志失败: $e');
      }
    }
  }
}

/// 日志配置类
///
/// 用于集中管理日志相关的配置
class LogConfig {
  LogConfig._();

  /// 是否启用文件日志
  static bool enableFileLogging = true;

  /// 是否启用控制台日志
  static bool enableConsoleLogging = true;

  /// 控制台日志最大行数（避免刷屏）
  static const int maxConsoleLines = 100;

  /// 是否记录网络请求
  static bool logNetworkRequests = true;

  /// 是否记录数据库操作
  static bool logDatabaseOperations = true;

  /// 日志上报地址（可选，用于生产环境）
  static String? logUploadEndpoint;

  /// 设置日志级别
  static void setLevel(LogLevel level) {
    AppLogger.instance.setLevel(level);
  }

  /// 启用调试模式（显示所有日志）
  static void enableDebugMode() {
    setLevel(LogLevel.debug);
  }

  /// 启用生产模式（只记录 WARN 和 ERROR）
  static void enableProductionMode() {
    setLevel(LogLevel.warn);
  }
}

/// 快捷方法：调试日志
void logDebug(String tag, String message, {Map<String, dynamic>? extra}) {
  AppLogger.debug(tag, message, extra: extra);
}

/// 快捷方法：信息日志
void logInfo(String tag, String message, {Map<String, dynamic>? extra}) {
  AppLogger.info(tag, message, extra: extra);
}

/// 快捷方法：警告日志
void logWarn(String tag, String message, {Map<String, dynamic>? extra}) {
  AppLogger.warn(tag, message, extra: extra);
}

/// 快捷方法：错误日志
void logError(
  String tag,
  String message, {
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) {
  AppLogger.error(
    tag,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );
}
