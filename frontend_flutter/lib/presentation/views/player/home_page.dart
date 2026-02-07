import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/widgets/controls_panel.dart';
import 'package:demo/presentation/widgets/player_action_bar.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/widgets/player/queue_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首页
///
/// 应用主页面，包含音频播放器和导航功能
/// 使用 Riverpod 的 PlayerViewModel
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 已处理的参数，避免重复播放
  String? _processedParam;

  /// 处理文件选择器
  Future<void> _handleFilePicker(BuildContext context, WidgetRef ref) async {
    try {
      // 调用 LocalMusicViewModel 导入音频到本地音乐歌单
      await ref.read(localMusicViewModelProvider.notifier).importAudioFiles();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已导入到"本地音乐"歌单')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
    }
  }

  /// 处理 URL 参数，自动播放音频
  Future<void> _handleUrlParams() async {
    try {
      // 使用 GoRouterState 获取当前路由的查询参数
      final goRouter = GoRouter.of(context);
      final uri = goRouter.state.uri;

      AppLogger.debug('HomePage', '处理 URL 参数: $uri');

      final bvid = uri.queryParameters['bvid'];
      final localId = uri.queryParameters['localId'];

      AppLogger.debug('HomePage', '解析参数 - bvid: $bvid, localId: $localId');

      // 检查是否有参数需要处理
      if (bvid == null && localId == null) {
        AppLogger.debug('HomePage', '无播放参数，跳过');
        return;
      }

      // 检查是否已经处理过相同的参数
      final currentParam = bvid != null ? 'bvid:$bvid' : 'localId:$localId';
      if (_processedParam == currentParam) {
        AppLogger.debug('HomePage', '参数已处理过: $currentParam');
        return;
      }
      _processedParam = currentParam;

      AppLogger.info('HomePage', '开始播放 - 参数: $currentParam');

      if (bvid != null) {
        await _playOnlineAudio(bvid);
      } else if (localId != null) {
        await _playLocalAudio(localId);
      }
    } catch (e) {
      AppLogger.error('HomePage', '处理 URL 参数失败: $e');
    }
  }

  /// 播放在线音频
  Future<void> _playOnlineAudio(String bvid) async {
    try {
      AppLogger.info('HomePage', '根据 URL 参数播放在线音频: $bvid');

      // 获取音频信息
      final trackRepo = ref.read(trackRepositoryProvider);
      final track = await trackRepo.getTrackByBvid(bvid);

      // 转换为 Audio 对象
      final audio = Audio(
        id: track.bvid ?? bvid,
        title: track.title,
        artist: track.artist ?? '未知艺术家',
        duration: track.duration,
        coverUrl: track.coverUrl,
      );

      // 开始播放
      final playerNotifier = ref.read(playerViewModelProvider.notifier);
      await playerNotifier.playOnlineAudio(audio: audio);

      AppLogger.info('HomePage', '在线音频播放成功: ${audio.title}');
    } catch (e) {
      AppLogger.error('HomePage', '播放在线音频失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  /// 播放本地音频
  Future<void> _playLocalAudio(String localId) async {
    try {
      AppLogger.info('HomePage', '根据 URL 参数播放本地音频: $localId');

      // 从本地音乐 ViewModel 获取音频
      final localMusicAsync = ref.read(localMusicViewModelProvider);

      final localAudio = await localMusicAsync.whenOrNull(
        data: (state) async {
          return state.map(
            initial: (_) => null,
            loading: (_) => null,
            loaded: (data) {
              try {
                return data.audios.firstWhere((a) => a.id.toString() == localId);
              } catch (_) {
                return null;
              }
            },
            importing: (_) => null,
            error: (_) => null,
          );
        },
      );

      if (localAudio == null) {
        throw Exception('本地音频不存在或尚未加载: $localId');
      }

      // 开始播放
      final playerNotifier = ref.read(playerViewModelProvider.notifier);
      await playerNotifier.playLocalAudio(
        localAudio.filePath,
        title: localAudio.title,
        artist: localAudio.artist,
      );

      AppLogger.info('HomePage', '本地音频播放成功: ${localAudio.title}');
    } catch (e) {
      AppLogger.error('HomePage', '播放本地音频失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 延迟处理，等待页面构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleUrlParams();
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // URL 参数变化时重新处理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleUrlParams();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 中获取查询参数，这样更可靠
    final goRouterState = GoRouter.of(context);
    final uri = goRouterState.state.uri;
    final bvid = uri.queryParameters['bvid'];
    final localId = uri.queryParameters['localId'];

    // 如果有参数且未处理，延迟处理播放
    if ((bvid != null || localId != null)) {
      final currentParam = bvid != null ? 'bvid:$bvid' : 'localId:$localId';
      if (_processedParam != currentParam) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleUrlParams();
        });
      }
    }

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
          onPressed: () {
            AppLogger.logButtonClick('播放列表', 'HomePage');
            QueueBottomSheet.show(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            elevation: 4,
          ),
          child: Icon(
            Icons.queue_music,
            size: UIConstants.iconMedium,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
