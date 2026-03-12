// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubtitleViewModel)
final subtitleViewModelProvider = SubtitleViewModelProvider._();

final class SubtitleViewModelProvider
    extends $NotifierProvider<SubtitleViewModel, SubtitleState> {
  SubtitleViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subtitleViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subtitleViewModelHash();

  @$internal
  @override
  SubtitleViewModel create() => SubtitleViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubtitleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubtitleState>(value),
    );
  }
}

String _$subtitleViewModelHash() => r'df3912dfbfb2c0aed503dabc35ef9655b21d468c';

abstract class _$SubtitleViewModel extends $Notifier<SubtitleState> {
  SubtitleState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SubtitleState, SubtitleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubtitleState, SubtitleState>,
              SubtitleState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
