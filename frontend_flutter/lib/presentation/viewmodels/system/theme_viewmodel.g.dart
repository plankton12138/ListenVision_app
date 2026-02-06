// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色/跟随系统）

@ProviderFor(ThemeViewModel)
final themeViewModelProvider = ThemeViewModelProvider._();

/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色/跟随系统）
final class ThemeViewModelProvider
    extends $NotifierProvider<ThemeViewModel, AppThemeMode> {
  /// 主题 ViewModel
  ///
  /// 负责应用的主题切换（浅色/深色/跟随系统）
  ThemeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeViewModelHash();

  @$internal
  @override
  ThemeViewModel create() => ThemeViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeMode>(value),
    );
  }
}

String _$themeViewModelHash() => r'eeb191a2599489f2d1995edd62af3009dd14f79c';

/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色/跟随系统）

abstract class _$ThemeViewModel extends $Notifier<AppThemeMode> {
  AppThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppThemeMode, AppThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeMode, AppThemeMode>,
              AppThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider 定义

@ProviderFor(themeStorageService)
final themeStorageServiceProvider = ThemeStorageServiceProvider._();

/// Provider 定义

final class ThemeStorageServiceProvider
    extends
        $FunctionalProvider<
          SharedStorageService,
          SharedStorageService,
          SharedStorageService
        >
    with $Provider<SharedStorageService> {
  /// Provider 定义
  ThemeStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeStorageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeStorageServiceHash();

  @$internal
  @override
  $ProviderElement<SharedStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedStorageService create(Ref ref) {
    return themeStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedStorageService>(value),
    );
  }
}

String _$themeStorageServiceHash() =>
    r'6c443fb7b086e3cd17d474979eeee6353dc00faf';
