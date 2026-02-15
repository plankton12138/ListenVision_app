import '../../core/utils/app_logger.dart';
import '../../models/sync_queue.dart';
import 'app_database.dart';

/// 同步队列数据访问对象
///
/// 负责同步队列的数据库操作
class SyncQueueDao {
  final AppDatabase _db;

  SyncQueueDao(this._db);

  // ==================== 插入 ====================

  /// 插入同步任务
  Future<int> insert(SyncTask task) async {
    final map = task.toMap();
    return await _db.insertSyncTask(map);
  }

  /// 批量插入同步任务
  Future<List<int>> insertBatch(List<SyncTask> tasks) async {
    final ids = <int>[];
    for (final task in tasks) {
      final id = await insert(task);
      ids.add(id);
    }
    return ids;
  }

  // ==================== 查询 ====================

  /// 根据 ID 获取同步任务
  Future<SyncTask?> getById(int id) async {
    final map = await _db.getSyncTaskById(id);
    if (map == null) return null;
    return SyncTask.fromMap(map);
  }

  /// 获取待同步的任务列表
  Future<List<SyncTask>> getPendingTasks({int limit = 50}) async {
    final maps = await _db.getPendingSyncTasks(limit: limit);
    return maps.map((m) => SyncTask.fromMap(m)).toList();
  }

  /// 获取失败但可重试的任务
  Future<List<SyncTask>> getRetryableTasks({int limit = 50}) async {
    final maps = await _db.getRetryableSyncTasks(limit: limit);
    return maps.map((m) => SyncTask.fromMap(m)).toList();
  }

  /// 获取所有待处理和可重试的任务
  Future<List<SyncTask>> getAllPendingTasks({int limit = 100}) async {
    final pending = await getPendingTasks(limit: limit);
    final retryable = await getRetryableTasks(limit: limit);

    // 合并并按创建时间排序
    final allTasks = [...pending, ...retryable];
    allTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return allTasks.take(limit).toList();
  }

  /// 根据 Track ID 获取同步任务
  Future<List<SyncTask>> getByTrackId(int trackId) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'track_id = ? AND status != ?',
      whereArgs: [trackId, 'succeeded'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SyncTask.fromMap(m)).toList();
  }

  /// 根据 BVID 获取同步任务
  Future<List<SyncTask>> getByBvid(String bvid) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'bvid = ? AND status != ?',
      whereArgs: [bvid, 'succeeded'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SyncTask.fromMap(m)).toList();
  }

  /// 根据 Playlist ID 获取同步任务
  Future<List<SyncTask>> getByPlaylistId(String playlistId) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'playlist_id = ? AND status != ?',
      whereArgs: [playlistId, 'succeeded'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SyncTask.fromMap(m)).toList();
  }

  // ==================== 更新 ====================

  /// 更新同步任务
  Future<void> update(SyncTask task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update task without id');
    }
    await _db.updateSyncTask(task.id!, task.toMap());
  }

  /// 标记为同步中
  Future<void> markAsSyncing(int id) async {
    await _db.markSyncTaskSyncing(id);
    AppLogger.debug('SyncQueueDao', '标记任务为同步中: $id');
  }

  /// 标记为成功
  Future<void> markAsSucceeded(int id) async {
    await _db.markSyncTaskSucceeded(id);
    AppLogger.info('SyncQueueDao', '标记任务为成功: $id');
  }

  /// 标记为失败
  Future<void> markAsFailed(int id, String errorMessage) async {
    await _db.markSyncTaskFailed(id, errorMessage);
    AppLogger.warn('SyncQueueDao', '标记任务为失败: $id - $errorMessage');
  }

  /// 增加重试次数
  Future<void> incrementRetry(int id) async {
    final db = await _db.database;
    await db.rawUpdate('''
      UPDATE sync_queue
      SET retry_count = retry_count + 1,
          updated_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  // ==================== 删除 ====================

  /// 删除同步任务
  Future<void> delete(int id) async {
    await _db.deleteSyncTask(id);
    AppLogger.info('SyncQueueDao', '删除同步任务: $id');
  }

  /// 批量删除已完成的任务
  Future<int> clearCompleted() async {
    final db = await _db.database;
    final result = await db.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['succeeded'],
    );
    AppLogger.info('SyncQueueDao', '清空已完成同步任务: $result 条');
    return result;
  }

  /// 删除所有已完成或失败的任务
  Future<void> clearAllFinished() async {
    final db = await _db.database;
    await db.delete(
      'sync_queue',
      where: 'status = ? OR (status = ? AND retry_count >= max_retries)',
      whereArgs: ['succeeded', 'failed'],
    );
    AppLogger.info('SyncQueueDao', '清空所有已完成同步任务');
  }

  // ==================== 统计 ====================

  /// 获取同步统计信息
  Future<SyncQueueStats> getStats() async {
    AppLogger.debug('SyncQueueDao', 'getStats() 开始');
    final stats = await _db.getSyncStats();
    AppLogger.debug('SyncQueueDao', 'getSyncStats() 返回: $stats');
    final result = SyncQueueStats(
      pending: stats['pending'] ?? 0,
      syncing: stats['syncing'] ?? 0,
      retryable: stats['retryable'] ?? 0,
    );
    AppLogger.debug('SyncQueueDao', 'getStats() 完成: $result');
    return result;
  }

  /// 检查是否有待处理任务
  Future<bool> hasPendingTasks() async {
    final stats = await getStats();
    return stats.pending > 0 || stats.retryable > 0;
  }
}

/// 同步队列统计信息
class SyncQueueStats {
  /// 待处理任务数
  final int pending;

  /// 同步中任务数
  final int syncing;

  /// 可重试任务数
  final int retryable;

  /// 总活动任务数
  int get active => pending + syncing + retryable;

  const SyncQueueStats({
    required this.pending,
    required this.syncing,
    required this.retryable,
  });

  @override
  String toString() {
    return 'SyncQueueStats(pending: $pending, syncing: $syncing, retryable: $retryable, active: $active)';
  }
}
