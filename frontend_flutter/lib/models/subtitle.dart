import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle.freezed.dart';
part 'subtitle.g.dart';

/// 单条字幕行
@freezed
class SubtitleLine with _$SubtitleLine {
  const factory SubtitleLine({
    required double from,       // 起始时间（秒）
    required double to,         // 结束时间（秒）
    required String content,    // 字幕文本
  }) = _SubtitleLine;

  factory SubtitleLine.fromJson(Map<String, dynamic> json) =>
      _$SubtitleLineFromJson(json);
}

/// 单语言字幕数据
@freezed
class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    required String lan,        // 语言代码 (zh-Hans, en-US)
    @JsonKey(name: 'lan_doc') required String lanDoc,     // 语言名称 (中文（简体）)
    required List<SubtitleLine> lines,
  }) = _SubtitleTrack;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackFromJson(json);
}

/// 视频字幕响应
@freezed
class SubtitleData with _$SubtitleData {
  const factory SubtitleData({
    required String bvid,
    required int cid,
    required List<SubtitleTrack> subtitles,
  }) = _SubtitleData;

  factory SubtitleData.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDataFromJson(json);
}
