import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cached_track.dart';
import '../../models/download_task.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../services/bilibili_api_service.dart';
import '../database/app_database.dart';
import '../database/download_task_dao.dart';
import '../database/play_history_dao.dart';
import '../database/track_dao.dart';
import 'download_repository.dart';
import 'history_repository.dart';
import 'track_repository.dart';

// ==================== 数据库 Providers ====================

/// AppDatabase Provider（单例）
///
/// 使用 keepAlive: true 确保数据库实例在整个应用生命周期内保持
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// TrackDao Provider
final trackDaoProvider = Provider<TrackDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TrackDao(db);
});

/// DownloadTaskDao Provider
final downloadTaskDaoProvider = Provider<DownloadTaskDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DownloadTaskDao(db);
});

/// PlayHistoryDao Provider
final playHistoryDaoProvider = Provider<PlayHistoryDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlayHistoryDao(db);
});

// ==================== Repository Providers ====================

/// TrackRepository Provider
///
/// 核心仓库，实现"本地优先，网络回源"原则。
/// 所有音频数据的读取都应通过此 Provider。
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final repository = TrackRepository(
    bilibiliApi: ref.watch(bilibiliApiServiceProvider),
    trackDao: ref.watch(trackDaoProvider),
    downloadTaskDao: ref.watch(downloadTaskDaoProvider),
  );

  // 当 Provider 被销毁时释放资源
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// DownloadRepository Provider
///
/// 下载仓库，管理下载任务的创建、执行和状态同步。
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final repository = DownloadRepository(
    db: ref.watch(appDatabaseProvider),
    bilibiliApi: ref.watch(bilibiliApiServiceProvider),
    trackDao: ref.watch(trackDaoProvider),
    downloadTaskDao: ref.watch(downloadTaskDaoProvider),
  );

  // 当 Provider 被销毁时释放资源
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// PlayHistoryRepository Provider
final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>((ref) {
  final repository = PlayHistoryRepository(
    dao: ref.watch(playHistoryDaoProvider),
  );
  ref.onDispose(() => repository.dispose());
  return repository;
});

// ==================== Stream Providers ====================

/// 下载进度事件流 Provider
///
/// 用于监听所有下载任务的进度变化。
/// UI 可以监听此 Provider 来更新下载进度。
final downloadProgressStreamProvider = StreamProvider.autoDispose((ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return repository.progressStream;
});

// ==================== Future Providers（便捷查询） ====================

/// 获取 Track by BVID
///
/// 使用 family 修饰符支持参数化查询。
/// 示例: ref.watch(trackByBvidProvider('BVxxx'))
final trackByBvidProvider = FutureProvider.autoDispose
    .family<CachedTrack?, String>((ref, bvid) async {
      final repository = ref.watch(trackRepositoryProvider);
      return await repository.getTrackBySourceId(bvid);
    });

/// 获取所有已下载的 Tracks
final downloadedTracksProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return await repository.getDownloadedTracks();
});

/// 获取所有收藏的 Tracks
final favoriteTracksProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return await repository.getFavoriteTracks();
});

/// 获取最近播放的 Tracks
final recentlyPlayedTracksProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return await repository.getRecentlyPlayed();
});

/// 获取所有下载任务
final downloadTasksProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(downloadRepositoryProvider);
  return await repository.getAllTasks();
});

/// 获取活跃下载任务
final activeDownloadTasksProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(downloadRepositoryProvider);
  return await repository.getActiveTasks();
});

/// 检查指定 BVID 是否已下载
final isTrackDownloadedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, bvid) async {
      final repository = ref.watch(trackRepositoryProvider);
      return await repository.isDownloaded(bvid);
    });

/// 根据 Track ID 获取下载任务
final downloadTaskByTrackIdProvider = FutureProvider.autoDispose
    .family<DownloadTask?, int>((ref, trackId) async {
      final repository = ref.watch(downloadRepositoryProvider);
      return await repository.getTaskByTrackId(trackId);
    });

// ==================== State Providers（UI 状态） ====================

/// 当前正在下载的任务列表（内存状态，用于快速 UI 更新）
///
/// 注意：此 Provider 只应在需要实时 UI 更新时使用。
/// 持久状态仍存储在数据库中。
/// 已迁移到 downloading_state_provider.dart（Riverpod 3.0 模式）
/// 使用: ref.watch(downloadingStateProvider)
/// 方法: ref.read(downloadingStateProvider.notifier).add(id)

// ==================== Utility Providers ====================

/// FilePickerService Provider
///
/// 文件选择服务，用于选择本地音频文件
final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});
