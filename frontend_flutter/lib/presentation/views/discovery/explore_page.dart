import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/discovery/explore_viewmodel.dart';
import 'package:demo/presentation/widgets/audio/audio_action_menu.dart';
import 'package:demo/presentation/widgets/common/snackbar_helper.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
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

  static const List<String> _tabs = ['B站音乐区', '网易云歌单'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      _loadRecommendIfNeed();
    } else if (currentIndex == 1) {
      _loadNeteaseIfNeed();
    }
  }

  void _loadRecommendIfNeed() {
    final state = ref.read(exploreViewModelProvider);
    state.whenData((s) {
      if (s is ExploreStateInitial || (s is ExploreStateLoaded && s.type != ExploreType.recommended)) {
        ref.read(exploreViewModelProvider.notifier).loadRecommended();
      }
    });
  }

  void _loadNeteaseIfNeed() {
    final neteaseAuthState = ref.read(neteaseAuthViewModelProvider);
    neteaseAuthState.whenData((authState) {
      if (authState is NeteaseAuthStateBound) {
        final neteaseState = ref.read(neteaseExploreViewModelProvider);
        neteaseState.whenData((s) {
          if (s is NeteaseExploreStateInitial) {
            ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(authState.account.id);
          }
        });
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
    final authState = ref.watch(platformAuthViewModelProvider);
    final neteaseAuthState = ref.watch(neteaseAuthViewModelProvider);
    final exploreState = ref.watch(exploreViewModelProvider);

    if (authState.isLoading || neteaseAuthState.isLoading) {
      return _buildLoadingView();
    }

    final authData = authState.value;
    final isBilibiliBound = authData != null && authData is PlatformAuthStateBound;

    final neteaseData = neteaseAuthState.value;
    final isNeteaseBound = neteaseData != null && neteaseData is NeteaseAuthStateBound;

    if (!isLoggedIn) {
      return _buildNotLoggedInPrompt();
    }

    _initLoadIfNeed(isBilibiliBound, isNeteaseBound, neteaseData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
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
          _buildNeteaseTab(isNeteaseBound, neteaseData),
        ],
      ),
    );
  }

  void _initLoadIfNeed(bool isBilibiliBound, bool isNeteaseBound, NeteaseAuthState? neteaseData) {
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

    if (isNeteaseBound && neteaseData is NeteaseAuthStateBound) {
      final neteaseState = ref.read(neteaseExploreViewModelProvider);
      neteaseState.whenData((state) {
        if (state is NeteaseExploreStateInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_tabController.index == 1) {
              ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(neteaseData.account.id);
            }
          });
        }
      });
    }
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
        const PopupMenuItem(
          value: 'share',
          child: Text('分享'),
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
      case 'share':
        final url = 'https://www.bilibili.com/video/${item.bvid}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享链接:\n$url')),
        );
        break;
    }
  }

  Widget _buildNeteaseTab(bool isBound, NeteaseAuthState? neteaseData) {
    if (!isBound) {
      return _buildNotBoundPrompt(
        platform: '网易云',
        message: '绑定后可查看你的网易云歌单',
      );
    }

    if (neteaseData is! NeteaseAuthStateBound) {
      return _buildNotBoundPrompt(
        platform: '网易云',
        message: '绑定后可查看你的网易云歌单',
      );
    }

    final neteaseExploreState = ref.watch(neteaseExploreViewModelProvider);

    return neteaseExploreState.when(
      loading: () => _buildLoadingView(),
      error: (e, _) => _buildErrorView(e.toString(), () {
        ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(neteaseData.account.id);
      }),
      data: (state) {
        return state.when(
          initial: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(neteaseData.account.id);
            });
            return _buildLoadingView();
          },
          loading: () => _buildLoadingView(),
          notBound: () => _buildNotBoundPrompt(
            platform: '网易云',
            message: '绑定后可查看你的网易云歌单',
          ),
          loaded: (playlists) => _buildNeteasePlaylistGrid(playlists),
          error: (message) => _buildErrorView(message, () {
            ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(neteaseData.account.id);
          }),
        );
      },
    );
  }

  Widget _buildNeteasePlaylistGrid(List<NeteasePlaylistItem> playlists) {
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无歌单', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final neteaseData = ref.read(neteaseAuthViewModelProvider).value;
        if (neteaseData is NeteaseAuthStateBound) {
          await ref.read(neteaseExploreViewModelProvider.notifier).loadPlaylists(neteaseData.account.id);
        }
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _buildNeteasePlaylistCard(playlist);
        },
      ),
    );
  }

  Widget _buildNeteasePlaylistCard(NeteasePlaylistItem playlist) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/explore/playlist/${playlist.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (playlist.cover.isNotEmpty)
                    Image.network(
                      playlist.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.library_music, size: 48),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.library_music, size: 48),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${playlist.trackCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (playlist.playCount != null)
                    Text(
                      _formatPlayCount(playlist.playCount!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

      await ref.read(playerViewModelProvider.notifier).playOnlineAudio(audio: audio);

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
