import 'dart:io';

import '../../core/utils/app_logger.dart';
import '../../models/download_task.dart';
import 'app_database.dart';

/// 状态转换异常
class InvalidStateTransitionError implements Exception {
  final DownloadStatus from;
  final DownloadStatus to;

  InvalidStateTransitionError(this.from, this.to);

  @override
  String toString() => '非法状态转换: $from -> $to';
}

/// 下载任务数据访问对象
///
/// 提供对 download_tasks 表的 CRUD 操作。
/// 每个下载任务都关联一个 track_id，与 tracks 表形成外键关系。
///
/// 状态机验证：只允许合法的状态转换，非法转换会抛出 [InvalidStateTransitionError]。
class DownloadTaskDao {
  final AppDatabase _db;

  DownloadTaskDao(this._db);

  /// 合法的状态转换规则
  /// 当前状态 -> 允许转换到的状态列表
  ///
  /// 状态转换说明：
  /// - pending: 等待中，可以开始下载、暂停、失败
  /// - downloading: 下载中，可以暂停、完成、失败
  /// - paused: 已暂停，可以恢复(重新排队或直接下载)、失败
  /// - completed: 已完成，可以重新下载
  /// - failed: 失败，可以重试
  static const _validTransitions = {
    DownloadStatus.pending: [
      DownloadStatus.downloading,
      DownloadStatus.paused,      // 等待中的任务可以暂停（用户操作）
      DownloadStatus.failed,
    ],
    DownloadStatus.downloading: [
      DownloadStatus.paused,
      DownloadStatus.stalled,
      DownloadStatus.completed,
      DownloadStatus.failed,
    ],
    DownloadStatus.paused: [
      DownloadStatus.pending,     // 恢复后重新排队
      DownloadStatus.downloading, // 直接恢复下载（槽位可用时）
      DownloadStatus.failed,
    ],
    DownloadStatus.stalled: [
      DownloadStatus.pending,     // 自动重试（重新排队）
      DownloadStatus.downloading, // 直接恢复下载（槽位可用时）
      DownloadStatus.failed,
    ],
    DownloadStatus.completed: [
      DownloadStatus.pending,     // 重新下载
    ],
    DownloadStatus.failed: [
      DownloadStatus.pending,     // 重试
    ],
  };

  /// 验证状态转换是否合法
  bool _isValidTransition(DownloadStatus from, DownloadStatus to) {
    final allowed = _validTransitions[from];
    return allowed?.contains(to) ?? false;
  }

  // ==================== 插入 ====================

  /// 插入下载任务
  ///
  /// 返回新创建任务的数据库 ID。
  Future<int> insert(DownloadTask task) async {
    final map = task.toMap();
    // 移除 id，让数据库自动生成
    map.remove('id');
    return await _db.insertDownloadTask(map);
  }

  /// 创建新的下载任务（便捷方法）
  ///
  /// 用于 Repository 层快速创建任务，不需要提前构建 DownloadTask 对象。
  Future<int> create({
    required String url,
    required String savePath,
    int? trackId,
    String? originalUrl,
    String? bvid,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    final task = DownloadTask(
      url: url,
      savePath: savePath,
      trackId: trackId,
      originalUrl: originalUrl,
      bvid: bvid,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      status: DownloadStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await insert(task);
  }

  // ==================== 查询 ====================

  /// 根据 ID 获取下载任务
  Future<DownloadTask?> getById(int id) async {
    final map = await _db.getDownloadTaskById(id);
    if (map == null) return null;
    return DownloadTask.fromMap(map);
  }

  /// 根据 BVID 获取下载任务
  Future<DownloadTask?> getByBvid(String bvid) async {
    final map = await _db.getDownloadTaskByBvid(bvid);
    if (map == null) return null;
    return DownloadTask.fromMap(map);
  }

  /// 获取所有下载任务
  Future<List<DownloadTask>> getAll() async {
    final maps = await _db.getAllDownloadTasks();
    return maps.map((m) => DownloadTask.fromMap(m)).toList();
  }

  /// 根据状态获取任务
  Future<List<DownloadTask>> getByStatus(DownloadStatus status) async {
    final maps = await _db.getDownloadTasksByStatus(status);
    return maps.map((m) => DownloadTask.fromMap(m)).toList();
  }

  /// 获取待处理的任务
  Future<List<DownloadTask>> getPending() async {
    return await getByStatus(DownloadStatus.pending);
  }

  /// 获取下载中的任务
  Future<List<DownloadTask>> getDownloading() async {
    return await getByStatus(DownloadStatus.downloading);
  }

  /// 获取已暂停的任务
  Future<List<DownloadTask>> getPaused() async {
    return await getByStatus(DownloadStatus.paused);
  }

  /// 获取已完成的任务
  Future<List<DownloadTask>> getCompleted() async {
    return await getByStatus(DownloadStatus.completed);
  }

  /// 获取失败的任务
  Future<List<DownloadTask>> getFailed() async {
    return await getByStatus(DownloadStatus.failed);
  }

  /// 获取未完成的任务（pending + paused + downloading）
  ///
  /// 用于应用重启后恢复任务。包括：
  /// - pending: 等待中的任务
  /// - paused: 暂停的任务（如果有临时文件可以恢复）
  /// - downloading: 下载中的任务（崩溃恢复）
  Future<List<DownloadTask>> getIncomplete() async {
    final all = await getAll();
    return all.where((t) =>
      t.status == DownloadStatus.pending ||
      t.status == DownloadStatus.paused ||
      t.status == DownloadStatus.downloading ||
      t.status == DownloadStatus.stalled
    ).toList();
  }

  /// 根据 savePath 获取任务（用于临时文件清理）
  Future<DownloadTask?> getBySavePath(String savePath) async {
    final all = await getAll();
    for (final task in all) {
      if (task.savePath == savePath) {
        return task;
      }
    }
    return null;
  }

  /// 获取活跃的任务（pending 或 downloading）
  Future<List<DownloadTask>> getActive() async {
    final all = await getAll();
    return all.where((t) => t.isActive).toList();
  }

  /// 检查是否存在指定 BVID 的任务
  Future<bool> exists(String bvid) async {
    final task = await getByBvid(bvid);
    return task != null;
  }

  /// 检查是否已有活跃任务
  Future<bool> hasActiveTask(String bvid) async {
    final task = await getByBvid(bvid);
    if (task == null) return false;
    return task.isActive;
  }

  /// 检查是否已完成
  Future<bool> isCompleted(String bvid) async {
    final task = await getByBvid(bvid);
    return task?.isCompleted ?? false;
  }

  // ==================== 更新 ====================

  /// 更新下载任务
  Future<void> update(DownloadTask task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update task without id');
    }
    await _db.updateDownloadTask(task.id!, task.toMap());
  }

  /// 更新进度
  ///
  /// [downloadedBytes] 已下载字节数
  /// [totalBytes] 总字节数
  Future<void> updateProgress(
    int id,
    int downloadedBytes,
    int totalBytes,
  ) async {
    await _db.updateDownloadProgress(id, downloadedBytes, totalBytes);
  }

  /// 更新进度百分比（便捷方法）
  ///
  /// [percent] 进度百分比 (0-100)
  /// 注意：此方法不更新字节数，因为实际文件大小在下载开始时未知
  Future<void> updateProgressPercent(int id, int percent) async {
    // 只更新进度时间戳，不更新字节数（避免显示错误的 ..B/100B）
    await _db.updateDownloadTask(id, {
      'last_progress_at': DateTime.now().toIso8601String(),
    });
  }

  /// 更新状态（带强制验证）
  ///
  /// 验证状态转换是否合法，非法转换会抛出 [InvalidStateTransitionError]。
  /// 这可以防止状态不一致导致的业务逻辑错误。
  Future<void> updateStatus(int id, DownloadStatus status) async {
    final current = await getById(id);
    if (current != null) {
      if (!_isValidTransition(current.status, status)) {
        AppLogger.error('DownloadTaskDao',
          '非法状态转换: ${current.status} -> $status, 任务ID: $id');
        throw InvalidStateTransitionError(current.status, status);
      }
    }
    await _db.updateDownloadStatus(id, status);
    AppLogger.info('DownloadTaskDao', '更新状态: id=$id, status=$status');
  }

  /// 标记为待处理（等待中）
  Future<void> markAsPending(int id) async {
    await updateStatus(id, DownloadStatus.pending);
  }

  /// 标记为下载中
  Future<void> markAsDownloading(int id) async {
    await updateStatus(id, DownloadStatus.downloading);
  }

  /// 标记为暂停（幂等操作）
  ///
  /// 如果任务已经是 paused 状态，直接返回而不报错。
  Future<void> markAsPaused(int id) async {
    final current = await getById(id);
    if (current != null && current.status == DownloadStatus.paused) {
      AppLogger.debug('DownloadTaskDao', '任务已是 paused 状态，跳过: $id');
      return;
    }
    await updateStatus(id, DownloadStatus.paused);
  }

  /// 标记为完成（幂等操作）
  ///
  /// 如果任务已经是 completed 状态，直接返回而不报错。
  Future<void> markAsCompleted(int id) async {
    final current = await getById(id);
    if (current != null && current.status == DownloadStatus.completed) {
      AppLogger.debug('DownloadTaskDao', '任务已是 completed 状态，跳过: $id');
      return;
    }
    await updateStatus(id, DownloadStatus.completed);
  }

  /// 标记为失败（幂等操作 + 状态验证）
  ///
  /// 如果任务已经是 failed 状态，只更新错误信息而不改变状态。
  Future<void> markAsFailed(int id, {String? errorMessage}) async {
    final current = await getById(id);
    if (current != null && current.status == DownloadStatus.failed) {
      // 已经是失败状态，只更新错误信息
      await _db.updateDownloadTask(id, {
        'error_message': errorMessage,
        'last_error': errorMessage,
      });
      return;
    }

    // 验证状态转换
    if (current != null) {
      if (!_isValidTransition(current.status, DownloadStatus.failed)) {
        AppLogger.warn('DownloadTaskDao',
          '无法将状态 ${current.status} 转换为 failed，任务ID: $id');
        return;
      }
    }

    await _db.updateDownloadTask(id, {
      'status': DownloadStatus.failed.value,
      'error_message': errorMessage,
      'last_error': errorMessage,
    });
  }

  /// 标记为卡死
  Future<void> markAsStalled(int id, {String? reason}) async {
    await _db.updateDownloadTask(id, {
      'status': DownloadStatus.stalled.value,
      'last_error': reason,
    });
  }

  /// 重置任务状态（用于崩溃恢复）
  ///
  /// 强制更新任务状态，绕过状态机验证。仅用于恢复异常中断的任务。
  Future<void> resetTaskStatus(int id, DownloadStatus status) async {
    await _db.updateDownloadStatus(id, status);
    AppLogger.info('DownloadTaskDao', '重置状态: id=$id, status=$status');
  }

  /// 更新已下载字节数（用于文件校验后修正）
  Future<void> updateDownloadedBytes(int id, int bytes) async {
    await _db.updateDownloadTask(id, {
      'downloaded_bytes': bytes,
    });
  }

  /// 更新错误信息
  Future<void> updateError(int id, String errorMessage) async {
    await _db.updateDownloadTask(id, {
      'error_message': errorMessage,
      'last_error': errorMessage,
    });
  }

  /// 更新心跳时间
  Future<void> updateHeartbeat(int id, DateTime timestamp) async {
    await _db.updateDownloadTask(id, {
      'last_heartbeat_at': timestamp.toIso8601String(),
    });
  }

  /// 更新进度时间
  Future<void> updateProgressTimestamp(int id, DateTime timestamp) async {
    await _db.updateDownloadTask(id, {
      'last_progress_at': timestamp.toIso8601String(),
    });
  }

  /// 递增重试次数
  Future<int> incrementRetry(int id) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE download_tasks SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
    final updated = await getById(id);
    return updated?.retryCount ?? 0;
  }

  /// 设置是否为用户暂停
  Future<void> setUserPaused(int id, bool value) async {
    await _db.updateDownloadTask(id, {
      'user_paused': value ? 1 : 0,
    });
  }

  // ==================== 断点续传支持 ====================

  /// 更新临时文件路径
  Future<void> updateTempFilePath(int id, String? tempFilePath) async {
    await _db.updateDownloadTask(id, {
      'temp_file_path': tempFilePath,
    });
  }

  /// 更新 ETag
  Future<void> updateEtag(int id, String? etag) async {
    await _db.updateDownloadTask(id, {
      'etag': etag,
    });
  }

  /// 更新 Last-Modified
  Future<void> updateLastModified(int id, String? lastModified) async {
    await _db.updateDownloadTask(id, {
      'last_modified': lastModified,
    });
  }

  // ==================== 请求ID支持 ====================

  /// 更新服务器分配的请求ID（用于断线重连）
  Future<void> updateRequestId(int id, String? requestId) async {
    await _db.updateDownloadTask(id, {
      'request_id': requestId,
    });
  }

  /// 批量更新断点续传信息
  Future<void> updateResumableInfo({
    required int id,
    int? downloadedBytes,
    int? totalBytes,
    String? tempFilePath,
    String? etag,
    String? lastModified,
    String? resumeToken,
  }) async {
    final data = <String, dynamic>{};
    if (downloadedBytes != null) {
      data['downloaded_bytes'] = downloadedBytes;
    }
    if (totalBytes != null) {
      data['total_bytes'] = totalBytes;
    }
    if (tempFilePath != null) {
      data['temp_file_path'] = tempFilePath;
    }
    if (etag != null) {
      data['etag'] = etag;
    }
    if (lastModified != null) {
      data['last_modified'] = lastModified;
    }
    if (resumeToken != null) {
      data['resume_token'] = resumeToken;
    }
    await _db.updateDownloadTask(id, data);
  }

  /// 清理临时文件
  Future<void> clearTempFile(int id) async {
    final task = await getById(id);
    if (task?.tempFilePath != null) {
      try {
        final file = File(task!.tempFilePath!);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('DownloadTaskDao', '删除临时文件: ${task.tempFilePath}');
        }
      } catch (e) {
        AppLogger.error('DownloadTaskDao', '删除临时文件失败: $e');
      }
    }
    // 清除数据库中的临时文件路径
    await _db.updateDownloadTask(id, {'temp_file_path': null});
  }

  /// 获取卡死的任务
  Future<List<DownloadTask>> getStalledTasks() async {
    return await getByStatus(DownloadStatus.stalled);
  }

  // ==================== 删除 ====================

  /// 删除任务
  Future<void> delete(int id) async {
    await _db.deleteDownloadTask(id);
    AppLogger.info('DownloadTaskDao', '删除任务: $id');
  }

  /// 根据 BVID 删除
  Future<void> deleteByBvid(String bvid) async {
    final task = await getByBvid(bvid);
    if (task?.id != null) {
      await delete(task!.id!);
    }
  }

  /// 清空已完成的任务
  Future<void> clearCompleted() async {
    await _db.clearCompletedDownloadTasks();
    AppLogger.info('DownloadTaskDao', '清空已完成任务');
  }

  /// 清空所有任务（谨慎使用）
  Future<void> clearAll() async {
    final tasks = await getAll();
    for (final task in tasks) {
      if (task.id != null) {
        await delete(task.id!);
      }
    }
    AppLogger.info('DownloadTaskDao', '清空所有任务');
  }

  // ==================== Stream 监听 ====================

  /// 监听所有任务变化
  ///
  /// 返回一个 Stream，当 download_tasks 表发生变化时 emits 最新任务列表。
  /// 这用于 ViewModel 层实现响应式 UI。
  Stream<List<DownloadTask>> watchAll() async* {
    // 首先获取当前数据
    yield await getAll();

    // 由于 sqflite 不原生支持 Stream，我们使用轮询机制
    // 在实际应用中，可以配合 Riverpod 的 refresh 机制使用
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await getAll();
    }
  }

  /// 监听指定状态的任务
  Stream<List<DownloadTask>> watchByStatus(DownloadStatus status) async* {
    yield await getByStatus(status);

    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await getByStatus(status);
    }
  }

  // ==================== 统计 ====================

  /// 获取任务总数
  Future<int> getCount() async {
    final stats = await _db.getStats();
    return stats['download_tasks'] ?? 0;
  }

  /// 获取各状态数量统计
  Future<Map<DownloadStatus, int>> getStatusCounts() async {
    final all = await getAll();
    final counts = <DownloadStatus, int>{};
    
    for (final status in DownloadStatus.values) {
      counts[status] = 0;
    }
    
    for (final task in all) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
    }
    
    return counts;
  }

  /// 获取总体下载进度（用于显示总进度条）
  Future<double> getOverallProgress() async {
    final tasks = await getAll();
    if (tasks.isEmpty) return 0.0;

    final totalProgress = tasks.fold<double>(
      0.0,
      (sum, task) => sum + task.progressPercentage,
    );

    return totalProgress / tasks.length;
  }
}
