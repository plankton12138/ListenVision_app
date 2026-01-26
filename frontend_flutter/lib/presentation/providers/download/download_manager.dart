import 'dart:io';
import 'dart:typed_data';

import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:demo/domain/entities/download_task.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/repositories/download_repository.dart';
import 'package:demo/core/utils/metadata_writer.dart';
import 'package:demo/data/managers/download_executor.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';

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

    try {
      // 1. 获取视频信息（使用 Repository）
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
          'audioUrl': audio.streamUrl,
          'bvid': bvid,
        },
      );

      if (videoData == null || videoData['audioUrl'] == null) {
        DialogHelper.showSnackBar(context, '获取视频信息失败', backgroundColor: Colors.red, duration: 500);
        return;
      }

      final title = videoData['title'] as String;
      final artist = videoData['artist'] as String;

      // 2. 检查是否已存在
      final existsResult = await _repository.existsByBvid(bvid);
      final exists = existsResult.fold((_) => false, (e) => e);
      if (exists) {
        DialogHelper.showSnackBar(context, '该任务已存在', backgroundColor: Colors.orange, duration: 1000);
        return;
      }

      // 3. 选择保存目录
      final saveDir = await _pickDirectory();
      if (saveDir == null) return;

      // 4. 使用原始音频流 URL（快速下载）
      // 直接使用 B站的音频流 URL，不进行格式转换
      final audioUrl = videoData['audioUrl'] as String;
      AppLogger.info('DownloadManager', '使用原始音频流下载: ${audioUrl.substring(0, audioUrl.length > 100 ? 100 : audioUrl.length)}...');

      // 5. 确定文件路径（使用 .m4a 扩展名）
      final sanitizedTitle = _sanitizeTitle(title);
      final fileName = '$sanitizedTitle.m4a';
      final savePath = path.join(saveDir, fileName);

      // 6. 创建下载任务记录
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
        DialogHelper.showSnackBar(context, '创建任务失败', backgroundColor: Colors.red, duration: 500);
        return;
      }

      AppLogger.info('DownloadManager', '任务创建成功: $taskId');

      // 7. 启动下载
      _startDownload(taskId, audioUrl, savePath, videoData);

      // 8. 刷新列表
      await refreshDownloads();

      DialogHelper.showSnackBar(context, '已添加到下载列表: $title', backgroundColor: Colors.green, duration: 1000);
    } catch (e) {
      AppLogger.error('DownloadManager', '_downloadByBvid 失败: $e');
      DialogHelper.showSnackBar(context, '下载失败: $e', backgroundColor: Colors.red, duration: 1000);
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
    AppLogger.info('DownloadManager', '已暂停任务: $id');
  }

  /// 恢复下载
  Future<void> resumeDownload(int id) async {
    final taskResult = await _repository.getTask(id);
    taskResult.fold(
      (failure) => AppLogger.error('DownloadManager', '获取任务失败: $failure'),
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
        AppLogger.info('DownloadManager', '已恢复任务: $id');
      },
    );
  }

  /// 删除下载
  Future<void> deleteDownload(int id) async {
    _executorManager.cancelTask(id);
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

  /// 加载下载列表
  Future<void> _loadDownloads() async {
    final result = await _repository.getAllTasks();
    result.fold(
      (failure) => AppLogger.error('DownloadManager', '加载任务失败: $failure'),
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
      final title = videoData['title']?.toString() ?? '未知标题';
      final artist = videoData['artist']?.toString() ?? '未知艺术家';
      final coverUrl = videoData['pic']?.toString();
      final album = videoData['bvid']?.toString();

      AppLogger.info('DownloadManager', '下载完成，处理元数据: $title - $artist');

      // 检测文件是否是 m4s 格式（B站分离音频流）
      final isM4sFormat = await _checkIsM4sFormat(filePath);

      Uint8List? coverData;

      if (isM4sFormat) {
        AppLogger.info('DownloadManager', '检测到 m4s 格式，跳过元数据写入，使用数据库存储');

        // 下载封面图片
        if (coverUrl != null && coverUrl.isNotEmpty) {
          try {
            final dio = Dio();
            final response = await dio.get(
              coverUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.data is List<int>) {
              coverData = Uint8List.fromList(response.data as List<int>);
              AppLogger.info('DownloadManager', '封面下载成功: ${coverData.length} bytes');
            }
          } catch (e) {
            AppLogger.warn('DownloadManager', '封面下载失败: $e');
          }
        }
      } else {
        // 标准 m4a/mp3 格式，使用 AudioMetadataHelper 写入元数据
        AppLogger.info('DownloadManager', '使用 AudioMetadataHelper 写入元数据');

        final success = await _metadataWriter.writeMetadata(
          filePath: filePath,
          title: title,
          artist: artist,
          coverUrl: coverUrl,
          album: album,
        );

        if (success) {
          AppLogger.info('DownloadManager', '元数据写入成功');

          // 验证写入：读取并确认元数据已保存
          try {
            final verifyData = await readMetadata(filePath);
            if (verifyData != null) {
              AppLogger.info('DownloadManager', '验证元数据: title=${verifyData['title']}, artist=${verifyData['artist']}, hasPicture=${verifyData['hasPicture']}');
            }
          } catch (e) {
            AppLogger.warn('DownloadManager', '验证元数据失败: $e');
          }
        } else {
          AppLogger.warn('DownloadManager', '元数据写入失败（返回false），将使用数据库存储');
        }
      }

      // 将文件添加到本地播放列表数据库
      await _addToLocalPlaylist(filePath, title, artist, coverData, album ?? '');

      AppLogger.info('DownloadManager', '元数据处理完成: $title');
    } catch (e) {
      AppLogger.error('DownloadManager', '元数据写入异常: $e');
    }
  }

  /// 检测文件是否是 m4s 格式
  Future<bool> _checkIsM4sFormat(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      // 检查文件扩展名
      if (filePath.toLowerCase().endsWith('.m4s')) {
        return true;
      }

      // 对于 .m4a 文件，读取文件头部检测是否是标准容器
      if (filePath.toLowerCase().endsWith('.m4a') || filePath.toLowerCase().endsWith('.mp4')) {
        final header = file.openSync(mode: FileMode.read).readSync(16);
        if (header.length >= 12) {
          // 检查是否包含 'ftyp' 标记（标准容器）
          // 标准 m4a/mp4 文件在偏移 4 处有 'ftyp' 标记
          final hasFtyp = header.length >= 8 &&
              header[4] == 0x66 && // 'f'
              header[5] == 0x74 && // 't'
              header[6] == 0x79 && // 'y'
              header[7] == 0x70;   // 'p'
          if (!hasFtyp) {
            AppLogger.debug('DownloadManager', '文件缺少 ftyp 容器标记，可能是 m4s 格式');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      AppLogger.warn('DownloadManager', 'm4s 格式检测失败: $e');
      return false;
    }
  }

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

  // ==================== 元数据补充 ====================

  /// 为已下载的文件补充元数据
  ///
  /// 用于修复之前下载但没有写入元数据的文件
  /// 返回成功处理的文件数
  Future<int> repairMetadataForCompletedTasks() async {
    int successCount = 0;
    int failedCount = 0;

    final completedTasks = _downloads.where((d) => d.status == DownloadStatus.completed).toList();

    AppLogger.info('DownloadManager', '开始补充元数据，共 ${completedTasks.length} 个已完成任务');

    for (var task in completedTasks) {
      // 检查文件是否存在
      final file = File(task.savePath);
      if (!await file.exists()) {
        AppLogger.warn('DownloadManager', '文件不存在，跳过: ${task.savePath}');
        failedCount++;
        continue;
      }

      try {
        // 先检查是否已有元数据
        final existingData = await readMetadata(task.savePath);
        if (existingData != null &&
            existingData['title'] != null &&
            existingData['title'].toString().isNotEmpty &&
            existingData['artist'] != null &&
            existingData['artist'].toString().isNotEmpty) {
          AppLogger.debug('DownloadManager', '文件已有元数据，跳过: ${task.title}');
          continue;
        }

        // 写入元数据
        final success = await _metadataWriter.writeMetadata(
          filePath: task.savePath,
          title: task.title ?? '未知标题',
          artist: task.artist ?? '未知艺术家',
          coverUrl: task.coverUrl,
          album: task.bvid,
        );

        if (success) {
          successCount++;
          AppLogger.info('DownloadManager', '元数据补充成功: ${task.title}');
        } else {
          failedCount++;
          AppLogger.error('DownloadManager', '元数据补充失败: ${task.title}');
        }
      } catch (e) {
        failedCount++;
        AppLogger.error('DownloadManager', '处理文件失败: ${task.savePath}, 错误: $e');
      }
    }

    AppLogger.info('DownloadManager', '元数据补充完成: 成功 $successCount, 失败 $failedCount, 跳过 ${completedTasks.length - successCount - failedCount}');
    return successCount;
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
