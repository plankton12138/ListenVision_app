import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/play_history.dart';

/// 播放历史仓储接口
///
/// Clean Architecture 中的 Repository 接口
/// 管理用户播放历史记录
abstract class PlayHistoryRepository {
  // ==================== 历史记录管理 ====================

  /// 获取播放历史
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量限制
  /// [offset] 偏移量
  /// 返回播放历史列表
  Future<Either<Failure, List<PlayHistory>>> getHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  /// 记录播放
  ///
  /// [userId] 用户 ID
  /// [audioId] 音频 ID（BV号）
  /// [title] 音频标题
  /// [artist] 艺术家
  /// [duration] 时长（秒）
  /// [progress] 播放进度（秒）
  /// [coverUrl] 封面 URL
  /// 返回记录是否成功
  Future<Either<Failure, bool>> recordPlay({
    required String userId,
    required String audioId,
    required String title,
    String? artist,
    int? duration,
    int progress = 0,
    String? coverUrl,
  });

  /// 更新播放进度
  ///
  /// [historyId] 历史记录 ID
  /// [progress] 新的播放进度（秒）
  /// 返回更新是否成功
  Future<Either<Failure, bool>> updateProgress({
    required String historyId,
    required int progress,
  });

  /// 删除单条历史记录
  ///
  /// [historyId] 历史记录 ID
  /// 返回删除是否成功
  Future<Either<Failure, bool>> deleteHistory({
    required String historyId,
  });

  /// 清空播放历史
  ///
  /// [userId] 用户 ID
  /// 返回清空是否成功
  Future<Either<Failure, bool>> clearHistory({
    required String userId,
  });

  // ==================== 统计信息 ====================

  /// 获取播放统计
  ///
  /// [userId] 用户 ID
  /// 返回播放统计信息
  Future<Either<Failure, PlayHistoryStats>> getStats({
    required String userId,
  });

  /// 获取最近播放
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量
  /// 返回最近播放的记录
  Future<Either<Failure, List<PlayHistory>>> getRecentPlays({
    required String userId,
    int limit = 10,
  });

  /// 获取最常播放
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量
  /// 返回最常播放的记录
  Future<Either<Failure, List<PlayHistory>>> getMostPlayed({
    required String userId,
    int limit = 10,
  });

  // ==================== 搜索与过滤 ====================

  /// 搜索播放历史
  ///
  /// [userId] 用户 ID
  /// [keyword] 搜索关键词
  /// [limit] 返回数量限制
  /// 返回匹配的历史记录
  Future<Either<Failure, List<PlayHistory>>> searchHistory({
    required String userId,
    required String keyword,
    int limit = 20,
  });

  /// 按日期范围获取历史
  ///
  /// [userId] 用户 ID
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  /// 返回日期范围内的历史记录
  Future<Either<Failure, List<PlayHistory>>> getHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // ==================== 缓存管理 ====================

  /// 刷新历史缓存
  ///
  /// [userId] 用户 ID
  /// 重新从服务器获取历史数据
  Future<Either<Failure, List<PlayHistory>>> refreshHistory({
    required String userId,
  });

  /// 清除历史缓存
  ///
  /// 清除本地缓存的历史数据
  Future<Either<Failure, void>> clearCache();
}
