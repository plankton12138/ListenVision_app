import '../../core/utils/app_logger.dart';
import '../api/backend_api_client.dart';
import '../api/bilibili_api_client.dart';

/// 搜索仓库
///
/// 负责搜索相关的数据操作
class SearchRepository {
  final BackendApiClient _backendApi;
  final BilibiliApiClient _bilibiliApi;

  SearchRepository({
    BackendApiClient? backendApi,
    BilibiliApiClient? bilibiliApi,
  })  : _backendApi = backendApi ?? BackendApiClient(),
        _bilibiliApi = bilibiliApi ?? BilibiliApiClient();

  // ==================== 本地搜索 ====================

  /// 本地搜索
  Future<Map<String, dynamic>> searchLocal({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('SearchRepository', '本地搜索: $keyword');
      return await _backendApi.searchLocal(
        keyword: keyword,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.error('SearchRepository', '本地搜索失败: $e');
      rethrow;
    }
  }

  // ==================== B站搜索 ====================

  /// 搜索B站视频
  Future<Map<String, dynamic>> searchBilibili({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('SearchRepository', '搜索B站: $keyword');
      return await _bilibiliApi.searchBilibili(
        keyword,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.error('SearchRepository', 'B站搜索失败: $e');
      rethrow;
    }
  }

  // ==================== 搜索建议 ====================

  /// 获取搜索建议
  Future<List<String>> getSearchSuggestions(String keyword) async {
    try {
      return await _backendApi.getSearchSuggestions(keyword);
    } catch (e) {
      AppLogger.error('SearchRepository', '获取搜索建议失败: $e');
      return [];
    }
  }

  // ==================== 搜索历史 ====================

  /// 获取搜索历史
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    try {
      return await _backendApi.getSearchHistory(limit: limit);
    } catch (e) {
      AppLogger.error('SearchRepository', '获取搜索历史失败: $e');
      return [];
    }
  }

  /// 清空搜索历史
  Future<bool> clearSearchHistory() async {
    try {
      await _backendApi.clearSearchHistory();
      AppLogger.info('SearchRepository', '清空搜索历史成功');
      return true;
    } catch (e) {
      AppLogger.error('SearchRepository', '清空搜索历史失败: $e');
      rethrow;
    }
  }

  /// 获取B站最近搜索
  Future<List<String>> getBilibiliRecentSearches({int limit = 10}) async {
    try {
      return await _bilibiliApi.getRecentSearches(limit: limit);
    } catch (e) {
      AppLogger.error('SearchRepository', '获取B站最近搜索失败: $e');
      return [];
    }
  }
}
