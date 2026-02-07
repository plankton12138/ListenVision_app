import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../models/playable_audio.dart';
import '../../../models/online_playable.dart';
import '../../viewmodels/player/queue_viewmodel.dart';
import '../../viewmodels/library/playlist_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

/// 队列列表项组件
///
/// 显示单首歌曲信息，支持点击播放、删除、收藏等操作
class QueueItemTile extends ConsumerWidget {
  /// 歌曲数据
  final PlayableAudio playable;

  /// 在队列中的索引
  final int index;

  /// 是否为当前播放
  final bool isCurrent;

  /// 是否启用拖拽排序
  final bool isReorderable;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  const QueueItemTile({
    super.key,
    required this.playable,
    required this.index,
    required this.isCurrent,
    this.isReorderable = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 获取收藏状态（仅在线音频支持收藏）
    final isOnline = playable.isOnline;
    final playlistNotifier = ref.read(playlistViewModelProvider.notifier);
    final playlistState = ref.watch(playlistViewModelProvider);

    // 获取 bvid（仅在线音频）
    String? bvid;
    if (isOnline && playable is OnlinePlayable) {
      bvid = playable.id;  // PlayableAudio.id 就是 bvid
    }

    final isFavorited = bvid != null && playlistNotifier.isFavorited(bvid);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        // 拖拽手柄
        leading: isReorderable
            ? ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: Colors.grey[400],
                ),
              )
            : (isCurrent
                ? Icon(Icons.play_arrow, color: theme.colorScheme.primary)
                : const Icon(Icons.music_note, color: Colors.grey)),

        title: Text(
          playable.title,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        subtitle: Text(
          playable.artist ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 收藏按钮（仅在线音频）
            if (isOnline && bvid != null)
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
                tooltip: isFavorited ? '取消收藏' : '收藏',
                onPressed: () => _toggleFavorite(context, ref, bvid!),
              ),

            // 下一首播放按钮
            if (!isCurrent)
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: '下一首播放',
                onPressed: () {
                  AppLogger.logButtonClick('下一首播放', 'QueueItemTile',
                    parameters: {'title': playable.title});
                  ref.read(queueViewModelProvider.notifier).insertNext(playable);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已添加到下一首: ${playable.title}')),
                  );
                },
              ),

            // 更多按钮
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'next',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline),
                      SizedBox(width: 8),
                      Text('下一首播放'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline),
                      SizedBox(width: 8),
                      Text('从列表移除'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        onTap: onTap ??
            () {
              AppLogger.logButtonClick('播放队列项', 'QueueItemTile',
                parameters: {'index': index});
              ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
            },

        onLongPress: onLongPress ??
            () {
              AppLogger.logButtonClick('长按队列项', 'QueueItemTile',
                parameters: {'title': playable.title});
              _showMoreOptions(context, ref);
            },
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, String bvid) async {
    AppLogger.logButtonClick('切换收藏', 'QueueItemTile',
      parameters: {'bvid': bvid, 'title': playable.title});

    // 获取 token
    final token = ref.read(authViewModelProvider.notifier).currentToken;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    final notifier = ref.read(playlistViewModelProvider.notifier);
    final added = await notifier.toggleFavorite(token, bvid);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added ? '已添加到收藏' : '已取消收藏'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'next':
        AppLogger.logButtonClick('下一首播放', 'QueueItemTile',
          parameters: {'title': playable.title});
        ref.read(queueViewModelProvider.notifier).insertNext(playable);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加到下一首: ${playable.title}')),
        );
        break;
      case 'remove':
        AppLogger.logButtonClick('删除队列项', 'QueueItemTile',
          parameters: {'index': index, 'title': playable.title});
        ref.read(queueViewModelProvider.notifier).removeAt(index);
        break;
    }
  }

  /// 显示更多选项（底部菜单）
  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('下一首播放'),
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction(context, ref, 'next');
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('从列表移除'),
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction(context, ref, 'remove');
              },
            ),
            // 添加分隔线
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
