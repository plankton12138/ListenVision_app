import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/download_task.dart';
import '../../../data/repositories/repository_providers.dart';

class DownloadStatusIndicator extends ConsumerWidget {
  final String bvid;
  final double size;
  final bool showLabel;

  const DownloadStatusIndicator({
    super.key,
    required this.bvid,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackAsync = ref.watch(trackByBvidProvider(bvid));

    return trackAsync.when(
      data: (track) {
        if (track != null && track.isDownloaded) {
          return _buildDownloaded();
        }

        if (track != null) {
          return ref.watch(downloadTaskByTrackIdProvider(track.id)).when(
            data: (task) {
              if (task == null) return _buildNotDownloaded();
              return _buildFromTask(task);
            },
            loading: () => _buildLoading(),
            error: (_, _) => _buildNotDownloaded(),
          );
        }

        return _buildNotDownloaded();
      },
      loading: () => _buildLoading(),
      error: (_, _) => _buildNotDownloaded(),
    );
  }

  Widget _buildFromTask(DownloadTask task) {
    final status = task.status;
    final progress = (task.progressPercentage * 100).toInt();

    switch (status) {
      case DownloadStatus.completed:
        return _buildDownloaded();
      case DownloadStatus.downloading:
        return _buildDownloading(progress);
      case DownloadStatus.paused:
        return _buildPaused();
      case DownloadStatus.failed:
        return _buildFailed();
      case DownloadStatus.pending:
      case DownloadStatus.stalled:
        return _buildPending();
    }
  }

  Widget _buildDownloading(int progress) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: progress > 0 ? progress / 100 : null,
        strokeWidth: 2,
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildPaused() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.pause_circle_outline,
          size: size,
          color: Colors.orange,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '已暂停',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFailed() {
    return Icon(
      Icons.error_outline,
      size: size,
      color: Colors.red,
    );
  }

  Widget _buildPending() {
    return Icon(
      Icons.schedule,
      size: size,
      color: Colors.orange,
    );
  }

  Widget _buildDownloaded() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.download_done,
          size: size,
          color: Colors.green,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '已下载',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotDownloaded() {
    return Icon(
      Icons.download_outlined,
      size: size,
      color: Colors.grey[400],
    );
  }

  Widget _buildLoading() {
    return SizedBox(width: size, height: size);
  }
}

class CompactDownloadStatusIndicator extends StatelessWidget {
  final DownloadStatus status;
  final int? progress;
  final double size;
  final bool isDownloaded;

  const CompactDownloadStatusIndicator({
    super.key,
    required this.status,
    this.progress,
    this.size = 20,
    this.isDownloaded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloaded && status == DownloadStatus.completed) {
      return Icon(
        Icons.download_done,
        size: size,
        color: Colors.green,
      );
    } else if (status == DownloadStatus.downloading) {
      final progressValue = progress != null && progress! > 0 ? progress! / 100 : null;
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: progressValue,
          strokeWidth: 2,
          backgroundColor: Colors.grey[300],
        ),
      );
    } else if (status == DownloadStatus.paused) {
      return Icon(
        Icons.pause_circle_outline,
        size: size,
        color: Colors.orange,
      );
    } else if (status == DownloadStatus.failed) {
      return Icon(
        Icons.error_outline,
        size: size,
        color: Colors.red,
      );
    } else {
      return Icon(
        Icons.download_outlined,
        size: size,
        color: Colors.grey[400],
      );
    }
  }
}
