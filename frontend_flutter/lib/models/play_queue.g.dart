// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayQueue _$PlayQueueFromJson(Map<String, dynamic> json) => _PlayQueue(
  tracks: (json['tracks'] as List<dynamic>)
      .map(
        (e) =>
            const PlayableAudioConverter().fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  currentIndex: (json['currentIndex'] as num).toInt(),
  playMode:
      $enumDecodeNullable(_$PlayModeEnumMap, json['playMode']) ??
      PlayMode.sequence,
  shuffleOrder:
      (json['shuffleOrder'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  source: json['source'] == null
      ? null
      : QueueSource.fromJson(json['source'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlayQueueToJson(
  _PlayQueue instance,
) => <String, dynamic>{
  'tracks': instance.tracks.map(const PlayableAudioConverter().toJson).toList(),
  'currentIndex': instance.currentIndex,
  'playMode': _$PlayModeEnumMap[instance.playMode]!,
  'shuffleOrder': instance.shuffleOrder,
  'source': instance.source,
};

const _$PlayModeEnumMap = {
  PlayMode.sequence: 'sequence',
  PlayMode.loopAll: 'loopAll',
  PlayMode.shuffle: 'shuffle',
  PlayMode.loopOne: 'loopOne',
};
