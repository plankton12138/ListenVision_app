import 'dart:typed_data';

/// 本地音频实体
///
/// 用于表示本地导入的音频文件及其元数据
/// 与 domain/entities/audio.dart（在线音频）区分使用
class LocalAudio {
  final int? id;
  final String filePath;
  final String? albumTitle;
  final String title;
  final String artist;
  final int duration;
  final Uint8List? albumArt;
  final String? url; // 来源URL（如B站视频地址）
  bool isFavorite; // 是否收藏

  LocalAudio({
    this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    this.albumTitle,
    required this.duration,
    this.albumArt,
    this.url,
    this.isFavorite = false,
  });

  /// 复制并修改部分字段
  LocalAudio copyWith({
    int? id,
    String? filePath,
    String? title,
    String? artist,
    int? duration,
    Uint8List? albumArt,
    String? url,
    bool? isFavorite,
    String? albumTitle,
  }) {
    return LocalAudio(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      url: url ?? this.url,
      isFavorite: isFavorite ?? this.isFavorite,
      albumTitle: albumTitle ?? this.albumTitle,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'duration': duration,
      if (albumTitle != null) 'albumTitle': albumTitle,
      'albumArt': albumArt,
      'url': url,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// 从Map创建实例（数据库反序列化）
  factory LocalAudio.fromMap(Map<String, dynamic> map) {
    Uint8List? albumArtData;
    if (map['albumArt'] != null) {
      if (map['albumArt'] is Uint8List) {
        albumArtData = map['albumArt'] as Uint8List;
      } else if (map['albumArt'] is List) {
        // 从 JSON 反序列化后是 List<dynamic>，需要安全转换为 List<int>
        final list = map['albumArt'] as List;
        albumArtData = Uint8List.fromList(list.cast<int>());
      }
    }

    return LocalAudio(
      id: map['id'],
      filePath: map['filePath'] ?? '',
      title: map['title'] ?? '未知标题',
      artist: map['artist'] ?? '未知艺术家',
      duration: map['duration'] ?? 0,
      albumTitle: map['albumTitle'] as String?,
      albumArt: albumArtData,
      url: map['url'],
      isFavorite: map['isFavorite'] == 1,
    );
  }
}
