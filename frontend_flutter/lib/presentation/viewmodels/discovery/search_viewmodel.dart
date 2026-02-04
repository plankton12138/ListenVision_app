import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';

part 'search_viewmodel.freezed.dart';
part 'search_viewmodel.g.dart';

/// 搜索状态
@freezed
class SearchState with _$SearchState {
  /// 初始状态
  const factory SearchState.initial() = SearchStateInitial;

  /// 加载中
  const factory SearchState.loading() = SearchStateLoading;

  /// 搜索结果已加载
  const factory SearchState.resultsLoaded({
    required List<Map<String, dynamic>> results,
    required String query,
  }) = SearchStateResultsLoaded;

  /// 空闲状态
  const factory SearchState.idle({
    @Default([]) List<String> searchHistory,
    @Default([]) List<String> suggestions,
  }) = SearchStateIdle;

  /// 错误
  const factory SearchState.error({
    required String message,
  }) = SearchStateError;
}

/// 搜索 ViewModel
///
/// 职责：
/// 1. 本地音频元数据全文搜索（基于后端 FTS5）
/// 2. 搜索建议（基于用户搜索历史）
/// 3. 用户搜索历史管理
class SearchViewModel extends StateNotifier<SearchState> {
  final BackendApiClient _apiClient;

  SearchViewModel(this._apiClient) : super(const SearchState.initial()) {
    _initialize();
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

  /// 执行本地音频元数据全文搜索（基于后端 FTS5）
  ///
  /// @param keyword 搜索关键词
  /// @param limit 返回结果数量限制（默认 20）
  /// @returns 是否成功
  Future<bool> searchLocalAudio(String keyword, {int limit = 20}) async {
    if (keyword.trim().isEmpty) {
      state = SearchState.resultsLoaded(
        results: const [],
        query: keyword,
      );
      return false;
    }

    try {
      AppLogger.info('SearchViewModel', '搜索本地音频: $keyword');

      state = const SearchState.loading();

      final data = await _apiClient.searchLocal(
        keyword: keyword,
        pageSize: limit,
      );

      final results = (data['results'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      state = SearchState.resultsLoaded(
        results: results,
        query: keyword,
      );

      // 添加到本地搜索历史（前端维护）
      final currentHistory = state.maybeWhen(
        idle: (history, _) => history,
        resultsLoaded: (_, ___) => const [],
        orElse: () => const [],
      );

      final updatedHistory = _addToHistory(keyword, currentHistory);

      state = SearchState.idle(
        searchHistory: updatedHistory,
        suggestions: const [],
      );

      AppLogger.info('SearchViewModel', '搜索成功: ${results.length}条结果');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '搜索失败: $e');
      state = SearchState.error(message: e.toString());
      return false;
    }
  }

  /// 获取搜索建议（基于前缀匹配）
  ///
  /// @param prefix 搜索前缀
  /// @returns 是否成功
  Future<bool> getSearchSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      _updateIdleState(suggestions: const []);
      return false;
    }

    try {
      AppLogger.debug('SearchViewModel', '获取搜索建议: $prefix');

      final suggestions = await _apiClient.getSearchSuggestions(prefix);

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

  /// 加载用户搜索历史（需要登录）
  ///
  /// @returns 是否成功
  Future<bool> loadSearchHistory() async {
    try {
      AppLogger.debug('SearchViewModel', '加载搜索历史');

      final history = await _loadSearchHistoryFromServer();

      state.maybeWhen(
        idle: (_, suggestions) {
          state = SearchState.idle(
            searchHistory: history,
            suggestions: suggestions,
          );
        },
        orElse: () {
          state = SearchState.idle(
            searchHistory: history,
            suggestions: const [],
          );
        },
      );

      AppLogger.debug('SearchViewModel', '搜索历史: ${history.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return false;
    }
  }

  /// 从搜索历史中删除关键词（前端删除）
  ///
  /// 注意：此操作不会从服务器删除，仅从前端列表中移除
  void removeFromHistory(String keyword) {
    state.maybeWhen(
      idle: (history, suggestions) {
        final updatedHistory = List<String>.from(history)..remove(keyword);
        state = SearchState.idle(
          searchHistory: updatedHistory,
          suggestions: suggestions,
        );
      },
      orElse: () {},
    );
  }

  /// 清空搜索历史（前端清空 + 服务器清空）
  Future<void> clearSearchHistory() async {
    try {
      // 从服务器清空
      await _apiClient.clearSearchHistory();

      state.maybeWhen(
        idle: (_, suggestions) {
          state = SearchState.idle(
            searchHistory: const [],
            suggestions: suggestions,
          );
        },
        orElse: () {},
      );

      AppLogger.info('SearchViewModel', '清空搜索历史成功');
    } catch (e) {
      AppLogger.error('SearchViewModel', '清空搜索历史失败: $e');
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    state.maybeWhen(
      resultsLoaded: (_, __) {
        // 恢复到空闲状态
        state = SearchState.idle(
          searchHistory: state.maybeWhen(
            idle: (history, _) => history,
            orElse: () => const [],
          ),
          suggestions: state.maybeWhen(
            idle: (_, suggestions) => suggestions,
            orElse: () => const [],
          ),
        );
      },
      orElse: () {},
    );
  }

  /// 清除错误信息
  void clearError() {
    state.maybeWhen(
      error: (_) {
        state = const SearchState.idle();
      },
      orElse: () {},
    );
  }

  // ==================== 私有方法 ====================

  /// 从服务器加载搜索历史
  Future<List<String>> _loadSearchHistoryFromServer() async {
    try {
      return await _apiClient.getSearchHistory();
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return const [];
    }
  }

  /// 添加关键词到搜索历史
  List<String> _addToHistory(String keyword, List<String> history) {
    if (history.contains(keyword)) {
      return history;
    }
    final updated = [keyword, ...history];
    if (updated.length > 20) {
      return updated.sublist(0, 20);
    }
    return updated;
  }

  /// 更新空闲状态的辅助方法
  void _updateIdleState({
    List<String>? searchHistory,
    List<String>? suggestions,
  }) {
    state.maybeWhen(
      idle: (history, currentSuggestions) {
        state = SearchState.idle(
          searchHistory: searchHistory ?? history,
          suggestions: suggestions ?? currentSuggestions,
        );
      },
      orElse: () {
        state = SearchState.idle(
          searchHistory: searchHistory ?? const [],
          suggestions: suggestions ?? const [],
        );
      },
    );
  }
}

/// Provider 定义
@riverpod
BackendApiClient searchBackendApiClient(SearchBackendApiClientRef ref) {
  return BackendApiClient();
}

@riverpod
SearchViewModel searchViewModel(SearchViewModelRef ref) {
  final apiClient = ref.watch(searchBackendApiClientProvider);
  return SearchViewModel(apiClient);
}
