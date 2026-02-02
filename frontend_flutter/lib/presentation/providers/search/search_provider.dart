import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/core/network/dio_provider.dart';

/// 搜索状态管理 Provider
///
/// 职责：
/// 1. 本地音频元数据全文搜索（基于后端 FTS5）
/// 2. 搜索建议（基于用户搜索历史）
/// 3. 热门关键词（基于搜索统计）
/// 4. 用户搜索历史管理
class SearchProvider with ChangeNotifier {
  String? _token;

  SearchProvider();

  // ==================== 状态变量 ====================

  /// 搜索结果列表
  List<Map<String, dynamic>> _searchResults = [];

  /// 搜索建议列表（自动完成）
  List<String> _searchSuggestions = [];

  /// 热门关键词列表（Top 10）
  List<String> _trendingKeywords = [];

  /// 用户搜索历史
  List<String> _searchHistory = [];

  /// 加载状态
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  // ==================== Getters ====================

  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<String> get searchSuggestions => _searchSuggestions;
  List<String> get trendingKeywords => _trendingKeywords;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // ==================== 初始化 ====================

  /// 更新认证Token（由AuthProvider调用）
  void updateToken(String? token) {
    _token = token;
    AppLogger.debug('SearchProvider', 'Token updated: ${token != null ? "set" : "cleared"}');
  }

  /// 初始化：加载热门关键词和搜索历史
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 并行加载热门关键词和搜索历史
      await Future.wait([
        loadTrendingKeywords(),
        if (_token != null) loadSearchHistory(),
      ]);

      AppLogger.debug('SearchProvider', 'Initialized');
    } catch (e) {
      AppLogger.error('SearchProvider', 'Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 本地全文搜索 ====================

  /// 执行本地音频元数据全文搜索（基于后端 FTS5）
  ///
  /// @param keyword 搜索关键词
  /// @param limit 返回结果数量限制（默认 20）
  /// @returns 是否成功
  Future<bool> searchLocalAudio(String keyword, {int limit = 20}) async {
    if (keyword.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return false;
    }

    try {
      _isSearching = true;
      _errorMessage = null;
      notifyListeners();

      final result = await DioProvider.instance.get(
        '/search/local',
        queryParams: {
          'q': keyword,
          'limit': limit.toString(),
        },
      );

      _searchResults = List<Map<String, dynamic>>.from(result['data'] ?? []);

      // 添加到本地搜索历史（前端维护）
      if (!_searchHistory.contains(keyword)) {
        _searchHistory.insert(0, keyword);
        if (_searchHistory.length > 20) {
          _searchHistory = _searchHistory.sublist(0, 20);
        }
        notifyListeners();
      }

      AppLogger.debug('SearchProvider', 'Search found ${_searchResults.length} results');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('SearchProvider', 'Search error: $e');
      return false;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // ==================== 搜索建议 ====================

  /// 获取搜索建议（基于前缀匹配）
  ///
  /// @param prefix 搜索前缀
  /// @returns 是否成功
  Future<bool> getSearchSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await DioProvider.instance.get(
        '/search/suggestions',
        queryParams: {
          'q': prefix,
        },
      );

      _searchSuggestions = List<String>.from(result['data'] ?? []);

      AppLogger.debug('SearchProvider', 'Suggestions: ${_searchSuggestions.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('SearchProvider', 'Get suggestions error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空搜索建议
  void clearSearchSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  // ==================== 热门关键词 ====================

  /// 加载热门关键词（Top 10，最近 7 天）
  ///
  /// @returns 是否成功
  Future<bool> loadTrendingKeywords() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await DioProvider.instance.get('/search/trending');

      _trendingKeywords = List<String>.from(result['data'] ?? []);

      AppLogger.debug('SearchProvider', 'Trending keywords: ${_trendingKeywords.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('SearchProvider', 'Load trending keywords error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 搜索历史 ====================

  /// 加载用户搜索历史（需要登录）
  ///
  /// @returns 是否成功
  Future<bool> loadSearchHistory() async {
    if (_token == null) {
      AppLogger.debug('SearchProvider', 'No token, skip loading history');
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await DioProvider.instance.get('/search/history');

      _searchHistory = List<String>.from(result['data'] ?? []);

      AppLogger.debug('SearchProvider', 'Search history: ${_searchHistory.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('SearchProvider', 'Load search history error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从搜索历史中删除关键词（前端删除）
  ///
  /// 注意：此操作不会从服务器删除，仅从前端列表中移除
  void removeFromHistory(String keyword) {
    _searchHistory.remove(keyword);
    notifyListeners();
  }

  /// 清空搜索历史（前端清空）
  ///
  /// 注意：此操作不会从服务器删除，仅清空前端列表
  void clearSearchHistory() {
    _searchHistory = [];
    notifyListeners();
  }

  // ==================== 工具方法 ====================

  /// 清空搜索结果
  void clearSearchResults() {
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
