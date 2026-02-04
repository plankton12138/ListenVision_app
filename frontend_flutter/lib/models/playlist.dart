import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

/// 歌单类型枚举
enum PlaylistType {
  @JsonValue('system')
  system,
  @JsonValue('user')
  user,
}

/// 系统歌单类型枚举
enum SystemPlaylistType {
  @JsonValue('favorites')
  favorites,
  @JsonValue('now_playing')
  nowPlaying,
}

/// 歌单实体
@freezed
class Playlist with _$Playlist {
  const Playlist._();

  const factory Playlist({
    required String id,
    required String userId,
    required String name,
    String? description,
    String? coverUrl,
    required PlaylistType type,
    SystemPlaylistType? systemType,
    @Default(false) bool isPublic,
    @Default(0) int playCount,
    @Default(0) int itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Playlist;

  /// 从 JSON 创建
  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

  /// 从 DTO/后端响应创建（兼容旧格式）
  factory Playlist.fromDto(Map<String, dynamic> json) {
    return Playlist(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? json['desc'] as String?,
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
      type: _parseType(json['type'] as String?),
      systemType: _parseSystemType(json['system_type'] as String?),
      isPublic: (json['is_public'] as int? ?? 0) == 1,
      playCount: json['play_count'] as int? ?? json['playCount'] as int? ?? 0,
      itemCount: json['item_count'] as int? ?? json['itemCount'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// 是否为系统歌单
  bool get isSystem => type == PlaylistType.system;

  /// 是否为用户歌单
  bool get isUserPlaylist => type == PlaylistType.user;

  /// 是否为"我喜欢"歌单
  bool get isFavorites => systemType == SystemPlaylistType.favorites;

  /// 是否为"正在播放"歌单
  bool get isNowPlaying => systemType == SystemPlaylistType.nowPlaying;

  /// 是否有封面
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 是否有描述
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// 转换为后端格式
  Map<String, dynamic> toDto() {
    return {
      'id': int.tryParse(id) ?? id,
      'user_id': int.tryParse(userId) ?? userId,
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      'type': type == PlaylistType.system ? 'system' : 'user',
      if (systemType != null) 'system_type': systemType?.name,
      'is_public': isPublic ? 1 : 0,
    };
  }

  /// 解析歌单类型
  static PlaylistType _parseType(String? value) {
    if (value == 'system') return PlaylistType.system;
    return PlaylistType.user;
  }

  /// 解析系统歌单类型
  static SystemPlaylistType? _parseSystemType(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'favorites':
        return SystemPlaylistType.favorites;
      case 'now_playing':
      case 'nowPlaying':
        return SystemPlaylistType.nowPlaying;
      default:
        return null;
    }
  }

  /// 解析 DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  /// 创建"我喜欢"系统歌单
  static const favorites = Playlist(
    id: '1',
    userId: '0',
    name: '我喜欢',
    type: PlaylistType.system,
    systemType: SystemPlaylistType.favorites,
  );

  /// 创建"正在播放"系统歌单
  static const nowPlaying = Playlist(
    id: '2',
    userId: '0',
    name: '正在播放',
    type: PlaylistType.system,
    systemType: SystemPlaylistType.nowPlaying,
  );
}

/// 歌单项实体
@freezed
class PlaylistItem with _$PlaylistItem {
  const PlaylistItem._();

  const factory PlaylistItem({
    String? id,
    String? playlistId,
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
    required int position,
    DateTime? addedAt,
  }) = _PlaylistItem;

  /// 从 JSON 创建
  factory PlaylistItem.fromJson(Map<String, dynamic> json) => _$PlaylistItemFromJson(json);

  /// 从 DTO 创建
  factory PlaylistItem.fromDto(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id']?.toString(),
      playlistId: json['playlist_id']?.toString() ?? json['playlistId']?.toString(),
      bvid: json['bvid'] as String? ?? '',
      title: json['title'] as String?,
      artist: json['artist'] as String? ?? json['author'] as String?,
      duration: json['duration'] as int?,
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
      localPath: json['local_path'] as String? ?? json['localPath'] as String?,
      position: json['position'] as int? ?? 0,
      addedAt: Playlist._parseDateTime(json['added_at'] ?? json['addedAt']),
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

  /// 是否有封面
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 是否有标题
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// 是否有艺术家
  bool get hasArtist => artist != null && artist!.isNotEmpty;

  /// 转换为 DTO
  Map<String, dynamic> toDto() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      if (playlistId != null) 'playlist_id': int.tryParse(playlistId!) ?? playlistId,
      'bvid': bvid,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (localPath != null) 'local_path': localPath,
      'position': position,
    };
  }
}

/// 歌单详情（包含items）
@freezed
class PlaylistDetail with _$PlaylistDetail {
  const factory PlaylistDetail({
    required Playlist playlist,
    @Default([]) List<PlaylistItem> items,
  }) = _PlaylistDetail;

  /// 从 JSON 创建
  factory PlaylistDetail.fromJson(Map<String, dynamic> json) => _$PlaylistDetailFromJson(json);

  /// 从 DTO 创建
  factory PlaylistDetail.fromDto(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List?;
    return PlaylistDetail(
      playlist: Playlist.fromDto(json),
      items: itemsJson
          ?.map((item) => PlaylistItem.fromDto(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// PlaylistDetail 扩展
extension PlaylistDetailExtension on PlaylistDetail {
  /// 转换为 DTO
  Map<String, dynamic> toDto() {
    return {
      ...playlist.toDto(),
      'items': items.map((item) => item.toDto()).toList(),
    };
  }
}
