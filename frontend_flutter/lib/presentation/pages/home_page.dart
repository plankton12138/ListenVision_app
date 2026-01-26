// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/core/utils/file_picker_helper.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/widgets/controls_panel.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 首页
///
/// 应用主页面，包含音频播放器和导航功能
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 处理文件选择器
  Future<void> _handleFilePicker(BuildContext context) async {
    final filePicker = context.read<FilePickerService>();
    final audioProvider = context.read<AudioProvider>();

    try {
      final filePath = await filePicker.pickAudioFile();
      if (filePath != null) {
        await audioProvider.loadAudio(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _handleFilePicker(context),
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
          AudioInfo(),
          ControlsPanel(),
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
