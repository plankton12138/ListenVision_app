// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 歌单列表 Notifier
///
/// 管理用户歌单列表，使用 Riverpod 内置 AsyncValue<List<Playlist>>

@ProviderFor(PlaylistListNotifier)
final playlistListProvider = PlaylistListNotifierProvider._();

/// 歌单列表 Notifier
///
/// 管理用户歌单列表，使用 Riverpod 内置 AsyncValue<List<Playlist>>
final class PlaylistListNotifierProvider
    extends $AsyncNotifierProvider<PlaylistListNotifier, List<Playlist>> {
  /// 歌单列表 Notifier
  ///
  /// 管理用户歌单列表，使用 Riverpod 内置 AsyncValue<List<Playlist>>
  PlaylistListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistListNotifierHash();

  @$internal
  @override
  PlaylistListNotifier create() => PlaylistListNotifier();
}

String _$playlistListNotifierHash() =>
    r'96703bc70f6b6fa654b139ba14c718df4b4da9ba';

/// 歌单列表 Notifier
///
/// 管理用户歌单列表，使用 Riverpod 内置 AsyncValue<List<Playlist>>

abstract class _$PlaylistListNotifier extends $AsyncNotifier<List<Playlist>> {
  FutureOr<List<Playlist>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Playlist>>, List<Playlist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Playlist>>, List<Playlist>>,
              AsyncValue<List<Playlist>>,
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
    r'0a26317aff8d4e4c62085bd2cc2f9bcaca55a160';

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
