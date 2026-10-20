import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';

import '../../../models/playable_audio.dart';
import '../../../models/online_playable.dart';
import '../../../models/local_playable.dart';
import '../../../data/repositories/repository_providers.dart'
    hide favoriteTracksProvider;
import '../../../models/audio.dart';
import '../../viewmodels/player/playback_viewmodel.dart';
import '../../viewmodels/player/queue_viewmodel.dart';
import '../../viewmodels/library/favorite_tracks_notifier.dart';
import '../common/marquee_text.dart';

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

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  const QueueItemTile({
    super.key,
    required this.playable,
    required this.index,
    required this.isCurrent,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 获取收藏状态（由 FavoriteTracksNotifier 管理）
    final isOnline = playable.isOnline;

    // 获取纯 BVID（OnlinePlayable.id 现已包含 cid，需用 original.id 取纯 BVID）
    final bvid = (playable is OnlinePlayable) ? (playable as OnlinePlayable).original.id : playable.id;

    final favoriteTracksAsync = ref.watch(favoriteTracksProvider);
    final isFavorited = favoriteTracksAsync.whenOrNull(
      data: (ids) => ids.contains(bvid),
    ) ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: isCurrent
            ? Icon(Icons.play_arrow, color: theme.colorScheme.primary)
            : const Icon(Icons.music_note, color: Colors.grey),

        title: MarqueeText(
          playable.title,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? theme.colorScheme.primary : null,
          ),
        ),

        subtitle: MarqueeText(playable.artist ?? '未知艺术家'),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态标识（来源 + 本地/在线）
            _buildStatusBadge(context, ref),

            const SizedBox(width: 8),

            // 收藏按钮（仅在线音频）
            if (isOnline)
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
                tooltip: isFavorited ? '取消收藏' : '收藏',
                onPressed: () => _toggleFavorite(context, ref, bvid),
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
              // 设置队列索引
              ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
              // 使用 PlaybackViewModel 播放
              final queueState = ref.read(queueViewModelProvider);
              final tracks = queueState.queue?.tracks;
              if (tracks != null && index >= 0 && index < tracks.length) {
                ref.read(playbackViewModelProvider.notifier).play(
                  tracks[index],
                  index: index,
                );
              }
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

    // 确保 Track 记录存在
    final trackDao = ref.read(trackDaoProvider);
    var track = await trackDao.getBySourceId(bvid);
    track ??= await trackDao.saveFromAudio(Audio(
        id: bvid,
        title: playable.title.isNotEmpty ? playable.title : '未知标题',
        artist: playable.artist,
        duration: playable.duration,
        coverUrl: playable.coverUrl,
      ));

    final target = await ref.read(favoriteTracksProvider.notifier).toggle(
      bvid,
      title: playable.title,
      artist: playable.artist,
      duration: playable.duration,
      coverUrl: playable.coverUrl,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(target ? '已添加到收藏' : '已取消收藏'),
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

  /// 获取音频来源标签
  String? _getSourceLabel(PlayableAudio playable) {
    if (playable is LocalPlayable) {
      return '本地'; // 本地导入的音频
    } else if (playable is OnlinePlayable) {
      // Dart 已经知道 playable 是 OnlinePlayable 类型，不需要转换
      final audio = playable.original;

      // 根据音频 ID 前缀判断来源
      if (audio.id.startsWith('BV') || audio.id.startsWith('bv')) {
        return 'B站';
      }
    }
    return null;
  }

  /// 获取来源标签颜色
  Color _getSourceColor(String? source) {
    switch (source) {
      case 'B站':
        return const Color(0xFF00A1D6); // B站蓝
      case '网易云':
        return const Color(0xFFC20C0C); // 网易云红
      case '本地':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 构建状态标识组件
  Widget _buildStatusBadge(BuildContext context, WidgetRef ref) {
    final sourceLabel = _getSourceLabel(playable);
    final isLocalAudio = !playable.isOnline;

    // 本地音频：直接显示"本地"标签
    if (isLocalAudio) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getSourceColor(sourceLabel),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          sourceLabel ?? '本地',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      );
    }

    // 在线音频：判断是否已下载（使用纯 BVID）
    final bvid = (playable is OnlinePlayable) ? (playable as OnlinePlayable).original.id : playable.id;
    final isDownloadedAsync = ref.watch(isTrackDownloadedProvider(bvid));

    return isDownloadedAsync.when(
      data: (isDownloaded) {
        // 构建标签行
        final badges = <Widget>[];

        // 来源标签（B站/网易云）
        if (sourceLabel != null) {
          badges.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getSourceColor(sourceLabel),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sourceLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        // 本地标签（已下载的在线音频）
        if (isDownloaded) {
          if (badges.isNotEmpty) {
            badges.add(const SizedBox(width: 4));
          }
          badges.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '本地',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        if (badges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: badges,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
