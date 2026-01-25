import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/base/base_entity.dart';
import 'audio.dart';

part 'play_history.freezed.dart';
part 'play_history.g.dart';

/// 播放历史实体
///
/// Clean Architecture 中的播放历史领域对象
@freezed
class PlayHistory with _$PlayHistory implements BaseEntity {
  const PlayHistory._();

  const factory PlayHistory({
    required String id,
    required String userId,
    required Audio audio,
    required DateTime playedAt,
    @Default(0) int progress, // 播放进度（秒）
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PlayHistory;

  /// 从 JSON 创建
  factory PlayHistory.fromJson(Map<String, dynamic> json) => _$PlayHistoryFromJson(json);

  /// 从 DTO 创建
  factory PlayHistory.fromDto(Map<String, dynamic> json) {
    // ✅ 安全的数值转字符串转换（修复类型转换错误）
    final safeString = (dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toInt().toString();
      return value.toString();
    };

    // ✅ 安全的数值转换
    final safeInt = (dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    };

    return PlayHistory(
      id: safeString(json['id']) ?? '',
      userId: safeString(json['user_id'] ?? json['userId']) ?? '',
      audio: Audio.fromDto(json), // Audio 可以从整个 JSON 解析
      playedAt: _parseDateTime(json['played_at'] ?? json['playedAt']) ?? DateTime.now(),
      progress: safeInt(json['progress']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// 从 Audio 创建新的播放历史
  factory PlayHistory.fromAudio({
    required String userId,
    required Audio audio,
    int progress = 0,
  }) {
    return PlayHistory(
      id: '', // 新建时 ID 由后端生成
      userId: userId,
      audio: audio,
      playedAt: DateTime.now(),
      progress: progress,
    );
  }

  /// 播放进度百分比
  double get progressPercent {
    if (audio.duration == null || audio.duration == 0) return 0;
    return (progress / audio.duration!).clamp(0.0, 1.0);
  }

  /// 格式化播放时间（如：刚刚、5分钟前、2小时前、3天前）
  String get playedAtFormatted {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${playedAt.year}-${playedAt.month.toString().padLeft(2, '0')}-${playedAt.day.toString().padLeft(2, '0')}';
    }
  }

  /// 是否已完成播放（进度超过90%）
  bool get isCompleted {
    if (audio.duration == null || audio.duration == 0) return false;
    return progressPercent >= 0.9;
  }

  /// 是否有进度
  bool get hasProgress => progress > 0;

  /// 转换为 DTO
  Map<String, dynamic> toDto() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'user_id': int.tryParse(userId) ?? userId,
      'bvid': audio.id,
      'title': audio.title,
      'artist': audio.artist,
      'duration': audio.duration,
      'cover_url': audio.coverUrl,
      'played_at': playedAt.toIso8601String(),
      'progress': progress,
    };
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

/// 播放历史统计
@freezed
class PlayHistoryStats with _$PlayHistoryStats {
  const factory PlayHistoryStats({
    @Default(0) int totalPlays,
    PlayHistory? lastPlayed,
    @Default(0) int uniqueTracks,
    @Default(0) int totalDuration, // 总播放时长（分钟）
  }) = _PlayHistoryStats;

  /// 从 JSON 创建
  factory PlayHistoryStats.fromJson(Map<String, dynamic> json) => _$PlayHistoryStatsFromJson(json);
}
