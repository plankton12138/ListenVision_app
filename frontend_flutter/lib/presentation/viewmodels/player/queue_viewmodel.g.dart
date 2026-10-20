// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放队列 ViewModel（Riverpod 3.0 Notifier 模式）
///
/// 职责：
/// 1. 播放队列管理（添加、删除、清空）
/// 2. 当前播放索引管理
/// 3. 播放模式管理
/// 4. 持久化播放队列
///
/// 注意：播放控制逻辑已移至 PlaybackViewModel

@ProviderFor(QueueViewModel)
final queueViewModelProvider = QueueViewModelProvider._();

/// 播放队列 ViewModel（Riverpod 3.0 Notifier 模式）
///
/// 职责：
/// 1. 播放队列管理（添加、删除、清空）
/// 2. 当前播放索引管理
/// 3. 播放模式管理
/// 4. 持久化播放队列
///
/// 注意：播放控制逻辑已移至 PlaybackViewModel
final class QueueViewModelProvider
    extends $NotifierProvider<QueueViewModel, QueueState> {
  /// 播放队列 ViewModel（Riverpod 3.0 Notifier 模式）
  ///
  /// 职责：
  /// 1. 播放队列管理（添加、删除、清空）
  /// 2. 当前播放索引管理
  /// 3. 播放模式管理
  /// 4. 持久化播放队列
  ///
  /// 注意：播放控制逻辑已移至 PlaybackViewModel
  QueueViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queueViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queueViewModelHash();

  @$internal
  @override
  QueueViewModel create() => QueueViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QueueState>(value),
    );
  }
}

String _$queueViewModelHash() => r'57c4865a4b6bb36a4b55c08d455cf9ec8ee4b8a1';

/// 播放队列 ViewModel（Riverpod 3.0 Notifier 模式）
///
/// 职责：
/// 1. 播放队列管理（添加、删除、清空）
/// 2. 当前播放索引管理
/// 3. 播放模式管理
/// 4. 持久化播放队列
///
/// 注意：播放控制逻辑已移至 PlaybackViewModel

abstract class _$QueueViewModel extends $Notifier<QueueState> {
  QueueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QueueState, QueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QueueState, QueueState>,
              QueueState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
