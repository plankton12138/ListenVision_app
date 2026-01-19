import 'dart:convert';
import 'package:demo/models/play_history.dart';
import 'package:demo/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放历史状态管理
///
/// 负责管理用户的播放历史记录
class PlayHistoryProvider with ChangeNotifier {
  final ApiService _apiService;

  // 数据状态
  List<PlayHistoryItem> _history = [];
  PlayHistoryStats? _stats;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  PlayHistoryProvider(this._apiService);

  // Getters
  List<PlayHistoryItem> get history => _history;
  PlayHistoryStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHistory => _history.isNotEmpty;

  /// 初始化
  Future<void> initialize(String? token) async {
    if (token == null || token.isEmpty) {
      // 未登录，加载本地历史
      await _loadHistoryFromLocal();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await loadHistory(token);
      await loadStats(token);
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
  Future<void> loadHistory(String token, {int limit = 50}) async {
    try {
      final response = await _apiService.get(
        endpoint: '/history',
        token: token,
        query: {'limit': limit.toString()},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _history = data.map((json) => PlayHistoryItem.fromJson(json as Map<String, dynamic>)).toList();
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
      final response = await _apiService.get(
        endpoint: '/history/all',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        _history = data.map((json) => PlayHistoryItem.fromJson(json as Map<String, dynamic>)).toList();
        _saveHistoryToLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载全部播放历史失败: $e');
    }
  }

  /// 加载统计信息
  Future<void> loadStats(String token) async {
    try {
      final response = await _apiService.get(
        endpoint: '/history/stats',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        _stats = PlayHistoryStats.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载播放统计失败: $e');
    }
  }

  /// 记录播放
  Future<void> recordPlay(
    String? token, {
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int progress = 0,
  }) async {
    // 先更新本地列表（乐观更新）
    final existingIndex = _history.indexWhere((item) => item.bvid == bvid);
    final newItem = PlayHistoryItem(
      bvid: bvid,
      title: title,
      artist: artist,
      duration: duration,
      coverUrl: coverUrl,
      playedAt: DateTime.now(),
      progress: progress,
    );

    if (existingIndex >= 0) {
      // 更新现有记录
      _history[existingIndex] = newItem;
      _history.sort((a, b) => (b.playedAt ?? DateTime.now()).compareTo(a.playedAt ?? DateTime.now()));
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

    // 异步同步到服务器
    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.post(
          endpoint: '/history',
          token: token,
          data: {
            'bvid': bvid,
            if (title != null) 'title': title,
            if (artist != null) 'artist': artist,
            if (duration != null) 'duration': duration,
            if (coverUrl != null) 'coverUrl': coverUrl,
            'progress': progress,
          },
        );

        // 更新统计
        _stats = PlayHistoryStats(
          totalPlays: (_stats?.totalPlays ?? 0) + 1,
          lastPlayed: newItem,
        );
      } catch (e) {
        debugPrint('记录播放失败: $e');
      }
    }
  }

  /// 删除指定记录
  Future<bool> removeHistoryItem(String? token, String bvid) async {
    _history.removeWhere((item) => item.bvid == bvid);
    _saveHistoryToLocal();
    notifyListeners();

    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.delete(
          endpoint: '/history/$bvid',
          token: token,
        );
        return true;
      } catch (e) {
        debugPrint('删除播放记录失败: $e');
      }
    }
    return true;
  }

  /// 按ID删除记录
  Future<bool> removeHistoryById(String? token, int id) async {
    _history.removeWhere((item) => item.id == id);
    _saveHistoryToLocal();
    notifyListeners();

    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.delete(
          endpoint: '/history/by-id/$id',
          token: token,
        );
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

    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.delete(
          endpoint: '/history',
          token: token,
        );
        return true;
      } catch (e) {
        debugPrint('清空播放历史失败: $e');
      }
    }
    return true;
  }

  /// 获取去重后的历史（按bvid）
  List<PlayHistoryItem> get uniqueHistory {
    final seen = <String>{};
    return _history.where((item) {
      if (seen.contains(item.bvid)) {
        return false;
      }
      seen.add(item.bvid);
      return true;
    }).toList();
  }

  /// 根据bvid查找历史记录
  PlayHistoryItem? findByBvid(String bvid) {
    try {
      return _history.firstWhere((item) => item.bvid == bvid);
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
        _history = data.map((json) => PlayHistoryItem.fromJson(json as Map<String, dynamic>)).toList();
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
