import 'package:demo/models/audio_model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 播放列表管理器
///
/// 负责管理本地播放列表数据库，使用 SQLite 存储
/// Phase 2A: 新增播放状态持久化功能
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
      version: 2, // Phase 2A: 版本升级，添加 playback_state 表
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
        // Phase 2A: 创建播放状态表
        await db.execute('''
          CREATE TABLE playback_state (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            audio_id INTEGER NOT NULL,
            position INTEGER NOT NULL DEFAULT 0,
            current_index INTEGER NOT NULL DEFAULT -1,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (audio_id) REFERENCES playlist_audios(id) ON DELETE CASCADE
          )
        ''');
        debugPrint('【PlaylistManager】数据库初始化完成 (version $version)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('【PlaylistManager】数据库升级: $oldVersion -> $newVersion');
        if (oldVersion < 2) {
          // Phase 2A: 添加 playback_state 表
          await db.execute('''
            CREATE TABLE IF NOT EXISTS playback_state (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              audio_id INTEGER NOT NULL,
              position INTEGER NOT NULL DEFAULT 0,
              current_index INTEGER NOT NULL DEFAULT -1,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (audio_id) REFERENCES playlist_audios(id) ON DELETE CASCADE
            )
          ''');
        }
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

  // ==================== Phase 2A: 播放状态操作 ====================

  /// 保存播放状态
  ///
  /// 保存当前播放的音频ID、播放位置和索引
  Future<void> savePlaybackState({
    required int audioId,
    required int position,
    required int currentIndex,
  }) async {
    final db = await database;
    try {
      await db.insert(
        'playback_state',
        {
          'audio_id': audioId,
          'position': position,
          'current_index': currentIndex,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('【PlaylistManager】播放状态已保存: audioId=$audioId, position=$position, index=$currentIndex');
    } catch (e) {
      debugPrint('【PlaylistManager】保存播放状态失败: $e');
    }
  }

  /// 获取最近的播放状态
  ///
  /// 返回最新的播放状态记录，如果没有则返回 null
  Future<Map<String, dynamic>?> getPlaybackState() async {
    final db = await database;
    try {
      final results = await db.query(
        'playback_state',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      if (results.isNotEmpty) {
        debugPrint('【PlaylistManager】找到播放状态: ${results.first}');
        return results.first;
      }
      debugPrint('【PlaylistManager】没有找到播放状态');
      return null;
    } catch (e) {
      debugPrint('【PlaylistManager】获取播放状态失败: $e');
      return null;
    }
  }

  /// 清空播放状态
  Future<void> clearPlaybackState() async {
    final db = await database;
    try {
      await db.delete('playback_state');
      debugPrint('【PlaylistManager】播放状态已清空');
    } catch (e) {
      debugPrint('【PlaylistManager】清空播放状态失败: $e');
    }
  }

  /// 清空播放列表中的所有音频
  Future<void> clearPlaylist() async {
    final db = await database;
    try {
      await db.delete('playlist_audios');
      // 同时清空播放状态
      await clearPlaybackState();
      debugPrint('【PlaylistManager】播放列表已清空');
    } catch (e) {
      debugPrint('【PlaylistManager】清空播放列表失败: $e');
    }
  }

  /// 更新音频在列表中的位置（用于拖拽排序）
  Future<void> updateAudioPosition(int id, int newPosition) async {
    // 当前实现中，列表按 id ASC 排序，暂不需要额外的位置字段
    // 如果需要自定义排序，可以在此添加 position 字段和更新逻辑
    debugPrint('【PlaylistManager】updateAudioPosition: id=$id, position=$newPosition');
  }
}
