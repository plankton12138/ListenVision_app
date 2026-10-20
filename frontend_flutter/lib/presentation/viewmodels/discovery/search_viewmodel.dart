import 'dart:async';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/search_suggestion.dart';
import '../../../models/audio.dart';
import '../../../services/bilibili_api_service.dart';

part 'search_viewmodel.freezed.dart';
part 'search_viewmodel.g.dart';

/// 搜索平台枚举（预留扩展）
enum SearchPlatform { bilibili }

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

  const factory SearchState.error({required String message}) = SearchStateError;
}

/// 搜索结果项
class SearchResultItem {
  final String bvid;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? duration;
  final SearchPlatform platform;
  final int videos;

  SearchResultItem({
    required this.bvid,
    required this.title,
    this.author,
    this.coverUrl,
    this.duration,
    required this.platform,
    this.videos = 1,
  });
}

/// 搜索 ViewModel
///
/// 直接调用 B站 API，搜索历史本地存储。
@Riverpod(keepAlive: true)
class SearchViewModel extends _$SearchViewModel {
  late BilibiliApiService _api;
  int _searchId = 0;
  int _suggestionId = 0;
  CancelToken? _searchToken;
  CancelToken? _pageToken;
  CancelToken? _suggestionToken;
  Timer? _suggestionTimer;
  Completer<bool>? _suggestionCompleter;
  bool _loadingPage = false;

  @override
  Future<SearchState> build() async {
    _api = ref.watch(bilibiliApiServiceProvider);
    ref.onDispose(() {
      _cancelSearch();
      _cancelSuggestions();
    });
    return const SearchState.idle();
  }

  void _cancelSearch() {
    _searchId++;
    _searchToken?.cancel();
    _pageToken?.cancel();
    _searchToken = null;
    _pageToken = null;
    _loadingPage = false;
  }

  void _cancelSuggestions() {
    _suggestionId++;
    _suggestionTimer?.cancel();
    _suggestionToken?.cancel();
    _suggestionToken = null;
    final pending = _suggestionCompleter;
    if (pending != null && !pending.isCompleted) pending.complete(false);
    _suggestionCompleter = null;
  }

  bool _isCurrent(int id) => ref.mounted && id == _searchId;

  SearchResultItem _toResult(Audio audio) => SearchResultItem(
    bvid: audio.id,
    title: audio.title,
    author: audio.artist,
    coverUrl: audio.coverUrl,
    duration: audio.duration,
    platform: SearchPlatform.bilibili,
    videos: audio.videos,
  );

  Future<bool> search(String keyword, {int page = 1}) async {
    _cancelSearch();
    _cancelSuggestions();
    if (!ref.mounted) return false;
    final query = keyword.trim();
    if (query.isEmpty) {
      state = const AsyncData(SearchState.idle());
      return false;
    }
    final id = _searchId;
    final token = _searchToken = CancelToken();
    AppLogger.info('SearchViewModel', '搜索: $query, page=$page');
    state = const AsyncLoading();
    try {
      final audios = await _api.search(
        keyword: query,
        page: page,
        pageSize: 20,
        cancelToken: token,
      );
      if (!_isCurrent(id)) return false;
      final results = audios.map(_toResult).toList();
      state = AsyncData(
        SearchState.resultsLoaded(
          results: results,
          query: query,
          platform: SearchPlatform.bilibili,
          currentPage: page,
          hasMore: results.length >= 20,
        ),
      );
      return true;
    } catch (error, stack) {
      if (!_isCurrent(id) ||
          token.isCancelled ||
          error is TaskCanceledException) {
        return false;
      }
      AppLogger.error('SearchViewModel', '搜索失败: $error');
      state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> loadNextPage() async {
    final current = state.valueOrNull;
    if (_loadingPage ||
        current is! SearchStateResultsLoaded ||
        !current.hasMore) {
      return false;
    }
    _loadingPage = true;
    final id = _searchId;
    final token = _pageToken = CancelToken();
    try {
      final audios = await _api.search(
        keyword: current.query,
        page: current.currentPage + 1,
        pageSize: current.pageSize,
        cancelToken: token,
      );
      if (!_isCurrent(id) || token.isCancelled) return false;
      final seen = current.results.map((item) => item.bvid).toSet();
      final added = audios.map(_toResult).where((item) => seen.add(item.bvid));
      state = AsyncData(
        current.copyWith(
          results: [...current.results, ...added],
          currentPage: current.currentPage + 1,
          hasMore: audios.length >= current.pageSize,
        ),
      );
      return true;
    } catch (error) {
      if (_isCurrent(id) &&
          !token.isCancelled &&
          error is! TaskCanceledException) {
        AppLogger.error('SearchViewModel', '加载下一页失败: $error');
      }
      return false;
    } finally {
      if (identical(_pageToken, token)) {
        _pageToken = null;
        _loadingPage = false;
      }
    }
  }

  /// 防抖与过期检查放在 ViewModel，所有入口使用相同规则。
  Future<bool> getSearchSuggestions(String prefix) {
    _cancelSuggestions();
    if (!ref.mounted) return Future.value(false);
    final query = prefix.trim();
    if (query.length < 2) {
      _updateIdleState(suggestions: const []);
      return Future.value(false);
    }
    final id = _suggestionId;
    final pending = _suggestionCompleter = Completer<bool>();
    _suggestionTimer = Timer(const Duration(milliseconds: 300), () async {
      final token = _suggestionToken = CancelToken();
      var success = false;
      try {
        final raw = await _api.getSearchSuggestions(query, cancelToken: token);
        if (ref.mounted &&
            id == _suggestionId &&
            !token.isCancelled &&
            state.valueOrNull is SearchStateIdle &&
            state is! AsyncLoading<SearchState>) {
          _updateIdleState(
            suggestions: raw
                .map((s) => SearchSuggestion(value: s, name: s))
                .toList(),
          );
          success = true;
        }
      } catch (error) {
        if (ref.mounted &&
            id == _suggestionId &&
            !token.isCancelled &&
            error is! TaskCanceledException) {
          AppLogger.error('SearchViewModel', '获取搜索建议失败: $error');
        }
      } finally {
        if (!pending.isCompleted) pending.complete(success);
        if (identical(_suggestionCompleter, pending)) {
          _suggestionCompleter = null;
        }
      }
    });
    return pending.future;
  }

  void clearSearchSuggestions() {
    _cancelSuggestions();
    if (ref.mounted) _updateIdleState(suggestions: const []);
  }

  void clearSearchResults() {
    _cancelSearch();
    _cancelSuggestions();
    if (ref.mounted) state = const AsyncData(SearchState.idle());
  }

  Future<void> clearSearchHistory() async {
    _updateIdleState(searchHistory: const []);
  }

  void removeFromHistory(String keyword) {
    final current = state.valueOrNull;
    if (current is SearchStateIdle) {
      _updateIdleState(
        searchHistory: [...current.searchHistory]..remove(keyword),
      );
    }
  }

  void clearError() {
    if (state.hasError || state.valueOrNull is SearchStateError) {
      clearSearchResults();
    }
  }

  void _updateIdleState({
    List<String>? searchHistory,
    List<SearchSuggestion>? suggestions,
  }) {
    final current = state.valueOrNull;
    if (current is SearchStateIdle && state is! AsyncLoading<SearchState>) {
      state = AsyncData(
        current.copyWith(
          searchHistory: searchHistory ?? current.searchHistory,
          suggestions: suggestions ?? current.suggestions,
        ),
      );
    }
  }
}
