import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/network_status.dart';
import '../../../core/network/network_status_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../presentation/utils/error_ui_handler.dart';

/// 网络状态监听器
///
/// 监听网络状态变化，并在状态变化时显示 SnackBar 提示
/// 应该在应用的顶层包裹，确保全局监听
class NetworkStatusListener extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkStatusListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NetworkStatusListener> createState() =>
      _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends ConsumerState<NetworkStatusListener> {
  NetworkStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    // 监听网络状态变化（用于显示 SnackBar 提示）
    ref.listen<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      (previous, next) {
        next.when(
          data: (status) {
            _handleNetworkStatusChange(status);
          },
          loading: () {},
          error: (error, stackTrace) {
            AppLogger.error(
                'NetworkStatusListener', '网络状态监听错误', error: error);
          },
        );
      },
    );

    return widget.child;
  }

  /// 处理网络状态变化
  void _handleNetworkStatusChange(NetworkStatus currentStatus) {
    if (!mounted) return;

    final previousStatus = _previousStatus;
    _previousStatus = currentStatus;

    if (previousStatus == null) {
      // 首次加载，不显示提示
      return;
    }

    // 网络断开
    if (previousStatus.isConnected && !currentStatus.isConnected) {
      ErrorUIHandler.showError(
        context,
        '网络连接已断开，请检查网络设置',
        title: '网络断开',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 网络恢复
    if (!previousStatus.isConnected && currentStatus.isConnected) {
      ErrorUIHandler.showSuccess(
        context,
        '网络已恢复 (${currentStatus.connectionDescription})',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 连接类型变化（都在连接状态下）
    if (previousStatus.isConnected &&
        currentStatus.isConnected &&
        previousStatus.connectionType != currentStatus.connectionType) {
      ErrorUIHandler.showInfo(
        context,
        '网络切换到 ${currentStatus.connectionDescription}',
      );
    }
  }
}

/// 网络状态图标
///
/// 显示在 AppBar 中的网络状态图标，根据连接类型和状态显示不同图标和颜色
class NetworkStatusIcon extends ConsumerWidget {
  const NetworkStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);

    return networkStatusAsync.when(
      data: (status) => Tooltip(
        message: status.isConnected
            ? status.connectionDescription
            : '无网络连接',
        child: Icon(
          _getIcon(status),
          color: _getColor(status),
          size: 20,
        ),
      ),
      loading: () => const SizedBox(width: 20),
      error: (_, _) => const Tooltip(
        message: '网络状态未知',
        child: Icon(Icons.wifi_find, size: 20),
      ),
    );
  }

  /// 根据网络状态获取图标
  IconData _getIcon(NetworkStatus status) {
    if (!status.isConnected) return Icons.wifi_off;

    switch (status.connectionType) {
      case NetworkConnectionType.wifi:
        return Icons.wifi;
      case NetworkConnectionType.mobile:
        return Icons.signal_cellular_alt;
      case NetworkConnectionType.ethernet:
        return Icons.lan;
      case NetworkConnectionType.vpn:
        return Icons.vpn_key;
      case NetworkConnectionType.bluetooth:
        return Icons.bluetooth;
      case NetworkConnectionType.other:
      case NetworkConnectionType.none:
        return Icons.wifi_off;
    }
  }

  /// 根据网络状态获取颜色
  Color _getColor(NetworkStatus status) {
    if (!status.isConnected) return const Color(0xFFE53935);

    switch (status.connectionType) {
      case NetworkConnectionType.wifi:
        return const Color(0xFF43A047);
      case NetworkConnectionType.mobile:
        return const Color(0xFF1E88E5);
      case NetworkConnectionType.ethernet:
        return const Color(0xFF7B1FA2);
      case NetworkConnectionType.vpn:
        return const Color(0xFFFF9800);
      case NetworkConnectionType.bluetooth:
        return const Color(0xFF00ACC1);
      case NetworkConnectionType.other:
      case NetworkConnectionType.none:
        return const Color(0xFFE53935);
    }
  }
}
