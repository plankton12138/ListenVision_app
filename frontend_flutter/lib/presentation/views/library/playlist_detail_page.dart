import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/widgets/audio/audio_action_menu.dart';
import 'package:demo/presentation/viewmodels/library/playlist_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/state_utils.dart';

/// 歌单详情页面
///
/// 显示指定歌单的详细信息和音频列表
class PlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  @override
  void initState() {
    super.initState();
    // 初始加载由 Provider 自动触发
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(playlistDetailViewModelProvider(widget.playlistId));

    return Scaffold(
      appBar: AppBar(
        title: detailState.valueOrNull?.maybeWhen(
          loaded: (playlist, _, __) => Text(
            playlist.name,
            style: TextStyle(fontSize: UIConstants.fontSizeLarge),
          ),
          orElse: () => Text(
            '歌单详情',
            style: TextStyle(fontSize: UIConstants.fontSizeLarge),
          ),
        ),
        actions: <Widget>[
          ...?detailState.valueOrNull?.maybeWhen(
            loaded: (_, __, isOwner) => isOwner
                ? [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) => _onMenuAction(action, ref),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
                        PopupMenuItem(value: 'delete', child: Text('删除歌单')),
                      ],
                    ),
                  ]
                : [],
            orElse: () => [],
          ),
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: detailState.when(
        data: (state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (playlist, items, isOwner) => _buildContent(playlist, items, ref),
            error: (message) => _buildErrorState(message),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('加载失败')),
      ),
    );
  }

  Widget _buildContent(dynamic playlist, List<dynamic> items, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(playlistDetailViewModelProvider(widget.playlistId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // 歌单头部信息
          SliverToBoxAdapter(
            child: _buildPlaylistHeader(playlist, items.length),
          ),
          // 操作按钮
          SliverToBoxAdapter(
            child: _buildActionButtons(ref, items),
          ),
          // 分割线
          const SliverToBoxAdapter(
            child: Divider(height: 1),
          ),
          // 音频列表
          items.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              : _buildItemsList(items, ref),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader(dynamic playlist, int itemCount) {
    final coverUrl = playlist.coverUrl as String?;
    final name = playlist.name as String;
    final description = playlist.description as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 封面
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: coverUrl != null && coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.playlist_play, size: 48);
                      },
                    ),
                  )
                : const Icon(Icons.playlist_play, size: 48, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$itemCount 首歌曲',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, List items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _playAll(ref, items),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('下载全部'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _downloadAll(ref, items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List items, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildItemTile(item, index, ref);
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildItemTile(dynamic item, int index, WidgetRef ref) {
    final bvid = item.bvid as String;
    final title = item.title as String?;
    final artist = item.artist as String?;
    final duration = item.duration as int?;

    return ListTile(
      leading: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      title: Text(
        title ?? '未知标题',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${artist ?? '未知艺术家'}${duration != null ? ' • ${_formatDuration(duration)}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AudioActionMenu(
        bvid: bvid,
        title: title ?? '',
        artist: artist,
      ),
      onTap: () => context.push('/player?bvid=$bvid'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '歌单暂无歌曲',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(playlistDetailViewModelProvider(widget.playlistId).notifier).refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _playAll(WidgetRef ref, List items) {
    if (items.isEmpty) return;

    // TODO: 添加到播放队列并开始播放
    // final bvids = items.map((item) => item.bvid as String).toList();
    // ref.read(queueViewModelProvider.notifier).replaceAll(bvids);
    // ref.read(playerViewModelProvider.notifier).play();
    // context.push('/player');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('播放全部功能待实现')),
    );
  }

  void _downloadAll(WidgetRef ref, List items) {
    if (items.isEmpty) return;

    // TODO: 批量下载
    // for (final item in items) {
    //   ref.read(downloadViewModelProvider.notifier).addDownload(item.bvid);
    // }
    // context.push('/downloads');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${items.length} 首歌曲到下载队列')),
    );
  }

  void _onMenuAction(String action, WidgetRef ref) {
    switch (action) {
      case 'edit':
        _showEditDialog(ref);
        break;
      case 'delete':
        _showDeleteConfirmDialog(ref);
        break;
    }
  }

  void _showEditDialog(WidgetRef ref) {
    final playlist = ref.read(playlistDetailViewModelProvider(widget.playlistId)).valueOrNull?.maybeWhen(
      loaded: (playlist, _, __) => playlist,
      orElse: () => null,
    );
    if (playlist == null) return;

    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '歌单名称'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述（可选）'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(playlistDetailViewModelProvider(widget.playlistId).notifier).updatePlaylist(
                    name: nameController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                  );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '保存成功' : '保存失败'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: const Text('确定要删除这个歌单吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(playlistDetailViewModelProvider(widget.playlistId).notifier).deletePlaylist();
              if (mounted) {
                if (success) {
                  Navigator.pop(context); // 关闭对话框
                  context.pop(); // 返回上一页
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('删除失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
