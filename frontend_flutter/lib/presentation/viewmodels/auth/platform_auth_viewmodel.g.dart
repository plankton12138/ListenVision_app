// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 平台认证 ViewModel
///
/// 负责第三方平台（B站）的认证

@ProviderFor(PlatformAuthViewModel)
final platformAuthViewModelProvider = PlatformAuthViewModelProvider._();

/// 平台认证 ViewModel
///
/// 负责第三方平台（B站）的认证
final class PlatformAuthViewModelProvider
    extends $AsyncNotifierProvider<PlatformAuthViewModel, PlatformAuthState> {
  /// 平台认证 ViewModel
  ///
  /// 负责第三方平台（B站）的认证
  PlatformAuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformAuthViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformAuthViewModelHash();

  @$internal
  @override
  PlatformAuthViewModel create() => PlatformAuthViewModel();
}

String _$platformAuthViewModelHash() =>
    r'55237f31f41e861981e0fb3d091ec02239d41705';

/// 平台认证 ViewModel
///
/// 负责第三方平台（B站）的认证

abstract class _$PlatformAuthViewModel
    extends $AsyncNotifier<PlatformAuthState> {
  FutureOr<PlatformAuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PlatformAuthState>, PlatformAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlatformAuthState>, PlatformAuthState>,
              AsyncValue<PlatformAuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 当前绑定的B站账号 Provider

@ProviderFor(boundBilibiliAccount)
final boundBilibiliAccountProvider = BoundBilibiliAccountProvider._();

/// 当前绑定的B站账号 Provider

final class BoundBilibiliAccountProvider
    extends
        $FunctionalProvider<
          BilibiliUserInfo?,
          BilibiliUserInfo?,
          BilibiliUserInfo?
        >
    with $Provider<BilibiliUserInfo?> {
  /// 当前绑定的B站账号 Provider
  BoundBilibiliAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boundBilibiliAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boundBilibiliAccountHash();

  @$internal
  @override
  $ProviderElement<BilibiliUserInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BilibiliUserInfo? create(Ref ref) {
    return boundBilibiliAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BilibiliUserInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BilibiliUserInfo?>(value),
    );
  }
}

String _$boundBilibiliAccountHash() =>
    r'6271256b6f46886f8da1ef5e67f75cc9a59cea30';

/// 是否已绑定B站 Provider

@ProviderFor(isBilibiliBound)
final isBilibiliBoundProvider = IsBilibiliBoundProvider._();

/// 是否已绑定B站 Provider

final class IsBilibiliBoundProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 是否已绑定B站 Provider
  IsBilibiliBoundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBilibiliBoundProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBilibiliBoundHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isBilibiliBound(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isBilibiliBoundHash() => r'3a180a8a2efe949a6f99e2a88abbb7b3572213cc';
