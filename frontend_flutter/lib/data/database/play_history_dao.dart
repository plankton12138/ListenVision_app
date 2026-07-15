import '../../core/utils/app_logger.dart';
import 'app_database.dart';

/// 播放历史数据访问对象
///
/// 提供对 play_history 表的分页查询、去重、统计等操作。
/// 软限制保留最近 2000 条记录。
class PlayHistoryDao {
  final AppDatabase _db;

  PlayHistoryDao(this._db);

  /// 分页获取播放历史（去重：同一 source_id 只保留最新一条）
  Future<List<Map<String, dynamic>>> getHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final db = await _db.database;
    final offset = (page - 1) * pageSize;
    return await db.rawQuery('''
      SELECT ph.* FROM play_history ph
      INNER JOIN (
        SELECT source_id, MAX(played_at) AS max_played
        FROM play_history
        GROUP BY source_id
      ) latest ON ph.source_id = latest.source_id AND ph.played_at = latest.max_played
      ORDER BY ph.played_at DESC
      LIMIT ? OFFSET ?
    ''', [pageSize, offset]);
  }

  /// 插入或更新播放历史（同 source_id 则更新 played_at）
  Future<void> upsert(Map<String, dynamic> history) async {
    final db = await _db.database;
    final sourceId = history['source_id'] as String?;
    if (sourceId == null) return;

    final existing = await db.query(
      'play_history',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'played_at DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      history['played_at'] = DateTime.now().toIso8601String();
      await db.update('play_history', history, where: 'id = ?', whereArgs: [id]);
      AppLogger.debug('PlayHistoryDao', '更新播放历史: $sourceId');
    } else {
      history['played_at'] ??= DateTime.now().toIso8601String();
      await db.insert('play_history', history);
      AppLogger.debug('PlayHistoryDao', '插入播放历史: $sourceId');
    }

    // 软限制：保留最近 2000 条
    await _enforceLimit(2000);
  }

  /// 删除单条
  Future<void> deleteById(int id) async {
    final db = await _db.database;
    await db.delete('play_history', where: 'id = ?', whereArgs: [id]);
  }

  /// 批量删除
  Future<void> deleteByIds(List<int> ids) async {
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('play_history', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// 清空
  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('play_history');
  }

  /// 聚合统计
  Future<Map<String, dynamic>> getStats() async {
    final db = await _db.database;
    final total = await db.rawQuery('SELECT COUNT(*) as c FROM play_history');
    final unique = await db.rawQuery(
      'SELECT COUNT(DISTINCT source_id) as c FROM play_history',
    );
    return {
      'totalPlays': total.first['c'] ?? 0,
      'uniqueTracks': unique.first['c'] ?? 0,
    };
  }

  /// 软限制：超出 maxRows 则删除最旧的
  Future<void> _enforceLimit(int maxRows) async {
    final db = await _db.database;
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM play_history');
    final total = count.first['c'] as int? ?? 0;
    if (total > maxRows) {
      await db.rawQuery('''
        DELETE FROM play_history WHERE id IN (
          SELECT id FROM play_history ORDER BY played_at ASC LIMIT ?
        )
      ''', [total - maxRows]);
      AppLogger.info('PlayHistoryDao', '清理 ${total - maxRows} 条旧历史');
    }
  }
}
