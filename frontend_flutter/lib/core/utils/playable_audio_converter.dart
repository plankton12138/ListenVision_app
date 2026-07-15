import 'package:json_annotation/json_annotation.dart';
import '../../models/playable_audio.dart';
import '../../models/local_playable.dart';
import '../../models/online_playable.dart';

/// PlayableAudio 多态 JSON 转换器
///
/// 用于 json_serializable 在序列化/反序列化时处理 PlayableAudio 的多态问题
/// 通过 playableType 字段区分 local / online 两种具体类型：
/// - 'local' -> LocalPlayable
/// - 'online' -> OnlinePlayable
class PlayableAudioConverter
    implements JsonConverter<PlayableAudio, Map<String, dynamic>> {
  const PlayableAudioConverter();

  @override
  PlayableAudio fromJson(Map<String, dynamic> json) {
    final type = json['playableType'] as String?;
    switch (type) {
      case 'local':
        return LocalPlayable.fromMap(json);
      case 'online':
        return OnlinePlayable.fromMap(json);
      default:
        throw ArgumentError('Unknown PlayableAudio type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(PlayableAudio data) {
    return data.toMap();
  }
}
