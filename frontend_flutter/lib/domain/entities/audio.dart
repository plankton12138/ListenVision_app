import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/base/base_entity.dart';

part 'audio.freezed.dart';
part 'audio.g.dart';

/// 音频实体
///
/// Clean Architecture 中的音频领域对象
/// 表示一首音频/歌曲的完整信息
@freezed
class Audio with _$Audio implements BaseEntity {
  const Audio._();

  const factory Audio({
    required String id, // BV号
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
  }) = _Audio;

  /// 从 JSON 创建
  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);

  /// 从 DTO/后端响应创建
  factory Audio.fromDto(Map<String, dynamic> json) {
    return Audio(
      id: json['bvid'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? json['author'] as String? ?? json['uname'] as String?,
      album: json['album'] as String?,
      coverUrl: json['cover'] as String? ?? json['pic'] as String? ?? json['coverUrl'] as String?,
      streamUrl: json['stream_url'] as String? ?? json['streamUrl'] as String?,
      duration: _parseDuration(json['duration']),
      description: json['description'] as String? ?? json['desc'] as String?,
      playCount: _parsePlayCount(json['play'] as dynamic),
      uploader: json['uploader'] as String? ?? json['author'] as String?,
      uploaderMid: json['uploader_mid']?.toString() ?? json['mid']?.toString(),
      publishedAt: _parseDateTime(json['pubdate'] ?? json['published_at'] ?? json['publishedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
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

  /// 获取分享URL
  String get shareUrl => 'https://www.bilibili.com/video/$id';

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
    };
  }

  /// 转换为 PlaylistItem
  PlaylistItem toPlaylistItem({required String playlistId, required int position}) {
    return PlaylistItem(
      bvid: id,
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
}

/// 为了循环引用，PlaylistItem 在 playlist.dart 中定义
/// 这里使用前向声明
class PlaylistItem {
  final String? id;
  final String? playlistId;
  final String bvid;
  final String? title;
  final String? artist;
  final int? duration;
  final String? coverUrl;
  final int position;
  final DateTime? addedAt;

  const PlaylistItem({
    this.id,
    this.playlistId,
    required this.bvid,
    this.title,
    this.artist,
    this.duration,
    this.coverUrl,
    required this.position,
    this.addedAt,
  });
}
