import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/models/local_audio.dart';
import 'package:demo/models/local_playable.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/widgets/controls_panel.dart';
import 'package:demo/presentation/widgets/player_action_bar.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/widgets/player/queue_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

import '../../../core/utils/blob_url.dart';
import '../../widgets/common/network_status_listener.dart';
import '../../widgets/player/subtitle_view.dart';

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
      // 1. 使用 FilePickerService 选择文件
      final filePickerService = ref.read(filePickerServiceProvider);
      final file = await filePickerService.pickAudioFile();

      if (file == null) {
        AppLogger.debug('HomePage', '用户取消文件选择');
        return; // 用户取消，静默返回
      }

      final metadataService = ref.read(metadataServiceProvider);

      late final String storageKey;
      late final String fileName;
      String? playableUrl;

      // Web 平台不能依赖本地路径，使用 bytes -> blob URL 播放
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        playableUrl = createBlobUrl(bytes, mimeType: 'audio/mpeg');
        storageKey = file.name;
        fileName = file.name;
        AppLogger.info('HomePage', 'Web 选择本地音频：${file.name}, blobUrl=$playableUrl');
      } else {
        // Android 平台：XFile.path 可能是 content:// URI，需要使用 readAsBytes() 读取
        // 其他平台（Windows/macOS/Linux）：使用文件路径
        final isAndroid = !kIsWeb && Platform.isAndroid;
        
        if (isAndroid) {
          // Android: 使用 bytes 方式处理 content:// URI
          fileName = file.name;
          storageKey = file.path; // 仍使用 path 作为存储键（用于数据库去重）
          
          AppLogger.info('HomePage', 'Android 选择本地音频：${file.name}, path=${file.path}');
          
          // 从 bytes 读取元数据
          final bytes = await file.readAsBytes();
          final metadata = await metadataService.extractFromBytes(
            bytes: bytes,
            fileName: fileName,
          );
          
          // 创建 LocalAudio 对象
          final localAudio = LocalAudio(
            filePath: storageKey,
            url: playableUrl,
            title: metadata.title.isNotEmpty ? metadata.title : _getFileName(storageKey),
            artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
            duration: metadata.duration ?? 0,
            albumArt: metadata.cover,
          );
          
          // 保存到"本地音乐"歌单（如果未导入）
          final localMusicRepo = ref.read(localMusicRepositoryProvider);
          final isImported = await localMusicRepo.isFileImported(storageKey);
          
          if (!isImported) {
            await localMusicRepo.addLocalMusic(localAudio);
            AppLogger.info('HomePage', '已保存到本地音乐歌单');
          } else {
            AppLogger.info('HomePage', '音频已存在于本地音乐歌单，跳过保存');
          }
          
          // 创建 PlayableAudio 并添加到队列末尾
          final playable = LocalPlayable(localAudio);
          await ref.read(queueViewModelProvider.notifier).add(
            playable,
            playImmediately: false,
          );
          
          // 开始播放（播放刚添加的最后一首）
          final queueState = ref.read(queueViewModelProvider);
          final newIndex = queueState.queue.length - 1;
          await ref.read(queueViewModelProvider.notifier).playAt(newIndex);
          
          AppLogger.info('HomePage', '已添加到播放队列并开始播放，索引：$newIndex');
          
          // 用户反馈
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已添加到播放列表：${localAudio.title}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        } else {
          // 桌面平台：使用文件路径
          storageKey = file.path;
          fileName = file.name;
          AppLogger.info('HomePage', '选择本地音频：$storageKey');
        }
      }

      // 2. 提取元数据（Web 端仅从文件名推断）
      final metadata = kIsWeb
          ? metadataService.extractMetadataFromPath(storageKey)
          : await metadataService.extractFromFile(storageKey);

      // 3. 创建 LocalAudio 对象
      final localAudio = LocalAudio(
        filePath: storageKey,
        url: playableUrl,
        title: metadata.title.isNotEmpty ? metadata.title : _getFileName(storageKey),
        artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
        duration: metadata.duration ?? 0,
        albumArt: metadata.cover,
      );

      // 4. 非 Web：保存到"本地音乐"歌单（如果未导入）
      if (!kIsWeb) {
        final localMusicRepo = ref.read(localMusicRepositoryProvider);
        final isImported = await localMusicRepo.isFileImported(storageKey);

        if (!isImported) {
          await localMusicRepo.addLocalMusic(localAudio);
          AppLogger.info('HomePage', '已保存到本地音乐歌单');
        } else {
          AppLogger.info('HomePage', '音频已存在于本地音乐歌单，跳过保存');
        }
      } else {
        AppLogger.warn('HomePage', 'Web 平台：仅支持会话内播放，不持久化导入到本地音乐歌单');
      }

      // 5. 创建 PlayableAudio 并添加到队列末尾
      final playable = LocalPlayable(localAudio);
      await ref.read(queueViewModelProvider.notifier).add(
        playable,
        playImmediately: false, // 添加到末尾，不清空队列
      );

      // 6. 开始播放（播放刚添加的最后一首）
      final queueState = ref.read(queueViewModelProvider);
      final newIndex = queueState.queue.length - 1;
      await ref.read(queueViewModelProvider.notifier).playAt(newIndex);

      AppLogger.info('HomePage', '已添加到播放队列并开始播放，索引：$newIndex');

      // 7. 用户反馈
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加到播放列表：${localAudio.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('HomePage', '导入失败：$e', stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：${e.toString()}')),
        );
      }
    }
  }

  /// 辅助方法：从文件路径提取文件名（不含扩展名）
  String _getFileName(String filePath) {
    final fileName = filePath.split(RegExp(r'[\/\\]')).last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  /// 处理 URL 参数，自动播放音频
  Future<void> _handleUrlParams() async {
    try {
      // 使用 GoRouterState 获取当前路由的查询参数
      final goRouter = GoRouter.of(context);
      final uri = goRouter.state.uri;

      AppLogger.debug('HomePage', '处理 URL 参数：$uri');

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
        AppLogger.debug('HomePage', '参数已处理过：$currentParam');
        return;
      }
      _processedParam = currentParam;

      AppLogger.info('HomePage', '开始播放 - 参数：$currentParam');

      if (bvid != null) {
        await _playOnlineAudio(bvid);
      } else if (localId != null) {
        await _playLocalAudio(localId);
      }
    } catch (e) {
      AppLogger.error('HomePage', '处理 URL 参数失败：$e');
    }
  }

  /// 播放在线音频
  Future<void> _playOnlineAudio(String bvid) async {
    try {
      AppLogger.info('HomePage', '根据 URL 参数播放在线音频：$bvid');

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

      AppLogger.info('HomePage', '在线音频播放成功：${audio.title}');
    } catch (e) {
      AppLogger.error('HomePage', '播放在线音频失败：$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败：$e')),
        );
      }
    }
  }

  /// 播放本地音频
  Future<void> _playLocalAudio(String localId) async {
    try {
      AppLogger.info('HomePage', '根据 URL 参数播放本地音频：$localId');

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
        throw Exception('本地音频不存在或尚未加载：$localId');
      }

      // 开始播放
      final playerNotifier = ref.read(playerViewModelProvider.notifier);
      await playerNotifier.playLocalAudio(
        localAudio.filePath,
        title: localAudio.title,
        artist: localAudio.artist,
        albumArt: localAudio.albumArt,
      );

      AppLogger.info('HomePage', '本地音频播放成功：${localAudio.title}');
    } catch (e) {
      AppLogger.error('HomePage', '播放本地音频失败：$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败：$e')),
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
          // 网络状态图标
          const NetworkStatusIcon(),
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
      body: SafeArea(
        child: Column(
          children: [
            // 音频信息（封面、标题、艺术家）- 自适应高度
            const Flexible(
              flex: 3,
              child: AudioInfo(),
            ),

            // 字幕展示区 - 固定高度
            SizedBox(
              height: 100,
              child: SubtitleView(
                onSeek: (position) {
                  ref.read(playerViewModelProvider.notifier).seek(position);
                },
              ),
            ),

            // 控制面板（进度条、播放控制）
            const ControlsPanel(),

            // 底部操作栏（收藏、添加到歌单、更多）
            const PlayerActionBar(),
          ],
        ),
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
