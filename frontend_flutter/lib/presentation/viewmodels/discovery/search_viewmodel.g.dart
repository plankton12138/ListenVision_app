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

String _$searchViewModelHash() => r'fb462a1bd8d27327facdaafcdb05de54b6029e51';

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
