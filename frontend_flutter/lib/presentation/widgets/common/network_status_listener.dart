import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/network_status.dart';
import '../../../core/network/network_status_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../presentation/utils/error_ui_handler.dart';

/// 网络状态监听器
///
/// 监听网络状态变化，并在状态变化时显示提示
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
    // 监听网络状态变化
    ref.listen<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      (previous, next) {
        next.when(
          data: (status) {
            _handleNetworkStatusChange(status);
          },
          loading: () {
            // 加载中，不处理
          },
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
