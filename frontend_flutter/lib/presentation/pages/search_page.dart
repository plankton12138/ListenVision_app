// P2: 页面已迁移到 presentation/pages/
import 'dart:async';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/download/download_manager.dart';
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
      DialogHelper.showSnackBar(context, 'Reached max page size', backgroundColor: Colors.red, duration: 1000);
      return;
    }

    setState(() {
      _currentPage = page;
    });

    final provider = context.read<BilibiliProvider>();
    final success = await provider.searchBilibili(keyword, page: page);

    if (!success && mounted) {
      final error = provider.searchError ?? 'Unknown error';
      DialogHelper.showSnackBar(context, 'Search failed: $error', backgroundColor: Colors.red, duration: 2000);
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
                    DialogHelper.showSnackBar(context, '请先登录', backgroundColor: Colors.orange, duration: 1500);
                    return;
                  }

                  // Phase 2B: 标记为正在操作，防止重复点击
                  setState(() {
                    _togglingFavoriteBvids.add(bvid);
                  });

                  try {
                    final token = authProvider.user?.token ?? '';
                    if (token.isEmpty) {
                      DialogHelper.showSnackBar(context, '请先登录', backgroundColor: Colors.red, duration: 2000);
                      return;
                    }
                    final added = await playlistProvider.toggleFavorite(
                      token,
                      bvid,
                      title: title,
                      artist: author,
                    );

                    if (mounted) {
                      DialogHelper.showSnackBar(
                        context,
                        added ? '已添加到我喜欢' : '已从我喜欢移除',
                        backgroundColor: Colors.green,
                        duration: 1000,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      DialogHelper.showSnackBar(context, '操作失败: $e', backgroundColor: Colors.red, duration: 2000);
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
                    DialogHelper.showSnackBar(context, '请先登录', backgroundColor: Colors.orange, duration: 1500);
                    return;
                  }

                  if (userPlaylists.isEmpty) {
                    DialogHelper.showSnackBar(context, '请先创建歌单', backgroundColor: Colors.orange, duration: 2000);
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
                      final token = authProvider.user?.token ?? '';
                      if (token.isEmpty) {
                        DialogHelper.showSnackBar(context, '请先登录', backgroundColor: Colors.red, duration: 2000);
                        return;
                      }
                      final title = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
                      final author = item['author'] ?? 'Unknown';

                      await playlistProvider.addItem(
                        token,
                        selectedPlaylistId.toString(),
                        bvid,
                        title: title,
                        artist: author,
                      );

                      if (mounted) {
                        DialogHelper.showSnackBar(context, '已添加到歌单', backgroundColor: Colors.green, duration: 1500);
                      }
                    } catch (e) {
                      if (mounted) {
                        DialogHelper.showSnackBar(context, '添加失败: $e', backgroundColor: Colors.red, duration: 2000);
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

  /// Phase 2: 构建播放按钮
  Widget _buildPlayButton(BuildContext context, dynamic item) {
    final bvid = item['bvid'] ?? '';
    if (bvid.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      color: Colors.blue,
      onPressed: () => _playOnlineAudio(context, bvid, item),
    );
  }

  /// Phase 2: 播放在线音频
  Future<void> _playOnlineAudio(
    BuildContext context,
    String bvid,
    Map<String, dynamic> item,
  ) async {
    final audioProvider = context.read<AudioProvider>();
    final bilibiliProvider = context.read<BilibiliProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      // 显示加载提示
      if (mounted) {
        DialogHelper.showSnackBar(context, '正在加载...', backgroundColor: Colors.blue, duration: 1000);
      }

      // 创建 Audio 实体
      final title = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
      final audio = Audio.fromDto({
        'bvid': bvid,
        'title': title,
        'artist': item['author'],
        'cover': item['cover'] ?? item['pic'],
        'duration': _parseDuration(item['duration']),
      });

      // P0 修复: 不再使用已废弃的 streamUrl 参数
      // audioProvider 会自动构建代理 URL
      await audioProvider.playOnlineAudio(
        audio: audio,
      );

      // 记录播放历史
      if (authProvider.isLoggedIn) {
        await historyProvider.recordPlay(
          bvid: bvid,
          title: title,
          artist: item['author'],
          coverUrl: item['cover'] ?? item['pic'],
          duration: audio.duration,
        );
      }

      if (mounted) {
        DialogHelper.showSnackBar(context, '开始播放: $title', backgroundColor: Colors.green, duration: 1500);
      }
    } catch (e) {
      debugPrint('【SearchPage】播放失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(context, '播放失败: $e', backgroundColor: Colors.red, duration: 2000);
      }
    }
  }

  /// 解析时长字符串（mm:ss 或 hh:mm:ss -> 秒）
  int? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parts = value.split(':');
      if (parts.length == 2) {
        final min = int.tryParse(parts[0]);
        final sec = int.tryParse(parts[1]);
        if (min != null && sec != null) return min * 60 + sec;
      } else if (parts.length == 3) {
        final hr = int.tryParse(parts[0]);
        final min = int.tryParse(parts[1]);
        final sec = int.tryParse(parts[2]);
        if (hr != null && min != null && sec != null) {
          return hr * 3600 + min * 60 + sec;
        }
      }
      final seconds = int.tryParse(value);
      if (seconds != null) return seconds;
    }
    return null;
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
                  // Phase 2: 播放按钮
                  _buildPlayButton(context, item),
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
