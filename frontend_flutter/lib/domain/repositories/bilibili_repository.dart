import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/audio.dart';
import '../entities/recommendation.dart';

/// B站仓储接口
///
/// Clean Architecture 中的 Repository 接口
/// 管理 B站相关功能（账号绑定、推荐内容等）
abstract class BilibiliRepository {
  // ==================== 账号绑定 ====================

  /// 开始 QR 码登录
  ///
  /// 返回 QR 码登录 URL
  Future<Either<Failure, String>> startQRLogin();

  /// 检查 QR 码登录状态
  ///
  /// 返回登录状态：
  /// - 'pending': 等待扫描
  /// - 'scanned': 已扫描，等待确认
  /// - 'success': 登录成功
  /// - 'expired': 二维码已过期
  Future<Either<Failure, String>> checkQRLoginStatus();

  /// 取消 QR 码登录
  Future<Either<Failure, void>> cancelQRLogin();

  /// 解绑 B站账号
  ///
  /// [userId] 用户 ID
  /// 返回解绑是否成功
  Future<Either<Failure, bool>> unbindAccount({
    required String userId,
  });

  /// 获取绑定状态
  ///
  /// [userId] 用户 ID
  /// 返回绑定状态
  Future<Either<Failure, bool>> getBindingStatus({
    required String userId,
  });

  /// 获取绑定的用户信息
  ///
  /// [userId] 用户 ID
  /// 返回 B站用户信息
  Future<Either<Failure, BiliUserInfo>> getBoundUserInfo({
    required String userId,
  });

  // ==================== 音频获取 ====================

  /// 获取音频信息
  ///
  /// [bvid] 视频 BV 号
  /// [forceRefresh] 是否强制刷新（忽略缓存）
  /// 返回音频信息
  Future<Either<Failure, Audio>> getAudioInfo({
    required String bvid,
    bool forceRefresh = false,
  });

  /// 获取音频流 URL
  ///
  /// [bvid] 视频 BV 号
  /// 返回音频流 URL
  Future<Either<Failure, String>> getAudioStream({
    required String bvid,
  });

  /// 批量获取音频信息
  ///
  /// [bvids] 视频 BV 号列表
  /// 返回音频信息列表
  Future<Either<Failure, List<Audio>>> getBatchAudioInfo({
    required List<String> bvids,
  });

  /// 刷新音频元数据缓存
  ///
  /// [bvid] 视频 BV 号
  /// 返回刷新后的音频信息
  Future<Either<Failure, Audio>> refreshAudioMetadata({
    required String bvid,
  });

  // ==================== 推荐内容 ====================

  /// 获取热门歌单
  ///
  /// [page] 页码
  /// [pageSize] 每页数量
  /// 返回热门歌单列表
  Future<Either<Failure, List<BiliPlaylist>>> getHotPlaylists({
    int page = 1,
    int pageSize = 20,
  });

  /// 获取热歌榜单
  ///
  /// 返回榜单歌曲列表
  Future<Either<Failure, List<Recommendation>>> getRankList();

  /// 获取个性化推荐
  ///
  /// [userId] 用户 ID
  /// 返回个性化推荐内容
  Future<Either<Failure, PersonalizedResponse>> getPersonalizedRecommendations({
    String? userId,
  });

  /// 获取音乐区推荐
  ///
  /// 返回音乐区各分类推荐
  Future<Either<Failure, Map<String, List<Recommendation>>>> getMusicZoneRecommendations();

  // ==================== UP主相关 ====================

  /// 获取 UP主视频列表
  ///
  /// [mid] UP主 ID
  /// [page] 页码
  /// [pageSize] 每页数量
  /// 返回视频列表
  Future<Either<Failure, List<Audio>>> getUploaderVideos({
    required String mid,
    int page = 1,
    int pageSize = 20,
  });

  /// 获取 UP主信息
  ///
  /// [mid] UP主 ID
  /// 返回 UP主信息
  Future<Either<Failure, BiliUserInfo>> getUploaderInfo({
    required String mid,
  });

  // ==================== 搜索功能 ====================

  /// 搜索 B站视频
  ///
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// 返回搜索结果
  Future<Either<Failure, List<Recommendation>>> searchBilibili({
    required String keyword,
    int page = 1,
  });

  /// 获取搜索历史
  ///
  /// 返回最近搜索关键词列表
  Future<Either<Failure, List<String>>> getSearchHistory();

  /// 保存搜索关键词
  ///
  /// [keyword] 搜索关键词
  /// 返回保存是否成功
  Future<Either<Failure, bool>> saveSearchKeyword({
    required String keyword,
  });

  // ==================== 资源代理 ====================

  /// 获取代理图片 URL
  ///
  /// [originalUrl] 原始图片 URL
  /// 返回代理 URL
  String getProxyImageUrl(String originalUrl);

  /// 获取代理音频 URL
  ///
  /// 通过后端代理访问B站音频，解决防盗链问题
  ///
  /// [originalUrl] 原始音频 URL
  /// 返回代理 URL
  String getProxyAudioUrl(String originalUrl);

  // ==================== 缓存管理 ====================

  /// 获取缓存统计
  ///
  /// 返回缓存统计信息
  Future<Either<Failure, BiliCacheStats>> getCacheStats();

  /// 清理过期缓存
  ///
  /// 返回清理的缓存数量
  Future<Either<Failure, int>> cleanExpiredCache();

  /// 清空所有缓存
  ///
  /// 返回清空是否成功
  Future<Either<Failure, bool>> clearAllCache();
}

/// B站用户信息
class BiliUserInfo {
  final String uid;
  final String uname;
  final String avatar;
  final String? sign;

  const BiliUserInfo({
    required this.uid,
    required this.uname,
    required this.avatar,
    this.sign,
  });

  factory BiliUserInfo.fromJson(Map<String, dynamic> json) {
    return BiliUserInfo(
      uid: json['uid']?.toString() ?? json['mid']?.toString() ?? '',
      uname: json['uname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? json['face'] as String? ?? '',
      sign: json['sign'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'uname': uname,
      'avatar': avatar,
      if (sign != null) 'sign': sign,
    };
  }
}

/// B站缓存统计
class BiliCacheStats {
  final int totalCount;
  final int totalSize;
  final int expiredCount;
  final DateTime? oldestCache;
  final DateTime? newestCache;

  const BiliCacheStats({
    required this.totalCount,
    required this.totalSize,
    this.expiredCount = 0,
    this.oldestCache,
    this.newestCache,
  });

  factory BiliCacheStats.fromJson(Map<String, dynamic> json) {
    return BiliCacheStats(
      totalCount: json['total_count'] as int? ?? json['totalCount'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? json['totalSize'] as int? ?? 0,
      expiredCount: json['expired_count'] as int? ?? json['expiredCount'] as int? ?? 0,
      oldestCache: json['oldest_cache'] != null
          ? DateTime.tryParse(json['oldest_cache'] as String)
          : null,
      newestCache: json['newest_cache'] != null
          ? DateTime.tryParse(json['newest_cache'] as String)
          : null,
    );
  }

  /// 格式化缓存大小
  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
