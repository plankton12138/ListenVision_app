import 'package:dartz/dartz.dart';
import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/download_task.dart';
import 'package:demo/domain/repositories/download_repository.dart';
import 'package:demo/core/utils/metadata_writer.dart';
import 'package:demo/data/managers/download_executor.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// 下载管理器
///
/// Clean Architecture 协调层：
/// - 协调各模块完成下载流程
/// - 使用 Repository 模式访问数据
/// - 状态管理（通过 ChangeNotifier）
class DownloadManager with ChangeNotifier {
  // ==================== 依赖注入 ====================

  final DownloadRepository _repository;
  final DownloadExecutorManager _executorManager;
  final MetadataWriter _metadataWriter;

  // ==================== 状态 ====================

  /// 所有下载任务（内存缓存，从数据库加载）
  List<DownloadTask> _downloads = [];

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== 构造函数 ====================

  DownloadManager({
    DownloadRepository? repository,
  })  : _repository = repository ?? ServiceFactory.instance.downloadRepository,
        _metadataWriter = MetadataWriter(),
        _executorManager = DownloadExecutorManager(
          repository: repository ?? ServiceFactory.instance.downloadRepository,
          maxConcurrent: 3,
        ) {
    // 初始化仓库
    _repository.getAllTasks().then((result) {
      result.fold(
        (failure) => debugPrint('【DownloadManager】加载任务失败: $failure'),
        (tasks) {
          _downloads = tasks;
          notifyListeners();
        },
      );
      _isInitialized = true;
    });
  }

  // ==================== 公开方法 ====================

  /// 初始化数据库（向后兼容）
  Future<void> initDatabase() async {
    final result = await _repository.getAllTasks();
    result.fold(
      (failure) => debugPrint('【DownloadManager】初始化失败: $failure'),
      (tasks) {
        _downloads = tasks;
        notifyListeners();
      },
    );
    _isInitialized = true;
  }

  /// 刷新下载列表
  Future<void> refreshDownloads() async {
    final result = await _repository.getAllTasks();
    result.fold(
      (failure) => debugPrint('【DownloadManager】刷新失败: $failure'),
      (tasks) {
        _downloads = tasks;
        notifyListeners();
      },
    );
  }

  /// 获取所有下载任务
  List<DownloadTask> get downloads => List.unmodifiable(_downloads);

  // ==================== 下载操作 ====================

  /// 添加下载任务
  ///
  /// 支持：
  /// 1. 完整URL: https://www.bilibili.com/video/BVxxx
  /// 2. 纯BVID: BVxxx
  Future<void> addDownload(BuildContext context, String url) async {
    // 确保已初始化
    if (!_isInitialized) {
      await initDatabase();
    }

    // 处理直接传入 BVID 的情况
    if (url.startsWith('BV') && url.length == 12) {
      await _downloadByBvid(context, url);
      return;
    }

    // 检查 URL 格式
    if (!url.startsWith('https://www.bilibili.com/video/') &&
        !url.startsWith('http://www.bilibili.com/video/')) {
      showMySnackBar(context, '仅支持B站视频下载', Colors.red, 500);
      return;
    }

    try {
      final bvid = _extractBvid(url);
      if (bvid == null || bvid.isEmpty) {
        showMySnackBar(context, '无法解析视频ID', Colors.red, 500);
        return;
      }
      await _downloadByBvid(context, bvid);
    } catch (e) {
      debugPrint('【DownloadManager】下载失败: $e');
      showMySnackBar(context, '下载失败: $e', Colors.red, 1000);
    }
  }

  /// 通过 BVID 下载
  Future<void> _downloadByBvid(BuildContext context, String bvid) async {
    debugPrint('【DownloadManager】开始下载: $bvid');

    try {
      // 1. 获取视频信息（使用 Repository）
      final videoResult = await ServiceFactory.instance.bilibiliRepository.getAudioInfo(bvid: bvid);

      final videoData = videoResult.fold(
        (failure) {
          debugPrint('【DownloadManager】获取视频信息失败: $failure');
          return null;
        },
        (audio) => {
          'title': audio.title,
          'artist': audio.artist ?? '未知艺术家',
          'pic': audio.coverUrl,
          'audioUrl': audio.streamUrl,
          'bvid': bvid,
        },
      );

      if (videoData == null || videoData['audioUrl'] == null) {
        showMySnackBar(context, '获取视频信息失败', Colors.red, 500);
        return;
      }

      final title = videoData['title'] as String;
      final artist = videoData['artist'] as String;
      final audioUrl = videoData['audioUrl'] as String;

      // 2. 检查是否已存在
      final existsResult = await _repository.existsByBvid(bvid);
      final exists = existsResult.fold((_) => false, (e) => e);
      if (exists) {
        showMySnackBar(context, '该任务已存在', Colors.orange, 1000);
        return;
      }

      // 3. 选择保存目录
      final saveDir = await _pickDirectory();
      if (saveDir == null) return;

      // 4. 确定文件路径
      final sanitizedTitle = _sanitizeTitle(title);
      final fileName = '$sanitizedTitle.m4a';
      final savePath = path.join(saveDir, fileName);

      // 5. 创建下载任务记录
      final createResult = await _repository.createTask(
        url: audioUrl,
        savePath: savePath,
        originalUrl: 'https://www.bilibili.com/video/$bvid',
        title: title,
        artist: artist,
        coverUrl: videoData['pic'] as String?,
        bvid: bvid,
      );

      final taskId = createResult.fold((_) => -1, (id) => id);
      if (taskId == -1) {
        showMySnackBar(context, '创建任务失败', Colors.red, 500);
        return;
      }

      debugPrint('【DownloadManager】任务创建成功: $taskId');

      // 6. 启动下载
      _startDownload(taskId, audioUrl, savePath, videoData);

      // 7. 刷新列表
      await refreshDownloads();

      showMySnackBar(context, '已添加到下载列表: $title', Colors.green, 1000);
    } catch (e) {
      debugPrint('【DownloadManager】_downloadByBvid 失败: $e');
      showMySnackBar(context, '下载失败: $e', Colors.red, 1000);
    }
  }

  /// 启动下载执行
  void _startDownload(
    int taskId,
    String audioUrl,
    String savePath,
    Map<String, dynamic> videoData,
  ) {
    _executorManager.startTask(
      taskId: taskId,
      url: audioUrl,
      savePath: savePath,
      onProgress: (downloaded, total) async {
        // 更新进度
        await _repository.updateProgress(taskId, downloaded, total);
        
        // 更新内存中的进度
        final index = _downloads.indexWhere((d) => d.id == taskId);
        if (index != -1) {
          _downloads[index] = _downloads[index].copyWith(
            downloadedBytes: downloaded,
            totalBytes: total,
          );
        }
        
        notifyListeners();
      },
      onCompletion: (filePath, success) async {
        await refreshDownloads();

        if (success) {
          await _writeMetadataAfterDownload(filePath, videoData);
        }
      },
    );
  }

  /// 暂停下载
  Future<void> pauseDownload(int id) async {
    await _repository.updateStatus(id, DownloadStatus.paused);
    _executorManager.pauseTask(id);
    await refreshDownloads();
    debugPrint('【DownloadManager】已暂停任务: $id');
  }

  /// 恢复下载
  Future<void> resumeDownload(int id) async {
    final taskResult = await _repository.getTask(id);
    taskResult.fold(
      (failure) => debugPrint('【DownloadManager】获取任务失败: $failure'),
      (task) async {
        if (task == null) return;
        
        await _repository.updateStatus(id, DownloadStatus.pending);
        _startDownload(id, task.url, task.savePath, {
          'title': task.title,
          'artist': task.artist,
          'pic': task.coverUrl,
          'bvid': task.bvid,
        });
        await refreshDownloads();
        debugPrint('【DownloadManager】已恢复任务: $id');
      },
    );
  }

  /// 删除下载
  Future<void> deleteDownload(int id) async {
    _executorManager.cancelTask(id);
    await _repository.deleteTask(id);
    await refreshDownloads();
    debugPrint('【DownloadManager】已删除任务: $id');
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    await _repository.clearCompletedTasks();
    await refreshDownloads();
  }

  // ==================== 私有方法 ====================

  /// 加载下载列表
  Future<void> _loadDownloads() async {
    final result = await _repository.getAllTasks();
    result.fold(
      (failure) => debugPrint('【DownloadManager】加载任务失败: $failure'),
      (tasks) => _downloads = tasks,
    );
    notifyListeners();
  }

  /// 下载完成后写入元数据
  Future<void> _writeMetadataAfterDownload(
    String filePath,
    Map<String, dynamic> videoData,
  ) async {
    try {
      await _metadataWriter.writeMetadata(
        filePath: filePath,
        title: videoData['title']?.toString() ?? '未知标题',
        artist: videoData['artist']?.toString() ?? '未知艺术家',
        coverUrl: videoData['pic']?.toString(),
        album: videoData['bvid']?.toString(),
      );
      debugPrint('【DownloadManager】元数据写入成功');
    } catch (e) {
      debugPrint('【DownloadManager】元数据写入失败: $e');
    }
  }

  /// 从 URL 提取 BVID
  String? _extractBvid(String url) {
    final bvidRegex = RegExp(r'(BV[a-zA-Z0-9]{10})');
    final match = bvidRegex.firstMatch(url);
    return match?.group(1);
  }

  /// 选择保存目录
  Future<String?> _pickDirectory() async {
    try {
      return await getDirectoryPath();
    } catch (e) {
      debugPrint('【DownloadManager】选择目录失败: $e');
      return null;
    }
  }

  /// 清理标题字符串（移除非法字符）
  String _sanitizeTitle(String input) {
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ==================== 统计信息 ====================

  /// 获取指定状态的任务数
  int getCountByStatus(DownloadStatus status) {
    return _downloads.where((d) => d.status == status).length;
  }

  /// 进行中的任务数
  int get activeCount => getCountByStatus(DownloadStatus.downloading) +
      getCountByStatus(DownloadStatus.pending);

  /// 已完成的任务数
  int get completedCount => getCountByStatus(DownloadStatus.completed);

  /// 失败的任务数
  int get failedCount => getCountByStatus(DownloadStatus.failed);
}
