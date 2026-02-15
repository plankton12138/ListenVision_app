import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../models/sync_queue.dart';
import '../database/app_database.dart';
import '../database/sync_queue_dao.dart';
import '../sync/sync_worker.dart';

part 'sync_worker_provider.g.dart';

/// SyncWorker 实例 Provider
///
/// 提供同步工作器的单例访问
@riverpod
SyncWorker syncWorker(Ref ref) {
  final worker = SyncWorker(
    syncDao: SyncQueueDao(AppDatabase.instance),
  );

  // 启动工作器（30秒间隔）
  worker.start(interval: 30);

  AppLogger.info('SyncWorkerProvider', 'SyncWorker 已启动');

  // 在 ref dispose 时停止
  ref.onDispose(() {
    worker.dispose();
    AppLogger.info('SyncWorkerProvider', 'SyncWorker 已释放');
  });

  return worker;
}

/// 同步统计 StreamProvider（手动创建）
///
/// 提供实时的同步队列统计信息（使用 StreamProvider 支持实时更新）
/// 注意：此 Provider 依赖 syncWorkerProvider 以确保 SyncWorker 不会被过早释放
final syncStatsProvider = StreamProvider.autoDispose<SyncQueueStats>((ref) {
  // 获取 SyncWorker 实例
  final worker = ref.watch(syncWorkerProvider);

  AppLogger.debug('syncStatsProvider', '监听 SyncWorker.statsStream');

  // 返回统计变化流
  return worker.statsStream.map((stats) {
    AppLogger.debug('syncStatsProvider', '统计更新: $stats');
    return stats;
  });
});

/// 是否有待处理同步任务
@riverpod
Future<bool> hasPendingSyncTasks(Ref ref) async {
  final syncDao = SyncQueueDao(AppDatabase.instance);
  return await syncDao.hasPendingTasks();
}
