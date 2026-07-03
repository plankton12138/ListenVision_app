import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/search_suggestion.dart';
import '../../../services/bilibili_api_service.dart';

part 'search_viewmodel.freezed.dart';
part 'search_viewmodel.g.dart';

/// 搜索平台枚举（预留扩展）
enum SearchPlatform {
  bilibili,
}

/// 搜索状态
@freezed
abstract class SearchState with _$SearchState {
  const factory SearchState.initial() = SearchStateInitial;

  const factory SearchState.loading() = SearchStateLoading;

  const factory SearchState.resultsLoaded({
    required List<SearchResultItem> results,
    required String query,
    required SearchPlatform platform,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    @Default(0) int totalCount,
    @Default(false) bool hasMore,
  }) = SearchStateResultsLoaded;

  const factory SearchState.idle({
    @Default([]) List<String> searchHistory,
    @Default([]) List<SearchSuggestion> suggestions,
    @Default(SearchPlatform.bilibili) SearchPlatform platform,
  }) = SearchStateIdle;

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
/// 直接调用 B站 API，搜索历史本地存储。
@Riverpod(keepAlive: true)
class SearchViewModel extends _$SearchViewModel {
  BilibiliApiService? _api;

  @override
  Future<SearchState> build() async {
    _api = ref.watch(bilibiliApiServiceProvider);

    try {
      AppLogger.debug('SearchViewModel', '初始化');
      return const SearchState.idle();
    } catch (e) {
      AppLogger.error('SearchViewModel', '初始化失败: $e');
      return const SearchState.idle();
    }
  }

  /// 执行B站搜索
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

      final audios = await _api!.search(keyword: keyword, page: page, pageSize: 20);

      final results = audios.map((audio) => SearchResultItem(
        bvid: audio.id,
        title: audio.title,
        author: audio.artist,
        coverUrl: audio.coverUrl,
        duration: audio.duration,
        platform: SearchPlatform.bilibili,
      )).toList();

      final hasMore = results.length >= 20;

      if (!ref.mounted) return false;
      state = AsyncData(SearchState.resultsLoaded(
        results: results,
        query: keyword,
        platform: SearchPlatform.bilibili,
        currentPage: page,
        pageSize: 20,
        totalCount: 0,
        hasMore: hasMore,
      ));

      AppLogger.info('SearchViewModel', '搜索成功: ${results.length}条结果, hasMore=$hasMore');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '搜索失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 加载下一页搜索结果
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
      final audios = await _api!.search(
        keyword: currentState.query,
        page: nextPage,
        pageSize: currentState.pageSize,
      );

      final newResults = audios.map((audio) => SearchResultItem(
        bvid: audio.id,
        title: audio.title,
        author: audio.artist,
        coverUrl: audio.coverUrl,
        duration: audio.duration,
        platform: SearchPlatform.bilibili,
      )).toList();

      final mergedResults = [...currentState.results, ...newResults];
      final hasMore = newResults.length >= currentState.pageSize;

      if (!ref.mounted) return false;
      state = AsyncData(currentState.copyWith(
        results: mergedResults,
        currentPage: nextPage,
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

      final rawSuggestions = await _api!.getSearchSuggestions(prefix);

      final suggestions = rawSuggestions.map((s) => SearchSuggestion(
        value: s,
        name: s,
      )).toList();

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

  /// 清空搜索结果
  void clearSearchResults() {
    final current = state.valueOrNull;
    if (current is SearchStateResultsLoaded) {
      state = const AsyncData(SearchState.idle());
    }
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    _updateIdleState(searchHistory: const []);
    AppLogger.info('SearchViewModel', '清空搜索历史成功');
  }

  /// 从搜索历史中删除关键词
  void removeFromHistory(String keyword) {
    final current = state.valueOrNull;
    if (current is SearchStateIdle) {
      final updated = [...current.searchHistory]..remove(keyword);
      state = AsyncData(current.copyWith(searchHistory: updated));
    }
  }

  /// 清除错误信息
  void clearError() {
    if (state.valueOrNull is SearchStateError) {
      state = const AsyncData(SearchState.idle());
    }
  }

  // ==================== 私有方法 ====================

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
}
