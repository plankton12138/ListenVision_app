import 'dart:async';
import 'dart:io';

import 'package:listenvision/core/state/state_utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    try {
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

      // 从数据库重建内存状态（应用重启后调用）
      // 捕获异常，防止导致整个 build 失败
      try {
        await _repository!.rebuildState();
      } catch (e) {
        AppLogger.error('DownloadViewModel', 'rebuildState 失败: $e');
        // 继续执行，不阻塞
      }

      // 加载任务
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      // 恢复未完成的任务（捕获异常，防止导致整个 build 失败）
      try {
        await _resumeIncompleteTasks();
      } catch (e) {
        AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
        // 继续执行，不阻塞 UI 加载
      }

      return DownloadModelState.loaded(downloads: tasks);
    } catch (e, stack) {
      AppLogger.error('DownloadViewModel', 'build 失败: $e\n$stack');
      // 返回空列表而不是抛出异常，让 UI 能正常显示
      return DownloadModelState.loaded(downloads: []);
    }
  }

  /// 恢复未完成的任务（pending + paused + downloading）
  ///
  /// 改进版：验证文件状态，处理崩溃恢复，校验文件完整性。
  /// - pending: 恢复等待中的任务
  /// - paused: 检查临时文件是否存在，存在则可恢复
  /// - downloading: 崩溃前在下载，检查临时文件状态后决定是否恢复
  Future<void> _resumeIncompleteTasks() async {
    try {
      // 获取所有未完成的任务
      final incompleteTasks = await _repository!.getIncompleteTasks();

      for (final task in incompleteTasks) {
        // 单个任务失败不影响其他任务
        try {
          if (task.id == null) continue;

          // 验证文件状态
          final file = File(task.savePath);
          final tempFile = File('${task.savePath}.tmp');

          final fileExists = await file.exists();
          final tempExists = await tempFile.exists();

          // 已完成且文件存在，跳过
          if (task.status == DownloadStatus.completed && fileExists) {
            continue;
          }

          // 文件完整性校验
          bool hasValidTempFile = tempExists;
          if (tempExists) {
            try {
              final actualSize = await tempFile.length();
              final recordedSize = task.downloadedBytes;

              // 文件大小差异超过 1MB，可能损坏
              if ((actualSize - recordedSize).abs() > 1024 * 1024) {
                AppLogger.warn('DownloadViewModel',
                  '临时文件大小不一致: 记录=$recordedSize, 实际=$actualSize，重新下载');
                try {
                  await tempFile.delete();
                } catch (_) {}
                await _repository!.updateDownloadedBytes(task.id!, 0);
                hasValidTempFile = false;
              }
            } catch (e) {
              AppLogger.error('DownloadViewModel', '检查临时文件失败: $e');
              hasValidTempFile = false;
            }
          }

          // 崩溃前在下载，但临时文件不存在，重置状态
          if (task.status == DownloadStatus.downloading && !tempExists) {
            await _repository!.resetTaskStatus(task.id!, DownloadStatus.pending);
          }

          // 决定是否恢复
          bool shouldResume = switch (task.status) {
            DownloadStatus.pending => true,
            DownloadStatus.paused => hasValidTempFile || fileExists,
            DownloadStatus.downloading => hasValidTempFile,
            DownloadStatus.stalled => hasValidTempFile || fileExists,
            _ => false,
          };

          if (shouldResume) {
            AppLogger.info('DownloadViewModel',
              '恢复任务: ${task.bvid}, 状态: ${task.status}, 临时文件: $hasValidTempFile');
            try {
              await _repository!.startDownload(task.id!);
            } catch (e) {
              // 恢复失败，标记为失败状态但继续处理其他任务
              AppLogger.error('DownloadViewModel', '恢复任务 ${task.id} 失败: $e');
              try {
                await _repository!.markAsFailed(task.id!, '恢复失败: $e');
              } catch (_) {}
            }
          } else {
            // 无法恢复的任务标记为失败
            try {
              await _repository!.markAsFailed(task.id!, '应用异常关闭，下载未完成');
            } catch (e) {
              AppLogger.error('DownloadViewModel', '标记任务失败出错: $e');
            }
          }
        } catch (e) {
          // 单个任务处理出错，记录日志但继续处理其他任务
          AppLogger.error('DownloadViewModel', '处理任务 ${task.id} 时出错: $e');
        }
      }
    } catch (e) {
      AppLogger.error('DownloadViewModel', '获取未完成任务列表失败: $e');
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
    // 先更新 state 以触发 UI 重建（显示操作中状态）
    if (ref.mounted) {
      final currentTasks = state.valueOrNull?.downloads ?? [];
      state = AsyncData(DownloadModelState.loaded(downloads: currentTasks));
    }

    try {
      await _repository!.pauseDownload(taskId);
      _taskProgress.remove(taskId);

      AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '暂停任务失败: $e');
      rethrow;
    } finally {
      _operationStates[taskId] = false;  // 结束操作
      // 触发重建，确保 UI 能感知到操作状态的变化
      if (ref.mounted) {
        final tasks = await _repository!.getAllTasks();
        _updateQueuePositions();
        state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      }
    }
  }

  /// 恢复下载
  Future<void> resumeDownload(int taskId) async {
    _operationStates[taskId] = true;
    // 先更新 state 以触发 UI 重建（显示操作中状态）
    if (ref.mounted) {
      final currentTasks = state.valueOrNull?.downloads ?? [];
      state = AsyncData(DownloadModelState.loaded(downloads: currentTasks));
    }

    try {
      await _repository!.resumeDownload(taskId);

      AppLogger.info('DownloadViewModel', '已恢复任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
      rethrow;
    } finally {
      _operationStates[taskId] = false;
      // 触发一次 state 更新，确保 UI 能感知到操作状态的变化
      if (ref.mounted) {
        final tasks = await _repository!.getAllTasks();
        _updateQueuePositions();
        state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      }
    }
  }

  /// 强制恢复下载（忽略卡死/失败状态）
  Future<void> forceResume(int taskId) async {
    _operationStates[taskId] = true;
    // 先更新 state 以触发 UI 重建（显示操作中状态）
    if (ref.mounted) {
      final currentTasks = state.valueOrNull?.downloads ?? [];
      state = AsyncData(DownloadModelState.loaded(downloads: currentTasks));
    }

    try {
      await _repository!.forceResume(taskId);
      AppLogger.info('DownloadViewModel', '已强制恢复任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '强制恢复任务失败: $e');
      rethrow;
    } finally {
      _operationStates[taskId] = false;
      if (ref.mounted) {
        final tasks = await _repository!.getAllTasks();
        _updateQueuePositions();
        state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      }
    }
  }

  /// 删除下载任务
  Future<void> deleteDownload(int taskId, {bool deleteFile = false}) async {
    _operationStates[taskId] = true;
    // 先更新 state 以触发 UI 重建（显示操作中状态）
    if (ref.mounted) {
      final currentTasks = state.valueOrNull?.downloads ?? [];
      state = AsyncData(DownloadModelState.loaded(downloads: currentTasks));
    }

    try {
      await _repository!.deleteDownloadTask(taskId, deleteFile: deleteFile);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);

      AppLogger.info('DownloadViewModel', '已删除任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '删除任务失败: $e');
      rethrow;
    } finally {
      _operationStates[taskId] = false;
      if (ref.mounted) {
        final tasks = await _repository!.getAllTasks();
        _updateQueuePositions();
        state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      }
    }
  }

  /// 取消下载
  Future<void> cancelDownload(int taskId) async {
    _operationStates[taskId] = true;
    // 先更新 state 以触发 UI 重建（显示操作中状态）
    if (ref.mounted) {
      final currentTasks = state.valueOrNull?.downloads ?? [];
      state = AsyncData(DownloadModelState.loaded(downloads: currentTasks));
    }

    try {
      await _repository!.cancelDownload(taskId);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);

      AppLogger.info('DownloadViewModel', '已取消任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '取消任务失败: $e');
      rethrow;
    } finally {
      _operationStates[taskId] = false;
      if (ref.mounted) {
        final tasks = await _repository!.getAllTasks();
        _updateQueuePositions();
        state = AsyncData(DownloadModelState.loaded(downloads: tasks));
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

  /// 重试卡死的任务
  Future<void> retryStalledAll() async {
    try {
      await _repository!.retryStalledAll();

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '重试卡死任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '重试卡死任务失败: $e');
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
