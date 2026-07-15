// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_tracks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 收藏状态 Notifier
///
/// 独立管理收藏曲目 ID 集合，返回 Set<String>。

@ProviderFor(FavoriteTracksNotifier)
final favoriteTracksProvider = FavoriteTracksNotifierProvider._();

/// 收藏状态 Notifier
///
/// 独立管理收藏曲目 ID 集合，返回 Set<String>。
final class FavoriteTracksNotifierProvider
    extends $AsyncNotifierProvider<FavoriteTracksNotifier, Set<String>> {
  /// 收藏状态 Notifier
  ///
  /// 独立管理收藏曲目 ID 集合，返回 Set<String>。
  FavoriteTracksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteTracksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteTracksNotifierHash();

  @$internal
  @override
  FavoriteTracksNotifier create() => FavoriteTracksNotifier();
}

String _$favoriteTracksNotifierHash() =>
    r'9d72f34a11d733c5c656a8c23d44d6b2b59c7706';

/// 收藏状态 Notifier
///
/// 独立管理收藏曲目 ID 集合，返回 Set<String>。

abstract class _$FavoriteTracksNotifier extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
