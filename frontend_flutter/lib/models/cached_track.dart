import 'dart:typed_data';

import '../core/utils/local_track_id.dart';
import 'audio.dart';
import 'local_audio.dart';

/// 音轨来源类型
enum TrackSource { bilibili, local, network }

/// 音轨来源类型扩展
extension TrackSourceExtension on TrackSource {
  String get value {
    switch (this) {
      case TrackSource.bilibili:
        return 'bilibili';
      case TrackSource.local:
        return 'local';
      case TrackSource.network:
        return 'network';
    }
  }

  static TrackSource fromString(String? value) {
    switch (value) {
      case 'bilibili':
        return TrackSource.bilibili;
      case 'local':
        return TrackSource.local;
      case 'network':
        return TrackSource.network;
      default:
        return TrackSource.bilibili;
    }
  }
}

/// 缓存音轨 - 整合在线和本地音频的统一实体
///
/// 这是本地优先架构的核心数据模型，所有音频数据（无论是B站音频
/// 还是本地导入的音频）都统一使用此模型存储。
class CachedTrack {
  // 数据库 ID
  final int id;

  // 来源标识
  final String sourceId; // BVID 或 file_path
  final TrackSource sourceType;

  // 音频元数据
  final String title;
  final String? artist;
  final String? album;
  final int? duration; // 秒
  final String? coverUrl;
  final Uint8List? coverBlob;

  // B站特有
  final String? bvid;
  final String? uploader;
  final String? uploaderMid;
  final int? playCount;

  // 本地化状态
  final String? localPath;
  final bool isDownloaded;

  // 用户数据
  final bool isFavorite;
  final int localPlayCount;
  final DateTime? lastPlayedAt;

  // 歌单关联
  final int? position;
  final String? playlistId;

  // 时间戳
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;

  const CachedTrack({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.coverUrl,
    this.coverBlob,
    this.bvid,
    this.uploader,
    this.uploaderMid,
    this.playCount,
    this.localPath,
    this.isDownloaded = false,
    this.isFavorite = false,
    this.localPlayCount = 0,
    this.lastPlayedAt,
    this.position,
    this.playlistId,
    this.addedAt,
    this.updatedAt,
    this.syncedAt,
  });

  /// 是否可离线播放
  bool get isAvailableOffline => isDownloaded && localPath != null;

  /// 获取播放源（优先本地）
  String? get playableSource {
    if (localPath != null && localPath!.isNotEmpty) {
      return localPath;
    }
    return coverUrl;
  }

  /// 从 Map 创建（数据库反序列化）
  factory CachedTrack.fromMap(Map<String, dynamic> map) {
    Uint8List? coverBlobData;
    if (map['cover_blob'] != null) {
      if (map['cover_blob'] is Uint8List) {
        coverBlobData = map['cover_blob'] as Uint8List;
      } else if (map['cover_blob'] is List) {
        final list = map['cover_blob'] as List;
        coverBlobData = Uint8List.fromList(list.cast<int>());
      }
    }

    return CachedTrack(
      id: map['id'] as int,
      sourceId: map['source_id'] as String,
      sourceType: TrackSourceExtension.fromString(
        map['source_type'] as String?,
      ),
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      duration: map['duration'] as int?,
      coverUrl: map['cover_url'] as String?,
      coverBlob: coverBlobData,
      bvid: map['bvid'] as String?,
      uploader: map['uploader'] as String?,
      uploaderMid: map['uploader_mid'] as String?,
      playCount: map['play_count'] as int?,
      localPath: map['local_path'] as String?,
      isDownloaded: map['is_downloaded'] == 1,
      isFavorite: map['is_favorite'] == 1,
      localPlayCount: map['local_play_count'] as int? ?? 0,
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.tryParse(map['last_played_at'] as String)
          : null,
      position: map['position'] as int?,
      playlistId: map['playlist_id'] as String?,
      addedAt: map['added_at'] != null
          ? DateTime.tryParse(map['added_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'] as String)
          : null,
    );
  }

  /// 转换为 Map（数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'source_type': sourceType.value,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'cover_url': coverUrl,
      'cover_blob': coverBlob,
      'bvid': bvid,
      'uploader': uploader,
      'uploader_mid': uploaderMid,
      'play_count': playCount,
      'local_path': localPath,
      'is_downloaded': isDownloaded ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'local_play_count': localPlayCount,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'added_at': addedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// 转换为 Map 用于插入（不含 id）
  Map<String, dynamic> toMapForInsert() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  /// 创建副本，允许修改部分字段
  CachedTrack copyWith({
    int? id,
    String? sourceId,
    TrackSource? sourceType,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? coverUrl,
    Uint8List? coverBlob,
    String? bvid,
    String? uploader,
    String? uploaderMid,
    int? playCount,
    String? localPath,
    bool? isDownloaded,
    bool? isFavorite,
    int? localPlayCount,
    DateTime? lastPlayedAt,
    int? position,
    String? playlistId,
    DateTime? addedAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return CachedTrack(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      coverBlob: coverBlob ?? this.coverBlob,
      bvid: bvid ?? this.bvid,
      uploader: uploader ?? this.uploader,
      uploaderMid: uploaderMid ?? this.uploaderMid,
      playCount: playCount ?? this.playCount,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      localPlayCount: localPlayCount ?? this.localPlayCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      position: position ?? this.position,
      playlistId: playlistId ?? this.playlistId,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// 转换为 Audio（用于现有播放器）
  Audio toAudio() {
    return Audio(
      id: bvid ?? sourceId,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      duration: duration,
      playCount: playCount,
      uploader: uploader,
      uploaderMid: uploaderMid,
    );
  }

  /// 转换为 LocalAudio（本地导入）
  LocalAudio toLocalAudio() {
    return LocalAudio(
      id: id,
      filePath: localPath ?? '',
      title: title,
      artist: artist ?? '未知艺术家',
      duration: duration ?? 0,
      albumArt: coverBlob,
    );
  }

  /// 从 Audio 创建（用于B站搜索结果转换）
  factory CachedTrack.fromAudio(Audio audio) {
    return CachedTrack(
      id: 0, // 插入时由数据库生成
      sourceId: audio.id,
      sourceType: TrackSource.bilibili,
      title: audio.title,
      artist: audio.artist,
      album: audio.album,
      duration: audio.duration,
      coverUrl: audio.coverUrl,
      bvid: audio.id,
      uploader: audio.uploader,
      uploaderMid: audio.uploaderMid,
      playCount: audio.playCount,
    );
  }

  /// 从 LocalAudio 创建（用于本地音乐导入）
  factory CachedTrack.fromLocalAudio(LocalAudio localAudio) {
    final localId = localIdFromPath(localAudio.filePath);
    return CachedTrack(
      id: localAudio.id ?? 0,
      sourceId: localId,
      sourceType: TrackSource.local,
      title: localAudio.title,
      artist: localAudio.artist,
      duration: localAudio.duration,
      coverBlob: localAudio.albumArt,
      bvid: localId,
      localPath: localAudio.filePath,
      isDownloaded: true,
      isFavorite: localAudio.isFavorite,
    );
  }

  /// 格式化时长（秒 -> mm:ss 或 hh:mm:ss）
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化播放次数
  String get formattedPlayCount {
    if (playCount == null || playCount == 0) return '0';
    if (playCount! < 1000) return playCount.toString();
    if (playCount! < 10000) return '${(playCount! / 1000).toStringAsFixed(1)}k';
    if (playCount! < 100000000) {
      return '${(playCount! / 10000).toStringAsFixed(1)}w';
    }
    return '${(playCount! / 100000000).toStringAsFixed(1)}亿';
  }

  @override
  String toString() {
    return 'CachedTrack(id: $id, sourceId: $sourceId, title: $title, sourceType: $sourceType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedTrack && other.id == id && other.sourceId == sourceId;
  }

  @override
  int get hashCode => Object.hash(id, sourceId);
}
