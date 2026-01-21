// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaylistImpl _$$PlaylistImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistImpl(
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

Map<String, dynamic> _$$PlaylistImplToJson(_$PlaylistImpl instance) =>
    <String, dynamic>{
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

_$PlaylistItemImpl _$$PlaylistItemImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistItemImpl(
      id: json['id'] as String?,
      playlistId: json['playlistId'] as String?,
      bvid: json['bvid'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      coverUrl: json['coverUrl'] as String?,
      position: (json['position'] as num).toInt(),
      addedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$$PlaylistItemImplToJson(_$PlaylistItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playlistId': instance.playlistId,
      'bvid': instance.bvid,
      'title': instance.title,
      'artist': instance.artist,
      'duration': instance.duration,
      'coverUrl': instance.coverUrl,
      'position': instance.position,
      'addedAt': instance.addedAt?.toIso8601String(),
    };

_$PlaylistDetailImpl _$$PlaylistDetailImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistDetailImpl(
      playlist: Playlist.fromJson(json['playlist'] as Map<String, dynamic>),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlaylistDetailImplToJson(
  _$PlaylistDetailImpl instance,
) => <String, dynamic>{'playlist': instance.playlist, 'items': instance.items};
