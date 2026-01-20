import 'package:demo/constants/dimens.dart';
import 'package:demo/services/download/download_repository.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 下载任务管理页面
///
/// 显示本地下载任务
/// - 支持暂停/恢复/删除操作
/// - 支持查看下载进度
class BackendDownloadPage extends StatefulWidget {
  const BackendDownloadPage({super.key});

  @override
  State<BackendDownloadPage> createState() => _BackendDownloadPageState();
}

class _BackendDownloadPageState extends State<BackendDownloadPage> {
  late DownloadManager _downloadManager;

  @override
  void initState() {
    super.initState();
    _downloadManager = context.read<DownloadManager>();
    // 初始化数据库（如果还没有初始化）
    _downloadManager.initDatabase();
    // 监听下载状态变化
    _downloadManager.addListener(_onDownloadsChanged);
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadsChanged);
    super.dispose();
  }

  void _onDownloadsChanged() {
    setState(() {}); // 触发重建
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

  /// 从 status 字段获取状态
  DownloadStatus _getStatus(Map<String, dynamic> task) {
    final statusStr = task['status'] as String?;
    return DownloadStatusExtension.fromString(statusStr);
  }

  /// 获取状态颜色
  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Colors.orange;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.grey;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
    }
  }

  /// 获取状态文本
  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.paused:
        return '已暂停';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
    }
  }

  /// 计算进度百分比
  int _getProgress(Map<String, dynamic> task) {
    final downloaded = task['downloaded_bytes'] as int? ?? 0;
    final total = task['total_bytes'] as int? ?? 0;
    if (total <= 0) return 0;
    return ((downloaded / total) * 100).toInt();
  }

  /// 暂停/恢复任务
  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final id = task['id'] as int;
    final status = _getStatus(task);

    if (status == DownloadStatus.downloading || status == DownloadStatus.pending) {
      await _downloadManager.pauseDownload(id);
      if (mounted) {
        showMySnackBar(context, '已暂停', Colors.green, 1000);
      }
    } else if (status == DownloadStatus.paused) {
      await _downloadManager.resumeDownload(id);
      if (mounted) {
        showMySnackBar(context, '已恢复', Colors.green, 1000);
      }
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
      await _downloadManager.deleteDownload(task['id'] as int);
      if (mounted) {
        showMySnackBar(context, '已删除', Colors.green, 1000);
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
      await _downloadManager.clearCompleted();
      if (mounted) {
        final completedCount = _downloadManager.completedCount;
        showMySnackBar(context, '已清空 $completedCount 个任务', Colors.green, 1000);
      }
    }
  }

  /// 重试失败的任务
  Future<void> _retryTask(Map<String, dynamic> task) async {
    final id = task['id'] as int;
    await _downloadManager.resumeDownload(id);
    if (mounted) {
      showMySnackBar(context, '已重新开始下载', Colors.green, 1000);
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
            onPressed: () async {
              await _downloadManager.refreshDownloads();
            },
          ),
          // 清空已完成
          if (_downloadManager.completedCount > 0)
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
      body: Builder(
        builder: (context) {
          final downloads = _downloadManager.downloads;

          if (downloads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无下载任务', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 统计信息
              _buildStatsBar(downloads),
              // 任务列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final task = downloads[index];
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
  Widget _buildStatsBar(List<Map<String, dynamic>> downloads) {
    int activeCount = 0;
    int completedCount = 0;
    int failedCount = 0;

    for (var task in downloads) {
      final status = _getStatus(task);
      if (status == DownloadStatus.downloading || status == DownloadStatus.pending) {
        activeCount++;
      } else if (status == DownloadStatus.completed) {
        completedCount++;
      } else if (status == DownloadStatus.failed) {
        failedCount++;
      }
    }

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
          _buildStatItem('进行中', activeCount, Colors.blue),
          _buildStatItem('已完成', completedCount, Colors.green),
          if (failedCount > 0) _buildStatItem('失败', failedCount, Colors.red),
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
    final status = _getStatus(task);
    final progress = _getProgress(task);
    final downloaded = task['downloaded_bytes'] as int? ?? 0;
    final total = task['total_bytes'] as int? ?? 0;

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
                    task['title'] ?? '未知任务',
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

            // 错误信息
            if (status == DownloadStatus.failed && task['error_message'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  task['error_message'].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // 进度条
            if (status == DownloadStatus.downloading ||
                status == DownloadStatus.paused ||
                status == DownloadStatus.pending)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      status == DownloadStatus.paused
                          ? Colors.grey
                          : _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress% · ${_formatBytes(downloaded)}/${_formatBytes(total)}',
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
                // 重试按钮（仅失败任务）
                if (status == DownloadStatus.failed)
                  TextButton.icon(
                    onPressed: () => _retryTask(task),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),

                // 暂停/恢复按钮
                if (status == DownloadStatus.downloading ||
                    status == DownloadStatus.paused ||
                    status == DownloadStatus.pending)
                  TextButton.icon(
                    onPressed: () => _toggleTask(task),
                    icon: Icon(
                      status == DownloadStatus.downloading ||
                              status == DownloadStatus.pending
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      status == DownloadStatus.downloading ||
                              status == DownloadStatus.pending
                          ? '暂停'
                          : '继续',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          status == DownloadStatus.downloading ||
                                  status == DownloadStatus.pending
                              ? Colors.orange
                              : Colors.green,
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
