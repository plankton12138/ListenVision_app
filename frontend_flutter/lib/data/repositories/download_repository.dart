import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/utils/app_logger.dart';

import '../../models/download_task.dart';
import 'track_repository.dart' show DownloadProgressEvent;
import '../api/bilibili_api_client.dart';
import '../database/app_database.dart';
import '../database/download_task_dao.dart';
import '../database/track_dao.dart';

/// 下载仓库 - 增强版
///
/// 整合新的本地优先架构，支持：
/// 1. 下载任务持久化到数据库
/// 2. 断点续传（待实现）
/// 3. 并发下载控制
/// 4. 下载进度实时同步
class DownloadRepository {
  final TrackDao _trackDao;
  final DownloadTaskDao _downloadTaskDao;
  final BilibiliApiClient _bilibiliApi;


  // 当前活跃的下载任务
  final Map<int, CancelToken> _activeDownloads = {};

  // 待处理任务队列 (存储 taskId)
  final List<int> _pendingQueue = [];

  // 下载进度事件流
  final _progressController =
      StreamController<DownloadProgressEvent>.broadcast();

  // 队列变更事件流
  final _queueController = StreamController<int>.broadcast();

  // 最大并发下载数
  static const int _maxConcurrentDownloads = 3;

  DownloadRepository({
    TrackDao? trackDao,
    DownloadTaskDao? downloadTaskDao,
    BilibiliApiClient? bilibiliApi,
  })  : _trackDao = trackDao ?? TrackDao(AppDatabase.instance),
        _downloadTaskDao = downloadTaskDao ??
            DownloadTaskDao(AppDatabase.instance),
        _bilibiliApi = bilibiliApi ?? BilibiliApiClient();

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
  Future<int> addDownloadTask({
    required String bvid,
    required String url,
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    // 检查是否已存在该 BVID 的任务
    final existingTask = await _downloadTaskDao.getByBvid(bvid);
    if (existingTask != null) {
      AppLogger.info('DownloadRepository', '任务已存在: $bvid, 返回现有任务');
      return existingTask.id!;
    }

    // 获取或创建 Track
    final track = await _trackDao.getBySourceId(bvid);
    final trackId = track?.id;

    // 创建任务
    final taskId = await _downloadTaskDao.create(
      url: url,
      savePath: savePath,
      trackId: trackId,
      bvid: bvid,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
    );

    AppLogger.info('DownloadRepository', '创建下载任务: $taskId, bvid: $bvid');

    // 更新 Track 下载状态
    if (trackId != null) {
      await _trackDao.updateDownloadStatus(
        trackId,
        DownloadStatus.pending,
        0,
      );
    }

    return taskId;
  }

  /// 开始下载
  ///
  /// 执行实际的下载操作。支持并发控制和队列机制：
  /// - 如果并发未满，立即开始下载
  /// - 如果并发已满，任务进入等待队列
  Future<void> startDownload(int taskId) async {
    // 检查并发数，如果已满则加入队列
    if (_activeDownloads.length >= _maxConcurrentDownloads) {
      // 避免重复入队
      if (!_pendingQueue.contains(taskId)) {
        _pendingQueue.add(taskId);
        AppLogger.info(
          'DownloadRepository',
          '任务 $taskId 进入等待队列，当前队列位置: ${_pendingQueue.length}',
        );

        // 更新任务状态为 pending（等待中）
        await _downloadTaskDao.markAsPending(taskId);
        final task = await _downloadTaskDao.getById(taskId);
        if (task?.trackId != null) {
          await _trackDao.updateDownloadStatus(
            task!.trackId!,
            DownloadStatus.pending,
            0,
          );
        }
      }
      return;
    }

    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) {
      AppLogger.error('DownloadRepository', '任务不存在: $taskId');
      return;
    }

    if (task.bvid == null) {
      AppLogger.error('DownloadRepository', '任务缺少 BVID: $taskId');
      await _downloadTaskDao.markAsFailed(taskId,
          errorMessage: '任务缺少 BVID');
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
    if (task.trackId != null) {
      await _trackDao.updateDownloadStatus(
        task.trackId!,
        DownloadStatus.downloading,
        0,
      );
    }

    AppLogger.info('DownloadRepository', '开始下载: ${task.bvid} -> ${task.savePath}');

    try {
      // 执行下载
      await _bilibiliApi.downloadAudio(
        bvid: task.bvid!,
        savePath: task.savePath,
        onProgress: (percent, stage, message) async {
          // 更新数据库
          await _downloadTaskDao.updateProgressPercent(taskId, percent);
          if (task.trackId != null) {
            await _trackDao.updateDownloadStatus(
              task.trackId!,
              DownloadStatus.downloading,
              percent,
            );
          }

          // 发送进度事件
          _progressController.add(DownloadProgressEvent(
            taskId: taskId,
            trackId: task.trackId,
            bvid: task.bvid!,
            progress: percent,
            stage: stage,
            message: message,
          ));
        },
      );

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
      if (cancelToken.isCancelled) {
        // 用户取消
        await _downloadTaskDao.markAsPaused(taskId);
        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: 0,
          stage: 'paused',
          message: '下载已暂停',
        ));
      } else {
        // 下载失败
        await _downloadTaskDao.markAsFailed(taskId, errorMessage: e.toString());
        if (task.trackId != null) {
          await _trackDao.updateDownloadStatus(
            task.trackId!,
            DownloadStatus.failed,
            0,
          );
        }

        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: 0,
          stage: 'failed',
          message: '下载失败: $e',
        ));

        AppLogger.error('DownloadRepository', '下载失败: $e');
      }
    } finally {
      _activeDownloads.remove(taskId);
      _processQueue(); // 触发队列中的下一个任务（不等待，避免阻塞）
    }
  }

  /// 处理下载队列 - 启动队列中的下一个任务
  Future<void> _processQueue() async {
    // 检查是否有活跃下载槽位
    if (_activeDownloads.length >= _maxConcurrentDownloads) {
      return; // 并发已满，不处理队列
    }

    // 从队列中取出下一个任务，等待其加入 _activeDownloads 后再处理下一个
    // 确保并发数不会瞬时超过限制
    while (_pendingQueue.isNotEmpty &&
        _activeDownloads.length < _maxConcurrentDownloads) {
      final nextTaskId = _pendingQueue.removeAt(0);

      // 通知队列变更
      _queueController.add(nextTaskId);

      // 启动下载，等待其初始化完成（加入 _activeDownloads）后再继续
      AppLogger.info('DownloadRepository', '队列任务开始下载: $nextTaskId');
      await startDownload(nextTaskId);
    }
  }

  /// 暂停下载
  Future<void> pauseDownload(int taskId) async {
    // 如果任务在队列中，从队列移除
    if (_pendingQueue.contains(taskId)) {
      _pendingQueue.remove(taskId);
      _queueController.add(taskId);
      AppLogger.info('DownloadRepository', '任务 $taskId 从队列中移除（暂停）');
    }

    final cancelToken = _activeDownloads[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户暂停');
    }

    await _downloadTaskDao.markAsPaused(taskId);

    final task = await _downloadTaskDao.getById(taskId);
    if (task?.trackId != null) {
      await _trackDao.updateDownloadStatus(
        task!.trackId!,
        DownloadStatus.paused,
        0,
      );
    }

    AppLogger.info('DownloadRepository', '暂停下载: $taskId');
  }

  /// 恢复下载
  ///
  /// 先标记为待处理状态，再启动下载流程。
  /// 如果并发已满，任务会自动进入等待队列。
  /// TODO: 未来实现断点续传（Phase 7）
  Future<void> resumeDownload(int taskId) async {
    // 先更新状态为 pending，确保任务可以重新进入下载流程
    await _downloadTaskDao.markAsPending(taskId);
    await startDownload(taskId);

    AppLogger.info('DownloadRepository', '恢复下载: $taskId');
  }

  /// 取消下载
  Future<void> cancelDownload(int taskId) async {
    // 如果任务在队列中，从队列移除
    if (_pendingQueue.contains(taskId)) {
      _pendingQueue.remove(taskId);
      _queueController.add(taskId);
    }

    final cancelToken = _activeDownloads[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户取消');
    }

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
      await _trackDao.updateDownloadStatus(
        task!.trackId!,
        DownloadStatus.pending,
        0,
      );
      // 获取 track 并更新
      final trackToUpdate = await _trackDao.getById(task.trackId!);
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
    _progressController.close();
    _queueController.close();
  }
}
