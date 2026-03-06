import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/queue_source.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/library/history_viewmodel.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 播放历史页面
///
/// 显示用户的播放历史记录
/// 使用 Riverpod 的 HistoryViewModel
class PlayHistoryPage extends ConsumerStatefulWidget {
  const PlayHistoryPage({super.key});

  @override
  ConsumerState<PlayHistoryPage> createState() => _PlayHistoryPageState();
}

class _PlayHistoryPageState extends ConsumerState<PlayHistoryPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyViewModelProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放历史',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 清空历史按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            iconSize: UIConstants.iconMedium,
            onPressed: isLoggedIn
                ? () => _showClearHistoryDialog(context)
                : null,
          ),
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: !isLoggedIn
          ? _buildLoginPrompt(context)
          : _buildHistoryContent(),
    );
  }

  /// 构建登录提示
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('请先登录'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  /// 构建历史记录内容
  Widget _buildHistoryContent() {
    return ref.watch(historyViewModelProvider).when(
      data: (state) => state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (history, stats) {
          if (history.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              // 统计信息
              if (stats != null) _buildStatsCard(stats, context),
              // 历史列表
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildHistoryItem(item, index);
                  },
                ),
              ),
            ],
          );
        },
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $message'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(historyViewModelProvider.notifier).loadHistory(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(historyViewModelProvider.notifier).loadHistory(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('暂无播放历史'),
          const SizedBox(height: 8),
          Text(
            '开始播放音频后，这里会显示你的播放记录',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCard(PlayHistoryStats stats, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('总播放', stats.totalPlays.toString(), context),
            _buildStatItem('独特曲目', stats.uniqueTracks.toString(), context),
            _buildStatItem('总时长', _formatDuration(stats.totalDuration), context),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// 构建历史记录项
  Widget _buildHistoryItem(PlayHistory item, int index) {
    final audio = item.audio;
    return Dismissible(
      key: Key(item.id.isNotEmpty ? item.id : 'history_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(historyViewModelProvider.notifier).removeHistoryById(item.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: _buildCover(audio.coverUrl),
        title: Text(audio.title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          audio.artist ?? '未知艺术家',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDuration(audio.duration ?? 0),
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () {
          _playHistoryItem(item, ref);
        },
      ),
    );
  }

  /// 构建封面图
  Widget _buildCover(String? coverUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: coverUrl != null && coverUrl.isNotEmpty
          ? Image.network(
              coverUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                );
              },
            )
          : Container(
              width: 56,
              height: 56,
              color: Colors.grey[300],
              child: const Icon(Icons.music_note),
            ),
    );
  }

  Future<void> _playHistoryItem(PlayHistory item, WidgetRef ref) async {
    final audio = item.audio;
    final playable = OnlinePlayable(audio);

    // 更新播放队列（替换为单个音频）
    await ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
      [playable],
      QueueSource.manual(),
      initialIndex: 0,
    );

    // 播放音频
    await ref.read(queueViewModelProvider.notifier).playAt(0);

    if (mounted) {
      context.go('/');
    }

    AppLogger.info('PlayHistoryPage', '播放历史记录: ${audio.title}');
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// 显示清空历史对话框
  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放历史'),
        content: const Text('确定要清空所有播放历史吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyViewModelProvider.notifier).clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放历史已清空')),
        );
      }
    }
  }
}
