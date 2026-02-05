import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 歌单详情页面
///
/// 显示指定歌单的详细信息和音频列表
class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '歌单详情',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Center(
        child: Text('歌单 ID: $playlistId\n详情待实现'),
      ),
    );
  }
}
