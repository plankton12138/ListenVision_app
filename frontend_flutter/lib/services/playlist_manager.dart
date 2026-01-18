import 'package:demo/models/audio_model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 播放列表管理器
///
/// 负责管理本地播放列表数据库，使用 SQLite 存储
class PlaylistManager {
  static final PlaylistManager _databaseHandler = PlaylistManager._internal();
  factory PlaylistManager() => _databaseHandler;
  static Database? _database;

  PlaylistManager._internal();

  /// 获取数据库实例（单例模式）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('数据库路径: $directory');
    final path = join(directory.path, 'playlist.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建播放列表表
        await db.execute('''
          CREATE TABLE playlist_audios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE,
            title TEXT,
            artist TEXT,
            duration INTEGER,
            albumArt BLOB,
            url TEXT,
            isFavorite INTEGER
          )
        ''');
      },
    );
  }

  // ==================== 音频表操作 ====================

  /// 插入音频记录到播放列表
  ///
  /// 返回插入记录的ID，如果文件已存在则返回 -1
  Future<int> insertAudio(Audio audio) async {
    final db = await database;
    try {
      return await db.insert('playlist_audios', audio.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return -1; // 文件已存在
      }
      rethrow;
    }
  }

  /// 获取所有音频记录
  Future<List<Audio>> getAllAudios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlist_audios', orderBy: 'id ASC');
    return List.generate(maps.length, (i) => Audio.fromMap(maps[i]));
  }

  /// 删除指定ID的音频记录
  Future<int> deleteAudio(int id) async {
    final db = await database;
    return await db.delete('playlist_audios', where: 'id = ?', whereArgs: [id]);
  }
}
