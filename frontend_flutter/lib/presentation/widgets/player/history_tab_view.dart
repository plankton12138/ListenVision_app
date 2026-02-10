import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../models/history_group.dart';
import '../../../models/play_history.dart';
import '../../../models/queue_source.dart';
import '../../../models/online_playable.dart';
import '../../viewmodels/library/history_viewmodel.dart';
import '../../viewmodels/player/queue_viewmodel.dart';

/// 播放历史 Tab
///
/// 显示播放历史记录，按时间分组
class HistoryTabView extends ConsumerWidget {
  final ScrollController? scrollController;

  const HistoryTabView({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyViewModelProvider);

    return historyState.when(
      data: (state) {
        return state.when(
          initial: () => _buildEmptyState(context),
          loading: () => _buildLoadingState(),
          loaded: (history, stats) {
            if (history.isEmpty) {
              return _buildEmptyState(context);
            }

            final groups = HistoryGroup.groupByTime(history);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: groups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = groups[groupIndex];
                      return _buildHistoryGroup(context, ref, group);
                    },
                  ),
                ),
                _buildClearHistoryButton(context, ref),
              ],
            );
          },
          error: (message) => _buildErrorState(context, message),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, stackTrace) => _buildEmptyState(context),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '暂无播放历史',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
        ],
      ),
    );
  }

  /// 构建历史分组
  Widget _buildHistoryGroup(
    BuildContext context,
    WidgetRef ref,
    HistoryGroup group,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            group.label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),

        // 分组项
        ...group.items.map((item) => _buildHistoryItem(context, ref, item)),
      ],
    );
  }

  /// 构建历史列表项
  Widget _buildHistoryItem(
    BuildContext context,
    WidgetRef ref,
    PlayHistory item,
  ) {
    // 将 PlayHistory.audio 转换为 PlayableAudio
    final audio = item.audio;
    final playable = OnlinePlayable.fromAudio(audio, null);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: audio.coverUrl != null
            ? NetworkImage(audio.coverUrl!)
            : null,
        child: audio.coverUrl == null ? const Icon(Icons.music_note) : null,
      ),
      title: Text(audio.title),
      subtitle: Text(audio.artist ?? '未知艺术家'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: '添加到下一首',
        onPressed: () {
          AppLogger.logButtonClick('添加到下一首', 'HistoryTabView',
            parameters: {'title': audio.title});
          ref.read(queueViewModelProvider.notifier).insertNext(playable);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加到下一首: ${audio.title}')),
          );
        },
      ),
      onTap: () {
        AppLogger.logButtonClick('播放历史项', 'HistoryTabView',
          parameters: {'title': audio.title});
        // 播放该音频（替换当前队列）
        ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
          [playable],
          QueueSource.manual(),
          initialIndex: 0,
        );
        ref.read(queueViewModelProvider.notifier).playAt(0);
      },
    );
  }

  /// 构建清空历史按钮
  Widget _buildClearHistoryButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _showClearHistoryDialog(context, ref),
        child: const Text('清空历史记录'),
      ),
    );
  }

  /// 显示清空历史确认对话框
  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有播放历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(historyViewModelProvider.notifier).clearHistory();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
