// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$platformAuthViewModelHash() =>
    r'037f61ce1668d23cfc8fd23ff569c1da1a1cf6f7';

/// Provider 定义
///
/// Copied from [platformAuthViewModel].
@ProviderFor(platformAuthViewModel)
final platformAuthViewModelProvider =
    AutoDisposeProvider<PlatformAuthViewModel>.internal(
      platformAuthViewModel,
      name: r'platformAuthViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$platformAuthViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlatformAuthViewModelRef =
    AutoDisposeProviderRef<PlatformAuthViewModel>;
String _$boundBilibiliAccountHash() =>
    r'ef573fa6c12193955bdafc9dd877f1d876c4ad4c';

/// 当前绑定的B站账号 Provider
///
/// Copied from [boundBilibiliAccount].
@ProviderFor(boundBilibiliAccount)
final boundBilibiliAccountProvider =
    AutoDisposeProvider<BilibiliUserInfo?>.internal(
      boundBilibiliAccount,
      name: r'boundBilibiliAccountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$boundBilibiliAccountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoundBilibiliAccountRef = AutoDisposeProviderRef<BilibiliUserInfo?>;
String _$isBilibiliBoundHash() => r'84713c9fe01faf641c36e95969eeb9ae0c96f407';

/// 是否已绑定B站 Provider
///
/// Copied from [isBilibiliBound].
@ProviderFor(isBilibiliBound)
final isBilibiliBoundProvider = AutoDisposeProvider<bool>.internal(
  isBilibiliBound,
  name: r'isBilibiliBoundProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isBilibiliBoundHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsBilibiliBoundRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
