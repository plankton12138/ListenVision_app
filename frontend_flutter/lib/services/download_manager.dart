import 'package:demo/services/bilibiliApiService.dart';
import 'package:demo/services/download/download_repository.dart';
import 'package:demo/services/download/download_executor.dart';
import 'package:demo/services/download/metadata_writer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// 下载管理器
///
/// 重构后的职责：
/// - 协调各模块完成下载流程
/// - 提供统一的 API 给 UI 层
/// - 状态管理（通过 ChangeNotifier）
class DownloadManager with ChangeNotifier {
  // ==================== 依赖注入 ====================

  final DownloadRepository _repository = DownloadRepository();
  final DownloadExecutorManager _executorManager;
  final MetadataWriter _metadataWriter;

  BilibiliApiService? _bilibiliApiService;

  // ==================== 状态 ====================

  /// 所有下载任务（内存缓存，从数据库加载）
  List<Map<String, dynamic>> _downloads = [];

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== 构造函数 ====================

  DownloadManager() : _metadataWriter = MetadataWriter(), _executorManager = DownloadExecutorManager(
    repository: DownloadRepository(),
    maxConcurrent: 3,
  ) {
    // 初始化仓库
    _repository.init().then((_) {
      _loadDownloads();
    });
  }

  // ==================== 公开方法 ====================

  /// 初始化数据库（向后兼容）
  Future<void> initDatabase() async {
    await _repository.init();
    await _loadDownloads();
  }

  /// 刷新下载列表
  Future<void> refreshDownloads() async {
    await _loadDownloads();
  }

  /// 获取所有下载任务
  List<Map<String, dynamic>> get downloads => List.unmodifiable(_downloads);

  /// 设置 B站 API 服务
  void setBilibiliApiService(BilibiliApiService service) {
    _bilibiliApiService = service;
    _metadataWriter.setBilibiliApiService(service);
    debugPrint('【DownloadManager】已设置 BilibiliApiService');
  }

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
      // 1. 获取视频信息
      final videoData = await _getVideoInfo(bvid);
      if (videoData == null) {
        showMySnackBar(context, '获取视频信息失败', Colors.red, 500);
        return;
      }

      final title = videoData['title'] as String;
      final artist = videoData['artist'] as String;
      final pic = videoData['pic'] as String?;
      final audioUrl = videoData['audioUrl'] as String;

      // 2. 检查是否已存在
      final exists = await _repository.existsByBvid(bvid);
      if (exists) {
        showMySnackBar(context, '该任务已存在', Colors.orange, 1000);
        return;
      }

      // 3. 选择保存目录
      final saveDir = await _pickDirectory();
      if (saveDir == null) return;

      // 4. 确定文件路径
      final sanitizedTitle = sanitizeTitle(title);
      final fileName = '$sanitizedTitle.m4a';
      final savePath = path.join(saveDir, fileName);

      // 5. 创建下载任务记录
      final taskId = await _repository.insertTask({
        'url': audioUrl,
        'save_path': savePath,
        'downloaded_bytes': 0,
        'total_bytes': 0,
        'status': DownloadStatus.pending.value,
        'original_url': 'https://www.bilibili.com/video/$bvid',
        'title': title,
        'artist': artist,
        'cover_url': pic,
        'bvid': bvid,
      });

      debugPrint('【DownloadManager】任务创建成功: $taskId');

      // 6. 启动下载
      _startDownload(taskId, audioUrl, savePath, videoData);

      // 7. 刷新列表
      await _loadDownloads();

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
    final executor = _executorManager.startTask(
      taskId: taskId,
      url: audioUrl,
      savePath: savePath,
      onProgress: (downloaded, total) async {
        // 直接更新数据库
        await _repository.updateProgress(taskId, downloaded, total);
        
        // 更新内存中的进度（创建新的列表副本以触发 UI 更新）
        final newDownloads = [..._downloads];
        final index = newDownloads.indexWhere((d) => d['id'] == taskId);
        if (index != -1) {
          newDownloads[index] = {
            ...newDownloads[index],
            'downloaded_bytes': downloaded,
            'total_bytes': total,
          };
          _downloads = newDownloads;
        }
        
        notifyListeners();
      },
      onCompletion: (filePath, success) async {
        // 下载完成后刷新列表
        await _loadDownloads();

        if (success) {
          // 写入元数据
          await _writeMetadataAfterDownload(filePath, videoData);
        }
      },
    );

    if (executor == null) {
      debugPrint('【DownloadManager】无法启动下载，达到并发限制');
    }
  }

  /// 暂停下载
  Future<void> pauseDownload(int id) async {
    // 1. 更新数据库状态
    await _repository.updateStatus(id, DownloadStatus.paused);

    // 2. 通知执行器暂停
    _executorManager.pauseTask(id);

    // 3. 刷新列表
    await _loadDownloads();

    debugPrint('【DownloadManager】已暂停任务: $id');
  }

  /// 恢复下载
  Future<void> resumeDownload(int id) async {
    final task = await _repository.getTask(id);
    if (task == null) return;

    final url = task['url'] as String;
    final savePath = task['save_path'] as String;

    // 更新状态
    await _repository.updateStatus(id, DownloadStatus.pending);

    // 启动下载
    _startDownload(id, url, savePath, {
      'title': task['title'],
      'artist': task['artist'],
      'pic': task['cover_url'],
      'bvid': task['bvid'],
    });

    await _loadDownloads();
    debugPrint('【DownloadManager】已恢复任务: $id');
  }

  /// 删除下载
  Future<void> deleteDownload(int id) async {
    // 1. 取消正在进行的下载
    _executorManager.cancelTask(id);

    // 2. 删除数据库记录
    await _repository.deleteTask(id);

    // 3. 刷新列表
    await _loadDownloads();

    debugPrint('【DownloadManager】已删除任务: $id');
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    final count = await _repository.clearCompletedTasks();
    await _loadDownloads();
    debugPrint('【DownloadManager】已清空 $count 个已完成任务');
  }

  // ==================== 私有方法 ====================

  /// 加载下载列表
  Future<void> _loadDownloads() async {
    _downloads = await _repository.getAllTasks();
    _isInitialized = true;
    notifyListeners();
  }

  /// 获取视频信息
  Future<Map<String, dynamic>?> _getVideoInfo(String bvid) async {
    if (_bilibiliApiService == null) {
      debugPrint('【DownloadManager】BilibiliApiService 未设置');
      return null;
    }

    try {
      final videoInfo = await _bilibiliApiService!.getVideoInfo(bvid);
      final audioStream = await _bilibiliApiService!.getAudioStream(bvid);

      return {
        'title': videoInfo['title'] ?? '未知标题',
        'artist': videoInfo['owner']?['name'] ?? '未知艺术家',
        'pic': videoInfo['pic'],
        'audioUrl': audioStream['url'],
        'bvid': bvid,
      };
    } catch (e) {
      debugPrint('【DownloadManager】获取视频信息失败: $e');
      return null;
    }
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
  String sanitizeTitle(String input) {
    // 保留中文、英文、数字和常用符号
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ==================== 统计信息 ====================

  /// 获取指定状态的任务数
  int getCountByStatus(DownloadStatus status) {
    return _downloads.where((d) => d['status'] == status.value).length;
  }

  /// 进行中的任务数
  int get activeCount => getCountByStatus(DownloadStatus.downloading) +
      getCountByStatus(DownloadStatus.pending);

  /// 已完成的任务数
  int get completedCount => getCountByStatus(DownloadStatus.completed);

  /// 失败的任务数
  int get failedCount => getCountByStatus(DownloadStatus.failed);
}
