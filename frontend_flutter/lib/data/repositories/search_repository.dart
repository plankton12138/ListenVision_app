import '../../core/utils/app_logger.dart';
import '../../models/audio.dart';
import '../../services/bilibili_api_service.dart';
import '../database/app_database.dart';

/// 搜索仓库
///
/// 负责搜索相关的数据操作
class SearchRepository {
  final BilibiliApiService _bilibiliApi;
  final AppDatabase _db;

  SearchRepository({
    BilibiliApiService? bilibiliApi,
    AppDatabase? db,
  })  : _bilibiliApi = bilibiliApi ?? BilibiliApiService(),
        _db = db ?? AppDatabase.instance;

  // ==================== 本地搜索 ====================

  /// 本地搜索
  Future<List<Map<String, dynamic>>> searchLocal({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('SearchRepository', '本地搜索: $keyword');
      final results = await _db.searchTracks(keyword);
      final offset = (page - 1) * pageSize;
      return results.skip(offset).take(pageSize).toList();
    } catch (e) {
      AppLogger.error('SearchRepository', '本地搜索失败: $e');
      rethrow;
    }
  }

  // ==================== B站搜索 ====================

  /// 搜索B站视频
  Future<List<Audio>> searchBilibili({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('SearchRepository', '搜索B站: $keyword');
      return await _bilibiliApi.search(
        keyword: keyword,
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
      return await _bilibiliApi.getSearchSuggestions(keyword);
    } catch (e) {
      AppLogger.error('SearchRepository', '获取搜索建议失败: $e');
      return [];
    }
  }
}