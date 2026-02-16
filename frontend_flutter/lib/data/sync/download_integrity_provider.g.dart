// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_integrity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 下载完整性服务 Provider
///
/// 提供下载完整性服务的单例访问
/// 负责验证已下载文件的完整性，检测外部删除的文件

@ProviderFor(downloadIntegrityService)
final downloadIntegrityServiceProvider = DownloadIntegrityServiceProvider._();

/// 下载完整性服务 Provider
///
/// 提供下载完整性服务的单例访问
/// 负责验证已下载文件的完整性，检测外部删除的文件

final class DownloadIntegrityServiceProvider
    extends
        $FunctionalProvider<
          DownloadIntegrityService,
          DownloadIntegrityService,
          DownloadIntegrityService
        >
    with $Provider<DownloadIntegrityService> {
  /// 下载完整性服务 Provider
  ///
  /// 提供下载完整性服务的单例访问
  /// 负责验证已下载文件的完整性，检测外部删除的文件
  DownloadIntegrityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadIntegrityServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadIntegrityServiceHash();

  @$internal
  @override
  $ProviderElement<DownloadIntegrityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadIntegrityService create(Ref ref) {
    return downloadIntegrityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadIntegrityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadIntegrityService>(value),
    );
  }
}

String _$downloadIntegrityServiceHash() =>
    r'585459fa69a99bb95a42f3397ed60a771d394b36';

/// 服务运行状态 Provider

@ProviderFor(downloadIntegrityRunning)
final downloadIntegrityRunningProvider = DownloadIntegrityRunningProvider._();

/// 服务运行状态 Provider

final class DownloadIntegrityRunningProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 服务运行状态 Provider
  DownloadIntegrityRunningProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadIntegrityRunningProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadIntegrityRunningHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return downloadIntegrityRunning(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$downloadIntegrityRunningHash() =>
    r'fc13aba369a8adfac3f87cd64824f8111e37dbbf';

/// 上次扫描时间 Provider

@ProviderFor(lastIntegrityScanTime)
final lastIntegrityScanTimeProvider = LastIntegrityScanTimeProvider._();

/// 上次扫描时间 Provider

final class LastIntegrityScanTimeProvider
    extends $FunctionalProvider<DateTime?, DateTime?, DateTime?>
    with $Provider<DateTime?> {
  /// 上次扫描时间 Provider
  LastIntegrityScanTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastIntegrityScanTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastIntegrityScanTimeHash();

  @$internal
  @override
  $ProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime? create(Ref ref) {
    return lastIntegrityScanTime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$lastIntegrityScanTimeHash() =>
    r'6f53c1574680a8fe22c2c7186a21fa9d84d5931e';

/// 扫描状态 Provider

@ProviderFor(integrityScanStatus)
final integrityScanStatusProvider = IntegrityScanStatusProvider._();

/// 扫描状态 Provider

final class IntegrityScanStatusProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 扫描状态 Provider
  IntegrityScanStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'integrityScanStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$integrityScanStatusHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return integrityScanStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$integrityScanStatusHash() =>
    r'6e311e05c743715525ffb259e6f6ed9b7f81514f';
