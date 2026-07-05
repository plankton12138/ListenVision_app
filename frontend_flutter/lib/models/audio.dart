import 'package:freezed_annotation/freezed_annotation.dart';
import 'playlist.dart' hide PlaylistDetail;

part 'audio.freezed.dart';
part 'audio.g.dart';

/// 视频分P信息
class AudioPage {
  final int cid;
  final String title;
  final int duration; // 秒

  const AudioPage({
    required this.cid,
    required this.title,
    required this.duration,
  });

  /// 格式化时长（mm:ss）
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 静态格式化（供外部使用）
  static String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 音频实体
@freezed
abstract class Audio with _$Audio {
  const Audio._();

  const factory Audio({
    required String id, // BV号或 local_{hash}
    required String title,
    String? artist,
    String? album,
    String? coverUrl,
    String? streamUrl,
    int? duration, // 秒
    String? description,
    int? playCount,
    String? uploader,
    String? uploaderMid,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? localPath, // 本地音频文件路径（仅本地音频使用）
    int? cid, // B站视频分P ID
    @Default(1) int videos, // 分P总数，默认1
  }) = _Audio;

  /// 从 JSON 创建
  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);

  /// 从 DTO/后端响应创建
  factory Audio.fromDto(Map<String, dynamic> json) {
    // 安全的数值转字符串转换（防御性编程）
    final safeString = (dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toInt().toString();
      return value.toString();
    };

    // 统一封面字段解析（支持多种命名方式）
    // 后端可能返回：'cover', 'pic', 'cover', 'coverUrl', 'cover_url'
    final safeCoverUrl = () {
      // 优先级1：检查 'cover'（推荐）
      if (json['cover'] != null) {
        final value = json['cover'];
        if (value is String && value.isNotEmpty) return value;
        if (value is Map && value['url'] != null) return value['url'] as String;
        return value.toString();
      }
      // 优先级2：检查 'pic'（搜索页面使用）
      if (json['pic'] != null) {
        final value = json['pic'];
        if (value is String && value.isNotEmpty) return value;
        if (value is Map && value['url'] != null) return value['url'] as String;
        return value.toString();
      }
      // 优先级3：检查 'coverUrl'（标准字段）
      if (json['coverUrl'] != null) {
        return json['coverUrl'] as String?;
      }
      // 优先级4：检查 'cover_url'
      if (json['cover_url'] != null) {
        return json['cover_url'] as String?;
      }
      // 优先级5：默认：返回空
      return null;
    };

    return Audio(
      id: safeString(json['bvid'] ?? json['id'] ?? json['bvId']) ?? '',
      title: safeString(json['title']) ?? '',
      artist: safeString(json['artist'] ?? json['author'] ?? json['uname']),
      album: safeString(json['album']),
      coverUrl: safeCoverUrl(),  // ✅ 统一封面字段解析
      streamUrl: safeString(json['stream_url'] ?? json['streamUrl']),
      duration: _parseDuration(json['duration']),
      description: safeString(json['description'] ?? json['desc']),
      playCount: _parsePlayCount(json['play']),
      uploader: safeString(json['uploader'] ?? json['author']),
      uploaderMid: safeString(json['uploader_mid'] ?? json['mid']),
      publishedAt: _parseDateTime(json['pubdate'] ?? json['published_at'] ?? json['publishedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      localPath: safeString(json['local_path'] ?? json['localPath']),
      cid: _parseCid(json['cid']),
      videos: _parseIntWithDefault(json['videos'], 1),
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
    if (playCount! < 100000000) return '${(playCount! / 10000).toStringAsFixed(1)}w';
    return '${(playCount! / 100000000).toStringAsFixed(1)}亿';
  }

  /// 是否有封面
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 是否有流地址
  bool get hasStream => streamUrl != null && streamUrl!.isNotEmpty;

  /// 是否有描述
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// 是否有上传者
  bool get hasUploader => uploader != null && uploader!.isNotEmpty;

  /// 判断是否为新发布（7天内）
  bool get isNew {
    if (publishedAt == null) return false;
    final daysSincePublished = DateTime.now().difference(publishedAt!).inDays;
    return daysSincePublished <= 7;
  }

  /// 转换为 DTO
  Map<String, dynamic> toDto() {
    return {
      'bvid': id,
      'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (coverUrl != null) 'cover': coverUrl,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (duration != null) 'duration': duration,
      if (description != null) 'description': description,
      if (playCount != null) 'play': playCount,
      if (uploader != null) 'uploader': uploader,
      if (uploaderMid != null) 'mid': int.tryParse(uploaderMid!) ?? uploaderMid,
      if (localPath != null) 'local_path': localPath,
      if (cid != null) 'cid': cid,
      if (videos != 1) 'videos': videos,
    };
  }

  /// 转换为 PlaylistItem
  PlaylistItem toPlaylistItem({required String playlistId, required int position}) {
    return PlaylistItem(
      bvid: id,
      cid: cid,
      title: title,
      artist: artist,
      duration: duration,
      coverUrl: coverUrl,
      position: position,
    );
  }

  /// 解析时长（支持秒数、格式化字符串）
  static int? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // 尝试解析为整数秒
      final seconds = int.tryParse(value);
      if (seconds != null) return seconds;

      // 尝试解析格式化的时长 (mm:ss 或 hh:mm:ss)
      final parts = value.split(':');
      if (parts.length == 2) {
        final min = int.tryParse(parts[0]);
        final sec = int.tryParse(parts[1]);
        if (min != null && sec != null) return min * 60 + sec;
      } else if (parts.length == 3) {
        final hr = int.tryParse(parts[0]);
        final min = int.tryParse(parts[1]);
        final sec = int.tryParse(parts[2]);
        if (hr != null && min != null && sec != null) return hr * 3600 + min * 60 + sec;
      }
    }
    return null;
  }

  /// 解析播放次数
  static int? _parsePlayCount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 解析 DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  /// 解析 CID（B站视频分P ID）
  static int? _parseCid(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 解析整数（带默认值）
  static int _parseIntWithDefault(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
