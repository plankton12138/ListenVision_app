import 'dart:typed_data';

/// 可播放音频统一接口
///
/// 使用 Strategy 模式统一本地音频和在线音频的播放接口
/// 支持混合播放列表，在线和本地音频可在同一列表中播放
///
/// 迁移说明：从 just_audio 迁移到 audioplayers
/// - 移除了 AudioSource 相关方法
/// - 使用 url 属性直接传递音频路径/URL
abstract class PlayableAudio {
  /// 音频唯一标识
  String get id;

  /// 显示标题
  String get title;

  /// 艺术家
  String? get artist;

  /// 封面URL（在线音频）
  String? get coverUrl;

  /// 封面数据（本地音频）
  Uint8List? get coverData;

  /// 时长（秒）
  int? get duration;

  /// 是否为在线音频
  bool get isOnline;

  /// 获取音频 URL 或文件路径（用于 audioplayers）
  ///
  /// 多态核心方法：
  /// - LocalPlayable 返回本地文件路径
  /// - OnlinePlayable 返回网络 URL
  String get url;

  /// 转换为 Map（用于序列化）
  Map<String, dynamic> toMap();

  /// 格式化时长（mm:ss 或 hh:mm:ss）
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:'
          '${mins.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
