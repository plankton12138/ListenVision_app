import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/discovery/explore_viewmodel.dart';
import 'package:listenvision/presentation/widgets/audio/audio_action_menu.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['B站音乐区'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    _loadRecommendIfNeed();
  }

  void _loadRecommendIfNeed() {
    final state = ref.read(exploreViewModelProvider);
    state.whenData((s) {
      if (s is ExploreStateInitial || (s is ExploreStateLoaded && s.type != ExploreType.recommended)) {
        ref.read(exploreViewModelProvider.notifier).loadRecommended();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final exploreState = ref.watch(exploreViewModelProvider);
    final bilibiliBound = ref.watch(bilibiliBoundProvider);
    final isBilibiliBound = bilibiliBound.value ?? false;

    if (!isLoggedIn) {
      return _buildNotLoggedInPrompt();
    }

    _initLoadIfNeed(isBilibiliBound);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: UIConstants.iconMedium,
            onPressed: () => ref.read(exploreViewModelProvider.notifier).refresh(),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
            tooltip: '首页',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/search'),
            tooltip: '搜索',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      drawer: const MyDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBilibiliTab(exploreState, isBilibiliBound),
        ],
      ),
    );
  }

  void _initLoadIfNeed(bool isBilibiliBound) {
    final exploreState = ref.read(exploreViewModelProvider);
    exploreState.whenData((state) {
      if (state is ExploreStateInitial && isBilibiliBound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabController.index == 0) {
            ref.read(exploreViewModelProvider.notifier).loadRecommended();
          }
        });
      }
    });
  }

  Widget _buildBilibiliTab(AsyncValue<ExploreState> exploreState, bool isBound) {
    if (!isBound) {
      return _buildNotBoundPrompt(
        platform: 'B站',
        message: '绑定后可查看B站音乐区热门内容',
      );
    }

    return exploreState.when(
      loading: () => _buildLoadingView(),
      error: (e, _) => _buildErrorView(e.toString(), () => ref.read(exploreViewModelProvider.notifier).refresh()),
      data: (state) {
        return state.when(
          initial: () => _buildLoadingView(),
          loading: () => _buildLoadingView(),
          notBound: () => _buildNotBoundPrompt(
            platform: 'B站',
            message: '绑定后可查看B站音乐区热门内容',
          ),
          loaded: (items, hasMore, currentPage, type) => type == ExploreType.recommended
              ? _buildRecommendList(items, hasMore)
              : _buildLoadingView(),
          error: (message) => _buildErrorView(message, () => ref.read(exploreViewModelProvider.notifier).refresh()),
        );
      },
    );
  }

  Widget _buildRecommendList(List<ExploreItem> items, bool hasMore) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无推荐内容', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final itemCount = items.length + (hasMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          if (hasMore) {
            ref.read(exploreViewModelProvider.notifier).loadNext();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(exploreViewModelProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == items.length && hasMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = items[index];
            return _buildRecommendItem(item, index);
          },
        ),
      ),
    );
  }

  Widget _buildRecommendItem(ExploreItem item, int index) {
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 80,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                    ? Image.network(
                        item.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
              ),
              if (item.duration != null)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: Colors.black54,
                    child: Text(
                      _formatDuration(item.duration!),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                item.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            if (item.playCount != null)
              Text(
                ' ${_formatPlayCount(item.playCount!)} ',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        trailing: _buildItemTrailing(item),
        onTap: () => _playAudio(item),
      ),
    );
  }

  Widget _buildItemTrailing(ExploreItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      iconSize: 20,
      onSelected: (action) => _onItemAction(action, item),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add_to_playlist',
          child: Text('添加到歌单'),
        ),
        const PopupMenuItem(
          value: 'favorite',
          child: Text('收藏'),
        ),
        const PopupMenuItem(
          value: 'download',
          child: Text('下载'),
        ),

      ],
    );
  }

  void _onItemAction(String action, ExploreItem item) {
    switch (action) {
      case 'add_to_playlist':
        AudioActionMenu.show(
          context,
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
          showFavorite: false,
          showDownload: true,
        );
        break;
      case 'favorite':
        AudioActionMenu.show(
          context,
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
          showAddToPlaylist: false,
          showDownload: false,
        );
        break;
      case 'download':
        AudioActionMenu.show(
          context,
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
          showFavorite: false,
          showAddToPlaylist: false,
        );
        break;

    }
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
      ),
      drawer: const MyDrawer(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNotLoggedInPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
      ),
      drawer: const MyDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('请先登录以查看推荐内容'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotBoundPrompt({
    required String platform,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '需要绑定$platform账号',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.link),
              label: const Text('前往绑定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _playAudio(ExploreItem item) async {
    AppLogger.logUserAction(
      'ExplorePage',
      '播放音频',
      parameters: {'bvid': item.bvid, 'title': item.title},
    );

    try {
      final audio = Audio(
        id: item.bvid,
        title: item.title,
        artist: item.author,
        duration: item.duration,
        coverUrl: item.coverUrl,
      );

      final playable = OnlinePlayable.withProxyUrl(audio);
      await ref.read(playbackViewModelProvider.notifier).play(playable);

      if (mounted) {
        SnackbarHelper.showPlaying(context, item.title, artist: item.author);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
