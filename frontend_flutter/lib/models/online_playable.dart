import 'dart:typed_data';
import 'playable_audio.dart';
import 'audio.dart';
import 'playlist.dart';
import '../core/constants/api_constants.dart';

/// 在线音频的 Playable 实现
///
/// 包装 Audio 实体，实现 PlayableAudio 接口
/// 用于统一播放列表中的在线音频播放（通过后端代理）
///
/// 迁移说明：从 just_audio 迁移到 audioplayers
/// - 移除了 AudioSource 相关代码
/// - 直接使用代理 URL 作为播放地址
class OnlinePlayable extends PlayableAudio {
  final Audio _audio;
  final String? _proxyUrl; // 后端代理URL

  OnlinePlayable(this._audio, [this._proxyUrl]);

  /// 从 Audio 创建
  factory OnlinePlayable.fromAudio(Audio audio, String? proxyUrl) {
    return OnlinePlayable(audio, proxyUrl);
  }

  /// 从 Map 创建（用于反序列化）
  ///
  /// 动态生成代理 URL，避免硬编码 IP 地址
  factory OnlinePlayable.fromMap(Map<String, dynamic> map) {
    final audio = Audio.fromDto(map);
    final audioId = audio.id;

    if (audioId.startsWith('netease_')) {
      // 网易云播放链接使用原始 streamUrl
      return OnlinePlayable(audio);
    }

    // 动态生成代理 URL，使用当前的 API 基础 URL
    // 不使用保存的旧 proxyUrl（可能包含过期的 IP 地址）
    // 使用 127.0.0.1 替代 localhost（MPV 兼容性）
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    final proxyUrl = '$baseUrl/api/v1/bilibili/proxy/audio/$audioId?format=auto';

    return OnlinePlayable(audio, proxyUrl);
  }

  @override
  String get id => _audio.id;

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
      cid: item.cid,  // 传递 cid 用于字幕加载
    );
    return OnlinePlayable.fromAudio(audio, null);
  }
}
