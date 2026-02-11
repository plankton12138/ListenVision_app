// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'netease_playlist_detail_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NeteasePlaylistDetailViewModel)
final neteasePlaylistDetailViewModelProvider =
    NeteasePlaylistDetailViewModelFamily._();

final class NeteasePlaylistDetailViewModelProvider
    extends
        $AsyncNotifierProvider<
          NeteasePlaylistDetailViewModel,
          NeteasePlaylistDetailState
        > {
  NeteasePlaylistDetailViewModelProvider._({
    required NeteasePlaylistDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'neteasePlaylistDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$neteasePlaylistDetailViewModelHash();

  @override
  String toString() {
    return r'neteasePlaylistDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NeteasePlaylistDetailViewModel create() => NeteasePlaylistDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is NeteasePlaylistDetailViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$neteasePlaylistDetailViewModelHash() =>
    r'6f1e2402666a4516ce5b8efa9571a5308c17529a';

final class NeteasePlaylistDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          NeteasePlaylistDetailViewModel,
          AsyncValue<NeteasePlaylistDetailState>,
          NeteasePlaylistDetailState,
          FutureOr<NeteasePlaylistDetailState>,
          String
        > {
  NeteasePlaylistDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'neteasePlaylistDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NeteasePlaylistDetailViewModelProvider call(String playlistId) =>
      NeteasePlaylistDetailViewModelProvider._(
        argument: playlistId,
        from: this,
      );

  @override
  String toString() => r'neteasePlaylistDetailViewModelProvider';
}

abstract class _$NeteasePlaylistDetailViewModel
    extends $AsyncNotifier<NeteasePlaylistDetailState> {
  late final _$args = ref.$arg as String;
  String get playlistId => _$args;

  FutureOr<NeteasePlaylistDetailState> build(String playlistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<NeteasePlaylistDetailState>,
              NeteasePlaylistDetailState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NeteasePlaylistDetailState>,
                NeteasePlaylistDetailState
              >,
              AsyncValue<NeteasePlaylistDetailState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
