// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_viewmodel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleState _$SubtitleStateFromJson(Map<String, dynamic> json) =>
    _SubtitleState(
      data: json['data'] == null
          ? null
          : SubtitleData.fromJson(json['data'] as Map<String, dynamic>),
      activeTrack: json['activeTrack'] == null
          ? null
          : SubtitleTrack.fromJson(json['activeTrack'] as Map<String, dynamic>),
      currentLineIndex: (json['currentLineIndex'] as num?)?.toInt() ?? -1,
      isLoading: json['isLoading'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? false,
      isSubtitleEnabled: json['isSubtitleEnabled'] as bool? ?? true,
      error: json['error'] as String? ?? null,
      needLogin: json['needLogin'] as bool? ?? false,
    );

Map<String, dynamic> _$SubtitleStateToJson(_SubtitleState instance) =>
    <String, dynamic>{
      'data': instance.data,
      'activeTrack': instance.activeTrack,
      'currentLineIndex': instance.currentLineIndex,
      'isLoading': instance.isLoading,
      'isVisible': instance.isVisible,
      'isSubtitleEnabled': instance.isSubtitleEnabled,
      'error': instance.error,
      'needLogin': instance.needLogin,
    };

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

String _$subtitleViewModelHash() => r'05302ffb32228f37bb2869feaa3db42f29c52ad2';

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
