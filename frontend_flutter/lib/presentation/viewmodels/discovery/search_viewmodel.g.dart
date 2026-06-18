// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索 ViewModel
///
/// 直接调用 B站 API，搜索历史本地存储。

@ProviderFor(SearchViewModel)
final searchViewModelProvider = SearchViewModelProvider._();

/// 搜索 ViewModel
///
/// 直接调用 B站 API，搜索历史本地存储。
final class SearchViewModelProvider
    extends $AsyncNotifierProvider<SearchViewModel, SearchState> {
  /// 搜索 ViewModel
  ///
  /// 直接调用 B站 API，搜索历史本地存储。
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

String _$searchViewModelHash() => r'ba78148db35d7dbdc1a929a9a9554f838aa8dfd1';

/// 搜索 ViewModel
///
/// 直接调用 B站 API，搜索历史本地存储。

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
