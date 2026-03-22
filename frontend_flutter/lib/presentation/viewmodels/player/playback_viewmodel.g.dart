// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放控制器 ViewModel
///
/// 职责：
/// 1. 统一管理播放状态（播放/暂停/加载/完成）
/// 2. 当前播放音频信息
/// 3. 播放控制（play/pause/stop/seek/next/previous）
/// 4. 音量和倍速设置
///
/// 依赖：
/// - AudioPlayerService: 底层播放器
/// - QueueViewModel: 队列数据（只读取，不修改）
/// - SubtitleViewModel: 字幕管理

@ProviderFor(PlaybackViewModel)
final playbackViewModelProvider = PlaybackViewModelProvider._();

/// 播放控制器 ViewModel
///
/// 职责：
/// 1. 统一管理播放状态（播放/暂停/加载/完成）
/// 2. 当前播放音频信息
/// 3. 播放控制（play/pause/stop/seek/next/previous）
/// 4. 音量和倍速设置
///
/// 依赖：
/// - AudioPlayerService: 底层播放器
/// - QueueViewModel: 队列数据（只读取，不修改）
/// - SubtitleViewModel: 字幕管理
final class PlaybackViewModelProvider
    extends $NotifierProvider<PlaybackViewModel, PlaybackState> {
  /// 播放控制器 ViewModel
  ///
  /// 职责：
  /// 1. 统一管理播放状态（播放/暂停/加载/完成）
  /// 2. 当前播放音频信息
  /// 3. 播放控制（play/pause/stop/seek/next/previous）
  /// 4. 音量和倍速设置
  ///
  /// 依赖：
  /// - AudioPlayerService: 底层播放器
  /// - QueueViewModel: 队列数据（只读取，不修改）
  /// - SubtitleViewModel: 字幕管理
  PlaybackViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackViewModelHash();

  @$internal
  @override
  PlaybackViewModel create() => PlaybackViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackState>(value),
    );
  }
}

String _$playbackViewModelHash() => r'fe20610432cec1f5a37f97108f1ce10d50b23c03';

/// 播放控制器 ViewModel
///
/// 职责：
/// 1. 统一管理播放状态（播放/暂停/加载/完成）
/// 2. 当前播放音频信息
/// 3. 播放控制（play/pause/stop/seek/next/previous）
/// 4. 音量和倍速设置
///
/// 依赖：
/// - AudioPlayerService: 底层播放器
/// - QueueViewModel: 队列数据（只读取，不修改）
/// - SubtitleViewModel: 字幕管理

abstract class _$PlaybackViewModel extends $Notifier<PlaybackState> {
  PlaybackState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlaybackState, PlaybackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaybackState, PlaybackState>,
              PlaybackState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(audioPlayerService)
final audioPlayerServiceProvider = AudioPlayerServiceProvider._();

final class AudioPlayerServiceProvider
    extends
        $FunctionalProvider<
          AudioPlayerService,
          AudioPlayerService,
          AudioPlayerService
        >
    with $Provider<AudioPlayerService> {
  AudioPlayerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioPlayerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioPlayerServiceHash();

  @$internal
  @override
  $ProviderElement<AudioPlayerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AudioPlayerService create(Ref ref) {
    return audioPlayerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioPlayerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioPlayerService>(value),
    );
  }
}

String _$audioPlayerServiceHash() =>
    r'92102d1c8bbcc116200f5493d4e24bc7a5269b7f';
