import 'package:demo/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';

part 'explore_viewmodel.freezed.dart';
part 'explore_viewmodel.g.dart';

/// 发现内容类型
enum ExploreType {
  /// 热门榜单
  hot,

  /// 个性化推荐
  recommended,

  /// 最新发布
  latest,
}

/// 发现状态
@freezed
abstract class ExploreState with _$ExploreState {
  /// 初始状态
  const factory ExploreState.initial() = ExploreStateInitial;

  /// 加载中
  const factory ExploreState.loading() = ExploreStateLoading;

  /// 未绑定B站
  const factory ExploreState.notBound() = ExploreStateNotBound;

  /// 内容已加载
  const factory ExploreState.loaded({
    required List<ExploreItem> items,
    required bool hasMore,
    required int currentPage,
    required ExploreType type,
  }) = ExploreStateLoaded;

  /// 错误
  const factory ExploreState.error({
    required String message,
  }) = ExploreStateError;
}

/// 发现项
class ExploreItem {
  final String bvid;
  final String title;
  final String author;
  final int? duration;
  final int? playCount;
  final String? coverUrl;
  final int? rank; // 排名（仅热门榜单）

  ExploreItem({
    required this.bvid,
    required this.title,
    required this.author,
    this.duration,
    this.playCount,
    this.coverUrl,
    this.rank,
  });

  /// 从JSON创建
  factory ExploreItem.fromJson(Map<String, dynamic> json, {int? rank}) {
    return ExploreItem(
      bvid: json['bvid'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? json['owner']?['name'] as String? ?? '未知',
      duration: _parseDuration(json['duration']),
      playCount: json['play'] as int? ?? json['stat']?['view'] as int?,
      coverUrl: json['cover'] as String?,
      rank: rank,
    );
  }

  /// 解析时长字符串（如 "03:45" -> 225秒）
  static int? _parseDuration(dynamic duration) {
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

/// 发现页面 ViewModel
///
/// 职责：
/// 1. 加载B站音乐区热门内容
/// 2. 加载个性化推荐
/// 3. 加载最新发布
@Riverpod(keepAlive: true)
class ExploreViewModel extends _$ExploreViewModel {
  BackendApiClient? _apiClient;
  /// B站推荐 API 限制：ps >= 15 时返回错误
  /// 使用 10 作为安全值
  static const _pageSize = 10;

  @override
  Future<ExploreState> build() async {
    _apiClient = ref.watch(searchBackendApiClientProvider);

    try {
      AppLogger.debug('ExploreViewModel', '初始化');
      // 返回初始状态，等待页面加载
      return const ExploreState.initial();
    } catch (e) {
      AppLogger.error('ExploreViewModel', '初始化失败: $e');
      return const ExploreState.initial();
    }
  }

  /// 加载热门榜单
  ///
  /// 后端返回歌单列表，每个歌单包含预览音频
  /// 将歌单的预览音频展开为音频列表
  Future<bool> loadHotRanking({int page = 1}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载热门榜单: page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final data = await _apiClient!.getHotRank(
        page: page,
        pageSize: _pageSize,
      );

      // 后端返回的是歌单列表，key 为 'playlists'
      final playlistsData = data['playlists'] as List? ?? [];
      final totalCount = data['total'] as int? ?? 0;

      // 将歌单的预览音频展开为音频列表
      final items = <ExploreItem>[];
      int rank = (page - 1) * _pageSize + 1;

      for (final playlist in playlistsData) {
        final playlistJson = playlist as Map<String, dynamic>;
        final previews = playlistJson['previews'] as List? ?? [];

        // 将每个预览音频转换为 ExploreItem
        for (final preview in previews) {
          final previewJson = preview as Map<String, dynamic>;
          items.add(ExploreItem(
            bvid: previewJson['id']?.toString() ?? '',
            title: previewJson['title']?.toString() ?? '',
            author: playlistJson['uname']?.toString() ?? '',
            duration: previewJson['duration'] as int?,
            playCount: playlistJson['statistic']?['play'] as int?,
            coverUrl: playlistJson['cover'] as String?,
            rank: rank++,
          ));
        }
      }

      final hasMore = (page * _pageSize) < totalCount;

      if (!ref.mounted) return false;
      state = AsyncData(ExploreState.loaded(
        items: items,
        hasMore: hasMore,
        currentPage: page,
        type: ExploreType.hot,
      ));

      AppLogger.info('ExploreViewModel', '热门榜单加载成功: ${items.length}条');
      return true;
    } catch (e) {
      AppLogger.error('ExploreViewModel', '加载热门榜单失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 加载个性化推荐
  Future<bool> loadRecommended({int page = 1}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载推荐: page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final data = await _apiClient!.getRecommend(
        page: page,
        pageSize: _pageSize,
      );

      final videos = data['videos'] as List? ?? [];
      final total = data['total'] as int? ?? 0;

      final items = videos.map((v) {
        final json = v as Map<String, dynamic>;
        return ExploreItem(
          bvid: json['bvid'] as String? ?? '',
          title: json['title'] as String? ?? '',
          author: json['author'] as String? ?? '未知',
          duration: json['duration'] as int?,
          playCount: json['play'] as int?,
          coverUrl: json['cover'] as String?,
        );
      }).toList();

      final hasMore = (page * _pageSize) < total;

      if (!ref.mounted) return false;
      state = AsyncData(ExploreState.loaded(
        items: items,
        hasMore: hasMore,
        currentPage: page,
        type: ExploreType.recommended,
      ));

      AppLogger.info('ExploreViewModel', '推荐加载成功: ${items.length}条');
      return true;
    } catch (e) {
      AppLogger.error('ExploreViewModel', '加载推荐失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 加载最新发布
  Future<bool> loadLatest({int page = 1}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载最新发布: page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      // 使用搜索空关键词获取最新内容（按时间排序）
      final data = await _apiClient!.searchBilibili(
        '', // 空关键词
        page: page,
        pageSize: _pageSize,
      );

      final videos = data['videos'] as List? ?? [];
      final totalCount = data['total'] as int? ?? 0;

      final items = videos.map((v) {
        return ExploreItem.fromJson(v as Map<String, dynamic>);
      }).toList();

      final hasMore = (page * _pageSize) < totalCount;

      if (!ref.mounted) return false;
      state = AsyncData(ExploreState.loaded(
        items: items,
        hasMore: hasMore,
        currentPage: page,
        type: ExploreType.latest,
      ));

      AppLogger.info('ExploreViewModel', '最新发布加载成功: ${items.length}条');
      return true;
    } catch (e) {
      AppLogger.error('ExploreViewModel', '加载最新发布失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 加载下一页
  Future<bool> loadNext() async {
    final currentState = state.valueOrNull;
    if (currentState is! ExploreStateLoaded) {
      AppLogger.warn('ExploreViewModel', '当前非已加载状态，无法加载下一页');
      return false;
    }

    if (!currentState.hasMore) {
      AppLogger.debug('ExploreViewModel', '没有更多内容');
      return false;
    }

    final nextPage = currentState.currentPage + 1;

    // 根据当前类型加载下一页
    switch (currentState.type) {
      case ExploreType.hot:
        return await loadHotRanking(page: nextPage);
      case ExploreType.recommended:
        // 个性化推荐不支持分页
        return false;
      case ExploreType.latest:
        return await loadLatest(page: nextPage);
    }
  }

  /// 刷新当前列表
  Future<bool> refresh() async {
    final currentState = state.valueOrNull;
    ExploreType? currentType;

    if (currentState is ExploreStateLoaded) {
      currentType = currentState.type;
    }

    if (currentType == null) {
      // 默认加载热门
      return await loadHotRanking();
    }

    switch (currentType) {
      case ExploreType.hot:
        return await loadHotRanking();
      case ExploreType.recommended:
        return await loadRecommended();
      case ExploreType.latest:
        return await loadLatest();
    }
  }

  /// 清除错误状态
  void clearError() {
    if (state.valueOrNull is ExploreStateError) {
      state = const AsyncData(ExploreState.initial());
    }
  }
}

/// BackendApiClient Provider (复用 SearchViewModel 的)
@riverpod
BackendApiClient exploreBackendApiClient(Ref ref) {
  return BackendApiClient();
}
