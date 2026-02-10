import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../data/database/sync_queue_dao.dart';
import '../../../../data/sync/sync_worker_provider.dart';

/// 同步状态指示器
///
/// 显示当前同步队列的状态，包括：
/// - 空闲（没有待处理任务）
/// - 工作中（正在处理任务）
/// - 有待处理任务（显示数量）
class SyncStatusIndicator extends ConsumerStatefulWidget {
  /// 图标大小
  final double size;

  /// 是否显示标签
  final bool showLabel;

  /// 是否显示弹出菜单
  final bool showMenu;

  const SyncStatusIndicator({
    super.key,
    this.size = 20,
    this.showLabel = false,
    this.showMenu = true,
  });

  @override
  ConsumerState<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<SyncStatusIndicator> {
  void _showSyncMenu() {
    if (!widget.showMenu) return;

    final stats = ref.read(syncStatsProvider).value;
    if (stats == null) return;

    if (stats.active == 0) {
      // 没有待处理任务，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所有数据已同步'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 显示同步状态菜单
    showDialog(
      context: context,
      builder: (context) => _SyncStatusDialog(stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(syncStatsProvider);

    return statsAsync.when(
      data: (stats) {
        AppLogger.debug('SyncStatusIndicator', '状态更新: $stats');
        final hasActive = stats.active > 0;

        if (!hasActive) {
          // 空闲状态
          return widget.showLabel
              ? const SizedBox.shrink()
              : _buildIdleIcon();
        }

        final child = _buildSyncingIcon(stats.active);

        return GestureDetector(
          onTap: _showSyncMenu,
          child: child,
        );
      },
      loading: () {
        AppLogger.debug('SyncStatusIndicator', '状态: loading');
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      error: (error, stackTrace) {
        AppLogger.error('SyncStatusIndicator', '状态: error - $error', error: error, stackTrace: stackTrace);
        return const SizedBox.shrink();
      },
    );
  }

  /// 空闲图标
  Widget _buildIdleIcon() {
    return Icon(
      Icons.cloud_done,
      size: widget.size,
      color: Colors.green[400],
    );
  }

  /// 同步中图标
  Widget _buildSyncingIcon(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '同步中 ($count)',
            style: TextStyle(
              fontSize: widget.size * 0.7,
              color: Colors.blue[400],
            ),
          ),
        ],
      ],
    );
  }
}

/// 同步状态对话框
class _SyncStatusDialog extends ConsumerWidget {
  final SyncQueueStats stats;

  const _SyncStatusDialog({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('同步状态'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.pending > 0) ...[
            _buildStatusRow(
              icon: Icons.schedule,
              color: Colors.blue,
              label: '待同步',
              count: stats.pending,
            ),
            const SizedBox(height: 8),
          ],
          if (stats.syncing > 0) ...[
            _buildStatusRow(
              icon: Icons.sync,
              color: Colors.orange,
              label: '同步中',
              count: stats.syncing,
            ),
            const SizedBox(height: 8),
          ],
          if (stats.retryable > 0) ...[
            _buildStatusRow(
              icon: Icons.refresh,
              color: Colors.deepOrange,
              label: '待重试',
              count: stats.retryable,
            ),
            const SizedBox(height: 8),
          ],
          if (stats.active == 0) ...[
            _buildStatusRow(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              label: '已同步',
              count: 0,
            ),
            const SizedBox(height: 16),
            Text(
              '所有数据已同步',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (stats.active > 0)
          TextButton.icon(
            onPressed: () {
              // 手动触发同步
              ref.read(syncWorkerProvider).syncNow();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.sync),
            label: const Text('立即同步'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          count > 0 ? '$label: $count' : label,
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }
}

/// 紧凑型同步状态指示器（仅图标，不监听状态）
///
/// 用于已经知道同步状态的场景
class CompactSyncStatusIndicator extends StatelessWidget {
  final bool hasActive;
  final bool hasFailed;
  final double size;

  const CompactSyncStatusIndicator({
    super.key,
    this.hasActive = false,
    this.hasFailed = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (hasFailed) {
      return Icon(
        Icons.sync_problem,
        size: size,
        color: Colors.orange[400],
      );
    } else if (hasActive) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
        ),
      );
    } else {
      return Icon(
        Icons.cloud_done,
        size: size,
        color: Colors.green[400],
      );
    }
  }
}
