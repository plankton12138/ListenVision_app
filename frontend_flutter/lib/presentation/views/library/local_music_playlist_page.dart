import 'package:demo/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/local_audio.dart';
import '../../viewmodels/library/local_music_viewmodel.dart';

/// 本地音乐歌单页面
///
/// 展示和管理"本地音乐"歌单中的音频文件
class LocalMusicPlaylistPage extends ConsumerWidget {
  const LocalMusicPlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localMusicViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '本地音乐',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: '批量导入',
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).importMultipleFiles();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '导入音频',
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: state.when(
        data: (localState) => localState.map(
          initial: (_) => const Center(child: CircularProgressIndicator()),
          loading: (_) => const Center(child: CircularProgressIndicator()),
          loaded: (data) => _buildPlaylistView(context, data.audios, ref),
          importing: (data) => _buildImportingView(
            context,
            data.current,
            data.total,
            data.currentFile,
          ),
          error: (data) => _buildErrorView(context, data.message, ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
      ),
    );
  }

  /// 歌单内容视图
  Widget _buildPlaylistView(
      BuildContext context, List<LocalAudio> audios, WidgetRef ref) {
    if (audios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('本地音乐歌单是空的'),
            const SizedBox(height: 8),
            const Text(
              '导入的本地音频将显示在这里',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
              },
              icon: const Icon(Icons.add),
              label: const Text('导入音频'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 歌单信息头
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildCoverImage(audios),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本地音乐',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${audios.length}首歌曲',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // 播放全部按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              // 播放全部本地音乐
              if (audios.isNotEmpty) {
                _playAudio(context, audios.first);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('播放全部'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        // 歌曲列表
        Expanded(
          child: ListView.builder(
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
              return _buildAudioListTile(context, audio, index, ref);
            },
          ),
        ),
      ],
    );
  }

  /// 构建封面图片
  Widget _buildCoverImage(List<LocalAudio> audios) {
    // 获取第一个有封面的音频
    final audioWithCover = audios.firstWhere(
      (a) => a.albumArt != null,
      orElse: () => audios.first,
    );

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: audioWithCover.albumArt != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                audioWithCover.albumArt!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40),
              ),
            )
          : const Icon(Icons.music_note, size: 40),
    );
  }

  /// 构建音频列表项
  Widget _buildAudioListTile(
      BuildContext context, LocalAudio audio, int index, WidgetRef ref) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: Text(
        audio.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${audio.artist} · ${_formatDuration(audio.duration)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              audio.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: audio.isFavorite ? Colors.red : null,
              size: 20,
            ),
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).toggleFavorite(
                    audio.id!,
                    !audio.isFavorite,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showItemMenu(context, audio, ref),
          ),
        ],
      ),
      onTap: () => _playAudio(context, audio),
    );
  }

  /// 导入中视图
  Widget _buildImportingView(
      BuildContext context, int current, int total, String currentFile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: current / total,
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '导入中... $current/$total',
            style: const TextStyle(fontSize: 16),
          ),
          if (currentFile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                currentFile,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(BuildContext context, String message, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示歌曲菜单
  void _showItemMenu(BuildContext context, LocalAudio audio, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                audio.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(audio.artist),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () {
                Navigator.pop(context);
                _playAudio(context, audio);
              },
            ),
            ListTile(
              leading: Icon(
                audio.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: audio.isFavorite ? Colors.red : null,
              ),
              title: Text(audio.isFavorite ? '取消收藏' : '收藏'),
              onTap: () {
                Navigator.pop(context);
                ref.read(localMusicViewModelProvider.notifier).toggleFavorite(
                      audio.id!,
                      !audio.isFavorite,
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('从歌单移除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, audio, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(BuildContext context, LocalAudio audio, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text(
            '确定要从"本地音乐"歌单中移除"${audio.title}"吗？\n\n（不会删除原始文件）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(localMusicViewModelProvider.notifier).deleteLocalMusic(audio.id!);
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 播放音频
  void _playAudio(BuildContext context, LocalAudio audio) {
    // 导航到播放器页面，播放本地音频
    // 使用 localId 参数标识本地音频
    context.push('/player?localId=${audio.id}');
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
