import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../services/bilibili_api_service.dart';

part 'explore_viewmodel.freezed.dart';
part 'explore_viewmodel.g.dart';

enum ExploreType {
  hot,
  recommended,
  latest,
}

@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState.initial() = ExploreStateInitial;
  const factory ExploreState.loading() = ExploreStateLoading;
  const factory ExploreState.notBound() = ExploreStateNotBound;
  const factory ExploreState.loaded({
    required List<ExploreItem> items,
    required bool hasMore,
    required int currentPage,
    required ExploreType type,
  }) = ExploreStateLoaded;
  const factory ExploreState.error({
    required String message,
  }) = ExploreStateError;
}

class ExploreItem {
  final String bvid;
  final String title;
  final String author;
  final int? duration;
  final int? playCount;
  final String? coverUrl;
  final int? rank;

  ExploreItem({
    required this.bvid,
    required this.title,
    required this.author,
    this.duration,
    this.playCount,
    this.coverUrl,
    this.rank,
  });

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

@Riverpod(keepAlive: true)
class ExploreViewModel extends _$ExploreViewModel {
  BilibiliApiService? _api;
  static const _pageSize = 20;

  @override
  Future<ExploreState> build() async {
    _api = ref.watch(bilibiliApiServiceProvider);

    try {
      AppLogger.debug('ExploreViewModel', '初始化');
      return const ExploreState.initial();
    } catch (e) {
      AppLogger.error('ExploreViewModel', '初始化失败: $e');
      return const ExploreState.initial();
    }
  }

  Future<bool> loadHotRanking({int page = 1}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载热门榜单: page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final recommendations = await _api!.getRank(type: 'music');

      // Paginate locally since Bilibili API returns all at once
      final start = (page - 1) * _pageSize;
      final end = start + _pageSize;
      final pageItems = recommendations.skip(start).take(_pageSize).toList();
      final hasMore = end < recommendations.length;

      final items = <ExploreItem>[];
      int rank = start + 1;
      for (final rec in pageItems) {
        items.add(ExploreItem(
          bvid: rec.id,
          title: rec.title,
          author: rec.artist ?? '未知',
          duration: int.tryParse(rec.duration ?? ''),
          playCount: rec.playCount,
          coverUrl: rec.coverUrl,
          rank: rank++,
        ));
      }

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

  Future<bool> loadRecommended({int page = 1, bool append = false}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载推荐: page=$page, append=$append');

      List<ExploreItem> existingItems = [];
      if (append) {
        final currentState = state.value;
        if (currentState is ExploreStateLoaded && currentState.type == ExploreType.recommended) {
          existingItems = currentState.items;
        }
      }

      if (!ref.mounted) return false;
      if (!append) {
        state = const AsyncLoading();
      }

      final recommendations = await _api!.getRecommendations(page: page);

      final newItems = recommendations.map((rec) {
        return ExploreItem(
          bvid: rec.id,
          title: rec.title,
          author: rec.artist ?? '未知',
          duration: int.tryParse(rec.duration ?? ''),
          playCount: rec.playCount,
          coverUrl: rec.coverUrl,
        );
      }).toList();

      final allItems = [...existingItems, ...newItems];
      final hasMore = newItems.length >= _pageSize;

      if (!ref.mounted) return false;
      state = AsyncData(ExploreState.loaded(
        items: allItems,
        hasMore: hasMore,
        currentPage: page,
        type: ExploreType.recommended,
      ));

      AppLogger.info('ExploreViewModel', '推荐加载成功: 新增${newItems.length}条，共${allItems.length}条');
      return true;
    } catch (e) {
      AppLogger.error('ExploreViewModel', '加载推荐失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> loadLatest({int page = 1}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载最新发布: page=$page');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final audios = await _api!.search(keyword: '', page: page, pageSize: _pageSize);

      final items = audios.map((audio) {
        return ExploreItem(
          bvid: audio.id,
          title: audio.title,
          author: audio.artist ?? '未知',
          duration: audio.duration,
          playCount: audio.playCount,
          coverUrl: audio.coverUrl,
        );
      }).toList();

      final hasMore = items.length >= _pageSize;

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

  Future<bool> loadNext() async {
    final currentState = state.value;
    if (currentState is! ExploreStateLoaded) {
      AppLogger.warn('ExploreViewModel', '当前非已加载状态，无法加载下一页');
      return false;
    }

    if (!currentState.hasMore) {
      AppLogger.debug('ExploreViewModel', '没有更多内容');
      return false;
    }

    final nextPage = currentState.currentPage + 1;

    switch (currentState.type) {
      case ExploreType.hot:
        return await loadHotRanking(page: nextPage);
      case ExploreType.recommended:
        return await loadRecommended(page: nextPage, append: true);
      case ExploreType.latest:
        return await loadLatest(page: nextPage);
    }
  }

  Future<bool> refresh() async {
    final currentState = state.value;
    ExploreType? currentType;

    if (currentState is ExploreStateLoaded) {
      currentType = currentState.type;
    }

    if (currentType == null) {
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

  void clearError() {
    if (state.value is ExploreStateError) {
      state = const AsyncData(ExploreState.initial());
    }
  }
}
