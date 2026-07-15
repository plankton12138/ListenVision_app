import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/network_status.dart';
import '../../core/utils/app_logger.dart';

part 'network_status_provider.g.dart';

/// 网络状态 Provider
///
/// 实时监测网络连接状态，使用 connectivity_plus 插件
/// 支持监听网络类型变化（WiFi/移动数据/无网络等）
@riverpod
class NetworkStatusNotifier extends _$NetworkStatusNotifier {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<NetworkStatus> build() async {
    // 初始化网络状态
    _startMonitoring();
    
    // 当 provider 被销毁时取消订阅
    ref.onDispose(() {
      _subscription?.cancel();
      AppLogger.info('NetworkStatusProvider', '网络状态监听已停止');
    });
    
    return await _getCurrentNetworkStatus();
  }

  /// 开始监听网络状态变化
  void _startMonitoring() {
    _subscription?.cancel();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged, onError: _onError);

    AppLogger.info('NetworkStatusProvider', '网络状态监听已启动');
  }

  /// 处理网络状态变化
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    try {
      final newStatus = await _mapConnectivityResults(results);
      
      // 只有当状态真正改变时才更新
      if (state case AsyncData<NetworkStatus>(:final value)) {
        if (value != newStatus) {
          state = AsyncData(newStatus);
          AppLogger.info('NetworkStatusProvider',
              '网络状态变化: ${value.connectionDescription} -> ${newStatus.connectionDescription}');
        }
      } else {
        // 首次加载或错误后恢复
        state = AsyncData(newStatus);
      }
    } catch (e) {
      AppLogger.error('NetworkStatusProvider', '处理网络状态变化失败: $e');
    }
  }

  /// 处理监听错误
  void _onError(Object error) {
    AppLogger.error('NetworkStatusProvider', '网络状态监听错误: $error');
    state = AsyncData(NetworkStatus.disconnected());
  }

  /// 获取当前网络状态
  Future<NetworkStatus> _getCurrentNetworkStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return await _mapConnectivityResults(results);
    } catch (e) {
      AppLogger.error('NetworkStatusProvider', '获取当前网络状态失败: $e');
      return NetworkStatus.disconnected();
    }
  }

  /// 映射 ConnectivityResult 到 NetworkStatus
  Future<NetworkStatus> _mapConnectivityResults(
    List<ConnectivityResult> results,
  ) async {
    if (results.contains(ConnectivityResult.none)) {
      return NetworkStatus.disconnected();
    }

    // 优先级：Ethernet > WiFi > Mobile > 其他
    if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.connected(NetworkConnectionType.ethernet);
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkStatus.connected(NetworkConnectionType.wifi);
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.connected(NetworkConnectionType.mobile);
    }

    if (results.contains(ConnectivityResult.bluetooth)) {
      return NetworkStatus.connected(NetworkConnectionType.bluetooth);
    }

    if (results.contains(ConnectivityResult.vpn)) {
      return NetworkStatus.connected(NetworkConnectionType.vpn);
    }

    return NetworkStatus.connected(NetworkConnectionType.other);
  }

  /// 手动刷新网络状态
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final status = await _getCurrentNetworkStatus();
      state = AsyncData(status);
    } catch (e, st) {
      AppLogger.error('NetworkStatusProvider', '刷新网络状态失败: $e');
      state = AsyncError(e, st);
    }
  }
}

/// 网络连接状态 Provider
///
/// 只返回是否已连接，方便简单场景使用
@riverpod
bool isNetworkConnected(Ref ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.when(
    data: (status) => status.isConnected,
    loading: () => false,
    error: (_, _) => false,
  );
}

/// 网络连接类型 Provider
///
/// 返回具体的连接类型，可能为 null（加载中或错误）
@riverpod
NetworkConnectionType? networkConnectionType(Ref ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.when(
    data: (status) => status.connectionType,
    loading: () => null,
    error: (_, _) => NetworkConnectionType.none,
  );
}

/// 网络状态描述 Provider
///
/// 返回用户友好的连接描述文本
@riverpod
String networkConnectionDescription(Ref ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.when(
    data: (status) => status.connectionDescription,
    loading: () => '检测中...',
    error: (_, _) => '未知',
  );
}
