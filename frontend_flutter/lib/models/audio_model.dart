import 'dart:typed_data';

/// 音频模型
///
/// 用于表示音频文件及其元数据，支持从数据库序列化/反序列化
class Audio {
  final int? id;
  final String filePath;
  final String title;
  final String artist;
  final int duration;
  final Uint8List? albumArt;
  final String? url; // 来源URL（如B站视频地址）
  bool isFavorite; // 是否收藏

  Audio({
    this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArt,
    this.url,
    this.isFavorite = false, // 默认未收藏
  });

  /// 复制并修改部分字段
  Audio copyWith({
    String? filePath,
    String? title,
    String? artist,
    int? duration,
    Uint8List? albumArt,
    String? url,
    bool? isFavorite,
  }) {
    return Audio(
      id: id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      url: url ?? this.url,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'albumArt': albumArt,
      'url': url,
      'isFavorite': isFavorite ? 1 : 0, // 数据库中用 1 表示收藏，0 表示未收藏
    };
  }

  /// 从Map创建Audio实例（数据库反序列化）
  factory Audio.fromMap(Map<String, dynamic> map) {
    // 处理 albumArt BLOB 类型转换
    Uint8List? albumArtData;
    if (map['albumArt'] != null) {
      if (map['albumArt'] is Uint8List) {
        albumArtData = map['albumArt'] as Uint8List;
      } else if (map['albumArt'] is List) {
        albumArtData = Uint8List.fromList(map['albumArt'] as List<int>);
      }
    }

    return Audio(
      id: map['id'],
      filePath: map['filePath'] ?? '',
      title: map['title'] ?? '未知标题',
      artist: map['artist'] ?? '未知艺术家',
      duration: map['duration'] ?? 0,
      albumArt: albumArtData,
      url: map['url'],
      isFavorite: map['isFavorite'] == 1, // 从数据库读取时转换为布尔值
    );
  }
}
