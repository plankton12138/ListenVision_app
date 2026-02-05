import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../models/download_task.dart';

part 'download_viewmodel.freezed.dart';
part 'download_viewmodel.g.dart';

/// 下载状态
@freezed
class DownloadModelState with _$DownloadModelState {
  /// 初始状态
  const factory DownloadModelState.initial() = DownloadModelStateInitial;

  /// 加载中
  const factory DownloadModelState.loading() = DownloadModelStateLoading;

  /// 已加载
  const factory DownloadModelState.loaded({
    required List<DownloadTask> downloads,
    @Default('') String downloadStage,
    @Default(0) int downloadProgress,
    DownloadTask? activeTask,
  }) = DownloadModelStateLoaded;

  /// 错误
  const factory DownloadModelState.error({
    required String message,
  }) = DownloadModelStateError;
}

/// 下载管理 ViewModel（重构版 - 本地优先架构）
///
/// 新特性：
/// 1. 任务持久化到数据库（重启后仍可恢复）
/// 2. 监听 Repository 的进度流
/// 3. 真正的暂停/恢复（通过 CancelToken）
/// 4. 自动恢复未完成的任务
class DownloadViewModel extends StateNotifier<DownloadModelState> {
  final DownloadRepository _repository;
  StreamSubscription<DownloadProgressEvent>? _progressSubscription;

  DownloadViewModel(this._repository)
      : super(const DownloadModelState.initial()) {
    _initialize();
  }

  /// 初始化 - 从数据库加载任务并监听进度
  Future<void> _initialize() async {
    state = const DownloadModelState.loading();

    // 监听 Repository 的进度流
    _progressSubscription = _repository.progressStream.listen(
      _onProgressUpdate,
      onError: (error) {
        AppLogger.error('DownloadViewModel', '进度流错误: $error');
      },
    );

    // 从数据库加载任务
    await _loadTasks();

    // 自动恢复未完成的下载
    await _resumeIncompleteTasks();
  }

  /// 从数据库加载任务
  Future<void> _loadTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      state = DownloadModelState.loaded(
        downloads: tasks,
        downloadStage: '',
        downloadProgress: 0,
      );
      AppLogger.info('DownloadViewModel', '从数据库加载 ${tasks.length} 个任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '加载任务失败: $e');
      state = DownloadModelState.error(message: e.toString());
    }
  }

  /// 恢复未完成的任务（pending 和 paused）
  Future<void> _resumeIncompleteTasks() async {
    try {
      final pendingTasks = await _repository.getPendingTasks();
      for (final task in pendingTasks) {
        if (task.id != null) {
          AppLogger.info('DownloadViewModel', '自动恢复任务: ${task.bvid}');
          await _repository.startDownload(task.id!);
        }
      }
    } catch (e) {
      AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
    }
  }

  /// 处理进度更新
  void _onProgressUpdate(DownloadProgressEvent event) {
    state.maybeWhen(
      loaded: (tasks, _, __, ___) {
        // 更新任务列表中的进度
        final updatedTasks = tasks.map((task) {
          if (task.id == event.taskId) {
            return task.copyWith(
              downloadedBytes: (event.progress / 100 * 100).toInt(),
              totalBytes: 100,
              status: _getStatusFromStage(event.stage),
            );
          }
          return task;
        }).toList();

        // 找到当前活跃任务
        final activeTask = updatedTasks.firstWhere(
          (t) => t.id == event.taskId,
          orElse: () => updatedTasks.isNotEmpty ? updatedTasks.first : null as DownloadTask,
        );

        state = DownloadModelState.loaded(
          downloads: updatedTasks,
          downloadStage: event.message,
          downloadProgress: event.progress,
          activeTask: activeTask?.id == event.taskId ? activeTask : null,
        );
      },
      orElse: () {},
    );
  }

  /// 从 stage 字符串获取 DownloadStatus
  DownloadStatus _getStatusFromStage(String stage) {
    switch (stage) {
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'paused':
        return DownloadStatus.paused;
      case 'downloading':
        return DownloadStatus.downloading;
      default:
        return DownloadStatus.downloading;
    }
  }

  /// 获取所有下载任务
  List<DownloadTask> get downloads {
    return state.maybeWhen(
      loaded: (tasks, _, __, ___) => tasks,
      orElse: () => const [],
    );
  }

  /// 获取下载阶段描述
  String get downloadStage {
    return state.maybeWhen(
      loaded: (_, stage, __, ___) => stage,
      orElse: () => '',
    );
  }

  /// 获取下载进度百分比
  int get downloadProgress {
    return state.maybeWhen(
      loaded: (_, _, progress, ___) => progress,
      orElse: () => 0,
    );
  }

  /// 获取指定状态的任务数
  int getCountByStatus(DownloadStatus status) {
    return downloads.where((d) => d.status == status).length;
  }

  /// 进行中的任务数
  int get activeCount => getCountByStatus(DownloadStatus.downloading) +
      getCountByStatus(DownloadStatus.pending);

  /// 已完成的任务数
  int get completedCount => getCountByStatus(DownloadStatus.completed);

  /// 失败的任务数
  int get failedCount => getCountByStatus(DownloadStatus.failed);

  /// 获取当前下载状态（公开 getter）
  DownloadModelState get downloadState => state;

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

      // 创建下载任务（保存到数据库）
      final taskId = await _repository.addDownloadTask(
        bvid: bvid,
        url: _repository.getDownloadUrl(bvid),
        savePath: savePath,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
      );

      // 重新加载任务列表
      await _loadTasks();

      // 开始下载
      await _repository.startDownload(taskId);

      // 返回创建的任务
      return await _repository.getTaskByBvid(bvid);
    } catch (e) {
      AppLogger.error('DownloadViewModel', '添加下载任务失败: $e');
      state = DownloadModelState.error(message: e.toString());
      return null;
    }
  }

  /// 暂停下载（真正的暂停 - 取消网络请求）
  Future<void> pauseDownload(int taskId) async {
    try {
      await _repository.pauseDownload(taskId);
      await _loadTasks(); // 刷新列表
      AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '暂停任务失败: $e');
    }
  }

  /// 恢复下载
  Future<void> resumeDownload(int taskId) async {
    try {
      await _repository.resumeDownload(taskId);
      await _loadTasks(); // 刷新列表
      AppLogger.info('DownloadViewModel', '已恢复任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
    }
  }

  /// 删除下载任务
  Future<void> deleteDownload(int taskId, {bool deleteFile = false}) async {
    try {
      await _repository.deleteDownloadTask(taskId, deleteFile: deleteFile);
      await _loadTasks(); // 刷新列表
      AppLogger.info('DownloadViewModel', '已删除任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '删除任务失败: $e');
    }
  }

  /// 取消下载（保留任务记录，但停止下载）
  Future<void> cancelDownload(int taskId) async {
    try {
      await _repository.cancelDownload(taskId);
      await _loadTasks(); // 刷新列表
      AppLogger.info('DownloadViewModel', '已取消任务: $taskId');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '取消任务失败: $e');
    }
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    try {
      await _repository.clearCompleted();
      await _loadTasks(); // 刷新列表
      AppLogger.info('DownloadViewModel', '清空已完成任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '清空任务失败: $e');
    }
  }

  /// 重试失败的任务
  Future<void> retryFailed() async {
    try {
      await _repository.retryFailed();
      AppLogger.info('DownloadViewModel', '重试失败任务');
    } catch (e) {
      AppLogger.error('DownloadViewModel', '重试失败: $e');
    }
  }

  /// 暂停所有下载
  Future<void> pauseAll() async {
    try {
      await _repository.pauseAll();
      await _loadTasks();
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

  /// 清空数据
  void clear() {
    state = const DownloadModelState.initial();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }
}

/// Provider 定义
@Riverpod(keepAlive: true)
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository();
}

@Riverpod(keepAlive: true)
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return DownloadViewModel(repository);
}
