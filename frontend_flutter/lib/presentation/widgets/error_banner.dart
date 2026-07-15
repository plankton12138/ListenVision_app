import 'package:flutter/material.dart';

/// 错误提示横幅组件
///
/// 统一的错误显示组件
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 错误对话框组件
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  /// 显示错误对话框
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              onRetry!();
              if (onDismiss != null) onDismiss!();
            },
            child: const Text('重试'),
          ),
        TextButton(
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 紧凑型错误提示组件
class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onRetry,
            child: Text(
              '重试',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
