// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_worker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SyncWorker 实例 Provider
///
/// 提供同步工作器的单例访问

@ProviderFor(syncWorker)
final syncWorkerProvider = SyncWorkerProvider._();

/// SyncWorker 实例 Provider
///
/// 提供同步工作器的单例访问

final class SyncWorkerProvider
    extends $FunctionalProvider<SyncWorker, SyncWorker, SyncWorker>
    with $Provider<SyncWorker> {
  /// SyncWorker 实例 Provider
  ///
  /// 提供同步工作器的单例访问
  SyncWorkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWorkerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWorkerHash();

  @$internal
  @override
  $ProviderElement<SyncWorker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncWorker create(Ref ref) {
    return syncWorker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncWorker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncWorker>(value),
    );
  }
}

String _$syncWorkerHash() => r'444e5c9a04aab556548e39a48652fd9282e9cc43';

/// 是否有待处理同步任务

@ProviderFor(hasPendingSyncTasks)
final hasPendingSyncTasksProvider = HasPendingSyncTasksProvider._();

/// 是否有待处理同步任务

final class HasPendingSyncTasksProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// 是否有待处理同步任务
  HasPendingSyncTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasPendingSyncTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasPendingSyncTasksHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasPendingSyncTasks(ref);
  }
}

String _$hasPendingSyncTasksHash() =>
    r'0b0c6ba7ea0cd7c9fa90f9fa1bf0442c9a611339';
