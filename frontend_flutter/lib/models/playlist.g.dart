// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Playlist _$PlaylistFromJson(Map<String, dynamic> json) => _Playlist(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  type: $enumDecode(_$PlaylistTypeEnumMap, json['type']),
  systemType: $enumDecodeNullable(
    _$SystemPlaylistTypeEnumMap,
    json['systemType'],
  ),
  isPublic: json['isPublic'] as bool? ?? false,
  playCount: (json['playCount'] as num?)?.toInt() ?? 0,
  itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PlaylistToJson(_Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'type': _$PlaylistTypeEnumMap[instance.type]!,
  'systemType': _$SystemPlaylistTypeEnumMap[instance.systemType],
  'isPublic': instance.isPublic,
  'playCount': instance.playCount,
  'itemCount': instance.itemCount,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$PlaylistTypeEnumMap = {
  PlaylistType.system: 'system',
  PlaylistType.user: 'user',
};

const _$SystemPlaylistTypeEnumMap = {
  SystemPlaylistType.favorites: 'favorites',
  SystemPlaylistType.nowPlaying: 'now_playing',
};

_PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) =>
    _PlaylistItem(
      id: json['id'] as String?,
      playlistId: json['playlistId'] as String?,
      bvid: json['bvid'] as String,
      cid: (json['cid'] as num?)?.toInt(),
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      coverUrl: json['coverUrl'] as String?,
      localPath: json['localPath'] as String?,
      position: (json['position'] as num).toInt(),
      addedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$PlaylistItemToJson(_PlaylistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playlistId': instance.playlistId,
      'bvid': instance.bvid,
      'cid': instance.cid,
      'title': instance.title,
      'artist': instance.artist,
      'duration': instance.duration,
      'coverUrl': instance.coverUrl,
      'localPath': instance.localPath,
      'position': instance.position,
      'addedAt': instance.addedAt?.toIso8601String(),
    };

_PlaylistDetail _$PlaylistDetailFromJson(Map<String, dynamic> json) =>
    _PlaylistDetail(
      playlist: Playlist.fromJson(json['playlist'] as Map<String, dynamic>),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlaylistDetailToJson(_PlaylistDetail instance) =>
    <String, dynamic>{'playlist': instance.playlist, 'items': instance.items};
