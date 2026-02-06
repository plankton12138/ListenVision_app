import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/cached_track.dart';
import '../../../models/download_task.dart';
import '../../../data/repositories/repository_providers.dart';

/// 下载状态指示器
///
/// 显示音轨的下载状态，包括：
/// - 未下载（空心下载图标）
/// - 下载中（进度指示器）
/// - 已下载（实心下载图标）
/// - 已暂停（暂停图标）
/// - 失败（错误图标）
class DownloadStatusIndicator extends ConsumerWidget {
  /// BVID
  final String bvid;

  /// 图标大小
  final double size;

  /// 是否显示标签
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
        if (track == null) {
          return _buildNotDownloaded();
        }

        return _buildStatusIcon(context, track);
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => _buildNotDownloaded(),
    );
  }

  /// 未下载状态
  Widget _buildNotDownloaded() {
    return Icon(
      Icons.download_outlined,
      size: size,
      color: Colors.grey[400],
    );
  }

  /// 根据状态构建图标
  Widget _buildStatusIcon(BuildContext context, CachedTrack track) {
    final isDownloaded = track.isDownloaded;
    final downloadStatus = track.downloadStatus;
    final progress = track.downloadProgress;

    if (isDownloaded && downloadStatus == DownloadStatus.completed) {
      // 已下载
      return _buildDownloaded();
    } else if (downloadStatus == DownloadStatus.downloading) {
      // 下载中
      return _buildDownloading(progress);
    } else if (downloadStatus == DownloadStatus.paused) {
      // 已暂停
      return _buildPaused();
    } else if (downloadStatus == DownloadStatus.failed) {
      // 失败
      return _buildFailed();
    } else {
      // 未下载
      return _buildNotDownloaded();
    }
  }

  /// 已下载
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

  /// 下载中
  Widget _buildDownloading(int progress) {
    final progressValue = progress > 0 ? progress / 100 : null;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: progressValue,
        strokeWidth: 2,
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  /// 已暂停
  Widget _buildPaused() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.download_done,
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

  /// 失败
  Widget _buildFailed() {
    return Icon(
      Icons.error_outline,
      size: size,
      color: Colors.red,
    );
  }
}

/// 紧凑型下载状态指示器（仅图标，不请求状态）
///
/// 用于已经知道下载状态的场景，不需要再次查询
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
