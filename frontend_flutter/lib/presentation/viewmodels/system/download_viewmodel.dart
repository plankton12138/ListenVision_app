import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/track_repository.dart' show DownloadProgressEvent;
import '../../../models/download_task.dart';

part 'download_viewmodel.freezed.dart';
part 'download_viewmodel.g.dart';

/// 下载任务异常
class DownloadTaskException implements Exception {
  final String message;
  DownloadTaskException(this.message);

  @override
  String toString() => message;
}

/// 下载状态
@freezed
abstract class DownloadModelState with _$DownloadModelState {
  /// 初始状态
  const factory DownloadModelState.initial() = DownloadModelStateInitial;

  /// 已加载
  const factory DownloadModelState.loaded({
    required List<DownloadTask> downloads,
  }) = DownloadModelStateLoaded;

  /// 错误
  const factory DownloadModelState.error({
    required String message,
  }) = DownloadModelStateError;
}

/// 下载管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 新特性：
/// 1. 任务持久化到数据库（重启后仍可恢复）
/// 2. 监听 Repository 的进度流
/// 3. 真正的暂停/恢复（通过 CancelToken）
/// 4. 自动恢复未完成的任务
/// 5. 每个任务独立显示进度和队列位置
/// 6. UI 反馈：操作状态追踪（loading/error 提示）
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;
  StreamSubscription<DownloadProgressEvent>? _progressSub;
  StreamSubscription<int>? _queueSub;
  Timer? _debounceTimer;

  // 单任务进度缓存（taskId -> progress）
  final Map<int, int> _taskProgress = {};

  // 队列位置缓存（taskId -> queuePosition）
  final Map<int, int> _queuePositions = {};

  // 操作状态缓存（taskId -> isLoading）用于 UI 反馈
  // Phase 3: 使用稳定特性替代实验性 Mutations
  final Map<int, bool> _operationStates = {};

  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);

    // 设置清理回调
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _progressSub?.cancel();
      _queueSub?.cancel();
    });

    // 监听进度流
    _progressSub = _repository!.progressStream.listen(
      _onProgressUpdate,
      onError: (e) => AppLogger.error('DownloadViewModel', '进度流错误: $e'),
    );

    _queueSub = _repository!.queueStream.listen(
      (_) => _updateQueuePositions(),
      onError: (e) => AppLogger.error('DownloadViewModel', '队列流错误: $e'),
    );

    // 加载任务
    final tasks = await _repository!.getAllTasks();
    _updateQueuePositions();
    await _resumeIncompleteTasks();

    return DownloadModelState.loaded(downloads: tasks);
  }

  /// 恢复未完成的任务（pending 和 paused）
  Future<void> _resumeIncompleteTasks() async {
    try {
      final pendingTasks = await _repository!.getPendingTasks();
      for (final task in pendingTasks) {
        if (task.id != null) {
          AppLogger.info('DownloadViewModel', '自动恢复任务: ${task.bvid}');
          await _repository!.startDownload(task.id!);
        }
      }
    } catch (e) {
      AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
    }
  }

  /// 处理进度更新
  Future<void> _onProgressUpdate(DownloadProgressEvent event) async {
    _taskProgress[event.taskId] = event.progress;

    if (event.progress >= 100) {
      Future.delayed(const Duration(seconds: 2), () {
        _taskProgress.remove(event.taskId);
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // 官方推荐：异步操作后检查 ref.mounted
      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
    });
  }

  /// 更新队列位置缓存
  void _updateQueuePositions() {
    _queuePositions.clear();
    final queuedIds = _repository?.getQueuedTaskIds() ?? [];
    for (int i = 0; i < queuedIds.length; i++) {
      _queuePositions[queuedIds[i]] = i + 1;
    }
  }

  /// 获取任务进度（0-100）
  int getTaskProgress(int taskId) => _taskProgress[taskId] ?? 0;

  /// 获取队列位置（1-based, null 表示不在队列中）
  int? getQueuePosition(int taskId) => _queuePositions[taskId];

  /// 检查任务是否在队列中
  bool isInQueue(int taskId) => _repository?.isInQueue(taskId) ?? false;

  /// 检查任务是否正在操作（用于 UI 反馈）
  /// Phase 3: 稳定特性替代实验性 Mutations
  bool isOperating(int taskId) => _operationStates[taskId] ?? false;

  /// 添加下载任务（新架构 - 持久化到数据库）
  Future<DownloadTask?> addDownload({
    required String bvid,
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('DownloadViewModel', '添加下载任务: $bvid');

      final existingTask = await _repository!.getTaskByBvid(bvid);
      if (existingTask != null) {
        AppLogger.info('DownloadViewModel', '任务已存在: $bvid, 状态: ${existingTask.status}');

        if (existingTask.isCompleted) {
          throw DownloadTaskException('任务已完成，保存在: ${existingTask.savePath}');
        } else if (existingTask.isActive) {
          throw DownloadTaskException('任务已在下载队列中');
        } else if (existingTask.isFailed) {
          await _repository!.deleteDownloadTask(existingTask.id!);
        }
      }

      final taskId = await _repository!.addDownloadTask(
        bvid: bvid,
        url: _repository!.getDownloadUrl(bvid),
        savePath: savePath,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
      );

      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();
      await _repository!.startDownload(taskId);

      if (!ref.mounted) return null;
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));

      return await _repository!.getTaskByBvid(bvid);
    } catch (e) {
      AppLogger.error('DownloadViewModel', '添加下载任务失败: $e');
      rethrow;
    }
  }

  /// 暂停下载
  Future<void> pauseDownload(int taskId) async {
    _operationStates[taskId] = true;  // 开始操作
    try {
      await _repository!.pauseDownload(taskId);
      _taskProgress.remove(taskId);

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '暂停任务失败: $e');
      rethrow;
    } finally {
      if (ref.mounted) {
        _operationStates[taskId] = false;  // 结束操作
      }
    }
  }

  /// 恢复下载
  Future<void> resumeDownload(int taskId) async {
    _operationStates[taskId] = true;
    try {
      await _repository!.resumeDownload(taskId);

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已恢复任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
      rethrow;
    } finally {
      if (ref.mounted) {
        _operationStates[taskId] = false;
      }
    }
  }

  /// 删除下载任务
  Future<void> deleteDownload(int taskId, {bool deleteFile = false}) async {
    _operationStates[taskId] = true;
    try {
      await _repository!.deleteDownloadTask(taskId, deleteFile: deleteFile);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已删除任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '删除任务失败: $e');
      rethrow;
    } finally {
      if (ref.mounted) {
        _operationStates[taskId] = false;
      }
    }
  }

  /// 取消下载
  Future<void> cancelDownload(int taskId) async {
    _operationStates[taskId] = true;
    try {
      await _repository!.cancelDownload(taskId);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已取消任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '取消任务失败: $e');
      rethrow;
    } finally {
      if (ref.mounted) {
        _operationStates[taskId] = false;
      }
    }
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    try {
      await _repository!.clearCompleted();

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '清空已完成任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '清空任务失败: $e');
    }
  }

  /// 重试失败的任务
  Future<void> retryFailed() async {
    try {
      await _repository!.retryFailed();

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '重试失败任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '重试失败: $e');
    }
  }

  /// 暂停所有下载
  Future<void> pauseAll() async {
    try {
      await _repository!.pauseAll();

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '暂停所有任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '暂停所有任务失败: $e');
    }
  }

  /// 从 URL 提取 BVID
  String? extractBvid(String url) {
    final bvidRegex = RegExp(r'(BV[a-zA-Z0-9]{10})');
    final match = bvidRegex.firstMatch(url);
    return match?.group(1);
  }

  /// 清理标题字符串（移除非法字符）
  String sanitizeTitle(String input) {
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// DownloadModelState 扩展方法
extension DownloadModelStateX on DownloadModelState {
  /// 获取下载任务列表
  List<DownloadTask> get downloads => maybeWhen(
        loaded: (tasks) => tasks,
        orElse: () => const [],
      );
}
