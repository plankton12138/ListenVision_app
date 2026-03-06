import 'dart:io';

import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/state/state_utils.dart';
import 'package:listenvision/models/download_task.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../viewmodels/system/download_viewmodel.dart';

/// 下载任务管理页面
///
/// 显示和管理下载任务，包括：
/// - 任务状态（等待中、下载中、转码中、已完成、失败）
/// - 下载进度和速度
/// - 操作按钮（暂停、恢复、删除、重试）
class BackendDownloadPage extends ConsumerWidget {
  const BackendDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听错误状态并显示提示
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(downloadViewModelProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
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
          : Column(
              children: [
                // 统计信息栏
                _buildStatsBar(context, ref, downloads),
                // 任务列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 8),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final task = downloads[index];
                      return _DownloadTaskTile(taskId: task.id!);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// 统计信息栏
  Widget _buildStatsBar(BuildContext context, WidgetRef ref, List<DownloadTask> downloads) {
    final downloading = downloads.where((t) => t.status == DownloadStatus.downloading).length;
    final pending = downloads.where((t) => t.status == DownloadStatus.pending).length;
    final completed = downloads.where((t) => t.isCompleted).length;
    final failed = downloads.where((t) => t.isFailed).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _StatItem(label: '下载中', count: downloading, color: Colors.blue),
          const SizedBox(width: 16),
          _StatItem(label: '等待中', count: pending, color: Colors.grey),
          const SizedBox(width: 16),
          _StatItem(label: '已完成', count: completed, color: Colors.green),
          const SizedBox(width: 16),
          _StatItem(label: '失败', count: failed, color: Colors.red),
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
              Icon(Icons.download_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '暂无下载任务',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '默认下载目录: $dirText',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

/// 统计项组件
class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 下载任务列表项
///
/// 显示详细信息：
/// - 任务标题和艺术家
/// - 当前状态（详细描述）
/// - 下载进度条
/// - 下载速度和剩余时间
/// - 操作按钮
class _DownloadTaskTile extends ConsumerWidget {
  final int taskId;

  const _DownloadTaskTile({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final notifier = ref.read(downloadViewModelProvider.notifier);
    final isOperating = notifier.isOperating(taskId);
    final progress = notifier.getTaskProgress(taskId);
    final queuePosition = notifier.getQueuePosition(taskId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                _buildStatusIcon(context, task),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title ?? task.bvid ?? '未知标题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (task.artist != null)
                        Text(
                          task.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // 操作按钮
                _buildActionButtons(context, ref, task, queuePosition, isOperating),
              ],
            ),
            const SizedBox(height: 12),
            // 状态描述
            _buildStatusDetail(context, task, queuePosition, progress),
            // 进度条（下载中时显示）
            if (task.status == DownloadStatus.downloading || (task.status == DownloadStatus.paused && progress > 0))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildProgressBar(context, task, progress),
              ),
          ],
        ),
      ),
    );
  }

  /// 状态图标
  Widget _buildStatusIcon(BuildContext context, DownloadTask task) {
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
      case DownloadStatus.stalled:
        icon = Icons.warning_amber_rounded;
        color = Colors.deepOrange;
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

    return Icon(icon, color: color, size: 24);
  }

  /// 详细状态描述
  Widget _buildStatusDetail(BuildContext context, DownloadTask task, int? queuePosition, int progress) {
    String statusText;
    Color? statusColor;

    switch (task.status) {
      case DownloadStatus.pending:
        if (queuePosition != null) {
          statusText = '队列第 $queuePosition 位，等待下载...';
          statusColor = Colors.grey.shade600;
        } else {
          statusText = '准备中...';
          statusColor = Colors.grey.shade600;
        }
        break;
      case DownloadStatus.downloading:
        if (progress == 0) {
          statusText = '正在连接服务器...';
          statusColor = Theme.of(context).colorScheme.primary;
        } else if (task.totalBytes > 1000) {
          // 只有在知道总大小时（大于1KB，排除错误数据）才显示字节数
          final downloaded = _formatBytes(task.downloadedBytes);
          final total = _formatBytes(task.totalBytes);
          statusText = '下载中: $downloaded / $total';
          statusColor = Theme.of(context).colorScheme.primary;
        } else {
          // 不知道总大小时只显示百分比
          statusText = '下载中: $progress%';
          statusColor = Theme.of(context).colorScheme.primary;
        }
        break;
      case DownloadStatus.paused:
        statusText = '已暂停 ${progress > 0 ? '($progress%)' : ''}';
        statusColor = Colors.orange;
        break;
      case DownloadStatus.stalled:
        statusText = '下载卡死，等待重试...';
        statusColor = Colors.deepOrange;
        break;
      case DownloadStatus.completed:
        final file = task.savePath.split(Platform.pathSeparator).last;
        statusText = '已完成: $file';
        statusColor = Colors.green;
        break;
      case DownloadStatus.failed:
        statusText = '下载失败${task.errorMessage != null ? ': ${task.errorMessage}' : ''}';
        statusColor = Colors.red;
        break;
    }

    return Row(
      children: [
        Icon(
          _getStageIcon(task.status),
          size: 14,
          color: statusColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 进度条
  Widget _buildProgressBar(BuildContext context, DownloadTask task, int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$progress%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        if (task.totalBytes > 1000)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_formatBytes(task.downloadedBytes)} / ${_formatBytes(task.totalBytes)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  /// 操作按钮组
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    DownloadTask task,
    int? queuePosition,
    bool isOperating,
  ) {
    final viewModel = ref.read(downloadViewModelProvider.notifier);

    // 操作中显示 loading
    if (isOperating) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // 已完成：显示打开位置按钮
    if (task.isCompleted) {
      return IconButton(
        icon: Icon(Icons.folder_open, color: Colors.green.shade600),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存位置: ${task.savePath}'),
              action: SnackBarAction(
                label: '复制',
                onPressed: () {
                  // 后续可接入剪贴板能力以提升桌面端体验
                },
              ),
            ),
          );
        },
        tooltip: '查看位置',
      );
    }

    // 失败：显示重试和删除按钮
    if (task.isFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () => viewModel.resumeDownload(task.id!),
            tooltip: '重试',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => viewModel.deleteDownload(task.id!),
            tooltip: '删除',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    }

    // 队列中：显示取消按钮
    if (queuePosition != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$queuePosition',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
            onPressed: () => viewModel.cancelDownload(task.id!),
            tooltip: '取消',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    }

    // 下载中/暂停：显示暂停/继续和删除按钮
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.orange),
            onPressed: () => viewModel.pauseDownload(task.id!),
            tooltip: '暂停',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          )
        else if (task.status == DownloadStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () => viewModel.resumeDownload(task.id!),
            tooltip: '继续',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => viewModel.deleteDownload(task.id!),
          tooltip: '删除',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  IconData _getStageIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Icons.schedule;
      case DownloadStatus.downloading:
        return Icons.cloud_download;
      case DownloadStatus.paused:
        return Icons.pause;
      case DownloadStatus.stalled:
        return Icons.warning_amber_rounded;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
