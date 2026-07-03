import '../../core/utils/app_logger.dart';
import '../../models/play_history.dart';
import '../../models/audio.dart';
import '../database/app_database.dart';

/// 播放历史仓库
///
/// 负责播放历史相关的本地数据操作
class PlayHistoryRepository {
  final AppDatabase _db;

  PlayHistoryRepository({AppDatabase? db})
      : _db = db ?? AppDatabase.instance;

  // ==================== 播放历史操作 ====================

  /// 获取播放历史列表
  Future<List<PlayHistory>> getPlayHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final historyMaps = await _db.getRecentPlayHistory(
        limit: pageSize,
      );

      // 如果 offset > 0，需要跳过前面的记录
      final pagedMaps = offset > 0 && offset < historyMaps.length
          ? historyMaps.skip(offset).toList()
          : offset == 0
              ? historyMaps
              : <Map<String, dynamic>>[];

      final history = <PlayHistory>[];
      for (final map in pagedMaps) {
        try {
          final sourceId = map['source_id'] as String? ?? '';
          final title = map['title'] as String? ?? '';
          final artist = map['artist'] as String? ?? '';
          final coverUrl = map['cover_url'] as String? ?? '';
          final duration = map['duration'] as int? ?? 0;
          final progress = map['position'] as int? ?? 0;
          final playedAtStr = map['played_at'] as String? ?? '';
          final playedAt = DateTime.tryParse(playedAtStr) ?? DateTime.now();

          final audio = Audio(
            id: sourceId,
            title: title,
            artist: artist,
            coverUrl: coverUrl,
            duration: duration > 0 ? duration : null,
          );

          history.add(PlayHistory(
            id: map['id']?.toString() ?? '',
            userId: '',
            audio: audio,
            playedAt: playedAt,
            progress: progress,
          ));
        } catch (e) {
          AppLogger.error('PlayHistoryRepository', '解析播放历史记录失败: $e');
        }
      }

      AppLogger.info('PlayHistoryRepository', '获取播放历史成功：${history.length}条');
      return history;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '获取播放历史失败：$e');
      return [];
    }
  }

  /// 添加播放历史
  Future<bool> addPlayHistory({
    required String bvid,
    int? cid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? progress,
  }) async {
    try {
      await _db.insertPlayHistory({
        'source_id': bvid,
        'title': title ?? bvid,
        'artist': artist ?? '',
        'cover_url': coverUrl ?? '',
        'duration': duration ?? 0,
        'position': progress ?? 0,
      });
      AppLogger.debug('PlayHistoryRepository', '添加播放历史：$bvid - $title');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '添加播放历史失败：$e');
      return false;
    }
  }

  /// 更新播放历史进度
  Future<bool> updatePlayHistory({
    required String id,
    int? progress,
  }) async {
    try {
      final db = await _db.database;
      final data = <String, dynamic>{};
      if (progress != null) data['position'] = progress;
      data['played_at'] = DateTime.now().toIso8601String();

      await db.update(
        'play_history',
        data,
        where: 'id = ?',
        whereArgs: [int.tryParse(id) ?? id],
      );
      AppLogger.debug('PlayHistoryRepository', '更新播放历史：$id');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '更新播放历史失败：$e');
      return false;
    }
  }

  /// 删除播放历史
  Future<bool> deletePlayHistory(String id) async {
    try {
      final db = await _db.database;
      await db.delete(
        'play_history',
        where: 'id = ?',
        whereArgs: [int.tryParse(id) ?? id],
      );
      AppLogger.info('PlayHistoryRepository', '删除播放历史：$id');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '删除播放历史失败：$e');
      return false;
    }
  }

  /// 清空所有播放历史
  Future<bool> clearAllHistory() async {
    try {
      await _db.clearPlayHistory();
      AppLogger.info('PlayHistoryRepository', '清空所有播放历史');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '清空播放历史失败：$e');
      return false;
    }
  }
}