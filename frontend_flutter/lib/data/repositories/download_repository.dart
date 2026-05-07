import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/utils/app_logger.dart';
import '../../services/resumable_download_service.dart';
import '../../core/storage/shared_storage_service.dart';
import '../../services/download_service.dart' hide DownloadStatus;
import '../../services/bilibili_downloader.dart';
import 'package:path/path.dart' as p;

import '../../core/errors/exceptions.dart';
import '../../models/download_task.dart';
import 'track_repository.dart' show DownloadProgressEvent;
import '../api/bilibili_api_client.dart';
import '../database/app_database.dart';
import '../database/download_task_dao.dart' show InvalidStateTransitionError, DownloadTaskDao;
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
  final BilibiliApiClient _bilibiliApi;
  final ResumableDownloadService _resumableDownloadService;
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
    BilibiliApiClient? bilibiliApi,
    ResumableDownloadService? resumableDownloadService,
    DownloadSlotManager? slotManager,
  })  : _trackDao = trackDao ?? TrackDao(AppDatabase.instance),
        _downloadTaskDao = downloadTaskDao ??
            DownloadTaskDao(AppDatabase.instance),
        _bilibiliApi = bilibiliApi ?? BilibiliApiClient(),
        _resumableDownloadService = resumableDownloadService ??
            ResumableDownloadService(),
        _slotManager = slotManager ?? DownloadSlotManager(maxSlots: _maxConcurrentDownloads) {
    _startWatchdog();
  }

  /// 下载进度事件流
  Stream<DownloadProgressEvent> get progressStream => _progressController.stream;

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
    required String url,
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    return await AppDatabase.instance.transaction<int>((txn) async {
      int trackId;
      final existingTrack = await txn.query(
        'tracks',
        where: 'source_id = ?',
        whereArgs: [bvid],
        limit: 1,
      );

      if (existingTrack.isNotEmpty) {
        trackId = existingTrack.first['id'] as int;
      } else {
        trackId = await txn.insert('tracks', {
          'source_id': bvid,
          'source_type': 'bilibili',
          'title': title ?? bvid,
          'artist': artist,
          'cover_url': coverUrl,
          'bvid': bvid,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        AppLogger.info('DownloadRepository', '为搜索结果创建 Track: $bvid -> $trackId');
      }

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
        'url': url,
        'save_path': savePath,
        'title': title,
        'artist': artist,
        'cover_url': coverUrl,
        'status': DownloadStatus.pending.value,
        'downloaded_bytes': 0,
        'total_bytes': 0,
        'retry_count': 0,
        'user_paused': 0,
        'created_at': now,
        'updated_at': now,
      });

      AppLogger.info('DownloadRepository', '创建下载任务: $taskId, trackId: $trackId, bvid: $bvid');
      return taskId;
    });
  }

  /// 开始下载
  ///
  /// 执行实际的下载操作。支持并发控制和队列机制：
  /// - 如果并发未满，立即开始下载
  /// - 如果并发已满，任务进入等待队列
  Future<void> startDownload(int taskId) async {
    // 先获取任务信息，检查状态
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) {
      AppLogger.error('DownloadRepository', '任务不存在: $taskId');
      return;
    }

    await _downloadTaskDao.setUserPaused(taskId, false);
    await _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());

    // 如果任务已暂停、已完成或失败，不启动下载（需要显式恢复）
    if (task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.completed ||
        task.status == DownloadStatus.failed) {
      AppLogger.info('DownloadRepository',
        '任务状态为 ${task.status}，不自动启动: $taskId');
      // 从队列中移除（如果存在）
      _pendingQueue.remove(taskId);
      // 释放槽位（如果已占用）
      _slotManager.releaseSlot(taskId);
      return;
    }

    // 检查是否已经在下载中（必须在 restoreSlot 之前检查）
    if (_activeDownloads.containsKey(taskId)) {
      AppLogger.info('DownloadRepository', '任务已在下载中: $taskId');
      return;
    }

    // 尝试恢复槽位（如果是暂停的任务）
    if (!_slotManager.restoreSlot(taskId)) {
      if (!_pendingQueue.contains(taskId)) {
        _pendingQueue.add(taskId);
        AppLogger.info(
          'DownloadRepository',
          '任务 $taskId 进入等待队列，槽位: ${_slotManager.slotStats}',
        );

        await _downloadTaskDao.markAsPending(taskId);
      }
      return;
    }

    if (task.bvid == null) {
      AppLogger.error('DownloadRepository', '任务缺少 BVID: $taskId');
      await _downloadTaskDao.markAsFailed(taskId,
          errorMessage: '任务缺少 BVID');
      _slotManager.releaseSlot(taskId);
      return;
    }

    // 检查是否已经在下载中
    if (_activeDownloads.containsKey(taskId)) {
      AppLogger.info('DownloadRepository', '任务已在下载中: $taskId');
      return;
    }

    // 创建取消令牌
    final cancelToken = CancelToken();
    _activeDownloads[taskId] = cancelToken;

    // 更新状态为下载中
    await _downloadTaskDao.markAsDownloading(taskId);

    AppLogger.info('DownloadRepository',
      '开始下载: taskId=$taskId, bvid=${task.bvid}');

    try {
      // 检查是否支持断点续传（有已下载字节数和 ETag）
      final canResume = task.downloadedBytes > 0 &&
          task.etag != null &&
          (task.tempFilePath != null ||
              (task.totalBytes > 0 && task.downloadedBytes < task.totalBytes));

      final downloadFormat = SharedStorageService.instance.getDownloadFormat();

      if (canResume) {
        // 使用断点续传下载
        AppLogger.info('DownloadRepository', '使用断点续传: 已下载 ${task.downloadedBytes} bytes');
        await _downloadWithResumable(taskId, task, cancelToken);
      } else if (downloadFormat == 'mp3') {
        AppLogger.info('DownloadRepository', '使用后端 SSE 下载: format=$downloadFormat');
        await _downloadWithBackendService(taskId, task, cancelToken, downloadFormat);
      } else {
        AppLogger.info('DownloadRepository', '使用 BilibiliDownloader 下载: format=$downloadFormat');
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
      }

      // 下载完成
      await _downloadTaskDao.markAsCompleted(taskId);
      if (task.trackId != null) {
        await _trackDao.markAsDownloaded(task.trackId!, task.savePath);
      }

      _progressController.add(DownloadProgressEvent(
        taskId: taskId,
        trackId: task.trackId,
        bvid: task.bvid!,
        progress: 100,
        stage: 'completed',
        message: '下载完成',
      ));

      AppLogger.info('DownloadRepository', '下载完成: ${task.savePath}');
    } catch (e) {
      if (cancelToken.isCancelled || e is TaskCanceledException) {
        // 用户取消/暂停 - 保留临时文件以便续传
        await _downloadTaskDao.updateResumableInfo(
          id: taskId,
          tempFilePath: '${task.savePath}.tmp',
        );
        // 注意：此时任务可能已被 pauseDownload() 标记为 paused
        // 使用 try-catch 忽略非法状态转换错误
        try {
          await _downloadTaskDao.markAsPaused(taskId);
        } on InvalidStateTransitionError catch (_) {
          // 任务已经是 paused 状态，忽略
          AppLogger.debug('DownloadRepository', '任务已是 paused 状态，跳过标记');
        } catch (e) {
             // 忽略其他数据库错误，防止覆盖暂停状态
             AppLogger.warn('DownloadRepository', '更新暂停状态时出错(忽略): $e');
        }
        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: 0,
          stage: 'paused',
          message: '下载已暂停',
        ));
      } else {
        // 下载失败 - 检查当前状态，避免对已暂停/已完成的任务进行状态转换
        final currentTask = await _downloadTaskDao.getById(taskId);
        final currentStatus = currentTask?.status;

        // 如果任务已经是 paused 或 completed，不进行失败标记
        if (currentStatus == DownloadStatus.paused ||
            currentStatus == DownloadStatus.completed) {
          AppLogger.info('DownloadRepository',
            '任务状态为 $currentStatus，跳过失败标记: $taskId');
        } else {
          await _downloadTaskDao.markAsFailed(taskId, errorMessage: e.toString());

          _progressController.add(DownloadProgressEvent(
            taskId: taskId,
            trackId: task.trackId,
            bvid: task.bvid!,
            progress: 0,
            stage: 'failed',
            message: '下载失败: $e',
          ));

          AppLogger.error('DownloadRepository', '下载失败: $e');
          // 失败时释放槽位
          _slotManager.releaseSlot(taskId);
        }
      }
    } finally {
      _activeDownloads.remove(taskId);

      // ✅ 修复槽位处理逻辑：
      // - 暂停时：释放槽位（让其他任务可以使用）
      // - 完成时：释放槽位
      // - 失败时：已在 catch 中释放
      // - 其他情况：确保槽位被释放
      if (cancelToken.isCancelled) {
        // 暂停时不预留槽位，让其他任务可以开始
        _slotManager.releaseSlot(taskId);
      } else {
        // 完成或其他情况，释放槽位
        _slotManager.releaseSlot(taskId);
      }

      // 触发队列中的下一个任务（不等待，避免阻塞）
      try {
        _processQueue();
      } catch (e) {
        AppLogger.error('DownloadRepository', '处理后队列时出错: $e');
      }
    }
  }

  /// 使用断点续传下载
  Future<void> _downloadWithResumable(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
  ) async {
    final result = await _resumableDownloadService.downloadAudio(
      bvid: task.bvid!,
      savePath: task.savePath,
      downloadedBytes: task.downloadedBytes,
      etag: task.etag,
      lastModified: task.lastModified,
      onProgress: (current, total, percent) async {
        await _downloadTaskDao.updateResumableInfo(
          id: taskId,
          downloadedBytes: current,
          totalBytes: total,
          tempFilePath: '${task.savePath}.tmp',
        );
        await _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());
        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: percent,
          stage: 'downloading',
          message: '下载中 $current/$total',
        ));
      },
    );

    if (result.success) {
      // 保存 ETag 和 Last-Modified 以便后续续传
      await _downloadTaskDao.updateResumableInfo(
        id: taskId,
        etag: result.etag,
        lastModified: result.lastModified,
      );
      await _downloadTaskDao.updateTempFilePath(taskId, null);
    } else {
      if (result.errorType == ResumableDownloadErrorType.etagMismatch ||
          result.errorType == ResumableDownloadErrorType.notResumable) {
        AppLogger.warn('DownloadRepository',
          '断点续传不可用，回退全量下载: ${result.error}');
        await _downloadTaskDao.updateResumableInfo(
          id: taskId,
          downloadedBytes: 0,
          totalBytes: 0,
          etag: null,
          lastModified: null,
        );
        await _downloadTaskDao.updateTempFilePath(taskId, null);
        // 回退到全量下载，根据格式设置选择下载路径
        final downloadFormat = SharedStorageService.instance.getDownloadFormat();
        if (downloadFormat == 'mp3') {
          await _downloadWithBackendService(taskId, task, cancelToken, downloadFormat);
        } else {
          await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
        }
        return;
      }
      throw Exception(result.error ?? '下载失败');
    }
  }

  /// 使用 BilibiliDownloader 下载（零转换方案）
  Future<void> _downloadWithBilibiliDownloader(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
  ) async {
    final downloader = BilibiliDownloader(_bilibiliApi);

    // 检查取消状态
    if (cancelToken.isCancelled) {
      throw TaskCanceledException();
    }

    // 生成文件名
    final fileName = task.title ?? task.bvid ?? 'download';
    final saveDir = p.dirname(task.savePath);

    final result = await downloader.download(
      bvid: task.bvid!,
      saveDir: saveDir,
      fileName: fileName,
      onProgress: (percent, stage) {
        if (cancelToken.isCancelled) {
          cancelToken.cancel('用户取消');
          throw TaskCanceledException();
        }

        _downloadTaskDao.updateProgressPercent(taskId, percent);
        _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());

        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: percent,
          stage: stage,
          message: _getStageMessage(stage),
        ));
      },
    );

    if (!result.success) {
      throw Exception(result.error ?? '下载失败');
    }

    // 更新任务状态（文件路径由 BilibiliDownloader 直接写入，这里更新数据库记录）
    final updatedTask = await _downloadTaskDao.getById(taskId);
    if (updatedTask != null && result.filePath != null) {
      await _downloadTaskDao.update(updatedTask.copyWith(
        savePath: result.filePath,
        totalBytes: result.fileSize,
        downloadedBytes: result.fileSize,
      ));
    }
  }

  /// 使用 DownloadService 下载（后端 HTTP，支持格式选择）
  Future<void> _downloadWithBackendService(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
    String format,
  ) async {
    final service = DownloadService();

    try {
      final result = await service.simpleDownload(
        bvid: task.bvid!,
        savePath: task.savePath,
        format: format,
        onProgress: (received, total) {
          if (cancelToken.isCancelled) {
            throw TaskCanceledException();
          }

          final percent = total > 0 ? (received * 100 ~/ total) : 0;
          _downloadTaskDao.updateProgressPercent(taskId, percent);
          _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());

          _progressController.add(DownloadProgressEvent(
            taskId: taskId,
            trackId: task.trackId,
            bvid: task.bvid!,
            progress: percent,
            stage: 'downloading',
            message: '下载中 $received/$total',
          ));
        },
      );

      if (!result.success) {
        throw Exception(result.error ?? '下载失败');
      }

      // 更新文件大小到数据库（为未来可能的断点续传做准备）
      final file = File(task.savePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        final updatedTask = await _downloadTaskDao.getById(taskId);
        if (updatedTask != null) {
          await _downloadTaskDao.update(updatedTask.copyWith(
            totalBytes: fileSize,
            downloadedBytes: fileSize,
          ));
        }
      }
    } finally {
      service.dispose();
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
    };
    return messages[stage] ?? stage;
  }

  /// 处理下载队列 - 启动队列中的下一个任务
  Future<void> _processQueue() async {
    // 使用 SlotManager 检查是否有空闲槽位
    if (!_slotManager.hasAvailableSlot) {
      return; // 槽位已满，不处理队列
    }

    // 从队列中取出下一个任务，使用槽位管理器确保并发数不会超过限制
    while (_pendingQueue.isNotEmpty && _slotManager.hasAvailableSlot) {
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
      AppLogger.info('DownloadRepository', '队列任务开始下载: $nextTaskId, 槽位: ${_slotManager.slotStats}');
      await startDownload(nextTaskId);
    }
  }

  /// 暂停下载（幂等操作 + 超时机制）
  ///
  /// 改进点：
  /// 1. 幂等性：已暂停或已完成则直接返回
  /// 2. 超时机制：后端取消操作设置 5 秒超时
  Future<void> pauseDownload(int taskId) async {
    // 获取任务信息
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) {
      AppLogger.warn('DownloadRepository', '任务不存在: $taskId');
      return;
    }

    // 幂等性检查：已暂停或已完成则直接返回
    if (task.status == DownloadStatus.paused) {
      AppLogger.info('DownloadRepository',
        '任务 $taskId 已是 paused 状态，跳过暂停');
      return;
    }
    if (task.status == DownloadStatus.completed) {
      AppLogger.info('DownloadRepository',
        '任务 $taskId 已是 completed 状态，跳过暂停');
      return;
    }

    // 如果任务在队列中，从队列移除（幂等）
    if (_pendingQueue.contains(taskId)) {
      _pendingQueue.remove(taskId);
      _queueController.add(taskId);
      AppLogger.info('DownloadRepository', '任务 $taskId 从队列中移除（暂停）');
    }

    // 取消前端的下载流（幂等）
    final cancelToken = _activeDownloads[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户暂停');
      _activeDownloads.remove(taskId);
    }

    // 更新数据库状态
    await _downloadTaskDao.markAsPaused(taskId);
    await _downloadTaskDao.setUserPaused(taskId, true);

    AppLogger.info('DownloadRepository', '暂停完成: $taskId');
  }

  /// 恢复下载
  ///
  /// 支持断点续传：如果有已下载的字节数和 ETag，会从断点继续下载。
  /// 如果并发已满，任务会自动进入等待队列。
  ///
  /// 注意：此方法会立即返回，下载在后台执行。这是为了避免阻塞 UI 操作。
  Future<void> resumeDownload(int taskId) async {
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
    // 如果任务在队列中，从队列移除
    if (_pendingQueue.contains(taskId)) {
      _pendingQueue.remove(taskId);
      _queueController.add(taskId);
    }

    // 获取任务信息
    final task = await _downloadTaskDao.getById(taskId);

    final cancelToken = _activeDownloads[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户取消');
    }

    if (task?.id != null) {
      await _downloadTaskDao.setUserPaused(task!.id!, false);
    }

    // 释放槽位
    _slotManager.releaseSlot(taskId);

    await _downloadTaskDao.delete(taskId);

    AppLogger.info('DownloadRepository', '取消下载: $taskId');
  }

  /// 删除下载任务
  ///
  /// [deleteFile] 是否同时删除已下载的文件
  Future<void> deleteDownloadTask(int taskId, {bool deleteFile = false}) async {
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
    if (task?.trackId != null) {
      final trackToUpdate = await _trackDao.getById(task!.trackId!);
      if (trackToUpdate != null) {
        await _trackDao.update(trackToUpdate.copyWith(
          isDownloaded: false,
          localPath: null,
        ));
      }
    }

    // 删除任务记录
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
  Future<DownloadTask?> getTaskByBvid(String bvid) async {
    return await _downloadTaskDao.getByBvid(bvid);
  }

  Future<DownloadTask?> getTaskByTrackId(int trackId) async {
    final db = await AppDatabase.instance.database;
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
    await _downloadTaskDao.resetTaskStatus(taskId, DownloadStatus.pending);
    await _downloadTaskDao.setUserPaused(taskId, false);
    await startDownload(taskId);
  }

  /// 开始所有待处理的任务
  Future<void> startAllPending() async {
    final pendingTasks = await _downloadTaskDao.getPending();
    for (final task in pendingTasks) {
      if (task.id != null) {
        await startDownload(task.id!);
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
          await _downloadTaskDao.resetTaskStatus(task.id!, DownloadStatus.pending);
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
      await cleanupStalePausedTasks();

      AppLogger.info('DownloadRepository',
        '内存状态重建完成: 队列=${_pendingQueue.length}');
    } catch (e) {
      AppLogger.error('DownloadRepository', '内存状态重建失败: $e');
    }
  }

  /// 清理孤立的临时文件
  ///
  /// 删除没有对应任务记录的 .tmp 文件，以及已完成任务的临时文件。
  Future<void> cleanupOrphanTempFiles() async {
    try {
      // 获取下载目录（从第一个任务的 savePath 推断）
      final tasks = await _downloadTaskDao.getAll();
      if (tasks.isEmpty) return;

      // 从第一个任务推断下载目录
      final firstTask = tasks.firstWhere((t) => t.savePath.isNotEmpty,
        orElse: () => tasks.first);
      final downloadDir = Directory(firstTask.savePath).parent;

      if (!await downloadDir.exists()) {
        return;
      }

      final tempFiles = downloadDir
          .listSync()
          .where((f) => f.path.endsWith('.tmp'))
          .cast<File>()
          .toList();

      for (final tempFile in tempFiles) {
        // 检查是否有对应的任务记录
        final savePath = tempFile.path.replaceAll('.tmp', '');
        final task = await _downloadTaskDao.getBySavePath(savePath);

        if (task == null || task.status == DownloadStatus.completed) {
          // 无对应任务或已完成，删除临时文件
          await tempFile.delete();
          AppLogger.info('DownloadRepository', '清理孤立临时文件: ${tempFile.path}');
        }
      }
    } catch (e) {
      AppLogger.error('DownloadRepository', '清理临时文件失败: $e');
    }
  }

  /// 清理超时的暂停任务
  ///
  /// 超过 7 天未完成的暂停任务会被标记为失败。
  Future<void> cleanupStalePausedTasks() async {
    try {
      const staleDuration = Duration(days: 7);
      final now = DateTime.now();

      final pausedTasks = await _downloadTaskDao.getPaused();
      for (final task in pausedTasks) {
        if (task.updatedAt != null) {
          final age = now.difference(task.updatedAt!);
          if (age > staleDuration) {
            await _downloadTaskDao.markAsFailed(
              task.id!,
              errorMessage: '下载超时，任务已暂停超过 7 天',
            );
            AppLogger.info('DownloadRepository', '清理超时任务: ${task.id}');
          }
        }
      }
    } catch (e) {
      AppLogger.error('DownloadRepository', '清理超时任务失败: $e');
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
    try {
      final now = DateTime.now();
      final downloadingTasks = await _downloadTaskDao.getDownloading();

      for (final task in downloadingTasks) {
        if (task.id == null || task.userPaused) continue;

        final lastProgress = task.lastProgressAt ?? task.updatedAt;
        if (lastProgress == null) continue;

        final isStalled = now.difference(lastProgress) >= _stalledThreshold;
        if (!isStalled) continue;

        AppLogger.warn('DownloadRepository',
          '检测到卡死任务: taskId=${task.id}');

        await _downloadTaskDao.markAsStalled(
          task.id!,
          reason: '下载卡死，超过阈值未更新进度',
        );

        final activeToken = _activeDownloads[task.id!];
        if (activeToken != null && !activeToken.isCancelled) {
          activeToken.cancel('任务卡死，自动中断');
          _activeDownloads.remove(task.id!);
        }

        _slotManager.releaseSlot(task.id!);

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
      await _downloadTaskDao.markAsFailed(taskId,
        errorMessage: '卡死重试次数超过上限');
      AppLogger.warn('DownloadRepository',
        '任务卡死重试上限: taskId=$taskId');
      return;
    }

    final nextRetryCount = await _downloadTaskDao.incrementRetry(taskId);
    final delaySeconds = 10 * (1 << (nextRetryCount - 1));
    final clampedSeconds = delaySeconds.clamp(10, 300);
    final delay = Duration(seconds: clampedSeconds);

    AppLogger.info('DownloadRepository',
      '计划自动重试: taskId=$taskId, retry=$nextRetryCount, delay=${delay.inSeconds}s');

    Future.delayed(delay, () async {
      final latest = await _downloadTaskDao.getById(taskId);
      if (latest == null || latest.userPaused) return;
      if (latest.status != DownloadStatus.stalled) return;

      await _downloadTaskDao.markAsPending(taskId);
      await startDownload(taskId);
    });
  }

  // ==================== URL 获取 ====================

  /// 获取下载 URL
  String getDownloadUrl(String bvid, {String format = 'mp3'}) {
    return _bilibiliApi.getDownloadUrl(bvid, format: format);
  }

  /// 获取音频代理 URL（用于流式播放）
  String getProxyAudioUrl(String originalUrl) {
    return _bilibiliApi.getProxyAudioUrl(originalUrl);
  }

  /// 获取图片代理 URL
  String getProxyImageUrl(String originalUrl) {
    return _bilibiliApi.getProxyImageUrl(originalUrl);
  }

  // ==================== 资源释放 ====================

  /// 释放资源
  void dispose() {
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
