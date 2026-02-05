import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/download_repository.dart';
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

/// 下载管理 ViewModel
///
/// 负责音频下载的状态管理
class DownloadViewModel extends StateNotifier<DownloadModelState> {
  final DownloadRepository _repository;

  DownloadViewModel(this._repository) : super(const DownloadModelState.initial()) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    state = const DownloadModelState.loaded(
      downloads: [],
      downloadStage: '',
      downloadProgress: 0,
    );
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

  /// 添加下载任务
  Future<DownloadTask?> addDownload({
    required String bvid,
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('DownloadViewModel', '添加下载任务: $bvid');

      // 创建下载任务
      final task = DownloadTask(
        url: _repository.getDownloadUrl(bvid),
        savePath: savePath,
        bvid: bvid,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        status: DownloadStatus.pending,
        createdAt: DateTime.now(),
      );

      state.maybeWhen(
        loaded: (tasks, _, __, ___) {
          state = DownloadModelState.loaded(
            downloads: [...tasks, task],
            downloadStage: '准备中...',
            downloadProgress: 0,
          );
        },
        orElse: () {},
      );

      // 开始下载
      _startDownload(task);

      return task;
    } catch (e) {
      AppLogger.error('DownloadViewModel', '添加下载任务失败: $e');
      state = DownloadModelState.error(message: e.toString());
      return null;
    }
  }

  /// 启动下载
  void _startDownload(DownloadTask task) {
    _updateTaskStatus(task, DownloadStatus.downloading);

    // 设置下载阶段
    state.maybeWhen(
      loaded: (tasks, _, __, ___) {
        state = DownloadModelState.loaded(
          downloads: tasks,
          downloadStage: '准备中...',
          downloadProgress: 0,
          activeTask: task,
        );
      },
      orElse: () {},
    );

    // 使用后端 API 下载
    _repository.downloadAudio(
      bvid: task.bvid ?? '',
      savePath: task.savePath,
      onProgress: (percent, stage, message) {
        AppLogger.info('DownloadViewModel', '进度: $percent%, 阶段: $stage');
        state.maybeWhen(
          loaded: (tasks, _, __, active) {
            state = DownloadModelState.loaded(
              downloads: tasks,
              downloadStage: message,
              downloadProgress: percent,
              activeTask: active,
            );
          },
          orElse: () {},
        );
      },
    ).then((_) {
      // 下载成功
      AppLogger.info('DownloadViewModel', '下载完成: ${task.savePath}');

      state.maybeWhen(
        loaded: (tasks, _, __, active) {
          state = DownloadModelState.loaded(
            downloads: tasks,
            downloadStage: '完成',
            downloadProgress: 100,
            activeTask: active,
          );
        },
        orElse: () {},
      );

      _updateTaskStatus(task, DownloadStatus.completed);

      // 清空进度状态
      Future.delayed(const Duration(seconds: 2), () {
        state.maybeWhen(
          loaded: (tasks, _, __, active) {
            state = DownloadModelState.loaded(
              downloads: tasks,
              downloadStage: '',
              downloadProgress: 0,
              activeTask: active,
            );
          },
          orElse: () {},
        );
      });
    }).catchError((error) {
      // 下载失败
      AppLogger.error('DownloadViewModel', '下载失败: $error');

      final failedTask = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: error.toString(),
      );

      _replaceTask(failedTask);

      state.maybeWhen(
        loaded: (tasks, _, __, active) {
          state = DownloadModelState.loaded(
            downloads: tasks,
            downloadStage: '失败',
            downloadProgress: 0,
            activeTask: active,
          );
        },
        orElse: () {},
      );

      Future.delayed(const Duration(seconds: 2), () {
        state.maybeWhen(
          loaded: (tasks, _, __, active) {
            state = DownloadModelState.loaded(
              downloads: tasks,
              downloadStage: '',
              downloadProgress: 0,
              activeTask: active,
            );
          },
          orElse: () {},
        );
      });
    });
  }

  /// 暂停下载
  Future<void> pauseDownload(int taskId) async {
    final task = downloads.firstWhere(
      (d) => d.id == taskId,
      orElse: () => downloads.first,
    );
    _updateTaskStatus(task, DownloadStatus.paused);
    AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
  }

  /// 恢复下载
  Future<void> resumeDownload(int taskId) async {
    final task = downloads.firstWhere(
      (d) => d.id == taskId,
      orElse: () => downloads.first,
    );

    if (task.bvid == null || task.bvid!.isEmpty) {
      AppLogger.error('DownloadViewModel', '任务缺少 BVID，无法恢复');
      return;
    }

    _updateTaskStatus(task, DownloadStatus.pending);
    _startDownload(task);
    AppLogger.info('DownloadViewModel', '已恢复任务: $taskId');
  }

  /// 删除下载
  Future<void> deleteDownload(int taskId) async {
    state.maybeWhen(
      loaded: (tasks, _, __, active) {
        final updatedTasks = tasks.where((d) => d.id != taskId).toList();
        state = DownloadModelState.loaded(
          downloads: updatedTasks,
          downloadStage: downloadStage,
          downloadProgress: downloadProgress,
          activeTask: active?.id == taskId ? null : active,
        );
      },
      orElse: () {},
    );
    AppLogger.info('DownloadViewModel', '已删除任务: $taskId');
  }

  /// 清空已完成任务
  Future<void> clearCompleted() async {
    state.maybeWhen(
      loaded: (tasks, _, __, active) {
        final updatedTasks = tasks.where((d) => !d.isCompleted).toList();
        state = DownloadModelState.loaded(
          downloads: updatedTasks,
          downloadStage: downloadStage,
          downloadProgress: downloadProgress,
          activeTask: active,
        );
      },
      orElse: () {},
    );
  }

  /// 更新任务状态
  void _updateTaskStatus(DownloadTask task, DownloadStatus status) {
    final updatedTask = task.copyWith(status: status);
    _replaceTask(updatedTask);
  }

  /// 替换任务
  void _replaceTask(DownloadTask updatedTask) {
    state.maybeWhen(
      loaded: (tasks, stage, progress, active) {
        final index = tasks.indexWhere((d) => d.bvid == updatedTask.bvid);
        if (index != -1) {
          final updatedTasks = List<DownloadTask>.from(tasks);
          updatedTasks[index] = updatedTask;
          state = DownloadModelState.loaded(
            downloads: updatedTasks,
            downloadStage: stage,
            downloadProgress: progress,
            activeTask: active,
          );
        }
      },
      orElse: () {},
    );
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
}

/// Provider 定义
@riverpod
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository();
}

@riverpod
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return DownloadViewModel(repository);
}
