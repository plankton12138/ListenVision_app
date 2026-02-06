import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/discovery/explore_viewmodel.dart';
import 'package:demo/presentation/widgets/common/download_status_indicator.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发现页面
///
/// 显示B站音乐区热门内容
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['热门', '开发中'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final authState = ref.watch(platformAuthViewModelProvider);
    final exploreState = ref.watch(exploreViewModelProvider);

    // 检查认证状态是否正在加载
    if (authState.isLoading) {
      return _buildLoadingView();
    }

    // 从 authState 获取绑定状态 - 直接检查类型
    final authData = authState.value;
    final isBound = authData != null && authData is PlatformAuthStateBound;

    if (!isLoggedIn) {
      return _buildNotLoggedInPrompt();
    }

    if (!isBound) {
      return _buildNotBoundPrompt();
    }

    // 监听绑定状态变化，自动加载内容
    exploreState.whenData((state) {
      if (state is ExploreStateInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(exploreViewModelProvider.notifier).loadHotRanking();
        });
      }
    });

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
          _buildHotTab(exploreState),
          _buildComingSoonTab(),
        ],
      ),
    );
  }

  /// 构建热门Tab
  Widget _buildHotTab(AsyncValue<ExploreState> exploreState) {
    return exploreState.when(
      loading: () => _buildLoadingView(),
      error: (e, _) => _buildErrorView(e.toString()),
      data: (state) {
        return state.when(
          initial: () => _buildLoadingView(),
          loading: () => _buildLoadingView(),
          notBound: () => _buildNotBoundPrompt(),
          loaded: (items, _, _, _) => _buildHotContentGrid(items),
          error: (message) => _buildErrorView(message),
        );
      },
    );
  }

  /// 构建热门内容网格
  Widget _buildHotContentGrid(List<ExploreItem> items) {
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
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildHotCard(item, index);
        },
      ),
    );
  }

  /// 构建热门卡片
  Widget _buildHotCard(ExploreItem item, int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playAudio(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面区域
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面图片
                  if (item.coverUrl != null && item.coverUrl!.isNotEmpty)
                    Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, size: 48),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 48),
                    ),
                  // 排名徽章
                  if (item.rank != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: _buildRankBadge(item.rank!),
                    ),
                  // B站标识
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: _BilibiliBadge(),
                  ),
                  // 下载状态
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: DownloadStatusIndicator(
                      bvid: item.bvid,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 信息区域
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      if (item.duration != null)
                        Text(
                          _formatDuration(item.duration!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: rank <= 3 ? Colors.white : Colors.grey[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建开发中Tab
  Widget _buildComingSoonTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '功能开发中',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '敬请期待更多内容',
            style: TextStyle(color: Colors.grey[500]),
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
                '绑定后可查看B站音乐区热门内容',
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

  /// 播放音频
  void _playAudio(ExploreItem item) {
    AppLogger.logUserAction(
      'ExplorePage',
      '播放音频',
      parameters: {'bvid': item.bvid, 'title': item.title},
    );

    final audio = Audio(
      id: item.bvid,
      title: item.title,
      artist: item.author,
      duration: item.duration,
      coverUrl: item.coverUrl,
    );

    ref.read(playerViewModelProvider.notifier).playOnlineAudio(audio: audio);
    context.go('/');
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// B站标识组件
class _BilibiliBadge extends StatelessWidget {
  const _BilibiliBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'B站',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
