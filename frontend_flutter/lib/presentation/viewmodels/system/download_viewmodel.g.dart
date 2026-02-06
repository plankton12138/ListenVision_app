// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 下载管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 新特性：
/// 1. 任务持久化到数据库（重启后仍可恢复）
/// 2. 监听 Repository 的进度流
/// 3. 真正的暂停/恢复（通过 CancelToken）
/// 4. 自动恢复未完成的任务
/// 5. 每个任务独立显示进度和队列位置
/// 6. UI 反馈：操作状态追踪（loading/error 提示）

@ProviderFor(DownloadViewModel)
final downloadViewModelProvider = DownloadViewModelProvider._();

/// 下载管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 新特性：
/// 1. 任务持久化到数据库（重启后仍可恢复）
/// 2. 监听 Repository 的进度流
/// 3. 真正的暂停/恢复（通过 CancelToken）
/// 4. 自动恢复未完成的任务
/// 5. 每个任务独立显示进度和队列位置
/// 6. UI 反馈：操作状态追踪（loading/error 提示）
final class DownloadViewModelProvider
    extends $AsyncNotifierProvider<DownloadViewModel, DownloadModelState> {
  /// 下载管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
  ///
  /// 新特性：
  /// 1. 任务持久化到数据库（重启后仍可恢复）
  /// 2. 监听 Repository 的进度流
  /// 3. 真正的暂停/恢复（通过 CancelToken）
  /// 4. 自动恢复未完成的任务
  /// 5. 每个任务独立显示进度和队列位置
  /// 6. UI 反馈：操作状态追踪（loading/error 提示）
  DownloadViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadViewModelHash();

  @$internal
  @override
  DownloadViewModel create() => DownloadViewModel();
}

String _$downloadViewModelHash() => r'eecd40e6c15c2fb8256271b6601a5f2b8afba99f';

/// 下载管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 新特性：
/// 1. 任务持久化到数据库（重启后仍可恢复）
/// 2. 监听 Repository 的进度流
/// 3. 真正的暂停/恢复（通过 CancelToken）
/// 4. 自动恢复未完成的任务
/// 5. 每个任务独立显示进度和队列位置
/// 6. UI 反馈：操作状态追踪（loading/error 提示）

abstract class _$DownloadViewModel extends $AsyncNotifier<DownloadModelState> {
  FutureOr<DownloadModelState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DownloadModelState>, DownloadModelState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DownloadModelState>, DownloadModelState>,
              AsyncValue<DownloadModelState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
