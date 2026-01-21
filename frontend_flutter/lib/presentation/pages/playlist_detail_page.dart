// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/models/playlist.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 歌单详情页面
///
/// 展示歌单信息和歌单项列表
/// Phase 2: 完整的歌单项管理功能
class PlaylistDetailPage extends StatefulWidget {
  final int playlistId;

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

  @override
  void initState() {
    super.initState();
    _loadDetail();
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
        orElse: () => Playlist(
          id: widget.playlistId,
          userId: 0,
          name: '歌单详情',
          type: PlaylistType.user,
        ),
      );

      // 调用API获取详情（包含歌单项列表）
      final response = await DioProvider.instance.get('/playlists/${widget.playlistId}');

      if (response['success'] == true && response['data'] != null) {
        _detail = PlaylistDetail.fromJson(response['data'] as Map<String, dynamic>);
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

    try {
      final success = await playlistProvider.removeItem(
        authProvider.user!.token,
        widget.playlistId,
        item.bvid,
      );

      if (success && mounted) {
        showMySnackBar(context, '已移除', Colors.green, 1500);
        _loadDetail(); // 重新加载
      } else {
        showMySnackBar(context, '移除失败', Colors.red, 2000);
      }
    } catch (e) {
      showMySnackBar(context, '移除失败: $e', Colors.red, 2000);
    }
  }

  void _toggleReorder() {
    setState(() {
      _isReordering = !_isReordering;
    });
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

    try {
      await playlistProvider.reorderItems(
        authProvider.user!.token,
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
          if (_detail != null && _detail!.items.isNotEmpty)
            IconButton(
              icon: Icon(_isReordering ? Icons.check : Icons.sort),
              onPressed: _toggleReorder,
              tooltip: _isReordering ? '完成排序' : '调整顺序',
            ),
        ],
      ),
      body: _buildBody(),
    );
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

    return Column(
      children: [
        // 歌单信息
        _buildPlaylistInfo(),
        // 歌单项列表
        Expanded(
          child: ReorderableListView.builder(
            onReorder: _isReordering ? _reorderItems : (_, __) {},
            buildDefaultDragHandles: _isReordering,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _detail!.items.length,
            itemBuilder: (context, index) {
              final item = _detail!.items[index];
              return _buildItemCard(item, index);
            },
          ),
        ),
      ],
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
          // TODO: 播放这首歌
          showMySnackBar(context, '播放功能开发中', Colors.blue, 1500);
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
}
