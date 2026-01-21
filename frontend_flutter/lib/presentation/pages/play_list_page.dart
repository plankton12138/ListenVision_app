// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/models/audio_model.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 播放列表页面（当前播放队列）
///
/// Phase 2A: UI/交互优化
/// - 当前播放项高亮显示
/// - 拖拽排序
/// - 清空列表（带确认）
/// - 删除确认对话框
/// - 空列表友好提示
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  /// 是否处于排序模式
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final playlist = provider.playlist;

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
          // 排序按钮（仅当列表有2个以上项目时显示）
          if (playlist.length > 1)
            IconButton(
              icon: Icon(_isReordering ? Icons.check : Icons.sort),
              onPressed: () {
                setState(() {
                  _isReordering = !_isReordering;
                });
              },
              tooltip: _isReordering ? '完成排序' : '调整顺序',
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
      body: _isReordering
          ? _buildReorderableList(provider)
          : _buildNormalList(provider),
    );
  }

  /// 构建普通列表视图
  Widget _buildNormalList(AudioProvider provider) {
    final playlist = provider.playlist;

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
              '添加本地音频开始播放',
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
        final audio = playlist[index];
        final isCurrentlyPlaying = provider.currentIndex == index;
        return _buildAudioItem(audio, index, isCurrentlyPlaying, provider);
      },
    );
  }

  /// 构建单个音频项
  Widget _buildAudioItem(
    Audio audio,
    int index,
    bool isCurrentlyPlaying,
    AudioProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        // 当前播放项使用浅蓝色背景
        color: isCurrentlyPlaying
            ? Colors.blue.withOpacity(0.1)
            : Colors.transparent,
        // 当前播放项左侧蓝色竖条
        border: isCurrentlyPlaying
            ? const Border(left: BorderSide(color: Colors.blue, width: 4))
            : null,
      ),
      child: ListTile(
        // 当前播放项显示播放/暂停图标，否则显示音乐图标
        leading: isCurrentlyPlaying
            ? Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.music_note),
        title: Text(
          audio.title,
          style: TextStyle(
            fontSize: UIConstants.fontSizeMedium,
            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
            color: isCurrentlyPlaying ? Colors.blue : null,
          ),
        ),
        subtitle: Text(
          '艺术家：${audio.artist}',
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
              onPressed: () => _confirmDelete(audio),
            ),
          ],
        ),
        onTap: () => provider.playAudio(index),
      ),
    );
  }

  /// 构建可排序列表视图
  Widget _buildReorderableList(AudioProvider provider) {
    final playlist = provider.playlist;

    return ReorderableListView.builder(
      onReorder: _handleReorder,
      itemCount: playlist.length,
      itemBuilder: (context, index) {
        final audio = playlist[index];
        // 使用 filePath 作为 key，保证唯一性
        return Container(
          key: ValueKey(audio.filePath),
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: ListTile(
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(
              audio.title,
              style: const TextStyle(fontSize: UIConstants.fontSizeMedium),
            ),
            subtitle: Text(
              audio.artist,
              style: const TextStyle(fontSize: UIConstants.fontSizeSmall),
            ),
            trailing: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: UIConstants.fontSizeMedium),
            ),
          ),
        );
      },
    );
  }

  /// 处理拖拽排序
  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final provider = context.read<AudioProvider>();
    final playlist = List<Audio>.from(provider.playlist);

    // ReorderableListView 的 newIndex 处理
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 获取被移动的项目
    final movedItem = playlist[oldIndex];

    // 更新数据库：通过修改 filePath 来实现"移动"效果
    // SQLite 不支持直接调整行顺序，我们使用交换 ID 的方式
    final db = PlaylistManager();
    final database = await db.database;

    // 获取所有记录的 ID
    final List<Map> allRecords = await database.query(
      'playlist_audios',
      columns: ['id'],
      orderBy: 'id ASC',
    );

    if (allRecords.length > oldIndex && allRecords.length > newIndex) {
      final oldId = allRecords[oldIndex]['id'] as int;
      final newId = allRecords[newIndex]['id'] as int;

      // 交换 ID 来实现位置交换
      await database.rawUpdate(
        'UPDATE playlist_audios SET id = ? WHERE id = ?',
        [ -oldId, oldId ], // 临时设为负数避免冲突
      );
      await database.rawUpdate(
        'UPDATE playlist_audios SET id = ? WHERE id = ?',
        [ oldId, newId ],
      );
      await database.rawUpdate(
        'UPDATE playlist_audios SET id = ? WHERE id = ?',
        [ newId, -oldId ],
      );

      debugPrint('【PlaylistPage】排序已更新: 交换 ID $oldId <-> $newId');
    }

    // 重新加载
    await provider.loadPlaylist();

    // 主动刷新排序模式UI
    if (mounted) {
      setState(() {});
    }
  }

  /// 删除确认对话框
  Future<void> _confirmDelete(Audio audio) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除音频'),
        content: Text('确定要从播放列表中删除"${audio.title}"吗？'),
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
      await provider.removeFromPlaylist(audio.id!);
    }
  }

  /// 清空列表确认对话框
  Future<void> _confirmClearAll(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: Text('确定要清空所有 $count 首音频吗？'),
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
      final db = PlaylistManager();
      await db.clearPlaylist();
      final provider = context.read<AudioProvider>();
      await provider.loadPlaylist();
    }
  }
}
