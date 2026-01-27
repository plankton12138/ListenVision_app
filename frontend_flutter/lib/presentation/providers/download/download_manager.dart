import 'dart:typed_data';

import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:demo/domain/entities/download_task.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/repositories/download_repository.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;
import 'package:demo/data/datasources/remote/bilibili_api_datasource.dart';

/// 下载管理器
///
/// Clean Architecture 协调层：
/// - 协调各模块完成下载流程
/// - 使用后端带元数据写入的下载 API
/// - 状态管理（通过 ChangeNotifier）
class DownloadManager with ChangeNotifier {
  // ==================== 依赖注入 ====================

  final DownloadRepository _repository;
  final BilibiliApiService _bilibiliApiService;

  // ==================== 状态 ====================

  /// 所有下载任务（内存缓存，从数据库加载）
  List<DownloadTask> _downloads = [];

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== 下载阶段状态 ====================

  /// 下载阶段描述（用于UI显示）
  String _downloadStage = '';
  /// 下载进度百分比（0-100）
  int _downloadProgress = 0;

  String get downloadStage => _downloadStage;
  int get downloadProgress => _downloadProgress;

  // ==================== 构造函数 ====================

  DownloadManager({
    DownloadRepository? repository,
    BilibiliApiService? bilibiliApiService,
  })  : _repository = repository ?? ServiceFactory.instance.downloadRepository,
        _bilibiliApiService = bilibiliApiService ?? BilibiliApiService() {
    // 初始化仓库
    _repository.getAllTasks().then((result) {
      result.fold(
        (failure) => AppLogger.error('DownloadManager', '加载任务失败: $failure'),
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
      (failure) => AppLogger.error('DownloadManager', '初始化失败: $failure'),
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
      (failure) => AppLogger.error('DownloadManager', '刷新失败: $failure'),
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
      DialogHelper.showSnackBar(context, '仅支持B站视频下载', backgroundColor: Colors.red, duration: 500);
      return;
    }

    try {
      final bvid = _extractBvid(url);
      if (bvid == null || bvid.isEmpty) {
        DialogHelper.showSnackBar(context, '无法解析视频ID', backgroundColor: Colors.red, duration: 500);
        return;
      }
      await _downloadByBvid(context, bvid);
    } catch (e) {
      AppLogger.error('DownloadManager', '下载失败: $e');
      DialogHelper.showSnackBar(context, '下载失败: $e', backgroundColor: Colors.red, duration: 1000);
    }
  }

  /// 通过 BVID 下载
  Future<void> _downloadByBvid(BuildContext context, String bvid) async {
    AppLogger.info('DownloadManager', '开始下载: $bvid');

    // 重置进度状态
    _downloadStage = '准备中...';
    _downloadProgress = 0;
    notifyListeners();

    try {
      // 1. 获取视频信息（用于获取标题和UP主）
      final videoResult = await ServiceFactory.instance.bilibiliRepository.getAudioInfo(bvid: bvid);

      final videoData = videoResult.fold(
        (failure) {
          AppLogger.error('DownloadManager', '获取视频信息失败: $failure');
          return null;
        },
        (audio) => {
          'title': audio.title,
          'artist': audio.artist ?? '未知艺术家',
          'pic': audio.coverUrl,
          'bvid': bvid,
        },
      );

      if (videoData == null) {
        DialogHelper.showSnackBar(context, '获取视频信息失败', backgroundColor: Colors.red, duration: 500);
        _downloadStage = '';
        notifyListeners();
        return;
      }

      final title = videoData['title'] as String;
      final artist = videoData['artist'] as String;

      // 2. 检查是否已存在
      final existsResult = await _repository.existsByBvid(bvid);
      final exists = existsResult.fold((_) => false, (e) => e);
      if (exists) {
        DialogHelper.showSnackBar(context, '该任务已存在', backgroundColor: Colors.orange, duration: 1000);
        _downloadStage = '';
        notifyListeners();
        return;
      }

      // 3. 选择保存目录
      final saveDir = await _pickDirectory();
      if (saveDir == null) {
        _downloadStage = '';
        notifyListeners();
        return;
      }

      // 4. 确定文件路径（使用 .mp3 扩展名，后端会写入元数据）
      final sanitizedTitle = _sanitizeTitle(title);
      final fileName = '$sanitizedTitle.mp3';
      final savePath = path.join(saveDir, fileName);

      // 5. 创建下载任务记录
      final downloadUrl = _bilibiliApiService.getDownloadUrl(bvid, format: 'mp3');

      final createResult = await _repository.createTask(
        url: downloadUrl,
        savePath: savePath,
        originalUrl: 'https://www.bilibili.com/video/$bvid',
        title: title,
        artist: artist,
        coverUrl: videoData['pic'] as String?,
        bvid: bvid,
      );

      final taskId = createResult.fold((_) => -1, (id) => id);
      if (taskId == -1) {
        DialogHelper.showSnackBar(context, '创建任务失败', backgroundColor: Colors.red, duration: 500);
        _downloadStage = '';
        notifyListeners();
        return;
      }

      AppLogger.info('DownloadManager', '任务创建成功: $taskId');

      // 6. 启动下载（使用后端带元数据的API）
      _startDownload(taskId, bvid, savePath, title, artist);

      // 7. 刷新列表
      await refreshDownloads();

      DialogHelper.showSnackBar(context, '开始下载: $title', backgroundColor: Colors.green, duration: 1000);
    } catch (e) {
      AppLogger.error('DownloadManager', '_downloadByBvid 失败: $e');
      DialogHelper.showSnackBar(context, '下载失败: $e', backgroundColor: Colors.red, duration: 1000);
      _downloadStage = '';
      notifyListeners();
    }
  }

  /// 启动下载执行
  void _startDownload(
    int taskId,
    String bvid,
    String savePath,
    String title,
    String artist,
  ) {
    // 更新状态为下载中
    _updateTaskStatus(taskId, DownloadStatus.downloading);

    // 设置下载阶段
    _downloadStage = '准备中...';
    _downloadProgress = 0;
    notifyListeners();

    // 使用后端 API 下载（带元数据写入和实时进度）
    AppLogger.info('DownloadManager', '开始调用 downloadAudio...');
    _bilibiliApiService.downloadAudio(
      bvid: bvid,
      savePath: savePath,
      format: 'mp3',
      onProgress: (percent, stage, message) {
        AppLogger.info('DownloadManager', '=== onProgress 回调触发 ===');
        AppLogger.info('DownloadManager', 'percent: $percent, stage: $stage, message: [$message]');
        // 直接使用后端返回的百分比和阶段消息
        _downloadProgress = percent;
        _downloadStage = message;
        AppLogger.info('DownloadManager', '_downloadProgress: $_downloadProgress, _downloadStage: [$_downloadStage]');
        notifyListeners();
        AppLogger.info('DownloadManager', 'notifyListeners() 已调用');
      },
    ).then((_) async {
      // 下载成功
      AppLogger.info('DownloadManager', '下载完成: $savePath');

      _downloadStage = '完成';
      _downloadProgress = 100;
      notifyListeners();

      // 更新任务状态
      await _updateTaskStatus(taskId, DownloadStatus.completed);

      // 添加到本地播放列表
      await _addToLocalPlaylist(savePath, title, artist, null, bvid);

      // 清空进度状态
      Future.delayed(const Duration(seconds: 2), () {
        _downloadStage = '';
        _downloadProgress = 0;
        notifyListeners();
      });
    }).catchError((error) async {
      // 下载失败
      AppLogger.error('DownloadManager', '下载失败: $error');

      _downloadStage = '失败';
      notifyListeners();

      await _updateTaskStatus(taskId, DownloadStatus.failed);

      Future.delayed(const Duration(seconds: 2), () {
        _downloadStage = '';
        _downloadProgress = 0;
        notifyListeners();
      });
    });
  }

  /// 更新任务状态
  Future<void> _updateTaskStatus(int taskId, DownloadStatus status) async {
    await _repository.updateStatus(taskId, status);

    // 更新内存中的状态
    final index = _downloads.indexWhere((d) => d.id == taskId);
    if (index != -1) {
      _downloads[index] = _downloads[index].copyWith(status: status);
      notifyListeners();
    }
  }

  /// 暂停下载（注意：后端转换不支持暂停，此功能仅更新状态）
  Future<void> pauseDownload(int id) async {
    await _repository.updateStatus(id, DownloadStatus.paused);
    await refreshDownloads();
    _downloadStage = '已暂停';
    notifyListeners();
    AppLogger.info('DownloadManager', '已暂停任务: $id');
  }

  /// 恢复下载（重新启动下载任务）
  Future<void> resumeDownload(int id) async {
    final taskResult = await _repository.getTask(id);
    taskResult.fold(
      (failure) => AppLogger.error('DownloadManager', '获取任务失败: $failure'),
      (task) async {
        if (task == null) return;

        // 从 BVID 重新开始下载
        final bvid = task.bvid ?? '';
        if (bvid.isEmpty) {
          AppLogger.error('DownloadManager', '任务缺少 BVID，无法恢复');
          return;
        }

        await _repository.updateStatus(id, DownloadStatus.pending);
        _startDownload(id, bvid, task.savePath, task.title ?? '未知标题', task.artist ?? '未知艺术家');
        await refreshDownloads();
        AppLogger.info('DownloadManager', '已恢复任务: $id');
      },
    );
  }

  /// 删除下载
  Future<void> deleteDownload(int id) async {
    await _repository.deleteTask(id);
    await refreshDownloads();
    AppLogger.info('DownloadManager', '已删除任务: $id');
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    await _repository.clearCompletedTasks();
    await refreshDownloads();
  }

  // ==================== 私有方法 ====================

  /// 将文件添加到本地播放列表数据库
  Future<void> _addToLocalPlaylist(
    String filePath,
    String title,
    String artist,
    Uint8List? coverData,
    String url,
  ) async {
    try {
      final db = PlaylistManager();

      // 检查是否已存在（通过 getAllAudios 查找）
      final allAudios = await db.getAllAudios();
      final exists = allAudios.any((audio) => audio.filePath == filePath);
      if (exists) {
        AppLogger.debug('DownloadManager', '文件已在本地播放列表中: $title');
        return;
      }

      // 创建 LocalAudio 对象
      final audio = LocalAudio(
        filePath: filePath,
        title: title,
        artist: artist,
        duration: 0, // 下载时不知道时长，播放时会更新
        albumArt: coverData,
        url: url,
      );

      // 添加到数据库
      final result = await db.insertAudio(audio);
      if (result != -1) {
        AppLogger.info('DownloadManager', '已添加到本地播放列表: $title - $artist');
      } else {
        AppLogger.debug('DownloadManager', '文件已存在于本地播放列表: $title');
      }
    } catch (e) {
      AppLogger.error('DownloadManager', '添加到本地播放列表失败: $e');
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
      AppLogger.error('DownloadManager', '选择目录失败: $e');
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
