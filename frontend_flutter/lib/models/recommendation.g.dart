// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    _Recommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      duration: json['duration'] as String?,
      artist: json['artist'] as String?,
      playCount: (json['playCount'] as num?)?.toInt(),
      url: json['url'] as String?,
      type:
          $enumDecodeNullable(_$RecommendationTypeEnumMap, json['type']) ??
          RecommendationType.video,
    );

Map<String, dynamic> _$RecommendationToJson(_Recommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'duration': instance.duration,
      'artist': instance.artist,
      'playCount': instance.playCount,
      'url': instance.url,
      'type': _$RecommendationTypeEnumMap[instance.type]!,
    };

const _$RecommendationTypeEnumMap = {
  RecommendationType.video: 'video',
  RecommendationType.playlist: 'playlist',
};

_BiliPlaylist _$BiliPlaylistFromJson(Map<String, dynamic> json) =>
    _BiliPlaylist(
      menuId: (json['menuId'] as num).toInt(),
      uid: (json['uid'] as num?)?.toInt(),
      uploader: json['uploader'] as String?,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      intro: json['intro'] as String?,
      type: (json['type'] as num?)?.toInt(),
      songCount: (json['songCount'] as num?)?.toInt() ?? 0,
      stats: BiliPlaylistStats.fromJson(json['stats'] as Map<String, dynamic>),
      previews:
          (json['previews'] as List<dynamic>?)
              ?.map((e) => BiliAudioPreview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BiliPlaylistToJson(_BiliPlaylist instance) =>
    <String, dynamic>{
      'menuId': instance.menuId,
      'uid': instance.uid,
      'uploader': instance.uploader,
      'title': instance.title,
      'coverUrl': instance.coverUrl,
      'intro': instance.intro,
      'type': instance.type,
      'songCount': instance.songCount,
      'stats': instance.stats,
      'previews': instance.previews,
    };

_BiliPlaylistStats _$BiliPlaylistStatsFromJson(Map<String, dynamic> json) =>
    _BiliPlaylistStats(
      play: (json['play'] as num?)?.toInt() ?? 0,
      collect: (json['collect'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BiliPlaylistStatsToJson(_BiliPlaylistStats instance) =>
    <String, dynamic>{
      'play': instance.play,
      'collect': instance.collect,
      'comment': instance.comment,
    };

_BiliAudioPreview _$BiliAudioPreviewFromJson(Map<String, dynamic> json) =>
    _BiliAudioPreview(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      duration: (json['duration'] as num?)?.toInt(),
      coverUrl: json['coverUrl'] as String?,
    );

Map<String, dynamic> _$BiliAudioPreviewToJson(_BiliAudioPreview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'duration': instance.duration,
      'coverUrl': instance.coverUrl,
    };

_RecommendationResponse _$RecommendationResponseFromJson(
  Map<String, dynamic> json,
) => _RecommendationResponse(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  total: (json['total'] as num?)?.toInt() ?? 0,
  source: json['source'] as String?,
);

Map<String, dynamic> _$RecommendationResponseToJson(
  _RecommendationResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'page': instance.page,
  'pageSize': instance.pageSize,
  'total': instance.total,
  'source': instance.source,
};

_PersonalizedResponse _$PersonalizedResponseFromJson(
  Map<String, dynamic> json,
) => _PersonalizedResponse(
  source: json['source'] as String,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  videos:
      (json['videos'] as List<dynamic>?)
          ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  playlists:
      (json['playlists'] as List<dynamic>?)
          ?.map((e) => BiliPlaylist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PersonalizedResponseToJson(
  _PersonalizedResponse instance,
) => <String, dynamic>{
  'source': instance.source,
  'keywords': instance.keywords,
  'videos': instance.videos,
  'playlists': instance.playlists,
};
