// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 发现页面 ViewModel
///
/// 职责：
/// 1. 加载B站音乐区热门内容
/// 2. 加载个性化推荐
/// 3. 加载最新发布

@ProviderFor(ExploreViewModel)
final exploreViewModelProvider = ExploreViewModelProvider._();

/// 发现页面 ViewModel
///
/// 职责：
/// 1. 加载B站音乐区热门内容
/// 2. 加载个性化推荐
/// 3. 加载最新发布
final class ExploreViewModelProvider
    extends $AsyncNotifierProvider<ExploreViewModel, ExploreState> {
  /// 发现页面 ViewModel
  ///
  /// 职责：
  /// 1. 加载B站音乐区热门内容
  /// 2. 加载个性化推荐
  /// 3. 加载最新发布
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

String _$exploreViewModelHash() => r'6aabd736e85f1151ef42f9b12f807e8ea12e7375';

/// 发现页面 ViewModel
///
/// 职责：
/// 1. 加载B站音乐区热门内容
/// 2. 加载个性化推荐
/// 3. 加载最新发布

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

/// BackendApiClient Provider (复用 SearchViewModel 的)

@ProviderFor(exploreBackendApiClient)
final exploreBackendApiClientProvider = ExploreBackendApiClientProvider._();

/// BackendApiClient Provider (复用 SearchViewModel 的)

final class ExploreBackendApiClientProvider
    extends
        $FunctionalProvider<
          BackendApiClient,
          BackendApiClient,
          BackendApiClient
        >
    with $Provider<BackendApiClient> {
  /// BackendApiClient Provider (复用 SearchViewModel 的)
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
