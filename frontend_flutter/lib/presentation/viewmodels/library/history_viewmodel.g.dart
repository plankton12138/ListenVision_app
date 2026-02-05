// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_viewmodel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayHistoryStatsImpl _$$PlayHistoryStatsImplFromJson(
  Map<String, dynamic> json,
) => _$PlayHistoryStatsImpl(
  totalPlays: (json['totalPlays'] as num?)?.toInt() ?? 0,
  uniqueTracks: (json['uniqueTracks'] as num?)?.toInt() ?? 0,
  totalDuration: (json['totalDuration'] as num?)?.toInt() ?? 0,
  lastPlayed: json['lastPlayed'] == null
      ? null
      : PlayHistory.fromJson(json['lastPlayed'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$PlayHistoryStatsImplToJson(
  _$PlayHistoryStatsImpl instance,
) => <String, dynamic>{
  'totalPlays': instance.totalPlays,
  'uniqueTracks': instance.uniqueTracks,
  'totalDuration': instance.totalDuration,
  'lastPlayed': instance.lastPlayed,
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyRepositoryHash() => r'9f348279e1c7a676eddf0fa70d80f0b55982b952';

/// Provider 定义
///
/// Copied from [historyRepository].
@ProviderFor(historyRepository)
final historyRepositoryProvider =
    AutoDisposeProvider<PlayHistoryRepository>.internal(
      historyRepository,
      name: r'historyRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$historyRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryRepositoryRef = AutoDisposeProviderRef<PlayHistoryRepository>;
String _$historyViewModelHash() => r'2abcdc5dd5c47e1501611a1d7b174641462c89ed';

/// See also [historyViewModel].
@ProviderFor(historyViewModel)
final historyViewModelProvider = AutoDisposeProvider<HistoryViewModel>.internal(
  historyViewModel,
  name: r'historyViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryViewModelRef = AutoDisposeProviderRef<HistoryViewModel>;
String _$historyStateHash() => r'092965509b4046c8dda471b178a40a996142f876';

/// 历史状态 Provider - 用于 UI 层监听状态
///
/// Copied from [historyState].
@ProviderFor(historyState)
final historyStateProvider = AutoDisposeProvider<HistoryState>.internal(
  historyState,
  name: r'historyStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryStateRef = AutoDisposeProviderRef<HistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
