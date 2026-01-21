// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/models/recommendation.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 发现页面
///
/// 展示推荐内容和榜单功能
/// Phase 2: 实现推荐/榜单Tab切换
/// Phase 2B: 推荐Tab使用音乐区爬虫内容
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

  // 推荐数据（Phase 2B: 改为音乐区爬虫数据）
  List<Map<String, dynamic>> _musicZoneData = [];
  bool _musicZoneFallback = false;
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

    // 页面初始化时检查登录状态并加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  /// 检查登录状态，未登录则跳转到登录页
  void _checkLoginAndLoad() {
    if (_authProvider == null || !_authProvider!.isLoggedIn) {
      showMySnackBar(context, '请先登录', Colors.orange, 1500);
      context.go('/login');
      return;
    }
    _loadData();
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
        case 0: // Phase 2B: 推荐 - 使用音乐区爬虫数据
          await _loadMusicZone();
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

  /// Phase 2B: 加载音乐区数据（爬虫方式）
  Future<void> _loadMusicZone() async {
    final provider = _bilibiliProvider!;

    final success = await provider.loadMusicZoneRecommendations();

    if (!success) {
      setState(() {
        _errorMessage = provider.errorMessage ?? '加载音乐区推荐失败';
        _musicZoneFallback = true;
      });
      return;
    }

    // 从provider获取数据
    setState(() {
      _musicZoneData = provider.musicZoneRecommendations;
      _musicZoneFallback = provider.musicZoneFallback;
    });

    debugPrint('【ExplorePage】Music zone loaded: ${_musicZoneData.length} items');
  }

  @override
  Widget build(BuildContext context) {
    final isBound = _bilibiliProvider?.isBound ?? false;

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
                fontSize: UIConstants.fontSizeXLarge,
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

  /// 推荐Tab（Phase 2B: 显示音乐区爬虫数据）
  Widget _buildRecommendTab() {
    if (_musicZoneData.isEmpty) {
      return const Center(child: Text('暂无推荐内容'));
    }

    // 使用 ListView.builder 优化性能，按需构建子widget
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _musicZoneData.length + 1, // +1 for source card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSourceCard();
        }
        return _buildMusicZoneCard(_musicZoneData[index - 1]);
      },
    );
  }

  /// 构建来源提示卡片（Phase 2B）
  Widget _buildSourceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.music_note, color: _musicZoneFallback ? Colors.orange : Colors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _musicZoneFallback ? 'B站音乐区（当前使用热门推荐）' : 'B站音乐区个性化推荐',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (_musicZoneFallback)
                    const Text(
                      '爬取失败，已降级到热门推荐',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Phase 2B: 音乐区视频卡片
  Widget _buildMusicZoneCard(Map<String, dynamic> item) {
    final bvid = item['bvid'] ?? '';
    final title = item['title'] ?? '';
    final cover = item['cover'] ?? '';
    final author = item['author'] ?? 'Unknown';
    final playCount = item['playCount'] ?? 0;
    final arcurl = item['arcurl'] ?? '';

    // 处理封面URL
    String coverUrl = cover;
    if (coverUrl.startsWith('//')) {
      coverUrl = 'https:$coverUrl';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          if (arcurl.isNotEmpty) {
            showMySnackBar(context, '即将播放: $title', Colors.blue, 1500);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  coverUrl.isNotEmpty ? coverUrl : '',
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 32),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 右侧信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    // 作者和播放量
                    Text(
                      'UP: $author  ·  播放: $playCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () {
                  showMySnackBar(context, '播放功能开发中', Colors.blue, 1500);
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 榜单Tab
  Widget _buildRankTab() {
    // 使用 CustomScrollView 优化性能，支持多个 section
    return CustomScrollView(
      slivers: [
        // 热门歌单
        if (_hotPlaylists != null && _hotPlaylists!.playlists.isNotEmpty)
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    '热门歌单',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPlaylistCard(_hotPlaylists!.playlists[index]),
                  ),
                  childCount: _hotPlaylists!.playlists.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        // 热歌榜单
        if (_hotRank != null && _hotRank!.playlists.isNotEmpty)
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '热歌榜单',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPlaylistCard(_hotRank!.playlists[index]),
                  ),
                  childCount: _hotRank!.playlists.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
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
