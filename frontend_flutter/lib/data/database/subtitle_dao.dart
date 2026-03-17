import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SubtitleDao {
  final Database _db;

  SubtitleDao(this._db);

  /// 建表语句（在 DatabaseHelper 中调用）
  /// 
  /// 注意：cid 字段用于多 P 视频区分不同分 P 的字幕
  /// UNIQUE 约束使用 (bvid, cid, lan) 组合键
  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS subtitle_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL,
      cid INTEGER NOT NULL DEFAULT 0,
      lan TEXT NOT NULL,
      lan_doc TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(bvid, cid, lan)
    )
  ''';

  /// 保存字幕到缓存
  /// 
  /// [bvid] 视频 BV 号
  /// [cid] 视频分 P ID（多 P 视频必需）
  /// [lan] 语言代码
  /// [lanDoc] 语言名称
  /// [lines] 字幕行列表
  Future<void> saveSubtitle(
    String bvid,
    int cid,
    String lan,
    String lanDoc,
    List<Map<String, dynamic>> lines,
  ) async {
    await _db.insert(
      'subtitle_cache',
      {
        'bvid': bvid,
        'cid': cid,
        'lan': lan,
        'lan_doc': lanDoc,
        'content': jsonEncode(lines),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 查询缓存的字幕
  /// 
  /// [bvid] 视频 BV 号
  /// [cid] 视频分 P ID（可选，默认查询 cid=0 的字幕）
  Future<List<Map<String, dynamic>>?> getSubtitle(String bvid, {int cid = 0}) async {
    final rows = await _db.query(
      'subtitle_cache',
      where: 'bvid = ? AND cid = ?',
      whereArgs: [bvid, cid],
    );
    if (rows.isEmpty) return null;
    return rows;
  }

  /// 删除指定视频的字幕缓存
  /// 
  /// [bvid] 视频 BV 号
  /// [cid] 视频分 P ID（可选，不传则删除该 bvid 所有分 P 的字幕）
  Future<void> deleteSubtitle(String bvid, {int? cid}) async {
    if (cid != null) {
      await _db.delete(
        'subtitle_cache',
        where: 'bvid = ? AND cid = ?',
        whereArgs: [bvid, cid],
      );
    } else {
      await _db.delete('subtitle_cache', where: 'bvid = ?', whereArgs: [bvid]);
    }
  }

  /// 清空所有字幕缓存
  Future<void> clearAll() async {
    await _db.delete('subtitle_cache');
  }
}
