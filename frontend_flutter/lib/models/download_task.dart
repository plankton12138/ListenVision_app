/// 下载状态枚举
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

/// 下载状态扩展方法
extension DownloadStatusExtension on DownloadStatus {
  String get value {
    switch (this) {
      case DownloadStatus.pending:
        return 'pending';
      case DownloadStatus.downloading:
        return 'downloading';
      case DownloadStatus.paused:
        return 'paused';
      case DownloadStatus.completed:
        return 'completed';
      case DownloadStatus.failed:
        return 'failed';
    }
  }

  static DownloadStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }
}

/// 下载任务实体
class DownloadTask {
  final int? id;
  final int? trackId;
  final String url;
  final String savePath;
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final String? originalUrl;
  final String? title;
  final String? artist;
  final String? coverUrl;
  final String? bvid;
  final String? errorMessage;
  final String? tempFilePath; // 临时文件路径（断点续传使用）
  final String? etag; // ETag 用于验证文件是否更改
  final String? lastModified; // Last-Modified 头
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DownloadTask({
    this.id,
    this.trackId,
    required this.url,
    required this.savePath,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.pending,
    this.originalUrl,
    this.title,
    this.artist,
    this.coverUrl,
    this.bvid,
    this.errorMessage,
    this.tempFilePath,
    this.etag,
    this.lastModified,
    this.createdAt,
    this.updatedAt,
  });

  /// 进度百分比
  double get progressPercentage {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes * 100).clamp(0.0, 100.0);
  }

  /// 是否正在进行中
  bool get isActive =>
      status == DownloadStatus.pending || status == DownloadStatus.downloading;

  /// 是否已完成
  bool get isCompleted => status == DownloadStatus.completed;

  /// 是否已失败
  bool get isFailed => status == DownloadStatus.failed;

  /// 从 Map 创建
  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as int?,
      trackId: map['track_id'] as int?,
      url: map['url'] as String? ?? '',
      savePath: map['save_path'] as String? ?? '',
      downloadedBytes: map['downloaded_bytes'] as int? ?? 0,
      totalBytes: map['total_bytes'] as int? ?? 0,
      status: DownloadStatusExtension.fromString(map['status'] as String?),
      originalUrl: map['original_url'] as String?,
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      coverUrl: map['cover_url'] as String?,
      bvid: map['bvid'] as String?,
      errorMessage: map['error_message'] as String?,
      tempFilePath: map['temp_file_path'] as String?,
      etag: map['etag'] as String?,
      lastModified: map['last_modified'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      'url': url,
      'save_path': savePath,
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'status': status.value,
      if (originalUrl != null) 'original_url': originalUrl,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (bvid != null) 'bvid': bvid,
      if (errorMessage != null) 'error_message': errorMessage,
      if (tempFilePath != null) 'temp_file_path': tempFilePath,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 创建副本，允许修改部分字段
  DownloadTask copyWith({
    int? id,
    int? trackId,
    String? url,
    String? savePath,
    int? downloadedBytes,
    int? totalBytes,
    DownloadStatus? status,
    String? originalUrl,
    String? title,
    String? artist,
    String? coverUrl,
    String? bvid,
    String? errorMessage,
    String? tempFilePath,
    String? etag,
    String? lastModified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      originalUrl: originalUrl ?? this.originalUrl,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      bvid: bvid ?? this.bvid,
      errorMessage: errorMessage ?? this.errorMessage,
      tempFilePath: tempFilePath ?? this.tempFilePath,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
