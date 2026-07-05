import 'dart:typed_data';
import 'playable_audio.dart';
import 'audio.dart';
import 'playlist.dart';

/// 在线音频的 Playable 实现
///
/// 包装 Audio 实体，实现 PlayableAudio 接口
/// 用于统一播放列表中的在线音频播放（通过后端代理）
///
/// 迁移说明：从 just_audio 迁移到 media_kit
/// - 支持自定义 HTTP 请求头（httpHeaders），解决 B站CDN防盗链问题
/// - 移除了 AudioSource 相关代码
class OnlinePlayable extends PlayableAudio {
  final Audio _audio;
  final String? _proxyUrl; // 后端代理URL
  final Map<String, String>? httpHeaders; // 自定义HTTP请求头

  OnlinePlayable(this._audio, [this._proxyUrl, this.httpHeaders]);

  /// 从 Audio 创建
  factory OnlinePlayable.withProxyUrl(Audio audio) {
    return OnlinePlayable(audio);
  }

  /// 从 Audio 创建
  factory OnlinePlayable.fromAudio(Audio audio, String? proxyUrl) {
    return OnlinePlayable(audio, proxyUrl);
  }

  /// 从 Map 创建（用于反序列化）
  factory OnlinePlayable.fromMap(Map<String, dynamic> map) {
    final audio = Audio.fromDto(map);
    return OnlinePlayable(audio);
  }

  @override
  String get id => _audio.cid != null ? '${_audio.id}_${_audio.cid}' : _audio.id;

  @override
  String get title => _audio.title;

  @override
  String? get artist => _audio.artist;

  @override
  String? get coverUrl => _audio.coverUrl;

  @override
  Uint8List? get coverData => null; // 在线封面不缓存，按需加载

  @override
  int? get duration => _audio.duration;

  @override
  bool get isOnline => true;

  @override
  String get url {
    // 优先使用代理URL，其次使用原始streamUrl
    return _proxyUrl ?? _audio.streamUrl ?? '';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ..._audio.toDto(),
      'proxyUrl': _proxyUrl,
      'playableType': 'online',
    };
  }

  /// 获取原始 Audio
  Audio get original => _audio;

  /// 获取代理URL
  String? get proxyUrl => _proxyUrl;

  /// 获取实际的播放URL
  String? get effectiveUrl => _proxyUrl ?? _audio.streamUrl;

  /// 从 PlaylistItem 创建
  factory OnlinePlayable.fromPlaylistItem(PlaylistItem item) {
    final audio = Audio(
      id: item.bvid,
      title: item.title ?? '未知标题',
      artist: item.artist,
      duration: item.duration,
      coverUrl: item.coverUrl,
      streamUrl: null,
      cid: item.cid,
    );
    return OnlinePlayable.fromAudio(audio, null);
  }
}
