// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_viewmodel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayHistoryStats _$PlayHistoryStatsFromJson(Map<String, dynamic> json) =>
    _PlayHistoryStats(
      totalPlays: (json['totalPlays'] as num?)?.toInt() ?? 0,
      uniqueTracks: (json['uniqueTracks'] as num?)?.toInt() ?? 0,
      totalDuration: (json['totalDuration'] as num?)?.toInt() ?? 0,
      lastPlayed: json['lastPlayed'] == null
          ? null
          : PlayHistory.fromJson(json['lastPlayed'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlayHistoryStatsToJson(_PlayHistoryStats instance) =>
    <String, dynamic>{
      'totalPlays': instance.totalPlays,
      'uniqueTracks': instance.uniqueTracks,
      'totalDuration': instance.totalDuration,
      'lastPlayed': instance.lastPlayed,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放历史 ViewModel
///
/// 负责播放历史记录的状态管理

@ProviderFor(HistoryViewModel)
final historyViewModelProvider = HistoryViewModelProvider._();

/// 播放历史 ViewModel
///
/// 负责播放历史记录的状态管理
final class HistoryViewModelProvider
    extends $AsyncNotifierProvider<HistoryViewModel, HistoryState> {
  /// 播放历史 ViewModel
  ///
  /// 负责播放历史记录的状态管理
  HistoryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyViewModelHash();

  @$internal
  @override
  HistoryViewModel create() => HistoryViewModel();
}

String _$historyViewModelHash() => r'54b275da0128d926364c8ba9b6523686d6608122';

/// 播放历史 ViewModel
///
/// 负责播放历史记录的状态管理

abstract class _$HistoryViewModel extends $AsyncNotifier<HistoryState> {
  FutureOr<HistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HistoryState>, HistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HistoryState>, HistoryState>,
              AsyncValue<HistoryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider 定义

@ProviderFor(historyRepository)
final historyRepositoryProvider = HistoryRepositoryProvider._();

/// Provider 定义

final class HistoryRepositoryProvider
    extends
        $FunctionalProvider<
          PlayHistoryRepository,
          PlayHistoryRepository,
          PlayHistoryRepository
        >
    with $Provider<PlayHistoryRepository> {
  /// Provider 定义
  HistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlayHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlayHistoryRepository create(Ref ref) {
    return historyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayHistoryRepository>(value),
    );
  }
}

String _$historyRepositoryHash() => r'6ebc71d52aebb1c03221b101850ad794485c6f70';

/// 历史状态 Provider - 用于 UI 层监听状态

@ProviderFor(historyState)
final historyStateProvider = HistoryStateProvider._();

/// 历史状态 Provider - 用于 UI 层监听状态

final class HistoryStateProvider
    extends $FunctionalProvider<HistoryState, HistoryState, HistoryState>
    with $Provider<HistoryState> {
  /// 历史状态 Provider - 用于 UI 层监听状态
  HistoryStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyStateHash();

  @$internal
  @override
  $ProviderElement<HistoryState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryState create(Ref ref) {
    return historyState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryState>(value),
    );
  }
}

String _$historyStateHash() => r'3c2e928bef3fd5a504a5242c821a29702d84e2fa';
