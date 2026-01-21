/// Domain Types Export - Clean Architecture 类型导出
///
/// 此文件包含领域实体的类型别名和兼容类型定义
/// 遵循 Clean Architecture 原则

import 'package:demo/domain/entities/recommendation.dart';
import 'package:demo/domain/entities/play_history.dart';

// ========== 类型别名 ==========

/// 推荐项类型别名（与 Recommendation 相同）
typedef RecommendationItem = Recommendation;

/// 播放历史项类型别名（与 PlayHistory 相同）
typedef PlayHistoryItem = PlayHistory;

// ========== 兼容类型定义 ==========

/// B站歌单响应 - 用于热门歌单列表
class BiliPlaylistsResponse {
  final List<BiliPlaylist> playlists;
  final int page;
  final int pageSize;
  final int total;

  const BiliPlaylistsResponse({
    required this.playlists,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  /// 是否有更多数据
  bool get hasMore => (page * pageSize) < total;

  /// 总页数
  int get totalPages => total > 0 ? (total / pageSize).ceil() : 1;

  /// 是否为空
  bool get isEmpty => playlists.isEmpty;

  /// 列表长度
  int get length => playlists.length;
}
