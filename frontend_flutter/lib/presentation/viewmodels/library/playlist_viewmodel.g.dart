// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责歌单、收藏、播放队列的状态管理

@ProviderFor(PlaylistViewModel)
final playlistViewModelProvider = PlaylistViewModelProvider._();

/// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责歌单、收藏、播放队列的状态管理
final class PlaylistViewModelProvider
    extends $AsyncNotifierProvider<PlaylistViewModel, PlaylistState> {
  /// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
  ///
  /// 负责歌单、收藏、播放队列的状态管理
  PlaylistViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistViewModelHash();

  @$internal
  @override
  PlaylistViewModel create() => PlaylistViewModel();
}

String _$playlistViewModelHash() => r'f84aabd66d5f94084dfca199b39762205e115166';

/// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责歌单、收藏、播放队列的状态管理

abstract class _$PlaylistViewModel extends $AsyncNotifier<PlaylistState> {
  FutureOr<PlaylistState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlaylistState>, PlaylistState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlaylistState>, PlaylistState>,
              AsyncValue<PlaylistState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider定义

@ProviderFor(playlistRepository)
final playlistRepositoryProvider = PlaylistRepositoryProvider._();

/// Provider定义

final class PlaylistRepositoryProvider
    extends
        $FunctionalProvider<
          PlaylistRepository,
          PlaylistRepository,
          PlaylistRepository
        >
    with $Provider<PlaylistRepository> {
  /// Provider定义
  PlaylistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaylistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaylistRepository create(Ref ref) {
    return playlistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistRepository>(value),
    );
  }
}

String _$playlistRepositoryHash() =>
    r'd94960eabb81afa084d6e1daccbf2bbd9d327dc5';

@ProviderFor(sharedStorageService)
final sharedStorageServiceProvider = SharedStorageServiceProvider._();

final class SharedStorageServiceProvider
    extends
        $FunctionalProvider<
          SharedStorageService,
          SharedStorageService,
          SharedStorageService
        >
    with $Provider<SharedStorageService> {
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
