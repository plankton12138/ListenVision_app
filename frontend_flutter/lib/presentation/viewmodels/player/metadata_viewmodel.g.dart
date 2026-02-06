// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 元数据加载 ViewModel
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
/// 2. 从网络加载在线音频封面
/// 3. 元数据缓存管理

@ProviderFor(MetadataViewModel)
final metadataViewModelProvider = MetadataViewModelProvider._();

/// 元数据加载 ViewModel
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
/// 2. 从网络加载在线音频封面
/// 3. 元数据缓存管理
final class MetadataViewModelProvider
    extends $NotifierProvider<MetadataViewModel, MetadataState> {
  /// 元数据加载 ViewModel
  ///
  /// 职责：
  /// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
  /// 2. 从网络加载在线音频封面
  /// 3. 元数据缓存管理
  MetadataViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metadataViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metadataViewModelHash();

  @$internal
  @override
  MetadataViewModel create() => MetadataViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetadataState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetadataState>(value),
    );
  }
}

String _$metadataViewModelHash() => r'b364b432b2ec4bc9b9f45dc780b7950dae18ea3a';

/// 元数据加载 ViewModel
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
/// 2. 从网络加载在线音频封面
/// 3. 元数据缓存管理

abstract class _$MetadataViewModel extends $Notifier<MetadataState> {
  MetadataState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MetadataState, MetadataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MetadataState, MetadataState>,
              MetadataState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// MetadataService Provider

@ProviderFor(metadataService)
final metadataServiceProvider = MetadataServiceProvider._();

/// MetadataService Provider

final class MetadataServiceProvider
    extends
        $FunctionalProvider<MetadataService, MetadataService, MetadataService>
    with $Provider<MetadataService> {
  /// MetadataService Provider
  MetadataServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metadataServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metadataServiceHash();

  @$internal
  @override
  $ProviderElement<MetadataService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MetadataService create(Ref ref) {
    return metadataService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetadataService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetadataService>(value),
    );
  }
}

String _$metadataServiceHash() => r'4e369d92cdc6db79b26c115d2eb0ca55aebc1a5b';
