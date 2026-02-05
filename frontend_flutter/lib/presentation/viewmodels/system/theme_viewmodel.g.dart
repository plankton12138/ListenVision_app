// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeStorageServiceHash() =>
    r'b128178b2951dad786055d8b089792651c43d0a7';

/// Provider 定义
///
/// Copied from [themeStorageService].
@ProviderFor(themeStorageService)
final themeStorageServiceProvider =
    AutoDisposeProvider<SharedStorageService>.internal(
      themeStorageService,
      name: r'themeStorageServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeStorageServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ThemeStorageServiceRef = AutoDisposeProviderRef<SharedStorageService>;
String _$themeViewModelHash() => r'37784180967b8fa6dc212272cbc34a754274918e';

/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色/跟随系统）
///
/// Copied from [ThemeViewModel].
@ProviderFor(ThemeViewModel)
final themeViewModelProvider =
    AutoDisposeNotifierProvider<ThemeViewModel, AppThemeMode>.internal(
      ThemeViewModel.new,
      name: r'themeViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeViewModel = AutoDisposeNotifier<AppThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
