// P2: 页面已迁移到 presentation/pages/
// Phase 2: 支持在线和本地音频混合播放列表
import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 播放列表页面（当前播放队列）
///
/// Phase 2A: UI/交互优化
/// - 当前播放项高亮显示
/// - 删除确认对话框
/// - 空列表友好提示
///
/// Phase 2: 混合播放列表
/// - 支持在线和本地音频统一显示
/// - 根据 isOnline 属性差异化显示
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final playlist = provider.unifiedPlaylist;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放列表 (${playlist.length})',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: playlist.isEmpty
                ? null
                : () => _confirmClearAll(playlist.length),
            tooltip: '清空列表',
          ),
          // 首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: _buildNormalList(provider),
    );
  }

  /// 构建普通列表视图
  Widget _buildNormalList(AudioProvider provider) {
    final playlist = provider.unifiedPlaylist;

    // 空列表提示
    if (playlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '播放列表为空',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '添加本地音频或播放在线音频',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 使用 ListView.builder 优化性能
    return ListView.builder(
      itemCount: playlist.length,
      itemBuilder: (context, index) {
        final playable = playlist[index];
        final isCurrentlyPlaying = provider.currentIndex == index;
        return _buildPlayableItem(playable, index, isCurrentlyPlaying, provider);
      },
    );
  }

  /// 构建单个可播放音频项
  Widget _buildPlayableItem(
    PlayableAudio playable,
    int index,
    bool isCurrentlyPlaying,
    AudioProvider provider,
  ) {
    final isOnline = playable.isOnline;
    final title = playable.title;
    final artist = playable.artist ?? '未知艺术家';

    // 封面处理
    Widget? leadingWidget;
    if (isCurrentlyPlaying) {
      // 当前播放项显示播放/暂停图标
      leadingWidget = Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          provider.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      );
    } else {
      // 显示封面
      if (isOnline && playable.coverUrl != null) {
        // 在线音频：使用网络封面
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: playable.coverUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 48,
              height: 48,
              color: Colors.grey[300],
              child: const Icon(Icons.music_note, size: 24),
            ),
            errorWidget: (context, url, error) => Container(
              width: 48,
              height: 48,
              color: Colors.grey[300],
              child: const Icon(Icons.music_note, size: 24),
            ),
          ),
        );
      } else if (!isOnline && playable.coverData != null) {
        // 本地音频：使用内嵌封面
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            playable.coverData!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        );
      } else {
        // 默认图标
        leadingWidget = Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOnline ? Colors.orange[100] : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            isOnline ? Icons.cloud : Icons.music_note,
            size: 24,
            color: isOnline ? Colors.orange : Colors.grey[600],
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        // 当前播放项使用浅蓝色背景
        color: isCurrentlyPlaying
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        // 当前播放项左侧蓝色竖条
        border: isCurrentlyPlaying
            ? const Border(left: BorderSide(color: Colors.blue, width: 4))
            : null,
      ),
      child: ListTile(
        leading: leadingWidget,
        title: Row(
          children: [
            // 在线/本地标识
            if (isOnline)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.cloud_circle,
                  size: 16,
                  color: Colors.orange,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.storage,
                  size: 16,
                  color: Colors.green,
                ),
              ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentlyPlaying ? Colors.blue : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '艺术家：$artist',
          style: const TextStyle(fontSize: UIConstants.fontSizeSmall),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 当前播放且正在播放时显示进度指示器
            if (isCurrentlyPlaying && provider.isPlaying)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(index, playable),
            ),
          ],
        ),
        onTap: () {
          // 使用统一的播放方法，确保索引正确同步
          provider.playUnifiedAt(index);
        },
      ),
    );
  }

  /// 删除确认对话框
  Future<void> _confirmDelete(int index, PlayableAudio playable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除音频'),
        content: Text('确定要从播放列表中删除"${playable.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AudioProvider>();
      await provider.removeFromUnifiedPlaylist(index);
    }
  }

  /// 清空列表确认对话框
  Future<void> _confirmClearAll(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: Text('确定要清空所有 $count 首音频吗？\n\n注意：本地音频将从数据库中删除，在线音频将从列表中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AudioProvider>();
      await provider.clearUnifiedPlaylist();
    }
  }
}
