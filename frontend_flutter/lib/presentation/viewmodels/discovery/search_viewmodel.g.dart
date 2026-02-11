// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议

@ProviderFor(SearchViewModel)
final searchViewModelProvider = SearchViewModelProvider._();

/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议
final class SearchViewModelProvider
    extends $AsyncNotifierProvider<SearchViewModel, SearchState> {
  /// 搜索 ViewModel
  ///
  /// 职责：
  /// 1. B站网络搜索
  /// 2. 搜索历史管理
  /// 3. 搜索建议
  SearchViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchViewModelHash();

  @$internal
  @override
  SearchViewModel create() => SearchViewModel();
}

String _$searchViewModelHash() => r'ede60a7caee832a3f700cb480c227d3acbfa112c';

/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议

abstract class _$SearchViewModel extends $AsyncNotifier<SearchState> {
  FutureOr<SearchState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SearchState>, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SearchState>, SearchState>,
              AsyncValue<SearchState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// BackendApiClient Provider

@ProviderFor(searchBackendApiClient)
final searchBackendApiClientProvider = SearchBackendApiClientProvider._();

/// BackendApiClient Provider

final class SearchBackendApiClientProvider
    extends
        $FunctionalProvider<
          BackendApiClient,
          BackendApiClient,
          BackendApiClient
        >
    with $Provider<BackendApiClient> {
  /// BackendApiClient Provider
  SearchBackendApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchBackendApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchBackendApiClientHash();

  @$internal
  @override
  $ProviderElement<BackendApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackendApiClient create(Ref ref) {
    return searchBackendApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackendApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackendApiClient>(value),
    );
  }
}

String _$searchBackendApiClientHash() =>
    r'400a9c22fe4f28b72107667ce448b4202bc3e579';
