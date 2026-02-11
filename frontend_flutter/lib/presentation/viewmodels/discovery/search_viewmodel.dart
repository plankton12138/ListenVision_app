import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';
import '../../../models/search_suggestion.dart';

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
abstract class SearchState with _$SearchState {
  /// 初始状态
  const factory SearchState.initial() = SearchStateInitial;

  /// 加载中
  const factory SearchState.loading() = SearchStateLoading;

  /// 搜索结果已加载
  const factory SearchState.resultsLoaded({
    required List<SearchResultItem> results,
    required String query,
    required SearchPlatform platform,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    @Default(0) int totalCount,
    @Default(false) bool hasMore,
  }) = SearchStateResultsLoaded;

  /// 空闲状态
  const factory SearchState.idle({
    @Default([]) List<String> searchHistory,
    @Default([]) List<SearchSuggestion> suggestions,
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
@Riverpod(keepAlive: true)
class SearchViewModel extends _$SearchViewModel {
  BackendApiClient? _apiClient;

  @override
  Future<SearchState> build() async {
    _apiClient = ref.watch(searchBackendApiClientProvider);

    try {
      AppLogger.debug('SearchViewModel', '初始化');

      // 加载搜索历史
      final history = await _loadSearchHistoryFromServer();

      AppLogger.debug('SearchViewModel', '初始化完成');
      return SearchState.idle(
        searchHistory: history,
        suggestions: const [],
      );
    } catch (e) {
      AppLogger.error('SearchViewModel', '初始化失败: $e');
      return const SearchState.idle();
    }
  }

  /// 执行B站搜索
  ///
  /// @param keyword 搜索关键词
  /// @param page 页码（从1开始，默认1）
  /// @returns 是否成功
  Future<bool> search(String keyword, {int page = 1}) async {
    if (keyword.trim().isEmpty) {
      if (!ref.mounted) return false;
      state = AsyncData(SearchState.resultsLoaded(
        results: const [],
        query: keyword,
        platform: SearchPlatform.bilibili,
        currentPage: 1,
        pageSize: 20,
        totalCount: 0,
        hasMore: false,
      ));
      return false;
    }

    try {
      AppLogger.info('SearchViewModel', 'B站搜索: $keyword, page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final data = await _apiClient!.searchBilibili(keyword, page: page);
      final videos = data['videos'] as List? ?? [];
      // 优先使用后端返回的 total，如果没有则根据结果数量判断
      final totalCount = data['total'] as int? ?? 0;
      final pageSize = data['pageSize'] as int? ?? 20;
      final backendPage = data['page'] as int? ?? page;

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

      // 判断是否有更多结果：
      // 1. 如果后端返回了 total，使用 total 判断
      // 2. 否则，如果返回结果数等于 pageSize，假设还有更多（B站API行为）
      // 判断是否有更多结果：
      // 1. 如果后端返回了 total > 0，使用 total 判断
      // 2. 否则，首次搜索(page=1)有结果就显示按钮（让用户尝试）
      // 3. 后续页面根据返回结果数判断
      final hasMore = totalCount > 0
          ? (backendPage * pageSize < totalCount)
          : (page == 1 ? results.isNotEmpty : (results.length >= pageSize));

      if (!ref.mounted) return false;
      state = AsyncData(SearchState.resultsLoaded(
        results: results,
        query: keyword,
        platform: SearchPlatform.bilibili,
        currentPage: page,
        pageSize: pageSize,
        totalCount: totalCount,
        hasMore: hasMore,
      ));

      AppLogger.info('SearchViewModel', '搜索成功: ${results.length}条结果, total=$totalCount, hasMore=$hasMore');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '搜索失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 加载下一页搜索结果
  ///
  /// @returns 是否成功
  Future<bool> loadNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState is! SearchStateResultsLoaded) {
      AppLogger.warn('SearchViewModel', '当前非搜索结果状态，无法加载下一页');
      return false;
    }

    if (!currentState.hasMore) {
      AppLogger.debug('SearchViewModel', '没有更多结果');
      return false;
    }

    final nextPage = currentState.currentPage + 1;
    AppLogger.info('SearchViewModel', '加载下一页: $nextPage');

    try {
      final data = await _apiClient!.searchBilibili(
        currentState.query,
        page: nextPage,
      );
      final videos = data['videos'] as List? ?? [];
      final totalCount = data['total'] as int? ?? currentState.totalCount;
      final pageSize = data['pageSize'] as int? ?? currentState.pageSize;

      final newResults = videos
          .map((v) => SearchResultItem(
                bvid: v['bvid'] as String,
                title: v['title'] as String,
                author: v['author'] as String?,
                coverUrl: v['cover'] as String?,
                duration: _parseDuration(v['duration']),
                platform: SearchPlatform.bilibili,
              ))
          .toList();

      // 合并结果
      final mergedResults = [...currentState.results, ...newResults];
      // 判断是否还有更多：如果返回空结果，则没有更多了
      final hasMore = totalCount > 0
          ? (nextPage * pageSize < totalCount)
          : (newResults.length >= pageSize);

      if (!ref.mounted) return false;
      state = AsyncData(currentState.copyWith(
        results: mergedResults,
        currentPage: nextPage,
        totalCount: totalCount,
        hasMore: hasMore,
      ));

      AppLogger.info('SearchViewModel', '加载下一页成功: ${newResults.length}条新结果, 总计${mergedResults.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载下一页失败: $e');
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
          await _apiClient!.getBilibiliSearchSuggestions(prefix);

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

      final current = state.valueOrNull;
      if (current is SearchStateIdle) {
        if (!ref.mounted) return false;
        state = AsyncData(current.copyWith(searchHistory: history));
      } else {
        if (!ref.mounted) return false;
        state = AsyncData(SearchState.idle(
          searchHistory: history,
          suggestions: const [],
        ));
      }

      AppLogger.debug('SearchViewModel', '搜索历史: ${history.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return false;
    }
  }

  /// 从搜索历史中删除关键词
  void removeFromHistory(String keyword) {
    final current = state.valueOrNull;
    if (current is SearchStateIdle) {
      state = AsyncData(current.copyWith(
        searchHistory: [...current.searchHistory]..remove(keyword),
      ));
    }
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    try {
      await _apiClient!.clearBilibiliSearchHistory();

      final current = state.valueOrNull;
      if (current is SearchStateIdle) {
        if (!ref.mounted) return;
        state = AsyncData(current.copyWith(searchHistory: const []));
      }

      AppLogger.info('SearchViewModel', '清空搜索历史成功');
    } catch (e) {
      AppLogger.error('SearchViewModel', '清空搜索历史失败: $e');
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    final current = state.valueOrNull;
    if (current is SearchStateResultsLoaded) {
      state = const AsyncData(SearchState.idle());
    }
  }

  /// 清除错误信息
  void clearError() {
    if (state.valueOrNull is SearchStateError) {
      state = const AsyncData(SearchState.idle());
    }
  }

  // ==================== 私有方法 ====================

  Future<List<String>> _loadSearchHistoryFromServer() async {
    try {
      return await _apiClient!.getBilibiliSearchHistory();
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return const [];
    }
  }

  void _updateIdleState({
    List<String>? searchHistory,
    List<SearchSuggestion>? suggestions,
  }) {
    final current = state.valueOrNull;
    if (current is SearchStateIdle) {
      state = AsyncData(current.copyWith(
        searchHistory: searchHistory ?? current.searchHistory,
        suggestions: suggestions ?? current.suggestions,
      ));
    } else {
      state = AsyncData(SearchState.idle(
        searchHistory: searchHistory ?? const <String>[],
        suggestions: suggestions ?? const <SearchSuggestion>[],
      ));
    }
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
BackendApiClient searchBackendApiClient(Ref ref) {
  return BackendApiClient();
}
