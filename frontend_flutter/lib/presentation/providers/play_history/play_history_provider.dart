import 'dart:convert';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

/// 播放历史状态管理
///
/// 负责管理用户的播放历史记录
class PlayHistoryProvider with ChangeNotifier {
  late final DioProvider _dioProvider;

  // 数据状态 - 使用 PlayHistory 作为类型
  List<PlayHistory> _history = [];
  PlayHistoryStats? _stats;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  PlayHistoryProvider({DioProvider? dioProvider}) {
    _dioProvider = dioProvider ?? DioProvider.instance;
  }

  // Getters
  List<PlayHistory> get history => _history;
  PlayHistoryStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHistory => _history.isNotEmpty;

  /// 初始化
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await loadHistory(50);
      await loadStats();
    } catch (e) {
      _errorMessage = e.toString();
      // 加载失败时使用本地缓存
      await _loadHistoryFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从服务器加载播放历史
  Future<void> loadHistory(int limit) async {
    try {
      final response = await _dioProvider.get(
        '/history',
        queryParams: {'limit': limit.toString()},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _history = data.map((json) => PlayHistory.fromDto(json as Map<String, dynamic>)).toList();
        _saveHistoryToLocal();
      }
    } catch (e) {
      debugPrint('加载播放历史失败: $e');
      rethrow;
    }
  }

  /// 加载所有历史（不分页）
  Future<void> loadAllHistory(String token) async {
    try {
      final response = await _dioProvider.get(
        '/history/all',
        queryParams: {'token': token},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _history = data.map((json) => PlayHistory.fromDto(json as Map<String, dynamic>)).toList();
        _saveHistoryToLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载全部播放历史失败: $e');
    }
  }

  /// 加载统计信息
  Future<void> loadStats() async {
    try {
      final response = await _dioProvider.get('/history/stats');

      if (response['success'] == true && response['data'] != null) {
        _stats = PlayHistoryStats.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载播放统计失败: $e');
    }
  }

  /// 记录播放
  /// Phase 2 遗留问题: 扩展支持本地音频（localPath）
  Future<void> recordPlay({
    String? token,
    String? bvid,
    String? localPath,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int progress = 0,
  }) async {
    // 确定音频标识符（本地音频使用文件路径作为 ID）
    final identifier = bvid ?? localPath ?? '';
    if (identifier.isEmpty) {
      debugPrint('【PlayHistoryProvider】bvid 和 localPath 都为空，无法记录播放');
      return;
    }

    // 先更新本地列表（乐观更新）
    final existingIndex = _history.indexWhere((item) => item.audio.id == identifier);

    // 创建新的 Audio 对象
    final audio = Audio(
      id: identifier,
      title: title ?? '',
      artist: artist,
      duration: duration,
      coverUrl: coverUrl,
    );

    final newItem = PlayHistory(
      id: '', // 新建时 ID 由后端生成
      userId: '', // 用户 ID 从 token 获取
      audio: audio,
      playedAt: DateTime.now(),
      progress: progress,
    );

    if (existingIndex >= 0) {
      // 更新现有记录
      _history[existingIndex] = newItem;
      _history.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    } else {
      // 添加新记录到开头
      _history.insert(0, newItem);
      // 限制历史记录数量
      if (_history.length > 100) {
        _history = _history.sublist(0, 100);
      }
    }

    _saveHistoryToLocal();
    notifyListeners();

    // 异步同步到服务器（非阻塞，15秒超时）
    if (token != null && token.isNotEmpty) {
      // P0 修复: 不使用 await，避免阻塞播放流程
      // 增加超时时间到15秒，避免频繁超时失败
      // 注意：直接使用 dio 实例以设置自定义超时
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.fullBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Authorization': 'Bearer $token'},
      ));

      dio
          .post(
            '/history',
            data: {
              if (bvid != null) 'bvid': bvid,
              if (localPath != null) 'localPath': localPath,
              if (title != null) 'title': title,
              if (artist != null) 'artist': artist,
              if (duration != null) 'duration': duration,
              if (coverUrl != null) 'coverUrl': coverUrl,
              'progress': progress,
            },
          )
          .then((response) {
        // 更新统计
        _stats = PlayHistoryStats(
          totalPlays: (_stats?.totalPlays ?? 0) + 1,
        );
        debugPrint('【PlayHistoryProvider】播放历史记录成功');
      }).catchError((e) {
        debugPrint('【PlayHistoryProvider】记录播放失败（不影响播放）: $e');
      });
    }
  }

  /// 删除指定记录
  Future<bool> removeHistoryItem(String? token, String bvid) async {
    _history.removeWhere((item) => item.audio.id == bvid);
    _saveHistoryToLocal();
    notifyListeners();

    if (token != null && token.isNotEmpty) {
      try {
        await _dioProvider.delete('/history/$bvid');
        return true;
      } catch (e) {
        debugPrint('删除播放记录失败: $e');
      }
    }
    return true;
  }

  /// 按ID删除记录
  Future<bool> removeHistoryById(String? token, String id) async {
    _history.removeWhere((item) => item.id == id);
    _saveHistoryToLocal();
    notifyListeners();

    if (token != null && token.isNotEmpty) {
      try {
        await _dioProvider.delete('/history/by-id/$id');
        return true;
      } catch (e) {
        debugPrint('删除播放记录失败: $e');
      }
    }
    return true;
  }

  /// 清空历史
  Future<bool> clearHistory(String? token) async {
    _history = [];
    _stats = null;
    _saveHistoryToLocal();
    notifyListeners();

    // 同步到服务器
    if (token != null && token.isNotEmpty) {
      try {
        await _dioProvider.delete('/history');
        return true;
      } catch (e) {
        debugPrint('清空播放历史失败: $e');
      }
    }
    return true;
  }

  /// 获取去重后的历史（按bvid）
  List<PlayHistory> get uniqueHistory {
    final seen = <String>{};
    return _history.where((item) {
      if (seen.contains(item.audio.id)) {
        return false;
      }
      seen.add(item.audio.id);
      return true;
    }).toList();
  }

  /// 根据bvid查找历史记录
  PlayHistory? findByBvid(String bvid) {
    try {
      return _history.firstWhere((item) => item.audio.id == bvid);
    } catch (e) {
      return null;
    }
  }

  // ==================== 本地存储方法 ====================

  static const _historyKey = 'play_history_cache';

  Future<void> _loadHistoryFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson != null) {
        final data = jsonDecode(historyJson) as List;
        _history = data.map((json) => PlayHistory.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载本地播放历史失败: $e');
    }
  }

  Future<void> _saveHistoryToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_history.map((item) => item.toJson()).toList());
      await prefs.setString(_historyKey, json);
    } catch (e) {
      debugPrint('保存本地播放历史失败: $e');
    }
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    _history = [];
    _stats = null;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);

    notifyListeners();
  }
}
