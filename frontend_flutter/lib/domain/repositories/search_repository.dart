import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/audio.dart';

/// 搜索仓储接口
///
/// Clean Architecture 中的 Repository 接口
/// 管理音频搜索功能
abstract class SearchRepository {
  // ==================== 搜索功能 ====================

  /// 搜索音频
  ///
  /// [keyword] 搜索关键词
  /// [limit] 返回结果数量限制（默认20，最大100）
  /// 返回搜索结果列表
  Future<Either<Failure, List<Audio>>> search({
    required String keyword,
    int limit = 20,
  });

  /// 获取搜索建议
  ///
  /// [keyword] 搜索关键词
  /// [limit] 返回数量限制
  /// 返回建议关键词列表
  Future<Either<Failure, List<String>>> getSuggestions({
    required String keyword,
    int limit = 10,
  });

  /// 获取热门搜索关键词
  ///
  /// [limit] 返回数量限制
  /// 返回热门关键词列表
  Future<Either<Failure, List<String>>> getTrendingKeywords({
    int limit = 10,
  });

  // ==================== 搜索历史 ====================

  /// 获取搜索历史
  ///
  /// [limit] 返回数量限制
  /// 返回搜索历史关键词列表
  Future<Either<Failure, List<String>>> getSearchHistory({
    int limit = 10,
  });

  /// 保存搜索关键词
  ///
  /// [keyword] 搜索关键词
  /// 返回保存是否成功
  Future<Either<Failure, bool>> saveSearchKeyword({
    required String keyword,
  });

  /// 删除搜索关键词
  ///
  /// [keyword] 搜索关键词
  /// 返回删除是否成功
  Future<Either<Failure, bool>> removeSearchKeyword({
    required String keyword,
  });

  /// 清空搜索历史
  ///
  /// 返回清空是否成功
  Future<Either<Failure, bool>> clearSearchHistory();

  // ==================== 高级搜索 ====================

  /// 按艺术家搜索
  ///
  /// [artist] 艺术家名称
  /// [limit] 返回结果数量限制
  /// 返回搜索结果
  Future<Either<Failure, List<Audio>>> searchByArtist({
    required String artist,
    int limit = 20,
  });

  /// 按时长范围搜索
  ///
  /// [minDuration] 最小时长（秒）
  /// [maxDuration] 最大时长（秒）
  /// [limit] 返回结果数量限制
  /// 返回搜索结果
  Future<Either<Failure, List<Audio>>> searchByDuration({
    int? minDuration,
    int? maxDuration,
    int limit = 20,
  });

  /// 组合搜索
  ///
  /// [keyword] 关键词（可选）
  /// [artist] 艺术家（可选）
  /// [minDuration] 最小时长（可选）
  /// [maxDuration] 最大时长（可选）
  /// [limit] 返回结果数量限制
  /// 返回搜索结果
  Future<Either<Failure, List<Audio>>> advancedSearch({
    String? keyword,
    String? artist,
    int? minDuration,
    int? maxDuration,
    int limit = 20,
  });

  // ==================== 缓存管理 ====================

  /// 获取缓存的搜索结果
  ///
  /// [keyword] 搜索关键词
  /// 返回缓存的搜索结果
  Future<Either<Failure, List<Audio>>> getCachedResult({
    required String keyword,
  });

  /// 缓存搜索结果
  ///
  /// [keyword] 搜索关键词
  /// [results] 搜索结果
  /// 返回缓存是否成功
  Future<Either<Failure, bool>> cacheResult({
    required String keyword,
    required List<Audio> results,
  });

  /// 清除过期缓存
  ///
  /// 返回清除的缓存数量
  Future<Either<Failure, int>> clearExpiredCache();
}
