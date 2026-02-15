// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloading_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 下载状态 Notifier
///
/// 管理当前正在下载的任务 ID 集合（内存状态）

@ProviderFor(DownloadingState)
final downloadingStateProvider = DownloadingStateProvider._();

/// 下载状态 Notifier
///
/// 管理当前正在下载的任务 ID 集合（内存状态）
final class DownloadingStateProvider
    extends $NotifierProvider<DownloadingState, Set<int>> {
  /// 下载状态 Notifier
  ///
  /// 管理当前正在下载的任务 ID 集合（内存状态）
  DownloadingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadingStateHash();

  @$internal
  @override
  DownloadingState create() => DownloadingState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$downloadingStateHash() => r'625dca9afc955b37f9280e145c1f874dfec06de8';

/// 下载状态 Notifier
///
/// 管理当前正在下载的任务 ID 集合（内存状态）

abstract class _$DownloadingState extends $Notifier<Set<int>> {
  Set<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<int>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<int>, Set<int>>,
              Set<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
