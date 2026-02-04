import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/widgets/controls_panel.dart';
import 'package:demo/presentation/widgets/player_action_bar.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首页
///
/// 应用主页面，包含音频播放器和导航功能
/// 使用 Riverpod 的 PlayerViewModel
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// 处理文件选择器
  Future<void> _handleFilePicker(BuildContext context, WidgetRef ref) async {
    try {
      // TODO: 实现文件选择器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件选择器待实现')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // 顶部应用栏
      appBar: AppBar(
        title: Text(
          'ListenVision',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: UIConstants.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 文件选择按钮
          IconButton(
            icon: const Icon(Icons.file_upload),
            iconSize: UIConstants.iconMedium,
            onPressed: () => _handleFilePicker(context, ref),
          ),
          // 发现按钮
          IconButton(
            icon: const Icon(Icons.explore),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/explore'),
          ),
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/search'),
          ),
        ],
      ),

      // 侧边栏抽屉
      drawer: const MyDrawer(),

      // 核心内容：音频播放器
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          // 音频信息（封面、标题、艺术家）
          AudioInfo(),
          // 控制面板（进度条、播放控制）
          ControlsPanel(),
          // 底部操作栏（收藏、添加到歌单、更多）
          PlayerActionBar(),
        ],
      ),

      // 持久显示的底部按钮
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () => context.go('/playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            elevation: 4,
          ),
          child: Icon(
            Icons.list,
            size: UIConstants.iconMedium,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
