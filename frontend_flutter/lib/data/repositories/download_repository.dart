import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/utils/app_logger.dart';
import '../../core/storage/shared_storage_service.dart';
import '../../services/bilibili_api_service.dart';
import '../../services/bilibili_downloader.dart';
import '../../services/ffmpeg_service.dart';
import 'package:path/path.dart' as p;

import '../../core/errors/exceptions.dart';
import '../../models/download_task.dart';
import 'track_repository.dart' show DownloadProgressEvent;
import '../database/app_database.dart';
import '../database/download_task_dao.dart' show DownloadTaskDao;
import '../database/track_dao.dart';
import 'download_slot_manager.dart';

/// 下载仓库 - 增强版
///
/// 整合新的本地优先架构，支持：
/// 1. 下载任务持久化到数据库
/// 2. 断点续传（Phase 7 已完成）
/// 3. 并发下载控制（使用 SlotManager）
/// 4. 下载进度实时同步
class DownloadRepository {
  final TrackDao _trackDao;
  final DownloadTaskDao _downloadTaskDao;
  final BilibiliApiService _bilibiliApi;
  final AppDatabase _db;
  final BilibiliDownloader Function(BilibiliApiService) _downloaderFactory;
  final Map<int, Future<void>> _runningTasks = {};
  bool _disposed = false;
  final DownloadSlotManager _slotManager;

  // 当前活跃的下载任务
  final Map<int, CancelToken> _activeDownloads = {};

  // 待处理任务队列 (存储 taskId)
  final List<int> _pendingQueue = [];

  // 下载进度事件流
  final _progressController =
      StreamController<DownloadProgressEvent>.broadcast();

  // 队列变更事件流
  final _queueController = StreamController<int>.broadcast();

  // 卡死检测定时器
  Timer? _watchdogTimer;

  // 最大并发下载数
  static const int _maxConcurrentDownloads = 3;

  // 卡死检测阈值与间隔
  static const Duration _stalledThreshold = Duration(minutes: 2);
  static const Duration _watchdogInterval = Duration(seconds: 30);
  static const int _maxAutoRetries = 3;

  DownloadRepository({
    TrackDao? trackDao,
    DownloadTaskDao? downloadTaskDao,
    BilibiliApiService? bilibiliApi,
    AppDatabase? db,
    BilibiliDownloader Function(BilibiliApiService)? downloaderFactory,
    DownloadSlotManager? slotManager,
  }) : _trackDao = trackDao ?? TrackDao(db ?? AppDatabase.instance),
       _downloadTaskDao =
           downloadTaskDao ?? DownloadTaskDao(db ?? AppDatabase.instance),
       _bilibiliApi = bilibiliApi ?? BilibiliApiService(),
       _db = db ?? AppDatabase.instance,
       _downloaderFactory =
           downloaderFactory ?? ((api) => BilibiliDownloader(api)),
       _slotManager =
           slotManager ??
           DownloadSlotManager(maxSlots: _maxConcurrentDownloads) {
    _startWatchdog();
  }

  /// 下载进度事件流
  Stream<DownloadProgressEvent> get progressStream =>
      _progressController.stream;

  /// 队列变更事件流 - 当任务从队列中移除时发出该任务ID
  Stream<int> get queueStream => _queueController.stream;

  /// 获取当前活跃下载数量
  int get activeDownloadCount => _activeDownloads.length;

  /// 获取待处理队列长度
  int get pendingQueueLength => _pendingQueue.length;

  /// 获取队列中的位置 (0-based, null 表示不在队列中)
  int? getQueuePosition(int taskId) {
    final index = _pendingQueue.indexOf(taskId);
    return index >= 0 ? index : null;
  }

  /// 检查任务是否在队列中
  bool isInQueue(int taskId) => _pendingQueue.contains(taskId);

  // ==================== 下载任务管理 ====================

  /// 添加下载任务
  ///
  /// 创建下载任务并保存到数据库，但不立即开始下载。
  /// 返回创建的任务 ID。
  ///
  /// 使用事务确保所有数据库操作原子性，避免数据库锁定。
  Future<int> addDownloadTask({
    required String bvid,
    int? cid,
    String url = '',
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
    String? albumTitle,
  }) async {
    return await _db.transaction<int>((txn) async {
      // 用 bvid+cid 组合作为 source_id，使不同分P被视为独立 track
      final sourceId = cid != null ? '${bvid}_p$cid' : bvid;

      int trackId;
      final existingTrack = await txn.query(
        'tracks',
        where: 'source_id = ?',
        whereArgs: [sourceId],
        limit: 1,
      );

      if (existingTrack.isNotEmpty) {
        trackId = existingTrack.first['id'] as int;
      } else {
        trackId = await txn.insert('tracks', {
          'source_id': sourceId,
          'source_type': 'bilibili',
          'title': title ?? bvid,
          'artist': artist,
          'cover_url': coverUrl,
          'bvid': bvid,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        AppLogger.info(
          'DownloadRepository',
          '为搜索结果创建 Track: $sourceId -> $trackId',
        );
      }

      // 按 track_id 查找已有下载任务
      final existingTask = await txn.query(
        'download_tasks',
        where: 'track_id = ?',
        whereArgs: [trackId],
        limit: 1,
      );
      if (existingTask.isNotEmpty) {
        return existingTask.first['id'] as int;
      }

      final now = DateTime.now().toIso8601String();
      final taskId = await txn.insert('download_tasks', {
        'track_id': trackId,
        'bvid': bvid,
        'cid': cid,
        'url': url,
        'save_path': savePath,
        'title': title,
        'artist': artist,
        'cover_url': coverUrl,
        'album_title': albumTitle,
        'status': DownloadStatus.pending.value,
        'downloaded_bytes': 0,
        'total_bytes': 0,
        'retry_count': 0,
        'user_paused': 0,
        'created_at': now,
        'updated_at': now,
      });

      AppLogger.info(
        'DownloadRepository',
        '创建下载任务: $taskId, trackId: $trackId, bvid: $bvid, cid: $cid',
      );
      return taskId;
    });
  }

  /// 开始下载
  ///
  /// 执行实际的下载操作。支持并发控制和队列机制：
  /// - 如果并发未满，立即开始下载
  /// - 如果并发已满，任务进入等待队列
  Future<void> startDownload(int taskId) {
    if (_disposed) return Future.value();
    return _runningTasks.putIfAbsent(
      taskId,
      () => _runDownload(taskId).whenComplete(() {
        _runningTasks.remove(taskId);
      }),
    );
  }

  Future<void> _runDownload(int taskId) async {
    final token = CancelToken();
    _activeDownloads[taskId] = token;
    DownloadTask? task;
    BilibiliDownloader? downloader;
    DownloadResult? result;
    var committed = false;
    Future<void> progressWrites = Future.value();
    bool current() =>
        !_disposed &&
        !token.isCancelled &&
        identical(_activeDownloads[taskId], token);
    void check() {
      if (!current()) throw const TaskCanceledException();
    }

    try {
      task = await _downloadTaskDao.getById(taskId);
      check();
      if (task == null ||
          task.status == DownloadStatus.completed ||
          task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.failed) {
        return;
      }
      if (!_slotManager.restoreSlot(taskId)) {
        if (!_pendingQueue.contains(taskId)) _pendingQueue.add(taskId);
        return;
      }
      if (task.bvid == null) throw StateError('任务缺少 BVID');
      await _downloadTaskDao.setUserPaused(taskId, false);
      await _downloadTaskDao.markAsDownloading(taskId);
      check();
      final formatName = SharedStorageService.instance.getDownloadFormat();
      final selectedFormat = AudioOutputFormat.values.firstWhere(
        (f) => f.extension == formatName,
        orElse: () => AudioOutputFormat.m4a,
      );
      final format = FfmpegService().supportsConversion
          ? selectedFormat
          : AudioOutputFormat.m4a;
      downloader = _downloaderFactory(_bilibiliApi);
      result = await downloader.download(
        bvid: task.bvid!,
        cid: task.cid,
        saveDir: p.dirname(task.savePath),
        fileName: task.title ?? task.bvid!,
        albumTitle: task.albumTitle,
        format: format,
        tempPath: '${task.savePath}.part.m4a',
        cancelToken: token,
        downloadCover: SharedStorageService.instance.getDownloadCover(),
        onProgress: (percent, stage) {
          if (!current()) return;
          progressWrites = progressWrites
              .then((_) async {
                if (!current()) return;
                await _downloadTaskDao.updateProgressPercent(taskId, percent);
                await _downloadTaskDao.updateProgressTimestamp(
                  taskId,
                  DateTime.now(),
                );
                if (current()) {
                  _progressController.add(
                    DownloadProgressEvent(
                      taskId: taskId,
                      trackId: task!.trackId,
                      bvid: task.bvid!,
                      progress: percent,
                      stage: stage,
                      message: _getStageMessage(stage),
                    ),
                  );
                }
              })
              .catchError((Object error) {
                AppLogger.warn('DownloadRepository', '记录下载进度失败: $error');
              });
        },
      );
      await progressWrites;
      check();
      if (!result.success || result.filePath == null) {
        throw StateError(result.error ?? '下载失败');
      }
      final completed = result;
      await _db.transaction<void>((txn) async {
        check();
        final rows = await txn.query(
          'download_tasks',
          where: 'id = ?',
          whereArgs: [taskId],
        );
        if (rows.isEmpty) throw const TaskCanceledException();
        await txn.update(
          'download_tasks',
          {
            'status': 'completed',
            'save_path': completed.filePath,
            'total_bytes': completed.fileSize,
            'downloaded_bytes': completed.fileSize,
            'temp_file_path': '${task!.savePath}.part.m4a',
            'error_message': null,
            'completed_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [taskId],
        );
        if (task.trackId != null) {
          await txn.update(
            'tracks',
            {
              'is_downloaded': 1,
              'local_path': completed.filePath,
              'download_status': 'completed',
              'download_progress': 100,
            },
            where: 'id = ?',
            whereArgs: [task.trackId],
          );
        }
        check();
      });
      committed = true;
      if (current()) {
        _progressController.add(
          DownloadProgressEvent(
            taskId: taskId,
            trackId: task.trackId,
            bvid: task.bvid!,
            progress: 100,
            stage: 'completed',
            message: completed.warning ?? '下载完成',
          ),
        );
      }
      final raw = File('${task.savePath}.part.m4a');
      if (await raw.exists()) await raw.delete();
      await _downloadTaskDao.updateTempFilePath(taskId, null);
    } catch (error) {
      if (!token.isCancelled && error is! TaskCanceledException) {
        AppLogger.error('DownloadRepository', '下载任务失败: $error');
      }
      await progressWrites;
      if (!_disposed && task != null) {
        final latest = await _downloadTaskDao.getById(taskId);
        if (latest != null && latest.status != DownloadStatus.completed) {
          if (token.isCancelled || error is TaskCanceledException) {
            await _downloadTaskDao.markAsPaused(taskId);
          } else {
            await _downloadTaskDao.markAsFailed(
              taskId,
              errorMessage: error.toString(),
            );
            if (!_disposed) {
              _progressController.add(
                DownloadProgressEvent(
                  taskId: taskId,
                  trackId: task.trackId,
                  bvid: task.bvid ?? '',
                  progress: 0,
                  stage: 'failed',
                  message: '下载失败: $error',
                ),
              );
            }
          }
        }
      }
    } finally {
      if (!committed &&
          result?.success == true &&
          result?.filePath != null &&
          task != null) {
        // 只回收本次任务创建的文件；转换前的原始源保留用于重试。
        final output = File(result!.filePath!);
        if (await output.exists()) {
          final raw = File('${task.savePath}.part.m4a');
          if (result.format == 'm4a' && !await raw.exists()) {
            await output.rename(raw.path);
          } else {
            await output.delete();
          }
        }
      }
      downloader?.dispose();
      _activeDownloads.remove(taskId);
      _slotManager.releaseSlot(taskId);
      if (!_disposed) unawaited(_processQueue());
    }
  }

  /// 获取阶段描述
  String _getStageMessage(String stage) {
    const messages = {
      'fetching_info': '获取视频信息',
      'fetching_audio': '获取音频流',
      'downloading_audio': '下载音频中',
      'downloading_cover': '下载封面中',
      'processing_file': '处理文件',
      'writing_metadata': '写入元数据',
      'completed': '下载完成',
      'converting': '转换格式中',
    };
    return messages[stage] ?? stage;
  }

  /// 处理下载队列 - 启动队列中的下一个任务
  Future<void> _processQueue() async {
    if (_disposed) return;
    // 使用 SlotManager 检查是否有空闲槽位
    if (!_slotManager.hasAvailableSlot) {
      return; // 槽位已满，不处理队列
    }

    // 从队列中取出下一个任务，使用槽位管理器确保并发数不会超过限制
    while (!_disposed &&
        _pendingQueue.isNotEmpty &&
        _slotManager.hasAvailableSlot) {
      final nextTaskId = _pendingQueue.removeAt(0);

      // 通知队列变更
      _queueController.add(nextTaskId);

      // ✅ 检查任务状态，跳过已完成或不存在的任务
      final task = await _downloadTaskDao.getById(nextTaskId);
      if (task == null) {
        AppLogger.warn('DownloadRepository', '队列中的任务不存在: $nextTaskId，跳过');
        continue;
      }

      // 已完成的任务不再下载
      if (task.status == DownloadStatus.completed) {
        AppLogger.info('DownloadRepository', '队列中的任务已完成: $nextTaskId，跳过');
        _slotManager.releaseSlot(nextTaskId); // 释放可能占用的槽位
        continue;
      }

      // 失败的任务需要用户手动重试，不从队列自动启动
      if (task.status == DownloadStatus.failed) {
        AppLogger.info('DownloadRepository', '队列中的任务已失败: $nextTaskId，需要手动重试');
        continue;
      }

      // 启动下载，startDownload 内部会处理槽位占用
      AppLogger.info(
        'DownloadRepository',
        '队列任务开始下载: $nextTaskId, 槽位: ${_slotManager.slotStats}',
      );
      await startDownload(nextTaskId);
    }
  }

  /// 暂停下载（幂等操作 + 超时机制）
  ///
  /// 改进点：
  /// 1. 幂等性：已暂停或已完成则直接返回
  /// 2. 超时机制：后端取消操作设置 5 秒超时
  Future<void> pauseDownload(int taskId) async {
    _activeDownloads[taskId]?.cancel('用户暂停');
    _pendingQueue.remove(taskId);
    await _runningTasks[taskId];
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null || task.status == DownloadStatus.completed) return;
    await _downloadTaskDao.markAsPaused(taskId);
    await _downloadTaskDao.setUserPaused(taskId, true);
    if (!_disposed) _queueController.add(taskId);
  }

  /// 恢复下载
  ///
  /// 支持断点续传：如果有已下载的字节数和 ETag，会从断点继续下载。
  /// 如果并发已满，任务会自动进入等待队列。
  ///
  /// 注意：此方法会立即返回，下载在后台执行。这是为了避免阻塞 UI 操作。
  Future<void> resumeDownload(int taskId) async {
    if (_disposed) return;
    await _runningTasks[taskId];
    // 先更新状态为 pending，确保任务可以重新进入下载流程
    await _downloadTaskDao.markAsPending(taskId);
    await _downloadTaskDao.setUserPaused(taskId, false);

    // 不等待 startDownload 完成，让它异步执行
    // 这样可以避免阻塞 UI，允许用户在下载过程中进行其他操作
    unawaited(startDownload(taskId));

    AppLogger.info('DownloadRepository', '恢复下载: $taskId（后台执行）');
  }

  /// 取消下载
  Future<void> cancelDownload(int taskId) async {
    _activeDownloads[taskId]?.cancel('用户取消');
    _pendingQueue.remove(taskId);
    await _runningTasks[taskId];
    final task = await _downloadTaskDao.getById(taskId);
    if (task != null) await _cleanupTaskTemp(task);
    _slotManager.releaseSlot(taskId);
    await _downloadTaskDao.delete(taskId);
    if (!_disposed) _queueController.add(taskId);
  }

  /// 删除下载任务
  ///
  /// [deleteFile] 是否同时删除已下载的文件
  Future<void> deleteDownloadTask(int taskId, {bool deleteFile = false}) async {
    _activeDownloads[taskId]?.cancel('用户删除任务');
    await _runningTasks[taskId];
    final task = await _downloadTaskDao.getById(taskId);

    // 如果任务在队列中，从队列移除
    if (_pendingQueue.contains(taskId)) {
      _pendingQueue.remove(taskId);
      _queueController.add(taskId);
    }

    // 如果正在下载，先取消
    if (_activeDownloads.containsKey(taskId)) {
      final cancelToken = _activeDownloads[taskId];
      if (cancelToken != null && !cancelToken.isCancelled) {
        cancelToken.cancel('用户删除任务');
      }
      _activeDownloads.remove(taskId);
    }

    // 释放槽位
    _slotManager.releaseSlot(taskId);

    // 删除文件
    if (deleteFile && task?.savePath != null) {
      try {
        final file = File(task!.savePath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('DownloadRepository', '删除文件: ${task.savePath}');
        }
      } catch (e) {
        AppLogger.error('DownloadRepository', '删除文件失败: $e');
      }
    }

    // 更新 Track 状态
    if (deleteFile && task?.trackId != null) {
      final trackToUpdate = await _trackDao.getById(task!.trackId!);
      if (trackToUpdate != null) {
        await _trackDao.markAsNotDownloaded(trackToUpdate.sourceId);
      }
    }

    // 删除任务记录之前，清理本任务私有的临时片段。
    if (task != null) await _cleanupTaskTemp(task);
    await _downloadTaskDao.delete(taskId);

    AppLogger.info('DownloadRepository', '删除任务: $taskId');
  }

  // ==================== 队列相关查询 ====================

  /// 获取队列中的所有任务ID
  List<int> getQueuedTaskIds() => List.unmodifiable(_pendingQueue);

  /// 获取队列中的任务详情
  Future<List<DownloadTask>> getQueuedTasks() async {
    final tasks = <DownloadTask>[];
    for (final taskId in _pendingQueue) {
      final task = await _downloadTaskDao.getById(taskId);
      if (task != null) {
        tasks.add(task);
      }
    }
    return tasks;
  }

  // ==================== 查询方法 ====================

  /// 获取所有下载任务
  Future<List<DownloadTask>> getAllTasks() async {
    return await _downloadTaskDao.getAll();
  }

  /// 获取活跃任务
  Future<List<DownloadTask>> getActiveTasks() async {
    return await _downloadTaskDao.getActive();
  }

  /// 获取待处理任务
  Future<List<DownloadTask>> getPendingTasks() async {
    return await _downloadTaskDao.getPending();
  }

  /// 获取下载中任务
  Future<List<DownloadTask>> getDownloadingTasks() async {
    return await _downloadTaskDao.getDownloading();
  }

  /// 获取已暂停任务
  Future<List<DownloadTask>> getPausedTasks() async {
    return await _downloadTaskDao.getPaused();
  }

  /// 获取已完成任务
  Future<List<DownloadTask>> getCompletedTasks() async {
    return await _downloadTaskDao.getCompleted();
  }

  /// 获取失败任务
  Future<List<DownloadTask>> getFailedTasks() async {
    return await _downloadTaskDao.getFailed();
  }

  /// 根据 BVID 获取任务
  Future<DownloadTask?> getTaskByBvid(String bvid, {int? cid}) async {
    final tasks = await _downloadTaskDao.getAll();
    // 按 bvid + cid 匹配：cid 都为 null 时匹配，或都为相同值时匹配
    return tasks.cast<DownloadTask?>().firstWhere(
      (t) => t?.bvid == bvid && t?.cid == cid,
      orElse: () => null,
    );
  }

  Future<DownloadTask?> getTaskByTrackId(int trackId) async {
    final db = await _db.database;
    final maps = await db.query(
      'download_tasks',
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DownloadTask.fromMap(maps.first);
  }

  // ==================== 批量操作 ====================

  /// 清空已完成的任务
  Future<void> clearCompleted() async {
    await _downloadTaskDao.clearCompleted();
    AppLogger.info('DownloadRepository', '清空已完成任务');
  }

  /// 重试失败的任务
  Future<void> retryFailed() async {
    final failedTasks = await _downloadTaskDao.getFailed();
    for (final task in failedTasks) {
      if (task.id != null) {
        await _downloadTaskDao.updateStatus(task.id!, DownloadStatus.pending);
        await startDownload(task.id!);
      }
    }
    AppLogger.info('DownloadRepository', '重试 ${failedTasks.length} 个失败任务');
  }

  /// 重试卡死的任务（手动触发）
  Future<void> retryStalledAll() async {
    final stalledTasks = await _downloadTaskDao.getStalledTasks();
    for (final task in stalledTasks) {
      if (task.id != null) {
        await _downloadTaskDao.markAsPending(task.id!);
        await _downloadTaskDao.setUserPaused(task.id!, false);
        await startDownload(task.id!);
      }
    }
    AppLogger.info('DownloadRepository', '重试 ${stalledTasks.length} 个卡死任务');
  }

  /// 强制恢复单个任务（忽略状态）
  Future<void> forceResume(int taskId) async {
    _activeDownloads[taskId]?.cancel('重新开始');
    await _runningTasks[taskId];
    await _downloadTaskDao.resetTaskStatus(taskId, DownloadStatus.pending);
    await _downloadTaskDao.setUserPaused(taskId, false);
    unawaited(startDownload(taskId));
  }

  /// 开始所有待处理的任务
  Future<void> startAllPending() async {
    final pendingTasks = await _downloadTaskDao.getPending();
    for (final task in pendingTasks) {
      if (task.id != null) {
        unawaited(startDownload(task.id!));
      }
    }
    AppLogger.info('DownloadRepository', '开始 ${pendingTasks.length} 个待处理任务');
  }

  /// 暂停所有下载中的任务
  Future<void> pauseAll() async {
    final downloadingTasks = await _downloadTaskDao.getDownloading();
    for (final task in downloadingTasks) {
      if (task.id != null) {
        await pauseDownload(task.id!);
      }
    }
    AppLogger.info('DownloadRepository', '暂停 ${downloadingTasks.length} 个任务');
  }

  // ==================== 任务恢复辅助方法 ====================

  /// 获取未完成的任务（pending + paused + downloading）
  Future<List<DownloadTask>> getIncompleteTasks() async {
    return await _downloadTaskDao.getIncomplete();
  }

  /// 更新已下载字节数（用于文件校验后修正）
  Future<void> updateDownloadedBytes(int taskId, int bytes) async {
    await _downloadTaskDao.updateDownloadedBytes(taskId, bytes);
  }

  /// 重置任务状态（用于崩溃恢复）
  Future<void> resetTaskStatus(int taskId, DownloadStatus status) async {
    await _downloadTaskDao.resetTaskStatus(taskId, status);
  }

  /// 标记任务为失败
  Future<void> markAsFailed(int taskId, String errorMessage) async {
    await _downloadTaskDao.markAsFailed(taskId, errorMessage: errorMessage);
  }

  // ==================== 内存状态重建与清理 ====================

  /// 从数据库重建内存状态（应用重启后调用）
  ///
  /// 功能：
  /// 1. 清空当前内存状态（_activeDownloads、_pendingQueue）
  /// 2. 将 downloading 状态的任务移回等待队列
  /// 3. 执行临时文件清理
  Future<void> rebuildState() async {
    if (_runningTasks.isNotEmpty || _disposed) return;
    try {
      // 获取所有下载中的任务
      final downloadingTasks = await _downloadTaskDao.getDownloading();

      // 清空当前内存状态（包括槽位管理器）
      _activeDownloads.clear();
      _pendingQueue.clear();
      _slotManager.clear();

      // 重建队列状态：将崩溃前在下载的任务移回等待队列
      for (final task in downloadingTasks) {
        if (task.id != null) {
          // 下载中的任务实际上已经中断（应用重启）
          // 将它们移回等待队列
          await _downloadTaskDao.resetTaskStatus(
            task.id!,
            DownloadStatus.pending,
          );
          _pendingQueue.add(task.id!);
        }
      }

      // 获取等待中的任务
      final pendingTasks = await _downloadTaskDao.getPending();
      for (final task in pendingTasks) {
        if (task.id != null && !_pendingQueue.contains(task.id!)) {
          _pendingQueue.add(task.id!);
        }
      }

      final stalledTasks = await _downloadTaskDao.getStalledTasks();
      for (final task in stalledTasks) {
        if (task.id != null && !_pendingQueue.contains(task.id!)) {
          _pendingQueue.add(task.id!);
        }
      }

      // 执行清理
      await cleanupOrphanTempFiles();

      AppLogger.info(
        'DownloadRepository',
        '内存状态重建完成: 队列=${_pendingQueue.length}',
      );
    } catch (e) {
      AppLogger.error('DownloadRepository', '内存状态重建失败: $e');
    }
  }

  /// 清理孤立的临时文件
  ///
  /// 删除没有对应任务记录的 .tmp 文件，以及已完成任务的临时文件。
  Future<void> _cleanupTaskTemp(DownloadTask task) async {
    final candidates = <String>{'${task.savePath}.part.m4a'};
    if (task.tempFilePath != null &&
        p.dirname(p.absolute(task.tempFilePath!)) ==
            p.dirname(p.absolute(task.savePath)) &&
        task.tempFilePath!.endsWith('.part.m4a')) {
      candidates.add(task.tempFilePath!);
    }
    for (final source in candidates) {
      for (final suffix in ['', '.json', '.jpg']) {
        final file = File('$source$suffix');
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<void> cleanupOrphanTempFiles() async {
    final tasks = await _downloadTaskDao.getAll();
    for (final task in tasks) {
      if (task.status != DownloadStatus.completed) continue;
      // 只清理有任务记录的私有临时文件，不遍历删除用户目录内的任意 .tmp。
      final candidates = <String>{
        '${task.savePath}.part.m4a',
        if (task.tempFilePath != null &&
            p.dirname(p.absolute(task.tempFilePath!)) ==
                p.dirname(p.absolute(task.savePath)) &&
            task.tempFilePath!.endsWith('.part.m4a'))
          task.tempFilePath!,
      };
      for (final source in candidates) {
        for (final suffix in ['', '.json', '.jpg']) {
          final file = File('$source$suffix');
          if (await file.exists()) await file.delete();
        }
      }
      if (task.id != null) {
        await _downloadTaskDao.updateTempFilePath(task.id!, null);
      }
    }
  }

  // ==================== Watchdog ====================

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      _scanForStalledTasks();
    });
  }

  Future<void> _scanForStalledTasks() async {
    if (_disposed) return;
    try {
      final now = DateTime.now();
      final downloadingTasks = await _downloadTaskDao.getDownloading();
      if (_disposed) return;

      for (final task in downloadingTasks) {
        if (task.id == null || task.userPaused) continue;

        final lastProgress = task.lastProgressAt ?? task.updatedAt;
        if (lastProgress == null) continue;

        final isStalled = now.difference(lastProgress) >= _stalledThreshold;
        if (!isStalled) continue;

        AppLogger.warn('DownloadRepository', '检测到卡死任务: taskId=${task.id}');

        final activeToken = _activeDownloads[task.id!];
        activeToken?.cancel('任务卡死，自动中断');
        await _runningTasks[task.id!];
        if (_disposed) return;
        final latest = await _downloadTaskDao.getById(task.id!);
        if (latest == null ||
            latest.userPaused ||
            latest.status == DownloadStatus.completed) {
          continue;
        }
        await _downloadTaskDao.markAsStalled(task.id!, reason: '下载无进度');
        await _scheduleAutoRetry(task.id!);
      }
    } catch (e) {
      AppLogger.error('DownloadRepository', '卡死检测失败: $e');
    }
  }

  Future<void> _scheduleAutoRetry(int taskId) async {
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null || task.userPaused) return;

    if (task.retryCount >= _maxAutoRetries) {
      await _downloadTaskDao.markAsFailed(taskId, errorMessage: '卡死重试次数超过上限');
      AppLogger.warn('DownloadRepository', '任务卡死重试上限: taskId=$taskId');
      return;
    }

    final nextRetryCount = await _downloadTaskDao.incrementRetry(taskId);
    final delaySeconds = 10 * (1 << (nextRetryCount - 1));
    final clampedSeconds = delaySeconds.clamp(10, 300);
    final delay = Duration(seconds: clampedSeconds);

    AppLogger.info(
      'DownloadRepository',
      '计划自动重试: taskId=$taskId, retry=$nextRetryCount, delay=${delay.inSeconds}s',
    );

    Future.delayed(delay, () async {
      if (_disposed) return;
      final latest = await _downloadTaskDao.getById(taskId);
      if (latest == null || latest.userPaused) return;
      if (latest.status != DownloadStatus.stalled) return;

      await _downloadTaskDao.markAsPending(taskId);
      await startDownload(taskId);
    });
  }

  // ==================== 资源释放 ====================

  /// 释放资源
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // 取消所有活跃下载
    for (final entry in _activeDownloads.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('释放资源');
      }
    }
    _activeDownloads.clear();
    _pendingQueue.clear();
    _watchdogTimer?.cancel();
    _progressController.close();
    _queueController.close();
  }
}
