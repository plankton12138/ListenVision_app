import 'dart:typed_data';

class Audio {
  final int? id;
  final String filePath;
  final String title;
  final String artist;
  final int duration;
  final Uint8List? albumArt;
  final String? url; // 新增字段
  bool isFavorite; // 新增字段

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

  factory Audio.fromMap(Map<String, dynamic> map) {
    return Audio(
      id: map['id'],
      filePath: map['filePath'],
      title: map['title'],
      artist: map['artist'],
      duration: map['duration'],
      albumArt: map['albumArt'],
      url: map['url'],
      isFavorite: map['isFavorite'] == 1, // 从数据库读取时转换为布尔值
    );
  }
}