// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExploreViewModel)
final exploreViewModelProvider = ExploreViewModelProvider._();

final class ExploreViewModelProvider
    extends $AsyncNotifierProvider<ExploreViewModel, ExploreState> {
  ExploreViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreViewModelHash();

  @$internal
  @override
  ExploreViewModel create() => ExploreViewModel();
}

String _$exploreViewModelHash() => r'71b5f9c558afe5e4d0be2198e5a747b9731dd38d';

abstract class _$ExploreViewModel extends $AsyncNotifier<ExploreState> {
  FutureOr<ExploreState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExploreState>, ExploreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExploreState>, ExploreState>,
              AsyncValue<ExploreState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
