import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'download_repository.dart';

/// 下载执行器配置
class DownloadExecutorConfig {
  /// 连接超时（秒）
  final int connectTimeout;

  /// 接收超时（秒）
  final int receiveTimeout;

  /// User-Agent
  final String userAgent;

  /// Referer
  final String referer;

  const DownloadExecutorConfig({
    this.connectTimeout = 30,
    this.receiveTimeout = 0, // 0 表示不限制
    this.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    this.referer = 'https://www.bilibili.com/',
  });
}

/// 下载进度回调
typedef DownloadProgressCallback = void Function(int downloadedBytes, int totalBytes);

/// 下载完成回调
typedef DownloadCompletionCallback = void Function(String filePath, bool success);

/// 下载执行器
///
/// 职责：
/// - 执行单个下载任务
/// - 支持断点续传
/// - 实时进度更新
/// - 错误处理和重试
class DownloadExecutor {
  final DownloadRepository _repository;
  final DownloadExecutorConfig _config;

  int? _taskId;
  CancelToken? _cancelToken;
  bool _isActive = false;
  bool _isCancelled = false;

  /// 是否正在执行
  bool get isActive => _isActive;

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  DownloadExecutor({
    required DownloadRepository repository,
    DownloadExecutorConfig config = const DownloadExecutorConfig(),
  })  : _repository = repository,
        _config = config;

  /// 执行下载任务
  ///
  /// [taskId] 任务ID
  /// [url] 下载URL
  /// [savePath] 保存路径
  /// [onProgress] 进度回调（已下载字节，总字节）
  /// [onCompletion] 完成回调（文件路径，是否成功）
  Future<void> execute({
    required int taskId,
    required String url,
    required String savePath,
    DownloadProgressCallback? onProgress,
    DownloadCompletionCallback? onCompletion,
  }) async {
    _taskId = taskId;
    _isActive = true;
    _isCancelled = false;
    _cancelToken = CancelToken();

    debugPrint('【DownloadExecutor】开始下载任务: $taskId');

    // 用于累积下载的数据（用于断点续传）
    final file = File(savePath);
    File? tempFile;  // 声明在函数级别，使所有块都能访问
    Uint8List? existingData;
    int downloadedBytes = 0;
    int totalBytes = 0;

    try {
      debugPrint('【DownloadExecutor】步骤1: 获取任务状态');
      // 1. 获取任务当前状态
      final task = await _repository.getTask(taskId);
      debugPrint('【DownloadExecutor】任务获取完成: ${task != null}');
      if (task == null) {
        throw Exception('任务不存在');
      }

      downloadedBytes = task['downloaded_bytes'] as int? ?? 0;
      totalBytes = task['total_bytes'] as int? ?? 0;
      debugPrint('【DownloadExecutor】进度: $downloadedBytes/$totalBytes');

      // 2. 检查是否已完成
      if (totalBytes > 0 && downloadedBytes >= totalBytes) {
        debugPrint('【DownloadExecutor】任务已完成，跳过下载: $taskId');
        await _repository.updateStatus(taskId, DownloadStatus.completed);
        onCompletion?.call(savePath, true);
        return;
      }

      debugPrint('【DownloadExecutor】步骤2: 更新状态');
      // 3. 更新状态为下载中
      await _repository.updateStatus(taskId, DownloadStatus.downloading);

      // 4. 如果有已下载的内容，先读取
      if (downloadedBytes > 0 && await file.exists()) {
        try {
          existingData = await file.readAsBytes();
          debugPrint('【DownloadExecutor】找到已下载内容: ${existingData.length} bytes');
        } catch (e) {
          debugPrint('【DownloadExecutor】读取已下载内容失败: $e');
          downloadedBytes = 0;
          existingData = null;
        }
      }

      debugPrint('【DownloadExecutor】步骤3: 配置 Dio');
      // 5. 配置 Dio
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: _config.connectTimeout);
      dio.options.receiveTimeout = Duration(seconds: _config.receiveTimeout);

      debugPrint('【DownloadExecutor】步骤4: 发起下载请求');
      // 6. 发起下载请求（支持断点续传）
      final options = Options(
        headers: {
          'Range': downloadedBytes > 0 ? 'bytes=$downloadedBytes-' : 'bytes=0-',
          'User-Agent': _config.userAgent,
          'Referer': _config.referer,
        },
        responseType: ResponseType.stream,
      );

      debugPrint('【DownloadExecutor】步骤5: 等待响应');
      final response = await dio.getUri(
        Uri.parse(url),
        options: options,
        cancelToken: _cancelToken,
      );

      debugPrint('【DownloadExecutor】步骤6: 处理响应头');
      // 7. 处理响应头获取文件大小
      final contentRange = response.headers.value('content-range');
      if (contentRange != null) {
        // 格式: bytes 0-1234567/12345678
        final parts = contentRange.split('/');
        if (parts.length == 2) {
          totalBytes = int.tryParse(parts[1]) ?? totalBytes;
        }
      } else {
        final contentLength = response.headers.value('content-length');
        if (contentLength != null) {
          totalBytes = int.tryParse(contentLength) ?? totalBytes;
        }
      }
      debugPrint('【DownloadExecutor】文件总大小: $totalBytes bytes');

      debugPrint('【DownloadExecutor】步骤7: 准备写入文件');
      // 8. 准备写入数据
      // === 使用临时文件策略：避免 Windows 文件锁定问题 ===
      // 下载到 .temp 文件，完成后再重命名为最终文件名
      try {
        // === 初始化临时文件路径 ===
        tempFile = File('$savePath.temp');

        // === 确保父目录存在 ===
        final directory = tempFile.parent;
        if (!await directory.exists()) {
          debugPrint('【DownloadExecutor】创建父目录: ${directory.path}');
          await directory.create(recursive: true);
        }

        // === 如果临时文件已存在，先删除 ===
        if (await tempFile.exists()) {
          debugPrint('【DownloadExecutor】删除已存在的临时文件: ${tempFile.path}');
          try {
            await tempFile.delete();
            // 等待文件系统完成删除（Windows 特定问题）
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            debugPrint('【DownloadExecutor】删除临时文件失败: $e');
            // 尝试使用带时间戳的文件名
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final backupFile = File('${tempFile.path}.$timestamp');
            try {
              await tempFile.rename(backupFile.path);
              debugPrint('【DownloadExecutor】旧临时文件已备份: ${backupFile.path}');
            } catch (_) {
              // 忽略，继续尝试
            }
          }
        }

        // === 累积数据块，最后一次性写入 ===
        // 这种方式避免了流式写入在 Windows 上的权限问题
        final chunks = <List<int>>[];

        // 如果有已下载的内容，先添加到块列表
        if (existingData != null && existingData.isNotEmpty) {
          debugPrint('【DownloadExecutor】找到已下载内容: ${existingData.length} bytes');
          chunks.add(existingData);
        }

        // 9. 流式下载
        await for (var chunk in response.data.stream) {
          if (_isCancelled) {
            debugPrint('【DownloadExecutor】下载已取消: $taskId');
            break;
          }

          // 检查任务状态是否变为暂停
          final currentTask = await _repository.getTask(taskId);
          if (currentTask != null) {
            final status = DownloadStatusExtension.fromString(currentTask['status'] as String?);
            if (status == DownloadStatus.paused) {
              debugPrint('【DownloadExecutor】任务已暂停: $taskId');
              break;
            }
          }

          // 累积数据块
          chunks.add(chunk);
          downloadedBytes += chunk.length as int;

          // 实时更新进度到数据库（每 1MB 更新一次）
          if (totalBytes > 0 && (downloadedBytes % (1024 * 1024) < chunk.length)) {
            debugPrint('【DownloadExecutor】进度: $downloadedBytes / $totalBytes (${(downloadedBytes * 100 / totalBytes).toStringAsFixed(1)}%)');
            await _repository.updateProgress(taskId, downloadedBytes, totalBytes);
            onProgress?.call(downloadedBytes, totalBytes);
          }
        }

        // 10. 将累积的数据块写入临时文件
        if (chunks.isNotEmpty) {
          final allData = Uint8List.fromList(chunks.expand((e) => e).toList());
          await tempFile.writeAsBytes(allData);
          debugPrint('【DownloadExecutor】数据已写入临时文件: ${allData.length} bytes');
        }

        // 11. 将临时文件重命名为最终文件名
        bool renameSuccess = false;
        if (await tempFile.exists()) {
          try {
            // 如果目标文件已存在，先删除
            if (await file.exists()) {
              await file.delete();
              await Future.delayed(const Duration(milliseconds: 50));
            }
            // 重命名临时文件为最终文件名
            await tempFile.rename(savePath);
            renameSuccess = true;
            debugPrint('【DownloadExecutor】临时文件已重命名: ${tempFile.path} -> $savePath');
          } catch (e) {
            debugPrint('【DownloadExecutor】重命名失败: $e，保留临时文件');
            // 重命名失败，回调返回临时文件路径
          }
        }

        // 12. 检查下载结果
        final finalPath = renameSuccess ? savePath : tempFile.path;
        if (!_isCancelled) {
          if (totalBytes > 0 && downloadedBytes >= totalBytes) {
            await _repository.updateStatus(taskId, DownloadStatus.completed);
            await _repository.updateProgress(taskId, totalBytes, totalBytes);
            debugPrint('【DownloadExecutor】下载完成: $taskId');
            onCompletion?.call(finalPath, true);
          } else if (downloadedBytes > 0) {
            // 部分下载，保存进度
            await _repository.updateProgress(taskId, downloadedBytes, totalBytes);
            debugPrint('【DownloadExecutor】部分下载: $taskId ($downloadedBytes/$totalBytes)');
            onCompletion?.call(finalPath, false);
          } else {
            // 没有下载任何内容
            debugPrint('【DownloadExecutor】没有下载到内容: $taskId');
            onCompletion?.call(finalPath, false);
          }
        } else {
          // 取消下载
          debugPrint('【DownloadExecutor】下载已取消: $taskId');
          onCompletion?.call(finalPath, false);
        }
      } finally {
        // 清理工作 - writeAsBytes 会自动关闭文件，无需额外处理
      }
    } on DioException catch (e) {
      debugPrint('【DownloadExecutor】下载异常: $e');

      if (e.type == DioExceptionType.badResponse && e.response?.statusCode == 416) {
        // 416 Range Not Satisfiable: 文件已下载完成
        debugPrint('【DownloadExecutor】文件已完整下载（416）: $taskId');
        await _repository.updateStatus(_taskId!, DownloadStatus.completed);
        onCompletion?.call(savePath, true);
      } else if (e.type == DioExceptionType.cancel) {
        // 用户取消
        debugPrint('【DownloadExecutor】下载被取消: $taskId');
      } else {
        // 其他错误
        await _repository.setErrorMessage(
          _taskId!,
          '下载失败: ${e.message ?? "未知错误"}',
        );
        onCompletion?.call(savePath, false);
      }
    } catch (e, stack) {
      debugPrint('【DownloadExecutor】未知错误: $e');
      debugPrint('【DownloadExecutor】堆栈跟踪:');
      debugPrint(stack.toString());
      debugPrint('【DownloadExecutor】目标文件路径: $savePath');
      if (tempFile != null) {
        debugPrint('【DownloadExecutor】临时文件路径: ${tempFile!.path}');
        try {
          debugPrint('【DownloadExecutor】临时文件存在: ${await tempFile.exists()}');
        } catch (_) {}
      }
      try {
        debugPrint('【DownloadExecutor】目标文件存在: ${await file.exists()}');
      } catch (_) {}
      await _repository.setErrorMessage(_taskId!, '下载异常: $e');
      onCompletion?.call(tempFile?.path ?? savePath, false);
    } finally {
      _isActive = false;
      _cancelToken = null;
    }
  }

  /// 取消下载
  void cancel() {
    _isCancelled = true;
    _cancelToken?.cancel('用户取消下载');
    debugPrint('【DownloadExecutor】请求取消下载: $_taskId');
  }

  /// 暂停下载（等同于取消，但保留进度）
  void pause() {
    _isCancelled = true;
    _cancelToken?.cancel('用户暂停下载');
    debugPrint('【DownloadExecutor】请求暂停下载: $_taskId');
  }
}

/// 下载管理器 - 管理多个下载执行器
///
/// 职责：
/// - 并发控制
/// - 执行器生命周期管理
class DownloadExecutorManager {
  final DownloadRepository _repository;
  final DownloadExecutorConfig _config;

  /// 最大并发下载数
  final int maxConcurrent;

  /// 活跃的执行器 {taskId: executor}
  final Map<int, DownloadExecutor> _activeExecutors = {};

  DownloadExecutorManager({
    required DownloadRepository repository,
    this.maxConcurrent = 3,
    DownloadExecutorConfig config = const DownloadExecutorConfig(),
  })  : _repository = repository,
        _config = config;

  /// 检查是否可以开始新下载
  bool get canStartNewDownload {
    // 清理已完成的执行器
    _activeExecutors.removeWhere((id, executor) => !executor.isActive);
    return _activeExecutors.length < maxConcurrent;
  }

  /// 获取当前活跃下载数
  int get activeCount => _activeExecutors.length;

  /// 启动下载任务
  ///
  /// 返回 null 表示无法启动（达到并发限制），否则返回执行器
  DownloadExecutor? startTask({
    required int taskId,
    required String url,
    required String savePath,
    DownloadProgressCallback? onProgress,
    DownloadCompletionCallback? onCompletion,
  }) {
    if (!canStartNewDownload) {
      debugPrint('【DownloadExecutorManager】已达到最大并发数 ($maxConcurrent)，无法启动新任务');
      return null;
    }

    final executor = DownloadExecutor(
      repository: _repository,
      config: _config,
    );

    _activeExecutors[taskId] = executor;

    // 启动异步执行
    executor.execute(
      taskId: taskId,
      url: url,
      savePath: savePath,
      onProgress: onProgress,
      onCompletion: (filePath, success) {
        _activeExecutors.remove(taskId);
        onCompletion?.call(filePath, success);
      },
    );

    return executor;
  }

  /// 取消任务
  void cancelTask(int taskId) {
    final executor = _activeExecutors[taskId];
    if (executor != null) {
      executor.cancel();
    }
  }

  /// 暂停任务
  void pauseTask(int taskId) {
    final executor = _activeExecutors[taskId];
    if (executor != null) {
      executor.pause();
    }
  }

  /// 取消所有任务
  void cancelAll() {
    for (var executor in _activeExecutors.values) {
      executor.cancel();
    }
    _activeExecutors.clear();
  }
}
