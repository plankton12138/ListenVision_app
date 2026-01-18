/// 播放历史项模型
class PlayHistoryItem {
  final int? id;
  final int? userId;
  final String bvid;
  final String? title;
  final String? artist;
  final int? duration;
  final String? coverUrl;
  final DateTime? playedAt;
  final int progress; // 播放进度（秒）

  PlayHistoryItem({
    this.id,
    this.userId,
    required this.bvid,
    this.title,
    this.artist,
    this.duration,
    this.coverUrl,
    this.playedAt,
    this.progress = 0,
  });

  factory PlayHistoryItem.fromJson(Map<String, dynamic> json) {
    return PlayHistoryItem(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      bvid: json['bvid'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      duration: json['duration'] as int?,
      coverUrl: json['cover_url'] as String?,
      playedAt: _parseDateTime(json['played_at']),
      progress: json['progress'] as int? ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'bvid': bvid,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (playedAt != null) 'played_at': playedAt!.toIso8601String(),
      'progress': progress,
    };
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

  /// 播放进度百分比
  double get progressPercent {
    if (duration == null || duration == 0) return 0;
    return (progress / duration!).clamp(0, 1);
  }

  /// 格式化播放时间（如：刚刚、5分钟前、2小时前、3天前）
  String get playedAtFormatted {
    if (playedAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(playedAt!);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${playedAt!.year}-${playedAt!.month.toString().padLeft(2, '0')}-${playedAt!.day.toString().padLeft(2, '0')}';
    }
  }

  PlayHistoryItem copyWith({
    int? id,
    int? userId,
    String? bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    DateTime? playedAt,
    int? progress,
  }) {
    return PlayHistoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      playedAt: playedAt ?? this.playedAt,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() {
    return 'PlayHistoryItem{id: $id, bvid: $bvid, title: $title, playedAt: $playedAt}';
  }
}

/// 播放历史统计
class PlayHistoryStats {
  final int totalPlays;
  final PlayHistoryItem? lastPlayed;

  PlayHistoryStats({
    required this.totalPlays,
    this.lastPlayed,
  });

  factory PlayHistoryStats.fromJson(Map<String, dynamic> json) {
    final lastPlayedJson = json['lastPlayed'] as Map<String, dynamic>?;
    return PlayHistoryStats(
      totalPlays: json['totalPlays'] as int? ?? 0,
      lastPlayed: lastPlayedJson != null ? PlayHistoryItem.fromJson(lastPlayedJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPlays': totalPlays,
      if (lastPlayed != null) 'lastPlayed': lastPlayed!.toJson(),
    };
  }

  @override
  String toString() {
    return 'PlayHistoryStats{totalPlays: $totalPlays, lastPlayed: ${lastPlayed?.title}}';
  }
}
