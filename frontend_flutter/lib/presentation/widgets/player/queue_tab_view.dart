import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../models/queue_source.dart';
import '../../../models/play_mode.dart';
import '../../viewmodels/player/queue_viewmodel.dart';
import 'queue_item_tile.dart';

/// 正在播放 Tab
///
/// 显示当前播放队列，支持点击播放、删除等操作
class QueueTabView extends ConsumerWidget {
  final ScrollController? scrollController;

  const QueueTabView({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);
    final queue = queueState.queue;
    final currentIndex = queueState.currentIndex;

    if (queue.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // 来源信息栏
        _buildSourceInfo(context, ref, queueState),

        // 播放模式栏
        _buildPlayModeBar(context, ref, queueState),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final playable = queue[index];
              final isCurrent = currentIndex == index;

              return QueueItemTile(
                key: ValueKey('${playable.id}_$index'),
                playable: playable,
                index: index,
                isCurrent: isCurrent,
              );
            },
          ),
        ),

        // 底部操作栏
        _buildBottomActions(context, ref, queueState),
      ],
    );
  }

  /// 构建来源信息栏
  Widget _buildSourceInfo(
    BuildContext context,
    WidgetRef ref,
    QueueState queueState,
  ) {
    final source = queueState.source;
    if (source == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_play, size: 18),
          const SizedBox(width: 8),
          const Text('来自: ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: GestureDetector(
              onTap: () {
                AppLogger.logButtonClick('来源信息', 'QueueTabView');
                _handleSourceTap(context, source);
              },
              child: Text(
                source.name,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (source.coverUrl != null) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                source.coverUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[300],
                    child: const Icon(Icons.album, size: 16),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建播放模式栏
  Widget _buildPlayModeBar(
    BuildContext context,
    WidgetRef ref,
    QueueState queueState,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${queueState.queue.length} 首歌曲',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          // 播放模式切换按钮
          InkWell(
            onTap: () {
              AppLogger.logButtonClick('切换播放模式', 'QueueTabView',
                parameters: {'currentMode': queueState.playMode.name});
              ref.read(queueViewModelProvider.notifier).togglePlayMode();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPlayModeIcon(queueState.playMode),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    queueState.playMode.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取播放模式图标
  String _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return '🔀';
      case PlayMode.loopAll:
        return '🔁';
      case PlayMode.shuffle:
        return '🔀';
      case PlayMode.loopOne:
        return '🔂';
    }
  }

  /// 处理来源点击
  void _handleSourceTap(BuildContext context, QueueSource source) {
    switch (source.type) {
      case SourceType.userPlaylist:
        // TODO: 跳转到歌单详情页
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('即将跳转到歌单: ${source.name}')),
        );
        break;
      case SourceType.favorites:
        // TODO: 跳转到收藏页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('即将跳转到收藏页')),
        );
        break;
      case SourceType.history:
        // TODO: 切换到历史 Tab
        break;
      case SourceType.search:
        // TODO: 跳转到搜索页
        break;
      case SourceType.manual:
        // 手动添加不跳转
        break;
    }
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '播放列表为空',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActions(BuildContext context, WidgetRef ref, QueueState queueState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 定位按钮
          TextButton.icon(
            onPressed: () {
              // TODO: 滚动到当前播放
            },
            icon: const Icon(Icons.location_on),
            label: const Text('定位'),
          ),
          const SizedBox(width: 16),
          // 清空按钮
          TextButton.icon(
            onPressed: queueState.queue.isEmpty
                ? null
                : () => _showClearConfirmDialog(context, ref),
            icon: const Icon(Icons.clear_all),
            label: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 显示清空确认对话框
  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: const Text('确定要清空播放列表吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(queueViewModelProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
