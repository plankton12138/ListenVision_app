/// 同步队列数据模型
///
/// 用于本地优先架构的网络同步重试机制
library;
import 'dart:convert';

/// 同步操作类型
enum SyncType {
  /// 收藏操作
  favorite('favorite'),

  /// 取消收藏
  unfavorite('unfavorite'),

  /// 播放历史
  playHistory('play_history'),

  /// 添加歌单项
  addPlaylistItem('add_playlist_item'),

  /// 删除歌单项
  removePlaylistItem('remove_playlist_item'),

  /// 创建歌单
  createPlaylist('create_playlist'),

  /// 更新歌单
  updatePlaylist('update_playlist'),

  /// 删除歌单
  deletePlaylist('delete_playlist');

  final String value;
  const SyncType(this.value);

  static SyncType fromString(String value) {
    return SyncType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SyncType.favorite,
    );
  }
}

/// 同步任务状态
enum SyncStatus {
  /// 等待同步
  pending('pending'),

  /// 同步中
  syncing('syncing'),

  /// 同步成功
  succeeded('succeeded'),

  /// 同步失败（可重试）
  failed('failed'),

  /// 已取消
  cancelled('cancelled');

  final String value;
  const SyncStatus(this.value);

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

/// 同步任务
class SyncTask {
  /// 任务 ID
  final int? id;

  /// 同步类型
  final SyncType type;

  /// 关联的 Track ID（可选）
  final int? trackId;

  /// 关联的 BVID（可选）
  final String? bvid;

  /// 关联的 Playlist ID（可选）
  final String? playlistId;

  /// 操作数据（JSON 字符串）
  final String? data;

  /// 当前状态
  final SyncStatus status;

  /// 重试次数
  final int retryCount;

  /// 最大重试次数
  final int maxRetries;

  /// 错误消息
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  /// 完成时间
  final DateTime? completedAt;

  SyncTask({
    this.id,
    required this.type,
    this.trackId,
    this.bvid,
    this.playlistId,
    this.data,
    required this.status,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// 判断是否应该重试
  bool get shouldRetry => retryCount < maxRetries && status == SyncStatus.failed;

  /// 判断任务是否处于活动状态
  bool get isActive => status == SyncStatus.pending || status == SyncStatus.syncing;

  /// 从数据库 Map 创建
  factory SyncTask.fromMap(Map<String, dynamic> map) {
    return SyncTask(
      id: map['id'] as int?,
      type: SyncType.fromString(map['type'] as String),
      trackId: map['track_id'] as int?,
      bvid: map['bvid'] as String?,
      playlistId: map['playlist_id'] as String?,
      data: map['data'] as String?,
      status: SyncStatus.fromString(map['status'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      maxRetries: map['max_retries'] as int? ?? 3,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.value,
      'track_id': trackId,
      'bvid': bvid,
      'playlist_id': playlistId,
      'data': data,
      'status': status.value,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 创建副本
  SyncTask copyWith({
    int? id,
    SyncType? type,
    int? trackId,
    String? bvid,
    String? playlistId,
    String? data,
    SyncStatus? status,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SyncTask(
      id: id ?? this.id,
      type: type ?? this.type,
      trackId: trackId ?? this.trackId,
      bvid: bvid ?? this.bvid,
      playlistId: playlistId ?? this.playlistId,
      data: data ?? this.data,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'SyncTask(id: $id, type: $type, status: $status, retryCount: $retryCount)';
  }
}

/// 同步任务创建工厂
class SyncTaskFactory {
  /// 创建收藏同步任务
  static SyncTask createFavoriteTask({
    required int trackId,
    required String bvid,
    required bool isFavorite,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) {
    final payload = <String, dynamic>{
      if (title != null && title.isNotEmpty) 'title': title,
      if (artist != null && artist.isNotEmpty) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
    };

    return SyncTask(
      type: isFavorite ? SyncType.favorite : SyncType.unfavorite,
      trackId: trackId,
      bvid: bvid,
      data: payload.isEmpty ? null : jsonEncode(payload),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// 创建播放历史同步任务
  static SyncTask createPlayHistoryTask({
    required int trackId,
    required String bvid,
  }) {
    return SyncTask(
      type: SyncType.playHistory,
      trackId: trackId,
      bvid: bvid,
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// 创建歌单项操作同步任务
  static SyncTask createPlaylistItemTask({
    required SyncType type,
    required String playlistId,
    required String bvid,
    int? position,
  }) {
    return SyncTask(
      type: type,
      playlistId: playlistId,
      bvid: bvid,
      data: position != null ? '{"position": $position}' : null,
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
  }
}
