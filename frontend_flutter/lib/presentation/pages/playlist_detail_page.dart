// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/widgets/add_song_dialog.dart';
import 'package:demo/presentation/widgets/sort_options_dialog.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 歌单详情页面
///
/// 展示歌单信息和歌单项列表
/// Phase 2: 完整的歌单项管理功能
class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  _PlaylistDetailPageState createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  PlaylistDetail? _detail;
  Playlist? _playlist;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isReordering = false;

  // 搜索状态
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 设置当前歌单ID到Provider
    final playlistProvider = context.read<PlaylistProvider>();
    playlistProvider.setCurrentPlaylistId(widget.playlistId);
    _loadDetail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取过滤后的歌单项列表
  List<PlaylistItem> get _filteredItems {
    if (_detail == null) return [];
    if (_searchQuery.isEmpty) return _detail!.items;

    final query = _searchQuery.toLowerCase();
    return _detail!.items.where((item) {
      final title = (item.title ?? item.bvid).toLowerCase();
      final artist = (item.artist ?? '').toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();
  }

  Future<void> _loadDetail() async {
    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    if (authProvider.user?.token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 先从provider获取歌单信息
      final playlists = playlistProvider.playlists;
      _playlist = playlists.firstWhere(
        (p) => p.id == widget.playlistId,
        orElse: () => const Playlist(
          id: '0',
          userId: '0',
          name: '歌单详情',
          type: PlaylistType.user,
        ),
      );

      // 调用API获取详情（包含歌单项列表）
      final response = await DioProvider.instance.get('/playlists/${widget.playlistId}');

      if (response['success'] == true && response['data'] != null) {
        // P0 修复: 使用 fromDto 而不是 fromJson，正确处理后端 snake_case 字段名
        _detail = PlaylistDetail.fromDto(response['data'] as Map<String, dynamic>);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _removeItem(PlaylistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除歌曲'),
        content: Text('确定要从歌单中移除"${item.title ?? item.bvid}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final token = authProvider.user?.token ?? '';

    if (token.isEmpty) {
      DialogHelper.showSnackBar(context, '用户未登录', backgroundColor: Colors.red, duration: 2000);
      return;
    }

    try {
      final success = await playlistProvider.removeItem(
        token,
        widget.playlistId,
        item.bvid,
      );

      if (success && mounted) {
        DialogHelper.showSnackBar(context, '已移除', backgroundColor: Colors.green, duration: 1500);
        _loadDetail(); // 重新加载
      } else {
        DialogHelper.showSnackBar(context, '移除失败', backgroundColor: Colors.red, duration: 2000);
      }
    } catch (e) {
      DialogHelper.showSnackBar(context, '移除失败: $e', backgroundColor: Colors.red, duration: 2000);
    }
  }

  void _toggleReorder() {
    setState(() {
      _isReordering = !_isReordering;
    });
  }

  // Phase 5: 显示添加歌曲对话框
  void _showAddSongDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSongDialog(),
    );
  }

  // Phase 5: 显示排序选项对话框
  void _showSortOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SortOptionsDialog(),
    );
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    if (_detail == null) return;

    // 局部更新UI（乐观更新）
    final items = List<PlaylistItem>.from(_detail!.items);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    setState(() {
      _detail = PlaylistDetail(playlist: _detail!.playlist, items: items);
    });

    // 调用后端API保存新顺序
    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final token = authProvider.user?.token ?? '';

    if (token.isEmpty) {
      DialogHelper.showSnackBar(context, '用户未登录', backgroundColor: Colors.red, duration: 2000);
      return;
    }

    try {
      await playlistProvider.reorderItems(
        token,
        widget.playlistId,
        items,
      );
    } catch (e) {
      // 失败时重新加载
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _playlist?.name ?? '歌单详情',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          // 搜索按钮
          if (_detail != null && _detail!.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchBar(),
              tooltip: '搜索歌曲',
            ),
          // Phase 5: 添加歌曲按钮
          if (_detail != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddSongDialog,
              tooltip: '添加歌曲',
            ),
          // Phase 5: 排序选项按钮
          if (_detail != null && _detail!.items.isNotEmpty && _searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptionsDialog,
              tooltip: '排序选项',
            ),
          // 拖拽排序按钮（搜索时隐藏）
          if (_detail != null && _detail!.items.isNotEmpty && _searchQuery.isEmpty)
            IconButton(
              icon: Icon(_isReordering ? Icons.check : Icons.list),
              onPressed: _toggleReorder,
              tooltip: _isReordering ? '完成排序' : '拖拽排序',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 显示搜索栏
  void _showSearchBar() {
    setState(() {
      if (_searchQuery.isEmpty) {
        // 打开搜索模式
        _searchQuery = ' '; // 触发搜索框显示
      } else {
        // 关闭搜索模式
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Widget _buildBody() {
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
              onPressed: _loadDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_detail == null || _detail!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '歌单还没有内容',
              style: TextStyle(
                fontSize: UIConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '去搜索页面添加歌曲吧',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final filteredItems = _filteredItems;

    return Column(
      children: [
        // 歌单信息
        _buildPlaylistInfo(),
        // 搜索框
        if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
          _buildSearchBar(),
        // 歌单项列表
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptySearchResult()
              : ReorderableListView.builder(
                  onReorder: _isReordering && _searchQuery.isEmpty ? _reorderItems : (_, __) {},
                  buildDefaultDragHandles: _isReordering,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildItemCard(item, index);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索歌曲或歌手',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// 构建空搜索结果提示
  Widget _buildEmptySearchResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            '没有找到相关歌曲',
            style: TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '试试其他搜索关键词',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _playlist?.isFavorites == true
                    ? Icons.favorite
                    : _playlist?.isNowPlaying == true
                        ? Icons.play_circle
                        : Icons.playlist_play,
                size: 48,
                color: _playlist?.isFavorites == true
                    ? Colors.red
                    : _playlist?.isNowPlaying == true
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _playlist?.name ?? '',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_playlist?.description != null)
                      Text(
                        _playlist!.description!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    Text(
                      '${_detail?.items.length ?? 0}首',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PlaylistItem item, int index) {
    return Container(
      key: ValueKey(item.id ?? item.bvid),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: _buildItemCover(item),
        title: Text(
          item.title ?? item.bvid,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (item.artist != null) item.artist,
            item.formattedDuration,
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _isReordering
            ? const Icon(Icons.drag_handle)
            : IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
                onPressed: () => _removeItem(item),
              ),
        onTap: () {
          // Phase 2: 播放这首歌
          _playPlaylistItem(context, item);
        },
      ),
    );
  }

  Widget _buildItemCover(PlaylistItem item) {
    final coverUrl = item.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          coverUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover(index: _detail?.items.indexOf(item) ?? 0);
          },
        ),
      );
    }
    return _buildDefaultCover(index: _detail?.items.indexOf(item) ?? 0);
  }

  Widget _buildDefaultCover({required int index}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// Phase 2: 播放歌单项
  /// P0 修复: 使用 proxyUrl 而不是已废弃的 streamUrl 参数
  Future<void> _playPlaylistItem(
    BuildContext context,
    PlaylistItem item,
  ) async {
    final audioProvider = context.read<AudioProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      DialogHelper.showSnackBar(context, '正在加载...', backgroundColor: Colors.blue, duration: 1000);

      // 创建 Audio 实体
      final audio = Audio.fromDto({
        'bvid': item.bvid,
        'title': item.title ?? item.bvid,
        'artist': item.artist,
        'cover': item.coverUrl,
        'duration': item.duration,
      });

      // P0 修复: 使用 proxyUrl（audioProvider 会自动构建代理 URL）
      // 不需要从 bilibiliProvider.getAudioStream 获取流 URL
      await audioProvider.playOnlineAudio(
        audio: audio,
      );

      // 记录播放历史
      if (authProvider.isLoggedIn) {
        await historyProvider.recordPlay(
          bvid: item.bvid,
          title: audio.title,
          artist: audio.artist,
          coverUrl: audio.coverUrl,
          duration: audio.duration,
        );
      }

      if (mounted) {
        DialogHelper.showSnackBar(context, '开始播放: ${audio.title}', backgroundColor: Colors.green, duration: 1500);
      }
    } catch (e) {
      debugPrint('【PlaylistDetailPage】播放失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(context, '播放失败: $e', backgroundColor: Colors.red, duration: 2000);
      }
    }
  }
}
