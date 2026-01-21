import 'package:flutter/material.dart';

/// 空状态组件
///
/// 用于显示列表、数据为空时的占位内容
class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
  });

  /// 空列表状态
  const EmptyState.list({
    super.key,
    String message = '暂无数据',
    String? subMessage,
    VoidCallback? onAction,
    String? actionLabel,
  }) : icon = Icons.inbox,
       message = message,
       subMessage = subMessage,
       onAction = onAction,
       actionLabel = actionLabel;

  /// 空搜索结果状态
  const EmptyState.search({
    super.key,
    String message = '未找到相关内容',
    String? subMessage,
    VoidCallback? onAction,
    String? actionLabel,
  }) : icon = Icons.search_off,
       message = message,
       subMessage = subMessage,
       onAction = onAction,
       actionLabel = actionLabel;

  /// 空收藏状态
  const EmptyState.favorites({
    super.key,
    String message = '还没有收藏任何内容',
    String? subMessage,
    VoidCallback? onAction,
    String? actionLabel,
  }) : icon = Icons.favorite_border,
       message = message,
       subMessage = subMessage,
       onAction = onAction,
       actionLabel = actionLabel;

  /// 空网络状态
  const EmptyState.network({
    super.key,
    String message = '网络连接失败',
    String? subMessage,
    VoidCallback? onAction,
    String? actionLabel = '重试',
  }) : icon = Icons.wifi_off,
       message = message,
       subMessage = subMessage,
       onAction = onAction,
       actionLabel = actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 紧凑型空状态组件（用于列表内部）
class CompactEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
