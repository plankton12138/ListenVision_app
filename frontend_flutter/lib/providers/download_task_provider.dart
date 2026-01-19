import 'package:flutter/foundation.dart';
import 'package:demo/services/api_service.dart';

/// Phase 3.3: 下载任务状态管理 Provider
///
/// 职责：
/// 1. 下载任务 CRUD 操作
/// 2. 下载进度追踪
/// 3. 任务状态管理（pending/downloading/paused/completed/failed）
/// 4. 断点续传支持
class DownloadTaskProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _token;

  DownloadTaskProvider(this._apiService);

  // ==================== 状态变量 ====================

  /// 用户的所有下载任务
  List<Map<String, dynamic>> _tasks = [];

  /// 当前正在下载的任务
  List<Map<String, dynamic>> _activeTasks = [];

  /// 已完成和失败的任务
  List<Map<String, dynamic>> _completedTasks = [];

  /// 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  List<Map<String, dynamic>> get tasks => _tasks;
  List<Map<String, dynamic>> get activeTasks => _activeTasks;
  List<Map<String, dynamic>> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== 初始化 ====================

  /// 更新认证Token（由AuthProvider调用）
  void updateToken(String? token) {
    _token = token;
    debugPrint('【DownloadTaskProvider】Token updated: ${token != null ? "set" : "cleared"}');
  }

  /// 初始化：加载用户的下载任务
  Future<void> initialize() async {
    if (_token == null) {
      debugPrint('【DownloadTaskProvider】No token, skip initialization');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await loadTasks();

      debugPrint('【DownloadTaskProvider】Initialized: ${_tasks.length} tasks');
    } catch (e) {
      debugPrint('【DownloadTaskProvider】Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 任务 CRUD ====================

  /// 创建下载任务
  ///
  /// @param bvid 视频 ID
  /// @returns 任务 ID（成功）或 null（失败）
  Future<int?> createTask(String bvid, {
    String? title,
    String? artist,
    String? coverUrl,
    int? duration,
    int? fileSize,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.post(
        endpoint: '/downloads',
        token: _token,
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (coverUrl != null) 'cover_url': coverUrl,
          if (duration != null) 'duration': duration,
          if (fileSize != null) 'file_size': fileSize,
        },
      );

      if (result['success'] == true && result['data'] != null) {
        // 重新加载任务列表
        await loadTasks();

        final taskId = result['data']['id'] as int;
        debugPrint('【DownloadTaskProvider】Task created: $taskId');
        return taskId;
      }

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Create task error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载用户的所有下载任务
  Future<bool> loadTasks({String? status}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = <String, String>{};
      if (status != null) {
        query['status'] = status;
      }

      final result = await _apiService.get(
        endpoint: '/downloads',
        token: _token,
        query: query,
      );

      _tasks = List<Map<String, dynamic>>.from(result['data'] ?? []);

      // 更新分类
      _updateTaskCategories();

      debugPrint('【DownloadTaskProvider】Loaded ${_tasks.length} tasks');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Load tasks error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载单个任务详情
  Future<Map<String, dynamic>?> getTaskById(int taskId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _apiService.get(
        endpoint: '/downloads/$taskId',
        token: _token,
      );

      final task = result['data'] as Map<String, dynamic>?;

      // 更新任务列表中的任务
      if (task != null) {
        final index = _tasks.indexWhere((t) => t['id'] == taskId);
        if (index != -1) {
          _tasks[index] = task;
          _updateTaskCategories();
          notifyListeners();
        }
      }

      return task;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Get task error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 任务操作 ====================

  /// 暂停下载任务
  Future<bool> pauseTask(int taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.put(
        endpoint: '/downloads/$taskId/pause',
        token: _token,
      );

      if (result['success'] == true) {
        // 更新本地任务状态
        await getTaskById(taskId);
        debugPrint('【DownloadTaskProvider】Task paused: $taskId');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Pause task error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 恢复下载任务
  Future<bool> resumeTask(int taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.put(
        endpoint: '/downloads/$taskId/resume',
        token: _token,
      );

      if (result['success'] == true) {
        // 更新本地任务状态
        await getTaskById(taskId);
        debugPrint('【DownloadTaskProvider】Task resumed: $taskId');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Resume task error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 标记任务完成
  Future<bool> completeTask(int taskId, {String? filePath}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.put(
        endpoint: '/downloads/$taskId/complete',
        token: _token,
        data: {
          if (filePath != null) 'file_path': filePath,
        },
      );

      if (result['success'] == true) {
        // 更新本地任务状态
        await getTaskById(taskId);
        debugPrint('【DownloadTaskProvider】Task completed: $taskId');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Complete task error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 删除下载任务
  Future<bool> deleteTask(int taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.delete(
        endpoint: '/downloads/$taskId',
        token: _token,
      );

      if (result['success'] == true) {
        // 从本地列表中删除
        _tasks.removeWhere((t) => t['id'] == taskId);
        _updateTaskCategories();
        notifyListeners();

        debugPrint('【DownloadTaskProvider】Task deleted: $taskId');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Delete task error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空所有已完成的任务
  Future<bool> clearCompletedTasks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService.delete(
        endpoint: '/downloads/completed',
        token: _token,
      );

      if (result['success'] == true) {
        // 重新加载任务列表
        await loadTasks();

        debugPrint('【DownloadTaskProvider】Cleared completed tasks');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('【DownloadTaskProvider】Clear completed tasks error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 进度更新 ====================

  /// 更新下载进度（本地状态更新，用于实时显示）
  ///
  /// 注意：此方法只更新本地状态，不上传到服务器
  /// 服务器进度更新应该在下载管理器中实现
  void updateProgress(int taskId, int progress, int downloadedSize) {
    final index = _tasks.indexWhere((t) => t['id'] == taskId);
    if (index != -1) {
      _tasks[index]['progress'] = progress;
      _tasks[index]['downloaded_size'] = downloadedSize;
      notifyListeners();
    }
  }

  /// 批量更新进度
  void updateProgresses(Map<int, Map<String, dynamic>> progresses) {
    progresses.forEach((taskId, data) {
      final index = _tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        _tasks[index].addAll(data);
      }
    });
    notifyListeners();
  }

  // ==================== 工具方法 ====================

  /// 更新任务分类（活跃任务 vs 已完成任务）
  void _updateTaskCategories() {
    _activeTasks = _tasks.where((t) {
      final status = t['status'] as String?;
      return status == 'pending' || status == 'downloading' || status == 'paused';
    }).toList();

    _completedTasks = _tasks.where((t) {
      final status = t['status'] as String?;
      return status == 'completed' || status == 'failed';
    }).toList();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 刷新任务列表
  Future<bool> refresh() async {
    return await loadTasks();
  }

  /// 获取特定状态的任务
  List<Map<String, dynamic>> getTasksByStatus(String status) {
    return _tasks.where((t) => t['status'] == status).toList();
  }

  /// 获取进行中的任务数
  int get activeTaskCount => _activeTasks.length;

  /// 获取已完成的任务数
  int get completedTaskCount => _tasks.where((t) => t['status'] == 'completed').length;

  /// 获取失败的任务数
  int get failedTaskCount => _tasks.where((t) => t['status'] == 'failed').length;
}
