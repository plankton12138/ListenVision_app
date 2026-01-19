import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/download_task_provider.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 后端下载任务管理页面
///
/// Phase 3 - 服务器端下载任务管理
/// - 显示用户的所有下载任务
/// - 支持暂停/恢复/删除操作
/// - 支持查看下载进度
class BackendDownloadPage extends StatefulWidget {
  const BackendDownloadPage({super.key});

  @override
  State<BackendDownloadPage> createState() => _BackendDownloadPageState();
}

class _BackendDownloadPageState extends State<BackendDownloadPage> {
  @override
  void initState() {
    super.initState();
    // 初始化时加载任务列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final provider = context.read<DownloadTaskProvider>();
    await provider.loadTasks();
  }

  /// 格式化字节为 MB/GB 显示
  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 获取状态颜色
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'downloading':
        return Colors.blue;
      case 'paused':
        return Colors.grey;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 获取状态文本
  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'downloading':
        return '下载中';
      case 'paused':
        return '已暂停';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return '未知';
    }
  }

  /// 暂停/恢复任务
  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final provider = context.read<DownloadTaskProvider>();
    final taskId = task['id'] as int;
    final status = task['status'] as String?;

    bool success;
    if (status == 'downloading') {
      success = await provider.pauseTask(taskId);
      if (mounted && success) {
        showMySnackBar(context, '已暂停', Colors.green, 1000);
      }
    } else if (status == 'paused') {
      success = await provider.resumeTask(taskId);
      if (mounted && success) {
        showMySnackBar(context, '已恢复', Colors.green, 1000);
      }
    } else {
      return;
    }

    if (!success && mounted) {
      showMySnackBar(context, provider.errorMessage ?? '操作失败', Colors.red, 2000);
    }
  }

  /// 删除任务
  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个下载任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<DownloadTaskProvider>();
      final success = await provider.deleteTask(task['id'] as int);
      if (mounted) {
        showMySnackBar(
          context,
          success ? '已删除' : (provider.errorMessage ?? '删除失败'),
          success ? Colors.green : Colors.red,
          2000,
        );
      }
    }
  }

  /// 清空已完成任务
  Future<void> _clearCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已完成'),
        content: const Text('确定要清空所有已完成的任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<DownloadTaskProvider>();
      final success = await provider.clearCompletedTasks();
      if (mounted) {
        showMySnackBar(
          context,
          success ? '已清空' : '清空失败',
          success ? Colors.green : Colors.red,
          2000,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          '下载任务',
          style: TextStyle(fontSize: Dimens.fontSizeLarge),
        ),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          // 清空已完成
          if (context.watch<DownloadTaskProvider>().completedTaskCount > 0)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_completed') {
                  _clearCompleted();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Text('清空已完成'),
                ),
              ],
            ),
          // 首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Consumer<DownloadTaskProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = provider.tasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无下载任务', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '已下载 ${provider.completedTaskCount} 个任务',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 统计信息
              _buildStatsBar(provider),
              // 任务列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskItem(task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 统计信息栏
  Widget _buildStatsBar(DownloadTaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('进行中', provider.activeTaskCount, Colors.blue),
          _buildStatItem('已完成', provider.completedTaskCount, Colors.green),
          _buildStatItem('失败', provider.failedTaskCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 单个任务卡片
  Widget _buildTaskItem(Map<String, dynamic> task) {
    final status = task['status'] as String?;
    final progress = task['progress'] as int? ?? 0;
    final downloadedSize = task['downloaded_size'] as int?;
    final fileSize = task['file_size'] as int?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? task['bvid'] ?? '未知任务',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 艺术家和时长
            if (task['artist'] != null || task['duration'] != null)
              Text(
                '${task['artist'] ?? '未知艺术家'} · ${_formatDuration(task['duration'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

            const SizedBox(height: 8),

            // 进度条
            if (status == 'downloading' || status == 'paused' || status == 'pending')
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      status == 'paused' ? Colors.grey : _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress% · ${_formatBytes(downloadedSize)}/${_formatBytes(fileSize)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 暂停/恢复按钮
                if (status == 'downloading' || status == 'paused')
                  TextButton.icon(
                    onPressed: () => _toggleTask(task),
                    icon: Icon(
                      status == 'downloading' ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(status == 'downloading' ? '暂停' : '继续'),
                    style: TextButton.styleFrom(
                      foregroundColor: status == 'downloading' ? Colors.orange : Colors.green,
                    ),
                  ),

                // 删除按钮
                TextButton.icon(
                  onPressed: () => _deleteTask(task),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
