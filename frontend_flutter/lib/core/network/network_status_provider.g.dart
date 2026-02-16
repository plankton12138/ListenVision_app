// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 网络状态 Provider
///
/// 实时监测网络连接状态，使用 connectivity_plus 插件
/// 支持监听网络类型变化（WiFi/移动数据/无网络等）

@ProviderFor(NetworkStatusNotifier)
final networkStatusProvider = NetworkStatusNotifierProvider._();

/// 网络状态 Provider
///
/// 实时监测网络连接状态，使用 connectivity_plus 插件
/// 支持监听网络类型变化（WiFi/移动数据/无网络等）
final class NetworkStatusNotifierProvider
    extends $AsyncNotifierProvider<NetworkStatusNotifier, NetworkStatus> {
  /// 网络状态 Provider
  ///
  /// 实时监测网络连接状态，使用 connectivity_plus 插件
  /// 支持监听网络类型变化（WiFi/移动数据/无网络等）
  NetworkStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkStatusNotifierHash();

  @$internal
  @override
  NetworkStatusNotifier create() => NetworkStatusNotifier();
}

String _$networkStatusNotifierHash() =>
    r'e1eaecc5ea319f2da8a4fb074772832bbcde2f35';

/// 网络状态 Provider
///
/// 实时监测网络连接状态，使用 connectivity_plus 插件
/// 支持监听网络类型变化（WiFi/移动数据/无网络等）

abstract class _$NetworkStatusNotifier extends $AsyncNotifier<NetworkStatus> {
  FutureOr<NetworkStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NetworkStatus>, NetworkStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NetworkStatus>, NetworkStatus>,
              AsyncValue<NetworkStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 网络连接状态 Provider
///
/// 只返回是否已连接，方便简单场景使用

@ProviderFor(isNetworkConnected)
final isNetworkConnectedProvider = IsNetworkConnectedProvider._();

/// 网络连接状态 Provider
///
/// 只返回是否已连接，方便简单场景使用

final class IsNetworkConnectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 网络连接状态 Provider
  ///
  /// 只返回是否已连接，方便简单场景使用
  IsNetworkConnectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isNetworkConnectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isNetworkConnectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isNetworkConnected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isNetworkConnectedHash() =>
    r'cf06ad150d0ecd1eba8dad7c0ab853d58f14654b';

/// 网络连接类型 Provider
///
/// 返回具体的连接类型，可能为 null（加载中或错误）

@ProviderFor(networkConnectionType)
final networkConnectionTypeProvider = NetworkConnectionTypeProvider._();

/// 网络连接类型 Provider
///
/// 返回具体的连接类型，可能为 null（加载中或错误）

final class NetworkConnectionTypeProvider
    extends
        $FunctionalProvider<
          NetworkConnectionType?,
          NetworkConnectionType?,
          NetworkConnectionType?
        >
    with $Provider<NetworkConnectionType?> {
  /// 网络连接类型 Provider
  ///
  /// 返回具体的连接类型，可能为 null（加载中或错误）
  NetworkConnectionTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkConnectionTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkConnectionTypeHash();

  @$internal
  @override
  $ProviderElement<NetworkConnectionType?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkConnectionType? create(Ref ref) {
    return networkConnectionType(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkConnectionType? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkConnectionType?>(value),
    );
  }
}

String _$networkConnectionTypeHash() =>
    r'4ea6de3da5cf43077907f7fe222deee83ffae7cd';

/// 网络状态描述 Provider
///
/// 返回用户友好的连接描述文本

@ProviderFor(networkConnectionDescription)
final networkConnectionDescriptionProvider =
    NetworkConnectionDescriptionProvider._();

/// 网络状态描述 Provider
///
/// 返回用户友好的连接描述文本

final class NetworkConnectionDescriptionProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 网络状态描述 Provider
  ///
  /// 返回用户友好的连接描述文本
  NetworkConnectionDescriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkConnectionDescriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkConnectionDescriptionHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return networkConnectionDescription(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$networkConnectionDescriptionHash() =>
    r'7dd8d37f2928827dbf3f0b4fa09b795cdee078da';
