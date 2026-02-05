// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchBackendApiClientHash() =>
    r'36f3df94226127e8b65e48826003cc5f8e1fc436';

/// BackendApiClient Provider
///
/// Copied from [searchBackendApiClient].
@ProviderFor(searchBackendApiClient)
final searchBackendApiClientProvider =
    AutoDisposeProvider<BackendApiClient>.internal(
      searchBackendApiClient,
      name: r'searchBackendApiClientProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchBackendApiClientHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchBackendApiClientRef = AutoDisposeProviderRef<BackendApiClient>;
String _$searchViewModelHash() => r'fd46b28a0ede30bf572ef010eb31a2eefd0d4039';

/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议
///
/// Copied from [SearchViewModel].
@ProviderFor(SearchViewModel)
final searchViewModelProvider =
    AutoDisposeNotifierProvider<SearchViewModel, SearchState>.internal(
      SearchViewModel.new,
      name: r'searchViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchViewModel = AutoDisposeNotifier<SearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
