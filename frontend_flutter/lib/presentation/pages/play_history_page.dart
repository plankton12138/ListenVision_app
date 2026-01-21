// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/domain/entities/domain_types.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 播放历史页面
///
/// 展示用户的播放历史记录
/// Phase 2: 完整的播放历史管理功能
class PlayHistoryPage extends StatefulWidget {
  const PlayHistoryPage({super.key});

  @override
  _PlayHistoryPageState createState() => _PlayHistoryPageState();
}

class _PlayHistoryPageState extends State<PlayHistoryPage> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 延迟到 build 完成后检查登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  /// 检查登录状态，未登录则跳转到登录页
  void _checkLoginAndLoad() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      showMySnackBar(context, '请先登录', Colors.orange, 1500);
      context.go('/login');
      return;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await historyProvider.initialize();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有播放历史吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();

    try {
      await historyProvider.clearHistory(authProvider.user!.token);
      if (mounted) {
        showMySnackBar(context, '播放历史已清空', Colors.green, 1500);
      }
    } catch (e) {
      if (mounted) {
        showMySnackBar(context, '清空失败: $e', Colors.red, 2000);
      }
    }
  }

  Future<void> _removeItem(PlayHistoryItem item) async {
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();
    await historyProvider.removeHistoryItem(
      authProvider.user?.token,
      item.audio.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<PlayHistoryProvider>();
    final history = historyProvider.history;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放历史',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: '清空历史',
            ),
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: _buildBody(history),
    );
  }

  Widget _buildBody(List<PlayHistoryItem> history) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '还没有播放记录',
              style: TextStyle(
                fontSize: UIConstants.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '去搜索或发现页面找些音乐听听吧',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return _buildHistoryCard(item, index);
        },
      ),
    );
  }

  Widget _buildHistoryCard(PlayHistoryItem item, int index) {
    return Dismissible(
      key: ValueKey(item.id ?? item.audio.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _removeItem(item);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildItemCover(item),
          title: Text(
            item.audio.title ?? item.audio.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (item.audio.artist != null) item.audio.artist,
                  _formatDuration(item.audio.duration ?? 0),
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              // 播放进度条
              if (item.audio.duration != null && item.audio.duration! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: item.progressPercent,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '播放至 ${_formatProgress(item.progress, item.audio.duration!)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              // 播放时间
              Text(
                item.playedAtFormatted,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              // TODO: 重新播放这首歌
              showMySnackBar(context, '播放功能开发中', Colors.blue, 1500);
            },
          ),
          onTap: () {
            // TODO: 播放这首歌
            showMySnackBar(context, '播放功能开发中', Colors.blue, 1500);
          },
        ),
      ),
    );
  }

  Widget _buildItemCover(PlayHistoryItem item) {
    final coverUrl = item.audio.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          coverUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
        ),
      );
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey),
    );
  }

  String _formatProgress(int progress, int duration) {
    final progressMin = progress ~/ 60;
    final progressSec = progress % 60;
    final durationMin = duration ~/ 60;
    final durationSec = duration % 60;
    return '${progressMin.toString().padLeft(2, '0')}:${progressSec.toString().padLeft(2, '0')} / ${durationMin.toString().padLeft(2, '0')}:${durationSec.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
