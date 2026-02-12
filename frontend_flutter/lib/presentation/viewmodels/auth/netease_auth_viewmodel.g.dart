// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'netease_auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NeteaseAuthViewModel)
final neteaseAuthViewModelProvider = NeteaseAuthViewModelProvider._();

final class NeteaseAuthViewModelProvider
    extends $AsyncNotifierProvider<NeteaseAuthViewModel, NeteaseAuthState> {
  NeteaseAuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'neteaseAuthViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$neteaseAuthViewModelHash();

  @$internal
  @override
  NeteaseAuthViewModel create() => NeteaseAuthViewModel();
}

String _$neteaseAuthViewModelHash() =>
    r'6dd11752d1cd85d8a3d469ecb7c550edb2445351';

abstract class _$NeteaseAuthViewModel extends $AsyncNotifier<NeteaseAuthState> {
  FutureOr<NeteaseAuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NeteaseAuthState>, NeteaseAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NeteaseAuthState>, NeteaseAuthState>,
              AsyncValue<NeteaseAuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(boundNeteaseAccount)
final boundNeteaseAccountProvider = BoundNeteaseAccountProvider._();

final class BoundNeteaseAccountProvider
    extends
        $FunctionalProvider<
          NeteaseUserInfo?,
          NeteaseUserInfo?,
          NeteaseUserInfo?
        >
    with $Provider<NeteaseUserInfo?> {
  BoundNeteaseAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boundNeteaseAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boundNeteaseAccountHash();

  @$internal
  @override
  $ProviderElement<NeteaseUserInfo?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NeteaseUserInfo? create(Ref ref) {
    return boundNeteaseAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NeteaseUserInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NeteaseUserInfo?>(value),
    );
  }
}

String _$boundNeteaseAccountHash() =>
    r'75a31c8e3bc301e7c1c92dd3526a491e1f868c0d';

@ProviderFor(isNeteaseBound)
final isNeteaseBoundProvider = IsNeteaseBoundProvider._();

final class IsNeteaseBoundProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsNeteaseBoundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isNeteaseBoundProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isNeteaseBoundHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isNeteaseBound(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isNeteaseBoundHash() => r'da861a3612a5452f31ec833d7a3d3c29e04bebf4';
