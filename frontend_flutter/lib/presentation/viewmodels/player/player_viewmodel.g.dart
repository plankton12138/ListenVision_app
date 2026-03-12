// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放器 ViewModel
///
/// 职责：
/// 1. 播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态管理
/// 4. 播放设置（音量、倍速）
///
/// 依赖：
/// - AudioPlayerService: 底层播放器封装
/// - SharedStorageService: 持久化播放设置

@ProviderFor(PlayerViewModel)
final playerViewModelProvider = PlayerViewModelProvider._();

/// 播放器 ViewModel
///
/// 职责：
/// 1. 播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态管理
/// 4. 播放设置（音量、倍速）
///
/// 依赖：
/// - AudioPlayerService: 底层播放器封装
/// - SharedStorageService: 持久化播放设置
final class PlayerViewModelProvider
    extends $NotifierProvider<PlayerViewModel, PlayerState> {
  /// 播放器 ViewModel
  ///
  /// 职责：
  /// 1. 播放控制（play/pause/stop/seek）
  /// 2. 音频源管理
  /// 3. 播放状态管理
  /// 4. 播放设置（音量、倍速）
  ///
  /// 依赖：
  /// - AudioPlayerService: 底层播放器封装
  /// - SharedStorageService: 持久化播放设置
  PlayerViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerViewModelHash();

  @$internal
  @override
  PlayerViewModel create() => PlayerViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerState>(value),
    );
  }
}

String _$playerViewModelHash() => r'809f824c29e2dcb88abcfa401bed438d9e1090d5';

/// 播放器 ViewModel
///
/// 职责：
/// 1. 播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态管理
/// 4. 播放设置（音量、倍速）
///
/// 依赖：
/// - AudioPlayerService: 底层播放器封装
/// - SharedStorageService: 持久化播放设置

abstract class _$PlayerViewModel extends $Notifier<PlayerState> {
  PlayerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerState, PlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerState, PlayerState>,
              PlayerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// AudioPlayerService Provider

@ProviderFor(audioPlayerService)
final audioPlayerServiceProvider = AudioPlayerServiceProvider._();

/// AudioPlayerService Provider

final class AudioPlayerServiceProvider
    extends
        $FunctionalProvider<
          AudioPlayerService,
          AudioPlayerService,
          AudioPlayerService
        >
    with $Provider<AudioPlayerService> {
  /// AudioPlayerService Provider
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

/// SharedStorageService Provider

@ProviderFor(sharedStorageService)
final sharedStorageServiceProvider = SharedStorageServiceProvider._();

/// SharedStorageService Provider

final class SharedStorageServiceProvider
    extends
        $FunctionalProvider<
          SharedStorageService,
          SharedStorageService,
          SharedStorageService
        >
    with $Provider<SharedStorageService> {
  /// SharedStorageService Provider
  SharedStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedStorageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedStorageServiceHash();

  @$internal
  @override
  $ProviderElement<SharedStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedStorageService create(Ref ref) {
    return sharedStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedStorageService>(value),
    );
  }
}

String _$sharedStorageServiceHash() =>
    r'df792e9db096eeedfe0f22cac72ea90a1712c709';
