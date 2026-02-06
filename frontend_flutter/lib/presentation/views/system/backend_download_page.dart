import 'dart:io';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/state/state_utils.dart';
import 'package:demo/models/download_task.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../viewmodels/system/download_viewmodel.dart';

/// 下载任务管理页面
///
/// 显示和管理下载任务
/// 使用 Riverpod 3.0 AsyncNotifier 模式 + 稳定特性 UI 反馈
class BackendDownloadPage extends ConsumerWidget {
  const BackendDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 3: 使用 ref.listen 处理错误提示（稳定特性）
    ref.listen(
      downloadViewModelProvider,
      (previous, next) {
        next.when(
          loading: () => null,
          data: (_) => null,
          error: (err, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('操作失败: $err'),
                action: SnackBarAction(
                  label: '关闭',
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
          },
        );
      },
    );

    // Riverpod 3.0: watch AsyncValue<DownloadModelState>
    final asyncState = ref.watch(downloadViewModelProvider);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            '下载任务',
            style: TextStyle(fontSize: UIConstants.fontSizeLarge),
          ),
        ),
        drawer: const MyDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            '下载任务',
            style: TextStyle(fontSize: UIConstants.fontSizeLarge),
          ),
        ),
        drawer: const MyDrawer(),
        body: Center(child: Text('错误: $err')),
      ),
      data: (state) => _buildContent(context, ref, state),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DownloadModelState state) {
    final downloads = state.downloads;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          '下载任务',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          // 清空已完成
          if (downloads.any((t) => t.isCompleted))
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                // Riverpod 3.0: 使用 .notifier 调用方法
                ref.read(downloadViewModelProvider.notifier).clearCompleted();
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
      body: downloads.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 8),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final task = downloads[index];
                return _DownloadTaskTile(taskId: task.id!);
              },
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

/// 下载任务列表项（独立显示进度和操作）
///
/// Phase 3: 使用 select 优化性能，仅监听需要的状态
class _DownloadTaskTile extends ConsumerWidget {
  final int taskId; // 只存储 ID，从 ViewModel 获取最新数据

  const _DownloadTaskTile({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod 3.0: 使用 select 只监听特定任务的数据
    final task = ref.watch(
      downloadViewModelProvider.select(
        (s) => s.valueOrNull?.downloads.firstWhere(
          (t) => t.id == taskId,
          orElse: () => DownloadTask(
            id: taskId,
            url: '',
            savePath: '',
            bvid: '未知',
            title: '未知任务',
            status: DownloadStatus.pending,
          ),
        ),
      ),
    ) ??
        DownloadTask(
          id: taskId,
          url: '',
          savePath: '',
          bvid: '未知',
          title: '未知任务',
          status: DownloadStatus.pending,
        );

    // Phase 3: 获取操作状态（通过 notifier 的 getter）
    // 注意：这里使用 read + build 时的调用方式，状态变化时会触发 widget 重建
    final notifier = ref.read(downloadViewModelProvider.notifier);
    final progress = notifier.getTaskProgress(taskId);
    final queuePosition = notifier.getQueuePosition(taskId);
    final isOperating = notifier.isOperating(taskId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildLeading(context, task),
            title: Text(
              task.title ?? task.bvid ?? '未知标题',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _buildSubtitle(task, queuePosition, progress),
            trailing: _buildTrailing(context, ref, task, queuePosition, isOperating),
          ),
          // 下载中的任务显示进度条
          if (task.status == DownloadStatus.downloading && progress > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress% - ${_formatBytes(task.downloadedBytes)} / ${_formatBytes(task.totalBytes)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context, DownloadTask task) {
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

  Widget _buildSubtitle(DownloadTask task, int? queuePosition, int progress) {
    // 队列中的任务显示队列位置
    if (queuePosition != null) {
      return Text(
        '等待中 - 队列第 $queuePosition 位',
        style: const TextStyle(color: Colors.grey),
      );
    }

    // 根据状态显示不同信息
    switch (task.status) {
      case DownloadStatus.pending:
        return const Text('等待中...');
      case DownloadStatus.downloading:
        if (progress == 0) {
          return const Text('准备下载...');
        }
        return const Text('下载中...');
      case DownloadStatus.paused:
        return Text('已暂停 - $progress%');
      case DownloadStatus.completed:
        return Text(
          '已完成 - ${task.savePath}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case DownloadStatus.failed:
        return Text(
          '下载失败${task.errorMessage != null ? ': ${task.errorMessage}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.red),
        );
    }
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref, DownloadTask task,
      int? queuePosition, bool isOperating) {
    // Phase 3: 操作中显示 loading 指示器
    if (isOperating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Riverpod 3.0: 使用 .notifier 调用方法
    final viewModel = ref.read(downloadViewModelProvider.notifier);

    // 已完成的任务
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

    // 失败的任务
    if (task.isFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () => viewModel.resumeDownload(task.id!),
            tooltip: '重试',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => viewModel.deleteDownload(task.id!),
            tooltip: '删除',
          ),
        ],
      );
    }

    // 队列中的任务（等待中）
    if (queuePosition != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 显示队列位置标记
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$queuePosition',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
            onPressed: () => viewModel.cancelDownload(task.id!),
            tooltip: '取消',
          ),
        ],
      );
    }

    // 下载中/暂停的任务
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.orange),
            onPressed: () => viewModel.pauseDownload(task.id!),
            tooltip: '暂停',
          )
        else if (task.status == DownloadStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () => viewModel.resumeDownload(task.id!),
            tooltip: '继续',
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => viewModel.deleteDownload(task.id!),
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
