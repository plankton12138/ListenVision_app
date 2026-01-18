import 'package:demo/constants/dimens.dart';
import 'package:demo/models/recommendation.dart';
import 'package:demo/providers/bilibili_provider.dart';
import 'package:demo/providers/auth_provider.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 发现页面
///
/// 展示推荐内容和榜单功能
/// Phase 2: 实现推荐/榜单Tab切换
/// TODO: 分区推荐功能待加入（需要WBI签名优化）
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 数据状态
  bool _isLoading = false;
  String? _errorMessage;

  // 推荐数据
  PersonalizedResponse? _personalizedResponse;
  BiliPlaylistsResponse? _hotPlaylists;
  BiliPlaylistsResponse? _hotRank;

  // 保存 Provider 引用
  BilibiliProvider? _bilibiliProvider;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _bilibiliProvider = context.read<BilibiliProvider>();
    _authProvider = context.read<AuthProvider>();

    // 页面初始化时加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    _loadDataForTab(_tabController.index);
  }

  /// 加载当前Tab的数据
  void _loadData() {
    final isBound = _bilibiliProvider?.isBound ?? false;
    if (!isBound) {
      setState(() {
        _errorMessage = '请先绑定B站账号以查看推荐内容';
      });
      return;
    }
    _loadDataForTab(_tabController.index);
  }

  /// 根据Tab索引加载数据
  Future<void> _loadDataForTab(int index) async {
    if (_bilibiliProvider == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (index) {
        case 0: // 推荐
          await _loadPersonalized();
          break;
        case 1: // 榜单
          await _loadRankings();
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载个性化推荐
  Future<void> _loadPersonalized() async {
    final provider = _bilibiliProvider!;

    // 调用后端个性化推荐API
    final success = await provider.loadPersonalizedRecommendations();
    if (!success) {
      setState(() {
        _errorMessage = provider.errorMessage ?? '加载推荐失败';
      });
      return;
    }

    // 从provider获取数据并转换为模型
    final items = provider.personalizedRecommendations;
    setState(() {
      _personalizedResponse = PersonalizedResponse(
        source: 'personalized',
        keywords: [],
        videos: items.map((item) => RecommendationItem.fromJson(item)).toList(),
        playlists: [],
      );
    });
  }

  /// 加载榜单数据
  Future<void> _loadRankings() async {
    final provider = _bilibiliProvider!;

    // 调用后端榜单API
    await provider.loadHotPlaylists();
    await provider.loadHotRank();

    // 从provider获取数据并转换为模型
    setState(() {
      _hotPlaylists = BiliPlaylistsResponse(
        playlists: provider.hotPlaylists.map((p) => BiliPlaylist.fromJson(p)).toList(),
        page: 1,
        pageSize: provider.hotPlaylists.length,
        total: provider.hotPlaylists.length,
      );
      _hotRank = BiliPlaylistsResponse(
        playlists: provider.hotRank.map((p) => BiliPlaylist.fromJson(p)).toList(),
        page: 1,
        pageSize: provider.hotRank.length,
        total: provider.hotRank.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBound = _bilibiliProvider?.isBound ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(fontSize: Dimens.fontSizeLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
        bottom: isBound
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '推荐'),
                  Tab(text: '榜单'),
                ],
              )
            : null,
      ),
      drawer: const MyDrawer(),
      body: _buildBody(isBound),
    );
  }

  Widget _buildBody(bool isBound) {
    if (!isBound) {
      return _buildBindingPrompt();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRecommendTab(),
        _buildRankTab(),
      ],
    );
  }

  /// 绑定引导页面
  Widget _buildBindingPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '绑定B站账号',
              style: TextStyle(
                fontSize: Dimens.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '绑定后可以查看个性化推荐和热门榜单',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/settings'),
              child: const Text('去设置绑定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 推荐Tab
  Widget _buildRecommendTab() {
    if (_personalizedResponse == null) {
      return const Center(child: Text('暂无推荐内容'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 个性化推荐提示
        if (_personalizedResponse!.keywords != null &&
            _personalizedResponse!.keywords!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '基于你的兴趣: ${_personalizedResponse!.keywords!.join('、')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 推荐视频列表
        if (_personalizedResponse!.videos != null &&
            _personalizedResponse!.videos!.isNotEmpty)
          ..._personalizedResponse!.videos!.map((item) => _buildVideoCard(item)),
        // 推荐歌单列表
        if (_personalizedResponse!.playlists != null &&
            _personalizedResponse!.playlists!.isNotEmpty)
          ..._personalizedResponse!.playlists!.map((playlist) => _buildPlaylistCard(playlist)),
      ],
    );
  }

  /// 榜单Tab
  Widget _buildRankTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 热门歌单
        if (_hotPlaylists != null && _hotPlaylists!.playlists.isNotEmpty) ...[
          Text(
            '热门歌单',
            style: TextStyle(
              fontSize: Dimens.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._hotPlaylists!.playlists.map((p) => _buildPlaylistCard(p)),
          const SizedBox(height: 24),
        ],
        // 热歌榜单
        if (_hotRank != null && _hotRank!.playlists.isNotEmpty) ...[
          Text(
            '热歌榜单',
            style: TextStyle(
              fontSize: Dimens.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._hotRank!.playlists.map((p) => _buildPlaylistCard(p)),
        ],
      ],
    );
  }

  /// 视频卡片
  Widget _buildVideoCard(RecommendationItem item) {
    String coverUrl = item.cover ?? '';
    if (coverUrl.startsWith('//')) {
      coverUrl = 'https:$coverUrl';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SizedBox(
          width: 100,
          height: 80,
          child: Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        ),
        title: SizedBox(
          height: 35,
          child: Text(
            item.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Text(
          'UP: ${item.author ?? '未知'}\n播放: ${item.play ?? 0}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () {
            showMySnackBar(context, '播放功能开发中', Colors.blue, 1500);
          },
        ),
      ),
    );
  }

  /// 歌单卡片
  Widget _buildPlaylistCard(dynamic playlist) {
    // 处理 BiliPlaylist 类型
    final BiliPlaylist? biliPlaylist = playlist is BiliPlaylist ? playlist : null;
    if (biliPlaylist == null) {
      return const SizedBox.shrink();
    }

    String coverUrl = biliPlaylist.cover ?? '';
    if (coverUrl.startsWith('//')) {
      coverUrl = 'https:$coverUrl';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SizedBox(
          width: 100,
          height: 80,
          child: Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.playlist_play),
              );
            },
          ),
        ),
        title: Text(
          biliPlaylist.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(biliPlaylist.intro ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${biliPlaylist.songCount}首 · ${biliPlaylist.formattedPlayCount}播放'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showMySnackBar(context, '歌单详情功能开发中', Colors.blue, 1500);
        },
      ),
    );
  }
}
