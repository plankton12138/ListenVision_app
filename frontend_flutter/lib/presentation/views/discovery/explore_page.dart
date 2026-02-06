import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/discovery/explore_viewmodel.dart';
import 'package:demo/presentation/widgets/audio/audio_action_menu.dart';
import 'package:demo/presentation/widgets/common/download_status_indicator.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发现页面
///
/// 显示B站音乐区热门、推荐、最新音频
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['热门', '推荐', '最新'];
  static const List<ExploreType> _types = [
    ExploreType.hot,
    ExploreType.recommended,
    ExploreType.latest,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChange);

    // 初始加载热门榜单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBindingAndLoad();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 检查绑定状态并加载内容
  void _checkBindingAndLoad() {
    final bound = ref.read(isBilibiliBoundProvider);
    if (bound) {
      ref.read(exploreViewModelProvider.notifier).loadHotRanking();
    }
  }

  /// Tab 切换监听
  void _onTabChange() {
    if (_tabController.indexIsChanging) return;

    final index = _tabController.index;
    final bound = ref.read(isBilibiliBoundProvider);

    if (!bound) return;

    switch (_types[index]) {
      case ExploreType.hot:
        ref.read(exploreViewModelProvider.notifier).loadHotRanking();
        break;
      case ExploreType.recommended:
        ref.read(exploreViewModelProvider.notifier).loadRecommended();
        break;
      case ExploreType.latest:
        ref.read(exploreViewModelProvider.notifier).loadLatest();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final bound = ref.watch(isBilibiliBoundProvider);

    if (!isLoggedIn) {
      return _buildNotLoggedInPrompt();
    }

    if (!bound) {
      return _buildNotBoundPrompt();
    }

    final exploreState = ref.watch(exploreViewModelProvider);

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
      body: exploreState.when(
        data: (state) {
          return state.when(
            initial: () => _buildInitialView(),
            loading: () => _buildLoadingView(),
            notBound: () => _buildNotBoundPrompt(),
            loaded: (items, hasMore, _, type) =>
                _buildAudioList(items, hasMore, type),
            error: (message) => _buildErrorView(message),
          );
        },
        loading: () => _buildLoadingView(),
        error: (e, _) => _buildErrorView(e.toString()),
      ),
    );
  }

  /// 构建初始视图
  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '探索B站音乐区',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 构建未登录提示
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

  /// 构建未绑定提示
  Widget _buildNotBoundPrompt() {
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
          ),
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '需要绑定B站账号',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '绑定后可查看B站音乐区推荐内容',
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
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(String message) {
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
            onPressed: () => ref.read(exploreViewModelProvider.notifier).refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建音频列表
  Widget _buildAudioList(List<ExploreItem> items, bool hasMore, ExploreType type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无内容', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          // 加载更多按钮
          if (index == items.length) {
            return ListTile(
              title: Center(
                child: Text(
                  '加载更多',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              onTap: () => ref.read(exploreViewModelProvider.notifier).loadNext(),
            );
          }

          final item = items[index];
          return _buildAudioItemTile(item, type);
        },
      ),
    );
  }

  /// 构建音频项 Tile
  Widget _buildAudioItemTile(ExploreItem item, ExploreType type) {
    // 热门榜单显示排名
    Widget? leading;
    if (type == ExploreType.hot && item.rank != null) {
      leading = _buildRankBadge(item.rank!);
    } else {
      leading = const Icon(Icons.music_note, color: Colors.grey);
    }

    return ListTile(
      leading: leading,
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _buildSubtitle(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 下载状态指示器
          DownloadStatusIndicator(bvid: item.bvid, size: 16),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showActionMenu(item),
      ),
      onTap: () => _playAudio(item),
    );
  }

  /// 构建副标题
  String _buildSubtitle(ExploreItem item) {
    final parts = <String>[item.author];

    if (item.duration != null) {
      parts.add(_formatDuration(item.duration!));
    }

    if (item.playCount != null) {
      parts.add(_formatPlayCount(item.playCount!));
    }

    return parts.join(' • ');
  }

  /// 构建排名徽章
  Widget _buildRankBadge(int rank) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.grey[400]!;
    } else if (rank == 3) {
      color = Colors.brown[300]!;
    } else {
      color = Colors.grey[300]!;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank <= 3 ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 播放音频
  void _playAudio(ExploreItem item) {
    AppLogger.logUserAction(
      'ExplorePage',
      '播放音频',
      parameters: {'bvid': item.bvid, 'title': item.title},
    );

    // 创建 Audio 对象并播放
    final audio = Audio(
      id: item.bvid,
      title: item.title,
      artist: item.author,
      duration: item.duration,
      coverUrl: item.coverUrl,
    );

    ref.read(playerViewModelProvider.notifier).playOnlineAudio(audio: audio);

    context.go('/player');
  }

  /// 显示操作菜单
  void _showActionMenu(ExploreItem item) {
    AudioActionMenu.show(
      context,
      bvid: item.bvid,
      title: item.title,
      artist: item.author,
      coverUrl: item.coverUrl,
      duration: item.duration,
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// 格式化播放量
  String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万播放';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k播放';
    }
    return '$count播放';
  }
}
