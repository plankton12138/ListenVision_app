import 'dart:async';

import '../../core/utils/app_logger.dart';
import '../../models/play_history.dart';
import '../../models/audio.dart';
import '../database/app_database.dart';
import '../database/play_history_dao.dart';

class PlayHistoryRepository {
  final PlayHistoryDao _dao;
  final StreamController<List<PlayHistory>> _controller =
      StreamController<List<PlayHistory>>.broadcast();

  PlayHistoryRepository({AppDatabase? db, PlayHistoryDao? dao})
      : _dao = dao ?? PlayHistoryDao(db ?? AppDatabase.instance);

  /// 监听历史变更的 Stream
  Stream<List<PlayHistory>> watchHistory() => _controller.stream;

  /// 分页获取历史
  Future<List<PlayHistory>> getPlayHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final maps = await _dao.getHistory(page: page, pageSize: pageSize);
      final history = maps.map(_parseRow).toList();
      AppLogger.debug('PlayHistoryRepository', '加载历史: page=$page, ${history.length}条');
      return history;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '获取历史失败: $e');
      return [];
    }
  }

  /// 记录播放
  Future<void> recordPlay({
    required String bvid,
    int? cid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? progress,
    String? sourceType,
    String? sourceId,
  }) async {
    try {
      final map = <String, dynamic>{
        'source_id': bvid,
        'title': title ?? bvid,
        'artist': artist ?? '',
        'cover_url': coverUrl ?? '',
        'duration': duration ?? 0,
        'position': progress ?? 0,
        if (sourceType != null) 'source_type': sourceType,
      };
      if (sourceId != null) {
        map['source_id'] = sourceId;
      }
      await _dao.upsert(map);
      _notifyChange();
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '记录播放失败: $e');
    }
  }

  /// 删除单条
  Future<void> deleteById(int id) async {
    await _dao.deleteById(id);
    _notifyChange();
  }

  /// 批量删除
  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    await _dao.deleteByIds(ids);
    _notifyChange();
  }

  /// 清空
  Future<void> clearAll() async {
    await _dao.clearAll();
    _notifyChange();
  }

  /// 获取收藏曲目 ID 集合
  Future<Set<String>> getFavoriteTrackIds() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'tracks',
      where: 'is_favorite = ?',
      whereArgs: [1],
      columns: ['source_id'],
    );
    return rows.map((r) => r['source_id'] as String).toSet();
  }

  // --- private ---

  PlayHistory _parseRow(Map<String, dynamic> map) {
    final sourceId = map['source_id'] as String? ?? '';
    return PlayHistory(
      id: map['id']?.toString() ?? '',
      userId: '',
      audio: Audio(
        id: sourceId,
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String?,
        duration: map['duration'] as int?,
        coverUrl: map['cover_url'] as String?,
      ),
      playedAt:
          DateTime.tryParse(map['played_at'] as String? ?? '') ?? DateTime.now(),
      progress: map['position'] as int? ?? 0,
      source: _parseSource(
          map['source_type'] as String?, map['source_id'] as String?),
    );
  }

  PlaySource? _parseSource(String? type, String? id) {
    if (type == null) return null;
    switch (type) {
      case 'playlist':
        return PlaySource.playlist(id ?? '');
      case 'search':
        return PlaySource.search(id ?? '');
      case 'history':
        return const PlaySource.history();
      case 'manual':
        return const PlaySource.manual();
      default:
        return null;
    }
  }

  Future<void> _notifyChange() async {
    final history = await getPlayHistory(pageSize: 50);
    if (!_controller.isClosed) _controller.add(history);
  }

  void dispose() {
    _controller.close();
  }
}
