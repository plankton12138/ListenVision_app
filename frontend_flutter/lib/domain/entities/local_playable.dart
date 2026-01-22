import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'playable_audio.dart';
import 'local_audio.dart';

/// 本地音频的 Playable 实现
///
/// 包装 LocalAudio 实体，实现 PlayableAudio 接口
/// 用于统一播放列表中的本地音频播放
class LocalPlayable extends PlayableAudio {
  final LocalAudio _audio;

  LocalPlayable(this._audio);

  /// 从 LocalAudio 创建
  factory LocalPlayable.fromAudio(LocalAudio audio) {
    return LocalPlayable(audio);
  }

  /// 从 Map 创建（用于反序列化）
  factory LocalPlayable.fromMap(Map<String, dynamic> map) {
    final audio = LocalAudio.fromMap(map);
    return LocalPlayable(audio);
  }

  @override
  String get id => 'local_${_audio.id ?? _audio.filePath.hashCode}';

  @override
  String get title => _audio.title;

  @override
  String? get artist => _audio.artist;

  @override
  String? get coverUrl => _audio.url; // 来源URL（如B站）

  @override
  Uint8List? get coverData => _audio.albumArt;

  @override
  int? get duration => _audio.duration;

  @override
  bool get isOnline => false;

  @override
  AudioSource get audioSource => AudioSource.uri(
        Uri.file(_audio.filePath),
        tag: _audio.title,
      );

  @override
  String get url => _audio.filePath;

  @override
  String get shareableUrl => _audio.filePath;

  @override
  Map<String, dynamic> toMap() {
    return {
      ..._audio.toMap(),
      'playableType': 'local',
    };
  }

  /// 获取原始 LocalAudio
  LocalAudio get original => _audio;
}
