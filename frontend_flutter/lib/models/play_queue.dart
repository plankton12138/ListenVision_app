import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/playable_audio_converter.dart';
import 'playable_audio.dart';
import 'play_mode.dart';
import 'queue_source.dart';

part 'play_queue.freezed.dart';
part 'play_queue.g.dart';

/// 播放队列
///
/// 独立于歌单体系的播放队列模型，管理当前播放的曲目列表和播放状态
/// 包含当前索引、播放模式、随机顺序和队列来源
@freezed
class PlayQueue with _$PlayQueue {
  const factory PlayQueue({
    /// 曲目列表
    @PlayableAudioConverter() required List<PlayableAudio> tracks,

    /// 当前播放索引
    required int currentIndex,

    /// 播放模式，默认为顺序播放
    @Default(PlayMode.sequence) PlayMode playMode,

    /// 随机播放顺序
    @Default([]) List<int> shuffleOrder,

    /// 队列来源（从哪里发起的播放）
    QueueSource? source,
  }) = _PlayQueue;

  /// 从 JSON 创建
  factory PlayQueue.fromJson(Map<String, dynamic> json) =>
      _$PlayQueueFromJson(json);
}
