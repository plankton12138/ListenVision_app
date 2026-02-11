// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExploreViewModel)
final exploreViewModelProvider = ExploreViewModelProvider._();

final class ExploreViewModelProvider
    extends $AsyncNotifierProvider<ExploreViewModel, ExploreState> {
  ExploreViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreViewModelHash();

  @$internal
  @override
  ExploreViewModel create() => ExploreViewModel();
}

String _$exploreViewModelHash() => r'722d192888492a9b1fdf703780848b38a2dfca5e';

abstract class _$ExploreViewModel extends $AsyncNotifier<ExploreState> {
  FutureOr<ExploreState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExploreState>, ExploreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExploreState>, ExploreState>,
              AsyncValue<ExploreState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(NeteaseExploreViewModel)
final neteaseExploreViewModelProvider = NeteaseExploreViewModelProvider._();

final class NeteaseExploreViewModelProvider
    extends
        $AsyncNotifierProvider<NeteaseExploreViewModel, NeteaseExploreState> {
  NeteaseExploreViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'neteaseExploreViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$neteaseExploreViewModelHash();

  @$internal
  @override
  NeteaseExploreViewModel create() => NeteaseExploreViewModel();
}

String _$neteaseExploreViewModelHash() =>
    r'a56f815c35712989d9f939bfe6ef1d0252b7f119';

abstract class _$NeteaseExploreViewModel
    extends $AsyncNotifier<NeteaseExploreState> {
  FutureOr<NeteaseExploreState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NeteaseExploreState>, NeteaseExploreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NeteaseExploreState>, NeteaseExploreState>,
              AsyncValue<NeteaseExploreState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(exploreBackendApiClient)
final exploreBackendApiClientProvider = ExploreBackendApiClientProvider._();

final class ExploreBackendApiClientProvider
    extends
        $FunctionalProvider<
          BackendApiClient,
          BackendApiClient,
          BackendApiClient
        >
    with $Provider<BackendApiClient> {
  ExploreBackendApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreBackendApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreBackendApiClientHash();

  @$internal
  @override
  $ProviderElement<BackendApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackendApiClient create(Ref ref) {
    return exploreBackendApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackendApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackendApiClient>(value),
    );
  }
}

String _$exploreBackendApiClientHash() =>
    r'7805fa58748128a739020cd7748c0cb77d04b253';
