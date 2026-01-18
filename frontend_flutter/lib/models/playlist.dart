/// 歌单类型枚举
enum PlaylistType {
  /// 系统歌单（如"我喜欢"、"正在播放"）
  system,
  /// 用户自建歌单
  user,
}

/// 系统歌单类型枚举
enum SystemPlaylistType {
  /// 我喜欢（收藏）
  favorites,
  /// 正在播放（播放队列）
  nowPlaying,
}

/// 歌单模型
class Playlist {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String? coverUrl;
  final PlaylistType type;
  final SystemPlaylistType? systemType;
  final int isPublic;
  final int playCount;
  final int itemCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Playlist({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    required this.type,
    this.systemType,
    this.isPublic = 0,
    this.playCount = 0,
    this.itemCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      type: json['type'] == 'system' ? PlaylistType.system : PlaylistType.user,
      systemType: _parseSystemType(json['system_type'] as String?),
      isPublic: json['is_public'] as int? ?? 0,
      playCount: json['play_count'] as int? ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static SystemPlaylistType? _parseSystemType(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'favorites':
        return SystemPlaylistType.favorites;
      case 'now_playing':
        return SystemPlaylistType.nowPlaying;
      default:
        return null;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  /// 是否为系统歌单
  bool get isSystem => type == PlaylistType.system;

  /// 是否为"我喜欢"歌单
  bool get isFavorites => systemType == SystemPlaylistType.favorites;

  /// 是否为"正在播放"歌单
  bool get isNowPlaying => systemType == SystemPlaylistType.nowPlaying;

  /// 是否为公开歌单
  bool get isPublicPlaylist => isPublic == 1;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      'type': type == PlaylistType.system ? 'system' : 'user',
      if (systemType != null) 'system_type': systemType?.name,
      'is_public': isPublic,
    };
  }

  Playlist copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? coverUrl,
    PlaylistType? type,
    SystemPlaylistType? systemType,
    int? isPublic,
    int? playCount,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      type: type ?? this.type,
      systemType: systemType ?? this.systemType,
      isPublic: isPublic ?? this.isPublic,
      playCount: playCount ?? this.playCount,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Playlist{id: $id, name: $name, type: $type, itemCount: $itemCount}';
  }
}

/// 歌单项模型
class PlaylistItem {
  final int? id;
  final int? playlistId;
  final String bvid;
  final String? title;
  final String? artist;
  final int? duration;
  final String? coverUrl;
  final int position;
  final DateTime? addedAt;

  PlaylistItem({
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

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'] as int?,
      playlistId: json['playlist_id'] as int?,
      bvid: json['bvid'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      duration: json['duration'] as int?,
      coverUrl: json['cover_url'] as String?,
      position: json['position'] as int? ?? 0,
      addedAt: Playlist._parseDateTime(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      'bvid': bvid,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (coverUrl != null) 'cover_url': coverUrl,
      'position': position,
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

  PlaylistItem copyWith({
    int? id,
    int? playlistId,
    String? bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
    DateTime? addedAt,
  }) {
    return PlaylistItem(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'PlaylistItem{id: $id, bvid: $bvid, title: $title, position: $position}';
  }
}

/// 歌单详情（包含items）
class PlaylistDetail {
  final Playlist playlist;
  final List<PlaylistItem> items;

  PlaylistDetail({
    required this.playlist,
    this.items = const [],
  });

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List?;
    return PlaylistDetail(
      playlist: Playlist.fromJson(json),
      items: itemsJson?.map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...playlist.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PlaylistDetail{playlist: $playlist, itemsCount: ${items.length}}';
  }
}
