// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayHistoryImpl _$$PlayHistoryImplFromJson(Map<String, dynamic> json) =>
    _$PlayHistoryImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      audio: Audio.fromJson(json['audio'] as Map<String, dynamic>),
      playedAt: DateTime.parse(json['playedAt'] as String),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PlayHistoryImplToJson(_$PlayHistoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'audio': instance.audio,
      'playedAt': instance.playedAt.toIso8601String(),
      'progress': instance.progress,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$PlayHistoryStatsImpl _$$PlayHistoryStatsImplFromJson(
  Map<String, dynamic> json,
) => _$PlayHistoryStatsImpl(
  totalPlays: (json['totalPlays'] as num?)?.toInt() ?? 0,
  lastPlayed: json['lastPlayed'] == null
      ? null
      : PlayHistory.fromJson(json['lastPlayed'] as Map<String, dynamic>),
  uniqueTracks: (json['uniqueTracks'] as num?)?.toInt() ?? 0,
  totalDuration: (json['totalDuration'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$PlayHistoryStatsImplToJson(
  _$PlayHistoryStatsImpl instance,
) => <String, dynamic>{
  'totalPlays': instance.totalPlays,
  'lastPlayed': instance.lastPlayed,
  'uniqueTracks': instance.uniqueTracks,
  'totalDuration': instance.totalDuration,
};
