// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleLine _$SubtitleLineFromJson(Map<String, dynamic> json) =>
    _SubtitleLine(
      from: (json['from'] as num).toDouble(),
      to: (json['to'] as num).toDouble(),
      content: json['content'] as String,
    );

Map<String, dynamic> _$SubtitleLineToJson(_SubtitleLine instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'content': instance.content,
    };

_SubtitleTrack _$SubtitleTrackFromJson(Map<String, dynamic> json) =>
    _SubtitleTrack(
      lan: json['lan'] as String,
      lanDoc: json['lan_doc'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => SubtitleLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubtitleTrackToJson(_SubtitleTrack instance) =>
    <String, dynamic>{
      'lan': instance.lan,
      'lan_doc': instance.lanDoc,
      'lines': instance.lines,
    };

_SubtitleData _$SubtitleDataFromJson(Map<String, dynamic> json) =>
    _SubtitleData(
      bvid: json['bvid'] as String,
      cid: (json['cid'] as num).toInt(),
      subtitles: (json['subtitles'] as List<dynamic>)
          .map((e) => SubtitleTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      needLogin: json['need_login'] as bool? ?? false,
    );

Map<String, dynamic> _$SubtitleDataToJson(_SubtitleData instance) =>
    <String, dynamic>{
      'bvid': instance.bvid,
      'cid': instance.cid,
      'subtitles': instance.subtitles,
      'need_login': instance.needLogin,
    };
