// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_music_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入

@ProviderFor(LocalMusicViewModel)
final localMusicViewModelProvider = LocalMusicViewModelProvider._();

/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入
final class LocalMusicViewModelProvider
    extends $AsyncNotifierProvider<LocalMusicViewModel, LocalMusicState> {
  /// 本地音乐 ViewModel
  ///
  /// 负责本地音乐歌单的管理和导入
  LocalMusicViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localMusicViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localMusicViewModelHash();

  @$internal
  @override
  LocalMusicViewModel create() => LocalMusicViewModel();
}

String _$localMusicViewModelHash() =>
    r'7645468a9685653f5d2f576d64dc5d0e68ed902a';

/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入

abstract class _$LocalMusicViewModel extends $AsyncNotifier<LocalMusicState> {
  FutureOr<LocalMusicState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LocalMusicState>, LocalMusicState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LocalMusicState>, LocalMusicState>,
              AsyncValue<LocalMusicState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider 定义

@ProviderFor(localMusicRepository)
final localMusicRepositoryProvider = LocalMusicRepositoryProvider._();

/// Provider 定义

final class LocalMusicRepositoryProvider
    extends
        $FunctionalProvider<
          LocalMusicRepository,
          LocalMusicRepository,
          LocalMusicRepository
        >
    with $Provider<LocalMusicRepository> {
  /// Provider 定义
  LocalMusicRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localMusicRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localMusicRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalMusicRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalMusicRepository create(Ref ref) {
    return localMusicRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalMusicRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalMusicRepository>(value),
    );
  }
}

String _$localMusicRepositoryHash() =>
    r'c3f860f2a2a62a628777f8457aab0b607a6276af';
