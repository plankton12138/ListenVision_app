// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScanViewModel)
final scanViewModelProvider = ScanViewModelProvider._();

final class ScanViewModelProvider
    extends $NotifierProvider<ScanViewModel, ScanState> {
  ScanViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanViewModelHash();

  @$internal
  @override
  ScanViewModel create() => ScanViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanState>(value),
    );
  }
}

String _$scanViewModelHash() => r'c5f09e28b9b76238ef8010d8d92cc5449dbf67c4';

abstract class _$ScanViewModel extends $Notifier<ScanState> {
  ScanState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScanState, ScanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanState, ScanState>,
              ScanState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
