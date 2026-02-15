import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_logger.dart';
import '../../models/local_audio.dart';

/// 本地音乐数据库
///
/// 使用 SQLite 存储本地音乐歌单的元数据
class LocalMusicDatabase {
  static final LocalMusicDatabase instance = LocalMusicDatabase._init();
  static Database? _database;

  LocalMusicDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('local_music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    AppLogger.info('LocalMusicDatabase', '数据库路径: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const intType = 'INTEGER';
    const blobType = 'BLOB';

    await db.execute('''
      CREATE TABLE local_music (
        id $idType,
        file_path $textType UNIQUE,
        title $textType,
        artist $textType,
        duration $intType,
        album_art $blobType,
        url $textNullableType,
        is_favorite $intType DEFAULT 0,
        added_at $textType
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_local_music_title ON local_music(title)
    ''');
    await db.execute('''
      CREATE INDEX idx_local_music_artist ON local_music(artist)
    ''');

    AppLogger.info('LocalMusicDatabase', '数据库表创建完成');
  }

  /// 插入音乐项
  Future<int> insertItem(LocalAudio audio) async {
    final db = await database;
    
    final data = {
      'file_path': audio.filePath,
      'title': audio.title,
      'artist': audio.artist,
      'duration': audio.duration,
      'album_art': audio.albumArt,
      'url': audio.url,
      'is_favorite': audio.isFavorite ? 1 : 0,
      'added_at': DateTime.now().toIso8601String(),
    };

    try {
      final id = await db.insert('local_music', data);
      AppLogger.info('LocalMusicDatabase', '插入音乐项: $id - ${audio.title}');
      return id;
    } catch (e) {
      AppLogger.error('LocalMusicDatabase', '插入音乐项失败: $e');
      rethrow;
    }
  }

  /// 获取所有音乐项
  Future<List<LocalAudio>> getAllItems() async {
    final db = await database;
    final maps = await db.query(
      'local_music',
      orderBy: 'added_at DESC',
    );
    
    return maps.map((m) => _mapToLocalAudio(m)).toList();
  }

  /// 根据 ID 获取音乐项
  Future<LocalAudio?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query(
      'local_music',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return _mapToLocalAudio(maps.first);
    }
    return null;
  }

  /// 根据文件路径检查是否已存在
  Future<bool> existsByFilePath(String filePath) async {
    final db = await database;
    final maps = await db.query(
      'local_music',
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 删除音乐项
  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete(
      'local_music',
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('LocalMusicDatabase', '删除音乐项: $id');
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'local_music',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取收藏列表
  Future<List<LocalAudio>> getFavorites() async {
    final db = await database;
    final maps = await db.query(
      'local_music',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'added_at DESC',
    );
    
    return maps.map((m) => _mapToLocalAudio(m)).toList();
  }

  /// 搜索音乐
  Future<List<LocalAudio>> search(String keyword) async {
    final db = await database;
    final maps = await db.query(
      'local_music',
      where: 'title LIKE ? OR artist LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'added_at DESC',
    );
    
    return maps.map((m) => _mapToLocalAudio(m)).toList();
  }

  /// 获取总数
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM local_music');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Map 转换为 LocalAudio
  LocalAudio _mapToLocalAudio(Map<String, dynamic> map) {
    Uint8List? albumArtData;
    if (map['album_art'] != null) {
      if (map['album_art'] is Uint8List) {
        albumArtData = map['album_art'] as Uint8List;
      } else if (map['album_art'] is List) {
        final list = map['album_art'] as List;
        albumArtData = Uint8List.fromList(list.cast<int>());
      }
    }

    return LocalAudio(
      id: map['id'] as int?,
      filePath: map['file_path'] ?? '',
      title: map['title'] ?? '未知标题',
      artist: map['artist'] ?? '未知艺术家',
      duration: map['duration'] ?? 0,
      albumArt: albumArtData,
      url: map['url'],
      isFavorite: map['is_favorite'] == 1,
    );
  }
}
