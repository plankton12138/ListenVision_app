// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AudioImpl _$$AudioImplFromJson(Map<String, dynamic> json) => _$AudioImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String?,
  album: json['album'] as String?,
  coverUrl: json['coverUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  description: json['description'] as String?,
  playCount: (json['playCount'] as num?)?.toInt(),
  uploader: json['uploader'] as String?,
  uploaderMid: json['uploaderMid'] as String?,
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$AudioImplToJson(_$AudioImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'coverUrl': instance.coverUrl,
      'streamUrl': instance.streamUrl,
      'duration': instance.duration,
      'description': instance.description,
      'playCount': instance.playCount,
      'uploader': instance.uploader,
      'uploaderMid': instance.uploaderMid,
      'publishedAt': instance.publishedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
