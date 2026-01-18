import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/audio_provider.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 播放列表页面
///
/// 显示本地音频播放列表，支持播放和删除操作
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放列表',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: ListView.builder(
        itemCount: provider.playlist.length,
        itemBuilder: (context, index) {
          final audio = provider.playlist[index];
          return ListTile(
            title: Text(
              audio.title,
              style: TextStyle(
                fontSize: Dimens.fontSizeMedium,
              ),
            ),
            subtitle: Text(
              '艺术家：${audio.artist}',
              style: TextStyle(
                fontSize: Dimens.fontSizeSmall,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => provider.removeFromPlaylist(audio.id!),
            ),
            onTap: () => provider.playAudio(index),
          );
        },
      ),
    );
  }
}
