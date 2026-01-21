// P2: 页面已迁移到 presentation/pages/
import 'dart:async';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  late DownloadManager _downloadManager;
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 1;

  // 从 BilibiliProvider 获取数据（使用 Builder 避免在事件处理中使用 watch）
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _searchError;

  // Phase 2B: 跟踪正在添加到歌单的项目，防止重复点击
  final Set<String> _addingToPlaylistBvids = {};
  final Set<String> _togglingFavoriteBvids = {};

  @override
  void initState() {
    super.initState();
    // 从 Provider 获取 DownloadManager
    _downloadManager = context.read<DownloadManager>();
    _downloadManager.initDatabase();

    // 从 Provider 获取初始状态
    final provider = context.read<BilibiliProvider>();
    _results = provider.searchResults;
    _isLoading = provider.isSearching;
    _searchError = provider.searchError;

    // 监听 Provider 变化
    provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    // 移除监听器（已在 initState 中保存了 provider 引用）
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<BilibiliProvider>();
    setState(() {
      _results = provider.searchResults;
      _isLoading = provider.isSearching;
      _searchError = provider.searchError;
    });
  }

  /// 搜索B站视频
  ///
  /// Phase 1 改进：通过后端API搜索，不再直接调用B站
  Future<void> _searchBilibili(BuildContext context, String keyword, {int page = 1}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Max page size
    if (page > 50) {
      showMySnackBar(context, 'Reached max page size', Colors.red, 1000);
      return;
    }

    setState(() {
      _currentPage = page;
    });

    final provider = context.read<BilibiliProvider>();
    final success = await provider.searchBilibili(keyword, page: page);

    if (!success && mounted) {
      final error = provider.searchError ?? 'Unknown error';
      showMySnackBar(context, 'Search failed: $error', Colors.red, 2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(context),
          // Search Results
          _buildSearchResults(),
        ],
      ),
      drawer: const MyDrawer(),
      persistentFooterButtons: _results.isEmpty
          ? [] // No search results
          : [
              // Page number
              Text(
                'Page $_currentPage',
                style: const TextStyle(color: Colors.black),
              ),
              // Prev Page Button
              if (_currentPage > 1)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    _searchBilibili(context, _searchController.text, page: _currentPage - 1);
                  },
                  child: const Text(
                    'Prev Page',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              // Next Page Button
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  _searchBilibili(context, _searchController.text, page: _currentPage + 1);
                },
                child: const Text(
                  'Next Page',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Flexible(
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'search for videos',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a keyword';
                  }
                  return null;
                },
                onFieldSubmitted: (value) {
                  _searchBilibili(context, value);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _searchBilibili(context, _searchController.text);
            },
          ),
        ],
      ),
    );
  }

  /// 构建收藏按钮
  Widget _buildFavoriteButton(BuildContext context, dynamic item) {
    // 优先使用后端返回的 bvid 字段
    final bvid = item['bvid'] ?? '';
    if (bvid.isEmpty) {
      return const SizedBox.shrink(); // 没有 bvid 则不显示按钮
    }

    final isToggling = _togglingFavoriteBvids.contains(bvid);

    // 使用 Consumer2 限制 rebuild 范围
    return Consumer2<AuthProvider, PlaylistProvider>(
      builder: (context, authProvider, playlistProvider, child) {
        final isFavorited = playlistProvider.isFavorited(bvid);

        // 获取视频元数据
        final title = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
        final author = item['author'] ?? 'Unknown';

        return IconButton(
          icon: isToggling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
          color: isFavorited ? Colors.red : Colors.grey,
          onPressed: isToggling
              ? null
              : () async {
                  if (!authProvider.isLoggedIn) {
                    showMySnackBar(context, '请先登录', Colors.orange, 1500);
                    return;
                  }

                  // Phase 2B: 标记为正在操作，防止重复点击
                  setState(() {
                    _togglingFavoriteBvids.add(bvid);
                  });

                  try {
                    final token = authProvider.user!.token;
                    final added = await playlistProvider.toggleFavorite(
                      token,
                      bvid,
                      title: title,
                      artist: author,
                    );

                    if (mounted) {
                      showMySnackBar(
                        context,
                        added ? '已添加到我喜欢' : '已从我喜欢移除',
                        Colors.green,
                        1000,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showMySnackBar(context, '操作失败: $e', Colors.red, 2000);
                    }
                  } finally {
                    // Phase 2B: 操作完成，移除标记
                    if (mounted) {
                      setState(() {
                        _togglingFavoriteBvids.remove(bvid);
                      });
                    }
                  }
                },
        );
      },
    );
  }

  /// 构建添加到歌单按钮
  Widget _buildAddToPlaylistButton(BuildContext context, dynamic item) {
    final bvid = item['bvid'] ?? '';
    if (bvid.isEmpty) {
      return const SizedBox.shrink();
    }

    final isAdding = _addingToPlaylistBvids.contains(bvid);

    // 使用 Consumer2 限制 rebuild 范围
    return Consumer2<AuthProvider, PlaylistProvider>(
      builder: (context, authProvider, playlistProvider, child) {
        // 获取用户歌单（排除系统歌单中的"我喜欢"和"正在播放"）
        final userPlaylists = playlistProvider.userPlaylists;

        return IconButton(
          icon: isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add),
          onPressed: isAdding
              ? null
              : () async {
                  if (!authProvider.isLoggedIn) {
                    showMySnackBar(context, '请先登录', Colors.orange, 1500);
                    return;
                  }

                  if (userPlaylists.isEmpty) {
                    showMySnackBar(context, '请先创建歌单', Colors.orange, 2000);
                    return;
                  }

                  // 显示歌单选择对话框
                  final selectedPlaylistId = await showDialog<int>(
                    context: context,
                    builder: (context) => _PlaylistSelectDialog(playlists: userPlaylists),
                  );

                  if (selectedPlaylistId != null) {
                    // Phase 2B: 标记为正在添加，防止重复点击
                    setState(() {
                      _addingToPlaylistBvids.add(bvid);
                    });

                    try {
                      final title = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
                      final author = item['author'] ?? 'Unknown';

                      await playlistProvider.addItem(
                        authProvider.user!.token,
                        selectedPlaylistId,
                        bvid,
                        title: title,
                        artist: author,
                      );

                      if (mounted) {
                        showMySnackBar(context, '已添加到歌单', Colors.green, 1500);
                      }
                    } catch (e) {
                      if (mounted) {
                        showMySnackBar(context, '添加失败: $e', Colors.red, 2000);
                      }
                    } finally {
                      // Phase 2B: 操作完成，移除标记
                      if (mounted) {
                        setState(() {
                          _addingToPlaylistBvids.remove(bvid);
                        });
                      }
                    }
                  }
                },
        );
      },
    );
  }

  /// 构建下载按钮（纯前端下载）
  Widget _buildDownloadButton(BuildContext context, dynamic item) {
    // 优先使用 bvid 字段
    final bvid = item['bvid'] ?? '';
    if (bvid.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () async {
        debugPrint('【SearchPage】Download button clicked');
        await _downloadManager.addDownload(context, bvid);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_searchError'),
            ElevatedButton(
              onPressed: () {
                context.read<BilibiliProvider>().clearError();
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No results found'));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];
          // 清理HTML标签
          String rawTitle = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
          // 后端返回 'cover' 字段，不是 'pic'
          String picUrl = item['cover'] ?? item['pic'] ?? '';

          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: ListTile(
              // Phase 1 改进：使用代理URL加载图片，解决防盗链问题
              leading: Image.network(
                context.read<BilibiliProvider>().getProxyImageUrl(picUrl.startsWith('http') ? picUrl : 'https:$picUrl'),
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
              title: SizedBox(
                height: 35,
                child: Text(
                  rawTitle,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              subtitle: Text(
                'UP: ${item['author'] ?? 'Unknown'} \nPLAY: ${item['play'] ?? '0'} \nDURATION: ${item['duration'] ?? '--:--'}',
                style: const TextStyle(fontSize: 8),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 收藏按钮
                  _buildFavoriteButton(context, item),
                  // 添加到歌单按钮
                  _buildAddToPlaylistButton(context, item),
                  // 下载按钮
                  _buildDownloadButton(context, item),
                ],
              ),
              onTap: () async {
                String url = item['arcurl'] ?? item['url'] ?? '';
                if (url.isNotEmpty) {
                  final Uri uri = Uri.parse(url);
                  await launchUrl(uri);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

/// 歌单选择对话框
class _PlaylistSelectDialog extends StatelessWidget {
  final List<Playlist> playlists;

  const _PlaylistSelectDialog({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加到歌单'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: playlists.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('暂无歌单，请先创建'),
            )
          : SizedBox(
              // 使用固定宽度和高度避免布局问题
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: playlists.map((playlist) {
                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.itemCount} 首歌曲'),
                      onTap: () {
                        Navigator.of(context).pop(playlist.id);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
