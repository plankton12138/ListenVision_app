import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发现页面
///
/// 显示推荐内容和热门音频
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取推荐内容
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    // TODO: 加载推荐内容
    // await ref.read(recommendationViewModelProvider.notifier).loadHotPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (!isLoggedIn) {
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
              Icon(Icons.login, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索入口
            _buildSearchEntry(context),
            const SizedBox(height: 24),

            // 热门推荐
            _buildSectionTitle('热门推荐', context),
            _buildHotRecommendations(context),
            const SizedBox(height: 24),

            // 热门榜单
            _buildSectionTitle('热门榜单', context),
            _buildHotRanking(context),
            const SizedBox(height: 24),

            // 分类浏览
            _buildSectionTitle('分类浏览', context),
            _buildCategories(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 构建搜索入口
  Widget _buildSearchEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 12),
              Text(
                '搜索音频、歌单、艺术家...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建区块标题
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建热门推荐
  Widget _buildHotRecommendations(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildRecommendationCard(Icons.whatshot, '每日推荐', '根据你的口味精心挑选', context),
          _buildRecommendationCard(Icons.trending_up, '飙升榜', '今日最热门音频', context),
          _buildRecommendationCard(Icons.new_releases, '新歌速递', '最新发布内容', context),
          _buildRecommendationCard(Icons.favorite, '收藏精选', '最受欢迎内容', context),
        ],
      ),
    );
  }

  /// 构建推荐卡片
  Widget _buildRecommendationCard(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: InkWell(
          onTap: () {
            // TODO: 导航到对应页面
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建热门榜单
  Widget _buildHotRanking(BuildContext context) {
    final rankings = List.generate(5, (index) {
      return {
        'rank': index + 1,
        'title': '热门音频 ${index + 1}',
        'artist': '艺术家 ${index + 1}',
        'plays': '${(index + 1) * 10000}',
      };
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = rankings[index];
          return ListTile(
            leading: _buildRankBadge(item['rank'] as int, context),
            title: Text(item['title'] as String),
            subtitle: Text(item['artist'] as String),
            trailing: Text('${item['plays']} 播放'),
            onTap: () {
              // TODO: 播放该音频
            },
          );
        },
      ),
    );
  }

  /// 构建排名徽章
  Widget _buildRankBadge(int rank, BuildContext context) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.grey[400]!;
    } else if (rank == 3) {
      color = Colors.brown[300]!;
    } else {
      color = Theme.of(context).colorScheme.surface;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank <= 3 ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建分类浏览
  Widget _buildCategories(BuildContext context) {
    final categories = [
      {'icon': Icons.music_note, 'name': '全部', 'color': Colors.blue},
      {'icon': Icons.person, 'name': '歌手', 'color': Colors.purple},
      {'icon': Icons.album, 'name': '专辑', 'color': Colors.orange},
      {'icon': Icons.list, 'name': '歌单', 'color': Colors.green},
      {'icon': Icons.mic, 'name': '有声书', 'color': Colors.teal},
      {'icon': Icons.radio, 'name': '电台', 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () {
            // TODO: 导航到分类页面
          },
          child: Container(
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: category['color'] as Color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
