// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_detail_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理

@ProviderFor(PlaylistDetailViewModel)
final playlistDetailViewModelProvider = PlaylistDetailViewModelFamily._();

/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理
final class PlaylistDetailViewModelProvider
    extends
        $AsyncNotifierProvider<PlaylistDetailViewModel, PlaylistDetailState> {
  /// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
  ///
  /// 负责单个歌单的详情展示和管理
  PlaylistDetailViewModelProvider._({
    required PlaylistDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playlistDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistDetailViewModelHash();

  @override
  String toString() {
    return r'playlistDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaylistDetailViewModel create() => PlaylistDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is PlaylistDetailViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistDetailViewModelHash() =>
    r'899e5b08c3aa6c930d403c9b4937453eb16a6181';

/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理

final class PlaylistDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaylistDetailViewModel,
          AsyncValue<PlaylistDetailState>,
          PlaylistDetailState,
          FutureOr<PlaylistDetailState>,
          String
        > {
  PlaylistDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'playlistDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
  ///
  /// 负责单个歌单的详情展示和管理

  PlaylistDetailViewModelProvider call(String playlistId) =>
      PlaylistDetailViewModelProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistDetailViewModelProvider';
}

/// 歌单详情 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责单个歌单的详情展示和管理

abstract class _$PlaylistDetailViewModel
    extends $AsyncNotifier<PlaylistDetailState> {
  late final _$args = ref.$arg as String;
  String get playlistId => _$args;

  FutureOr<PlaylistDetailState> build(String playlistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PlaylistDetailState>, PlaylistDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlaylistDetailState>, PlaylistDetailState>,
              AsyncValue<PlaylistDetailState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
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
