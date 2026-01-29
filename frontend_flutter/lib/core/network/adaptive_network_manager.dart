import 'dart:async';
import 'dart:io';
import 'package:demo/core/utils/app_logger.dart';

/// 网络质量等级
enum NetworkQuality {
  excellent, // 优秀 (>10Mbps, <50ms)
  good,      // 良好 (5-10Mbps, 50-100ms)
  fair,      // 一般 (2-5Mbps, 100-200ms)
  poor,      // 较差 (1-2Mbps, 200-500ms)
  bad,       // 差 (<1Mbps, >500ms)
}

/// 自适应网络管理器 
///
/// 职责：
/// 1. 实时监测网络质量
/// 2. 根据网络质量调整超时和重试策略
/// 3. 提供网络状态通知
class AdaptiveNetworkManager {
  static final AdaptiveNetworkManager _instance = AdaptiveNetworkManager._internal();
  factory AdaptiveNetworkManager() => _instance;
  AdaptiveNetworkManager._internal();

  // 网络质量状态
  NetworkQuality _currentQuality = NetworkQuality.good;
  DateTime _lastCheckTime = DateTime.now();

  // 历史记录（用于趋势分析）
  final List<NetworkQuality> _qualityHistory = [];
  static const int _maxHistorySize = 10;

  // 监测暂停控制
  bool _monitoringPaused = false;
  DateTime? _monitoringPausedAt;
  String? _monitoringPausedReason;

  // 监听器
  final List<Function(NetworkQuality)> _qualityListeners = [];

  // 定时器
  Timer? _monitoringTimer;

  // 配置参数
  static const Duration _checkInterval = Duration(seconds: 30);
  static const String _testUrl = 'https://www.google.com/generate_204';

  // ==================== Getters ====================

  NetworkQuality get currentQuality => _currentQuality;
  bool get isMonitoring => _monitoringTimer?.isActive ?? false;

  // ==================== 监听器管理 ====================

  void addQualityListener(Function(NetworkQuality) listener) {
    _qualityListeners.add(listener);
  }

  void removeQualityListener(Function(NetworkQuality) listener) {
    _qualityListeners.remove(listener);
  }

  void _notifyQualityChange(NetworkQuality quality) {
    for (final listener in _qualityListeners) {
      listener(quality);
    }
  }

  // ==================== 网络监测 ====================

  /// 暂停网络质量监测（全局）
  void pauseMonitoring({String reason = 'manual pause'}) {
    if (_monitoringPaused) return;
    _monitoringPaused = true;
    _monitoringPausedAt ??= DateTime.now();
    _monitoringPausedReason = reason;
    stopMonitoring();
    AppLogger.warn(
      'AdaptiveNetworkManager',
      '网络监测已暂停: $reason at ${_monitoringPausedAt!.toIso8601String()}',
    );
  }

  /// 恢复网络质量监测
  void resumeMonitoring() {
    if (!_monitoringPaused) return;
    _monitoringPaused = false;
    AppLogger.info('AdaptiveNetworkManager', '网络监测已恢复');
  }

  /// 开始网络质量监测
  void startMonitoring() {
    if (_monitoringPaused) {
      AppLogger.warn('AdaptiveNetworkManager', '网络监测已暂停，跳过启动');
      return;
    }
    if (_monitoringTimer?.isActive ?? false) return;

    _monitoringTimer = Timer.periodic(_checkInterval, (_) {
      _checkNetworkQuality();
    });

    // 立即执行一次检测
    _checkNetworkQuality();

    AppLogger.info('AdaptiveNetworkManager', '网络监测已启动');
  }

  /// 停止网络质量监测
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    AppLogger.info('AdaptiveNetworkManager', '网络监测已停止');
  }

  /// 检测网络质量 - 修复：使用Isolate避免阻塞主线程
  Future<NetworkQuality> _checkNetworkQuality() async {
    if (_monitoringPaused) {
      return _currentQuality;
    }
    try {
      // 使用Completable和timeout确保不会阻塞太久
      final completer = Completer<NetworkQuality>();
      
      // 在后台执行网络检测
      Future.microtask(() async {
        try {
          final stopwatch = Stopwatch()..start();
          
          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 3)
            ..idleTimeout = const Duration(seconds: 3);

          final request = await client.getUrl(Uri.parse(_testUrl));
          final response = await request.close();
          await response.drain<void>();
          client.close();

          stopwatch.stop();
          final latency = stopwatch.elapsedMilliseconds;

          // 根据延迟判断网络质量
          NetworkQuality newQuality;
          if (latency < 50) {
            newQuality = NetworkQuality.excellent;
          } else if (latency < 100) {
            newQuality = NetworkQuality.good;
          } else if (latency < 200) {
            newQuality = NetworkQuality.fair;
          } else if (latency < 500) {
            newQuality = NetworkQuality.poor;
          } else {
            newQuality = NetworkQuality.bad;
          }

          if (!completer.isCompleted) {
            completer.complete(newQuality);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(NetworkQuality.bad);
          }
        }
      });

      // 设置总体超时（包括DNS解析等）
      final quality = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => NetworkQuality.bad,
      );

      _updateQuality(quality);
      _lastCheckTime = DateTime.now();

      AppLogger.debug('AdaptiveNetworkManager', '网络检测完成: 质量=$quality');

      return quality;
    } catch (e) {
      AppLogger.warn('AdaptiveNetworkManager', '网络检测失败: $e');
      _updateQuality(NetworkQuality.bad);
      return NetworkQuality.bad;
    }
  }

  /// 更新网络质量
  void _updateQuality(NetworkQuality quality) {
    if (_currentQuality != quality) {
      _currentQuality = quality;
      _notifyQualityChange(quality);
      AppLogger.info('AdaptiveNetworkManager', '网络质量变化: $quality');
    }

    // 记录历史
    _qualityHistory.add(quality);
    if (_qualityHistory.length > _maxHistorySize) {
      _qualityHistory.removeAt(0);
    }
  }

  /// 强制刷新网络质量
  Future<NetworkQuality> refreshQuality() async {
    if (_monitoringPaused) {
      return _currentQuality;
    }
    return await _checkNetworkQuality();
  }

  // ==================== 自适应策略 ====================

  /// 获取连接超时时间
  Duration getConnectTimeout() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 5);
      case NetworkQuality.good:
        return const Duration(seconds: 8);
      case NetworkQuality.fair:
        return const Duration(seconds: 12);
      case NetworkQuality.poor:
        return const Duration(seconds: 20);
      case NetworkQuality.bad:
        return const Duration(seconds: 30);
    }
  }

  /// 获取接收超时时间
  Duration getReceiveTimeout() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 10);
      case NetworkQuality.good:
        return const Duration(seconds: 15);
      case NetworkQuality.fair:
        return const Duration(seconds: 25);
      case NetworkQuality.poor:
        return const Duration(seconds: 40);
      case NetworkQuality.bad:
        return const Duration(seconds: 60);
    }
  }

  /// 获取重试次数
  int getRetryCount() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:
        return 1;
      case NetworkQuality.fair:
        return 2;
      case NetworkQuality.poor:
        return 3;
      case NetworkQuality.bad:
        return 5;
    }
  }

  /// 获取重试延迟
  Duration getRetryDelay(int attempt) {
    final baseDelay = switch (_currentQuality) {
      NetworkQuality.excellent => 500,
      NetworkQuality.good => 1000,
      NetworkQuality.fair => 2000,
      NetworkQuality.poor => 3000,
      NetworkQuality.bad => 5000,
    };

    // 指数退避
    final delay = baseDelay * (1 << attempt);
    return Duration(milliseconds: delay.clamp(500, 30000));
  }

  /// 获取缓冲区大小
  int getBufferSize() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 10 * 1024 * 1024; // 10MB
      case NetworkQuality.good:
        return 5 * 1024 * 1024;  // 5MB
      case NetworkQuality.fair:
        return 2 * 1024 * 1024;  // 2MB
      case NetworkQuality.poor:
        return 1 * 1024 * 1024;  // 1MB
      case NetworkQuality.bad:
        return 512 * 1024;       // 512KB
    }
  }

  /// 是否启用预加载
  bool shouldPreload() {
    return _currentQuality.index <= NetworkQuality.fair.index;
  }

  /// 获取预加载字节数
  int getPreloadBytes() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 5 * 1024 * 1024;  // 5MB
      case NetworkQuality.good:
        return 2 * 1024 * 1024;  // 2MB
      case NetworkQuality.fair:
        return 1 * 1024 * 1024;  // 1MB
      case NetworkQuality.poor:
      case NetworkQuality.bad:
        return 512 * 1024;       // 512KB
    }
  }

  // ==================== 智能重试 ====================

  /// 执行带智能重试的操作
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final maxRetries = getRetryCount();
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt > maxRetries) {
          AppLogger.error(
            'AdaptiveNetworkManager',
            '${operationName ?? "操作"} 失败，已重试 $maxRetries 次: $e',
          );
          rethrow;
        }

        final delay = getRetryDelay(attempt - 1);
        AppLogger.warn(
          'AdaptiveNetworkManager',
          '${operationName ?? "操作"} 失败，${delay.inSeconds}秒后第 $attempt 次重试: $e',
        );

        await Future.delayed(delay);

        // 重试前刷新网络质量
        await refreshQuality();
      }
    }
  }

  // ==================== 释放资源 ====================

  void dispose() {
    stopMonitoring();
    _qualityListeners.clear();
    _qualityHistory.clear();
  }
}

/// 网络感知Dio拦截器配置
class NetworkAwareDioConfig {
  static Map<String, dynamic> getBaseOptions() {
    final manager = AdaptiveNetworkManager();

    return {
      'connectTimeout': manager.getConnectTimeout(),
      'receiveTimeout': manager.getReceiveTimeout(),
      'sendTimeout': manager.getConnectTimeout(),
    };
  }
}
