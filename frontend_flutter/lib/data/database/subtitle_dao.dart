import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SubtitleDao {
  final Database _db;

  SubtitleDao(this._db);

  /// 建表语句（在 DatabaseHelper 中调用）
  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS subtitle_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL,
      lan TEXT NOT NULL,
      lan_doc TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(bvid, lan)
    )
  ''';

  /// 保存字幕到缓存
  Future<void> saveSubtitle(String bvid, String lan, String lanDoc, List<Map<String, dynamic>> lines) async {
    await _db.insert(
      'subtitle_cache',
      {
        'bvid': bvid,
        'lan': lan,
        'lan_doc': lanDoc,
        'content': jsonEncode(lines),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 查询缓存的字幕
  Future<List<Map<String, dynamic>>?> getSubtitle(String bvid) async {
    final rows = await _db.query(
      'subtitle_cache',
      where: 'bvid = ?',
      whereArgs: [bvid],
    );
    if (rows.isEmpty) return null;
    return rows;
  }

  /// 删除指定视频的字幕缓存
  Future<void> deleteSubtitle(String bvid) async {
    await _db.delete('subtitle_cache', where: 'bvid = ?', whereArgs: [bvid]);
  }
}
