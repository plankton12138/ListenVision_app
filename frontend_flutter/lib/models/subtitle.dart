import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle.freezed.dart';
part 'subtitle.g.dart';

/// 单条字幕行
@freezed
abstract class SubtitleLine with _$SubtitleLine {
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
abstract class SubtitleTrack with _$SubtitleTrack {
  const SubtitleTrack._();

  const factory SubtitleTrack({
    required String lan,        // 语言代码 (zh-Hans, en-US, ai-zh)
    @JsonKey(name: 'lan_doc') required String lanDoc,  // 语言名称 (中文（简体）)
    required List<SubtitleLine> lines,
  }) = _SubtitleTrack;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackFromJson(json);

  /// 是否为 AI 生成的字幕
  bool get isAiGenerated => lan.startsWith('ai-');

  /// 显示名称（区分 AI 字幕）
  String get displayName => isAiGenerated ? '$lanDoc（AI）' : lanDoc;
}

/// 视频字幕响应
@freezed
abstract class SubtitleData with _$SubtitleData {
  const factory SubtitleData({
    required String bvid,
    required int cid,
    required List<SubtitleTrack> subtitles,
    @JsonKey(name: 'need_login') @Default(false) bool needLogin,  // 是否需要登录才能获取字幕
  }) = _SubtitleData;

  factory SubtitleData.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDataFromJson(json);
}
