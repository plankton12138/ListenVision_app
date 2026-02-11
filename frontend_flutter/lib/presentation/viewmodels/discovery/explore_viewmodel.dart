import 'package:demo/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';

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

class NeteasePlaylistItem {
  final String id;
  final String name;
  final String cover;
  final int trackCount;
  final int? playCount;

  NeteasePlaylistItem({
    required this.id,
    required this.name,
    required this.cover,
    required this.trackCount,
    this.playCount,
  });

  factory NeteasePlaylistItem.fromJson(Map<String, dynamic> json) {
    return NeteasePlaylistItem(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      trackCount: json['trackCount'] as int? ?? 0,
      playCount: json['playCount'] as int?,
    );
  }
}

@freezed
abstract class NeteaseExploreState with _$NeteaseExploreState {
  const factory NeteaseExploreState.initial() = NeteaseExploreStateInitial;
  const factory NeteaseExploreState.loading() = NeteaseExploreStateLoading;
  const factory NeteaseExploreState.notBound() = NeteaseExploreStateNotBound;
  const factory NeteaseExploreState.loaded({
    required List<NeteasePlaylistItem> playlists,
  }) = NeteaseExploreStateLoaded;
  const factory NeteaseExploreState.error({
    required String message,
  }) = NeteaseExploreStateError;
}

@Riverpod(keepAlive: true)
class ExploreViewModel extends _$ExploreViewModel {
  BackendApiClient? _apiClient;
  static const _pageSize = 10;

  @override
  Future<ExploreState> build() async {
    _apiClient = ref.watch(searchBackendApiClientProvider);

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

      final data = await _apiClient!.getHotRank(
        page: page,
        pageSize: _pageSize,
      );

      final playlistsData = data['playlists'] as List? ?? [];
      final totalCount = data['total'] as int? ?? 0;

      final items = <ExploreItem>[];
      int rank = (page - 1) * _pageSize + 1;

      for (final playlist in playlistsData) {
        final playlistJson = playlist as Map<String, dynamic>;
        final previews = playlistJson['previews'] as List? ?? [];

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

  Future<bool> loadRecommended({int page = 1, bool append = false}) async {
    try {
      AppLogger.info('ExploreViewModel', '加载B站音乐区: page=$page, append=$append');

      List<ExploreItem> existingItems = [];
      if (append) {
        final currentState = state.valueOrNull;
        if (currentState is ExploreStateLoaded && currentState.type == ExploreType.recommended) {
          existingItems = currentState.items;
        }
      }

      if (!ref.mounted) return false;
      if (!append) {
        state = const AsyncLoading();
      }

      final data = await _apiClient!.getRecommend(
        page: page,
        pageSize: _pageSize,
      );

      final videos = data['videos'] as List? ?? [];
      final total = data['total'] as int? ?? 0;

      final newItems = videos.map((v) {
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

      final allItems = [...existingItems, ...newItems];
      final hasMore = (page * _pageSize) < total;

      if (!ref.mounted) return false;
      state = AsyncData(ExploreState.loaded(
        items: allItems,
        hasMore: hasMore,
        currentPage: page,
        type: ExploreType.recommended,
      ));

      AppLogger.info('ExploreViewModel', 'B站音乐区加载成功: 新增${newItems.length}条，共${allItems.length}条');
      return true;
    } catch (e) {
      AppLogger.error('ExploreViewModel', '加载B站音乐区失败: $e');
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

      final data = await _apiClient!.searchBilibili(
        '',
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
    final currentState = state.valueOrNull;
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
    if (state.valueOrNull is ExploreStateError) {
      state = const AsyncData(ExploreState.initial());
    }
  }
}

@Riverpod(keepAlive: true)
class NeteaseExploreViewModel extends _$NeteaseExploreViewModel {
  BackendApiClient? _apiClient;

  @override
  Future<NeteaseExploreState> build() async {
    _apiClient = BackendApiClient();
    return const NeteaseExploreState.initial();
  }

  Future<bool> loadPlaylists(String uid) async {
    try {
      AppLogger.info('NeteaseExploreViewModel', '加载网易云歌单: uid=$uid');

      // 验证 uid 有效性
      if (uid.isEmpty) {
        AppLogger.error('NeteaseExploreViewModel', 'uid 为空，无法加载歌单');
        if (!ref.mounted) return false;
        state = const AsyncData(NeteaseExploreState.error(
          message: '网易云账号信息不完整，请重新登录',
        ));
        return false;
      }

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final data = await _apiClient!.getNeteaseUserPlaylists(uid);
      final playlistsData = data['playlists'] as List? ?? [];

      final playlists = playlistsData.map((p) {
        return NeteasePlaylistItem.fromJson(p as Map<String, dynamic>);
      }).toList();

      if (!ref.mounted) return false;
      state = AsyncData(NeteaseExploreState.loaded(playlists: playlists));

      AppLogger.info('NeteaseExploreViewModel', '网易云歌单加载成功: ${playlists.length}个');
      return true;
    } catch (e) {
      AppLogger.error('NeteaseExploreViewModel', '加载网易云歌单失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  void setNotBound() {
    state = const AsyncData(NeteaseExploreState.notBound());
  }

  void clearError() {
    if (state.valueOrNull is NeteaseExploreStateError) {
      state = const AsyncData(NeteaseExploreState.initial());
    }
  }
}

@riverpod
BackendApiClient exploreBackendApiClient(Ref ref) {
  return BackendApiClient();
}
