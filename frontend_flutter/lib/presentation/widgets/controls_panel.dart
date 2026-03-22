import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listenvision/presentation/widgets/volume_slider.dart';
import 'package:listenvision/presentation/widgets/speed_button.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/models/playable_audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';

/// 播放控制面板组件
///
/// 显示播放进度、时间显示和控制按钮（上一曲、播放/暂停、下一曲）
class ControlsPanel extends ConsumerWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playbackViewModelProvider);
    final playerViewModel = ref.read(playbackViewModelProvider.notifier);

    // 无播放内容时显示提示
    if (playerState.currentPlayable == null && playerState.isIdle) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            '暂无播放内容',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 时间显示（当前位置/总时长）
        _buildTimeDisplay(context, playerState),
        // 进度条
        _buildProgressBar(context, playerState, playerViewModel),
        // 控制按钮
        _buildControlButtons(context, ref, playerState, playerViewModel),
      ],
    );
  }

  /// 播放上一首
  void _playPrevious(BuildContext context, WidgetRef ref) {
    final playbackNotifier = ref.read(playbackViewModelProvider.notifier);
    playbackNotifier.previous();
  }

  /// 播放下一首
  void _playNext(BuildContext context, WidgetRef ref) {
    final playbackNotifier = ref.read(playbackViewModelProvider.notifier);
    playbackNotifier.next();
  }

  /// 播放可播放音频
  void _playPlayable(BuildContext context, WidgetRef ref, PlayableAudio playable) {
    final playerViewModel = ref.read(playbackViewModelProvider.notifier);

    if (playable.isOnline) {
      // 在线音频
      if (playable is OnlinePlayable) {
        playerViewModel.playOnlineAudio(
          audio: playable.original,
          proxyUrl: playable.proxyUrl,
        );
      }
    } else {
      // 本地音频 - 使用 url 属性获取文件路径，传递已保存的元数据
      playerViewModel.playLocalAudio(
        playable.url,
        title: playable.title,
        artist: playable.artist,
        albumArt: playable.coverData,
      );
    }
  }

  /// 构建时间显示
  ///
  /// 优先显示用户友好的状态消息和错误提示
  /// 当有有效时长和位置时优先显示时间，而不是状态
  Widget _buildTimeDisplay(
    BuildContext context,
    playerState,
  ) {
    final duration = playerState.duration ?? Duration.zero;
    final position = playerState.position;
    final hasValidDuration = duration > Duration.zero;
    final hasValidPosition = position >= Duration.zero;
    final hasPlaybackProgress = hasValidPosition && (position > Duration.zero || playerState.isPlaying);

    // UX改进：优先显示错误状态（最优先）
    if (playerState.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            playerState.statusMessage.isNotEmpty
                ? playerState.statusMessage
                : '播放失败',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    // 修复：如果有有效的时间信息，优先显示时间（而不是状态消息）
    // 这样可以避免自动切歌后显示"播放完成"或"加载中"而不显示时间
    if (hasValidDuration && hasPlaybackProgress) {
      return Text(
        '${position.toString().split('.')[0]} / '
        '${duration.toString().split('.')[0]}',
      );
    }

    if (!hasValidDuration && hasPlaybackProgress) {
      return Text(
        '${position.toString().split('.')[0]} / --:--',
      );
    }

    // UX改进：显示状态消息（正在播放、正在加载等）
    if (playerState.statusMessage.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            playerState.statusMessage,
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      );
    }

    // 加载状态（来自 PlaybackController）
    if (playerState.isLoading) {
      return const Text(
        '加载中...',
        style: TextStyle(color: Colors.blue),
      );
    }

    // 缓冲状态（audioplayers 不直接提供，通过加载状态推断）
    if (playerState.isBuffering) {
      return const Text(
        '缓冲中...',
        style: TextStyle(color: Colors.orange),
      );
    }

    // 已完成状态 - 只有在没有有效时长时才显示
    if (playerState.isCompleted && !hasValidDuration) {
      return const Text(
        '播放完成',
        style: TextStyle(color: Colors.green),
      );
    }

    // 空闲状态
    if (playerState.isIdle) {
      return const Text(
        '就绪',
        style: TextStyle(color: Colors.grey),
      );
    }

    // 默认显示时间（即使为0）
    return Text(
      '${position.toString().split('.')[0]} / '
      '${duration.toString().split('.')[0]}',
    );
  }

  /// 构建进度条
  ///
  /// 在有状态消息或错误时显示友好提示
  /// 只要有有效时长就显示进度条，而不是加载指示器
  Widget _buildProgressBar(
    BuildContext context,
    playerState,
    playerViewModel,
  ) {
    final duration = playerState.duration ?? Duration.zero;
    final durationSec = duration.inSeconds;
    final positionSec = playerState.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

    // 修复：只要有有效时长，就显示进度条（即使正在加载）
    // 这样可以避免音频已经开始播放但进度条仍显示加载中的问题
    final hasValidDuration = durationSec > 0;

    // UX改进：有错误时显示重试提示
    if (playerState.hasError) {
      return SizedBox(
        height: 48,
        child: Center(
          child: TextButton.icon(
            onPressed: () {
              AppLogger.logButtonClick('重试', 'ControlsPanel');
              // 使用 ViewModel 的 clearError 方法而不是 state 的扩展方法
              playerViewModel.clearError();
              playerViewModel.togglePlayPause();
            },
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text(
              '点击重试',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      );
    }

    // 修复：如果有有效时长，显示进度条（优先于状态消息和加载状态）
    if (hasValidDuration) {
      return Slider(
        value: safeValue,
        min: 0,
        max: durationSec.toDouble(),
        activeColor: Colors.green,
        inactiveColor: Colors.grey,
        onChanged: (value) {
          AppLogger.logButtonClick('进度条', 'ControlsPanel',
            parameters: {'position': value.toInt()});
          playerViewModel.seek(Duration(seconds: value.toInt()));
        },
      );
    }

    // UX改进：有状态消息时显示提示（没有有效时长时）
    if (playerState.statusMessage.isNotEmpty) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 加载或缓冲时显示进度指示器（没有有效时长时）
    if (playerState.isLoading || playerState.isBuffering) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // 默认显示不可用的进度条
    return Slider(
      value: 0,
      min: 0,
      max: 1.0,
      activeColor: Colors.green,
      inactiveColor: Colors.grey,
      onChanged: null,
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(BuildContext context, WidgetRef ref, playerState, playerViewModel) {
    final subtitleState = ref.watch(subtitleViewModelProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：播放控制按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 字幕按钮
            _buildSubtitleButton(context, ref, subtitleState),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick('上一首', 'ControlsPanel');
                _playPrevious(context, ref);
              },
            ),
            IconButton(
              icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick(
                  playerState.isPlaying ? '暂停' : '播放',
                  'ControlsPanel',
                );
                playerViewModel.togglePlayPause();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick('下一首', 'ControlsPanel');
                _playNext(context, ref);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 第二行：Phase 3B 播放控制（音量和倍速）
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            // 音量滑块
            VolumeSlider(),

            SizedBox(width: 24),

            // 倍速按钮
            SpeedButton(),
          ],
        ),
      ],
    );
  }

  /// 构建字幕按钮（类似B站字幕选择器）
  Widget _buildSubtitleButton(BuildContext context, WidgetRef ref, SubtitleState subtitleState) {
    final hasSubtitles = subtitleState.data?.subtitles.isNotEmpty ?? false;
    final isEnabled = subtitleState.isSubtitleEnabled;
    final isLoading = subtitleState.isLoading;
    final needLogin = subtitleState.needLogin;
    final hasError = subtitleState.error != null;

    // 图标颜色：有字幕且开启时高亮，需要登录时显示警告色
    Color iconColor;
    if (isLoading) {
      iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    } else if (needLogin) {
      iconColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.7);
    } else if (hasSubtitles && isEnabled) {
      iconColor = Theme.of(context).colorScheme.primary;
    } else {
      iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return PopupMenuButton<String>(
      icon: Icon(
        isLoading ? Icons.hourglass_empty : Icons.subtitles,
        color: iconColor,
        size: 28,
      ),
      tooltip: '字幕',
      onSelected: (value) {
        final notifier = ref.read(subtitleViewModelProvider.notifier);
        if (value == 'off') {
          notifier.setSubtitleEnabled(false);
        } else if (value == 'login') {
          // 跳转到绑定页面
          // TODO: 导航到B站绑定页面
        } else {
          notifier.switchLanguage(value);
          notifier.setSubtitleEnabled(true);
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        // 关闭选项
        items.add(
          PopupMenuItem(
            value: 'off',
            child: Row(
              children: [
                Icon(
                  !isEnabled ? Icons.check : null,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('关闭'),
              ],
            ),
          ),
        );

        // 需要登录提示
        if (needLogin && !hasSubtitles) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              enabled: false,
              value: 'need_login',
              child: Row(
                children: [
                  Icon(
                    Icons.login_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '需绑定B站账号',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 错误提示
        if (hasError && !hasSubtitles) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              enabled: false,
              value: 'error',
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '获取失败',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 无字幕提示
        if (!hasSubtitles && !needLogin && !hasError) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              enabled: false,
              value: 'no_subtitle',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '该视频无字幕',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 分隔线
        if (hasSubtitles) {
          items.add(const PopupMenuDivider());
        }

        // 字幕语言选项
        final subtitles = subtitleState.data?.subtitles ?? [];
        for (final track in subtitles) {
          items.add(
            PopupMenuItem(
              value: track.lan,
              child: Row(
                children: [
                  Icon(
                    isEnabled && subtitleState.activeTrack?.lan == track.lan
                        ? Icons.check
                        : null,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(track.displayName),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
