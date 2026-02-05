import 'dart:io';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/models/download_task.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 下载任务管理页面
///
/// 显示和管理下载任务
/// 使用 Riverpod 的 DownloadViewModel
class BackendDownloadPage extends ConsumerWidget {
  const BackendDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadViewModel = ref.watch(downloadViewModelProvider);
    final downloadState = downloadViewModel.downloadState;
    final downloads = downloadState.maybeWhen(
      loaded: (tasks, _, __, ___) => tasks,
      orElse: () => <DownloadTask>[],
    );

    final downloadStage = downloadState.maybeWhen(
      loaded: (_, stage, __, ___) => stage,
      orElse: () => '',
    );

    final downloadProgress = downloadState.maybeWhen(
      loaded: (_, __, progress, ___) => progress,
      orElse: () => 0,
    );

    final activeTask = downloadState.maybeWhen(
      loaded: (_, __, ___, task) => task,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          '下载任务',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          // 清空已完成
          if (downloadState.maybeWhen(
                loaded: (tasks, _, __, ___) => tasks.any((t) => t.isCompleted),
                orElse: () => false,
              ))
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(downloadViewModelProvider).clearCompleted();
              },
              tooltip: '清空已完成',
            ),
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // 下载进度指示器
          if (activeTask != null && downloadProgress > 0 && downloadProgress < 100)
            _buildProgressBanner(context, activeTask, downloadStage, downloadProgress),

          // 下载任务列表
          Expanded(
            child: downloads.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final task = downloads[index];
                      return _DownloadTaskTile(
                        task: task,
                        isActive: activeTask?.bvid == task.bvid,
                        onPause: () => ref.read(downloadViewModelProvider).pauseDownload(task.id!),
                        onResume: () => ref.read(downloadViewModelProvider).resumeDownload(task.id!),
                        onDelete: () => ref.read(downloadViewModelProvider).deleteDownload(task.id!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(
    BuildContext context,
    DownloadTask activeTask,
    String stage,
    int progress,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activeTask.title ?? '下载中...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('$progress%'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FutureBuilder<String>(
      future: _getDownloadDirectory(),
      builder: (context, snapshot) {
        final dirText = snapshot.data ?? '获取中...';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '暂无下载任务',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '默认下载目录: $dirText',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取下载目录（用于显示）
  Future<String> _getDownloadDirectory() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        return '${downloadDir.path}${Platform.pathSeparator}ListenVision';
      }
    } catch (e) {
      // ignore
    }
    // 降级显示
    try {
      final docDir = await getApplicationDocumentsDirectory();
      return '${docDir.path}${Platform.pathSeparator}Downloads';
    } catch (e) {
      return '未知';
    }
  }
}

/// 下载任务列表项
class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final bool isActive;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _DownloadTaskTile({
    required this.task,
    required this.isActive,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: _buildLeading(context),
        title: Text(
          task.title ?? task.bvid ?? '未知标题',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.artist != null) Text(task.artist!),
            const SizedBox(height: 4),
            _buildProgressBar(context),
          ],
        ),
        trailing: _buildTrailing(context),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    IconData icon;
    Color color;

    switch (task.status) {
      case DownloadStatus.pending:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = Theme.of(context).colorScheme.primary;
        break;
      case DownloadStatus.paused:
        icon = Icons.pause_circle;
        color = Colors.orange;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DownloadStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color);
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = task.progressPercentage;
    final hasProgress = task.totalBytes > 0;

    if (!hasProgress && task.status != DownloadStatus.completed) {
      return const Text('等待中...');
    }

    if (task.isCompleted) {
      return Text(
        '已完成 - ${task.savePath}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 4,
        ),
        const SizedBox(height: 2),
        Text(
          '${progress.toStringAsFixed(0)}% - ${_formatBytes(task.downloadedBytes)} / ${_formatBytes(task.totalBytes)}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (task.isCompleted) {
      return IconButton(
        icon: const Icon(Icons.folder_open),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存位置: ${task.savePath}')),
          );
        },
        tooltip: '查看位置',
      );
    }

    if (task.isFailed) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: onResume,
        tooltip: '重试',
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: onPause,
            tooltip: '暂停',
          )
        else if (task.status == DownloadStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: onResume,
            tooltip: '继续',
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: '删除',
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
