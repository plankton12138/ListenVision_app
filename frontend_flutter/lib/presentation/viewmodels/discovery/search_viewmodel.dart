import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';

part 'search_viewmodel.freezed.dart';
part 'search_viewmodel.g.dart';

/// 搜索平台枚举（预留扩展）
enum SearchPlatform {
  bilibili, // B站（当前唯一可用）
  // netease,   // 网易云音乐（未来扩展）
  // qqmusic,   // QQ音乐（未来扩展）
}

/// 搜索状态
@freezed
class SearchState with _$SearchState {
  /// 初始状态
  const factory SearchState.initial() = SearchStateInitial;

  /// 加载中
  const factory SearchState.loading() = SearchStateLoading;

  /// 搜索结果已加载
  const factory SearchState.resultsLoaded({
    required List<SearchResultItem> results,
    required String query,
    required SearchPlatform platform,
  }) = SearchStateResultsLoaded;

  /// 空闲状态
  const factory SearchState.idle({
    @Default([]) List<String> searchHistory,
    @Default([]) List<String> suggestions,
    @Default(SearchPlatform.bilibili) SearchPlatform platform,
  }) = SearchStateIdle;

  /// 错误
  const factory SearchState.error({
    required String message,
  }) = SearchStateError;
}

/// 搜索结果项
class SearchResultItem {
  final String bvid;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? duration;
  final SearchPlatform platform;

  SearchResultItem({
    required this.bvid,
    required this.title,
    this.author,
    this.coverUrl,
    this.duration,
    required this.platform,
  });
}

/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议
@riverpod
class SearchViewModel extends _$SearchViewModel {
  late final BackendApiClient _apiClient;

  @override
  SearchState build() {
    _apiClient = ref.read(searchBackendApiClientProvider);
    _initialize();
    return const SearchState.initial();
  }

  /// 初始化：加载搜索历史
  Future<void> _initialize() async {
    try {
      AppLogger.debug('SearchViewModel', '初始化');

      // 加载搜索历史
      final history = await _loadSearchHistoryFromServer();

      state = SearchState.idle(
        searchHistory: history,
        suggestions: const [],
      );

      AppLogger.debug('SearchViewModel', '初始化完成');
    } catch (e) {
      AppLogger.error('SearchViewModel', '初始化失败: $e');
      state = const SearchState.idle();
    }
  }

  /// 执行B站搜索
  ///
  /// @param keyword 搜索关键词
  /// @returns 是否成功
  Future<bool> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      state = SearchState.resultsLoaded(
        results: const [],
        query: keyword,
        platform: SearchPlatform.bilibili,
      );
      return false;
    }

    try {
      AppLogger.info('SearchViewModel', 'B站搜索: $keyword');

      state = const SearchState.loading();

      final data = await _apiClient.searchBilibili(keyword);
      final videos = data['videos'] as List? ?? [];

      final results = videos
          .map((v) => SearchResultItem(
                bvid: v['bvid'] as String,
                title: v['title'] as String,
                author: v['author'] as String?,
                coverUrl: v['cover'] as String?,
                duration: _parseDuration(v['duration']),
                platform: SearchPlatform.bilibili,
              ))
          .toList();

      state = SearchState.resultsLoaded(
        results: results,
        query: keyword,
        platform: SearchPlatform.bilibili,
      );

      // 添加到搜索历史
      await _addToSearchHistory(keyword);

      AppLogger.info('SearchViewModel', '搜索成功: ${results.length}条结果');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '搜索失败: $e');
      state = SearchState.error(message: e.toString());
      return false;
    }
  }

  /// 获取搜索建议
  Future<bool> getSearchSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      _updateIdleState(suggestions: const []);
      return false;
    }

    try {
      AppLogger.debug('SearchViewModel', '获取搜索建议: $prefix');

      // B站搜索建议（可接入B站API）
      final suggestions =
          await _apiClient.getBilibiliSearchSuggestions(prefix);

      _updateIdleState(suggestions: suggestions);

      AppLogger.debug('SearchViewModel', '搜索建议: ${suggestions.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '获取搜索建议失败: $e');
      return false;
    }
  }

  /// 清空搜索建议
  void clearSearchSuggestions() {
    _updateIdleState(suggestions: const []);
  }

  /// 加载用户搜索历史
  Future<bool> loadSearchHistory() async {
    try {
      AppLogger.debug('SearchViewModel', '加载搜索历史');

      final history = await _loadSearchHistoryFromServer();

      state = state.maybeMap(
        idle: (value) => value.copyWith(searchHistory: history),
        orElse: () => SearchState.idle(
          searchHistory: history,
          suggestions: const [],
        ),
      );

      AppLogger.debug('SearchViewModel', '搜索历史: ${history.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return false;
    }
  }

  /// 从搜索历史中删除关键词
  void removeFromHistory(String keyword) {
    state = state.maybeMap(
      idle: (value) => value.copyWith(
        searchHistory: [...value.searchHistory]..remove(keyword),
      ),
      orElse: () => state,
    );
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    try {
      await _apiClient.clearBilibiliSearchHistory();

      state = state.maybeMap(
        idle: (value) => value.copyWith(searchHistory: const []),
        orElse: () => state,
      );

      AppLogger.info('SearchViewModel', '清空搜索历史成功');
    } catch (e) {
      AppLogger.error('SearchViewModel', '清空搜索历史失败: $e');
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    state = state.maybeMap(
      resultsLoaded: (_) => SearchState.idle(
        searchHistory: state.maybeMap(
          idle: (value) => value.searchHistory,
          orElse: () => const [],
        ),
        suggestions: state.maybeMap(
          idle: (value) => value.suggestions,
          orElse: () => const [],
        ),
      ),
      orElse: () => state,
    );
  }

  /// 清除错误信息
  void clearError() {
    state = state.maybeMap(
      error: (_) => const SearchState.idle(),
      orElse: () => state,
    );
  }

  // ==================== 私有方法 ====================

  Future<List<String>> _loadSearchHistoryFromServer() async {
    try {
      return await _apiClient.getBilibiliSearchHistory();
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return const [];
    }
  }

  Future<void> _addToSearchHistory(String keyword) async {
    try {
      await _apiClient.addBilibiliSearchHistory(keyword);
    } catch (e) {
      AppLogger.error('SearchViewModel', '添加搜索历史失败: $e');
    }
  }

  void _updateIdleState({
    List<String>? searchHistory,
    List<String>? suggestions,
  }) {
    state = state.maybeMap(
      idle: (value) => value.copyWith(
        searchHistory: searchHistory ?? value.searchHistory,
        suggestions: suggestions ?? value.suggestions,
      ),
      orElse: () => SearchState.idle(
        searchHistory: searchHistory ?? const [],
        suggestions: suggestions ?? const [],
      ),
    );
  }

  /// 解析时长字符串（如 "03:45" -> 225秒）
  int? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is String) {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    }
    return null;
  }
}

/// BackendApiClient Provider
@riverpod
BackendApiClient searchBackendApiClient(SearchBackendApiClientRef ref) {
  return BackendApiClient();
}
