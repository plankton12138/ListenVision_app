// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$HistoryState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<PlayHistory> history,
      PlayHistoryStats? stats,
    )
    loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HistoryStateInitial value) initial,
    required TResult Function(HistoryStateLoading value) loading,
    required TResult Function(HistoryStateLoaded value) loaded,
    required TResult Function(HistoryStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HistoryStateInitial value)? initial,
    TResult? Function(HistoryStateLoading value)? loading,
    TResult? Function(HistoryStateLoaded value)? loaded,
    TResult? Function(HistoryStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HistoryStateInitial value)? initial,
    TResult Function(HistoryStateLoading value)? loading,
    TResult Function(HistoryStateLoaded value)? loaded,
    TResult Function(HistoryStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryStateCopyWith<$Res> {
  factory $HistoryStateCopyWith(
    HistoryState value,
    $Res Function(HistoryState) then,
  ) = _$HistoryStateCopyWithImpl<$Res, HistoryState>;
}

/// @nodoc
class _$HistoryStateCopyWithImpl<$Res, $Val extends HistoryState>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$HistoryStateInitialImplCopyWith<$Res> {
  factory _$$HistoryStateInitialImplCopyWith(
    _$HistoryStateInitialImpl value,
    $Res Function(_$HistoryStateInitialImpl) then,
  ) = __$$HistoryStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HistoryStateInitialImplCopyWithImpl<$Res>
    extends _$HistoryStateCopyWithImpl<$Res, _$HistoryStateInitialImpl>
    implements _$$HistoryStateInitialImplCopyWith<$Res> {
  __$$HistoryStateInitialImplCopyWithImpl(
    _$HistoryStateInitialImpl _value,
    $Res Function(_$HistoryStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HistoryStateInitialImpl implements HistoryStateInitial {
  const _$HistoryStateInitialImpl();

  @override
  String toString() {
    return 'HistoryState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<PlayHistory> history,
      PlayHistoryStats? stats,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HistoryStateInitial value) initial,
    required TResult Function(HistoryStateLoading value) loading,
    required TResult Function(HistoryStateLoaded value) loaded,
    required TResult Function(HistoryStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HistoryStateInitial value)? initial,
    TResult? Function(HistoryStateLoading value)? loading,
    TResult? Function(HistoryStateLoaded value)? loaded,
    TResult? Function(HistoryStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HistoryStateInitial value)? initial,
    TResult Function(HistoryStateLoading value)? loading,
    TResult Function(HistoryStateLoaded value)? loaded,
    TResult Function(HistoryStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class HistoryStateInitial implements HistoryState {
  const factory HistoryStateInitial() = _$HistoryStateInitialImpl;
}

/// @nodoc
abstract class _$$HistoryStateLoadingImplCopyWith<$Res> {
  factory _$$HistoryStateLoadingImplCopyWith(
    _$HistoryStateLoadingImpl value,
    $Res Function(_$HistoryStateLoadingImpl) then,
  ) = __$$HistoryStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HistoryStateLoadingImplCopyWithImpl<$Res>
    extends _$HistoryStateCopyWithImpl<$Res, _$HistoryStateLoadingImpl>
    implements _$$HistoryStateLoadingImplCopyWith<$Res> {
  __$$HistoryStateLoadingImplCopyWithImpl(
    _$HistoryStateLoadingImpl _value,
    $Res Function(_$HistoryStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HistoryStateLoadingImpl implements HistoryStateLoading {
  const _$HistoryStateLoadingImpl();

  @override
  String toString() {
    return 'HistoryState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<PlayHistory> history,
      PlayHistoryStats? stats,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HistoryStateInitial value) initial,
    required TResult Function(HistoryStateLoading value) loading,
    required TResult Function(HistoryStateLoaded value) loaded,
    required TResult Function(HistoryStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HistoryStateInitial value)? initial,
    TResult? Function(HistoryStateLoading value)? loading,
    TResult? Function(HistoryStateLoaded value)? loaded,
    TResult? Function(HistoryStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HistoryStateInitial value)? initial,
    TResult Function(HistoryStateLoading value)? loading,
    TResult Function(HistoryStateLoaded value)? loaded,
    TResult Function(HistoryStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class HistoryStateLoading implements HistoryState {
  const factory HistoryStateLoading() = _$HistoryStateLoadingImpl;
}

/// @nodoc
abstract class _$$HistoryStateLoadedImplCopyWith<$Res> {
  factory _$$HistoryStateLoadedImplCopyWith(
    _$HistoryStateLoadedImpl value,
    $Res Function(_$HistoryStateLoadedImpl) then,
  ) = __$$HistoryStateLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<PlayHistory> history, PlayHistoryStats? stats});

  $PlayHistoryStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class __$$HistoryStateLoadedImplCopyWithImpl<$Res>
    extends _$HistoryStateCopyWithImpl<$Res, _$HistoryStateLoadedImpl>
    implements _$$HistoryStateLoadedImplCopyWith<$Res> {
  __$$HistoryStateLoadedImplCopyWithImpl(
    _$HistoryStateLoadedImpl _value,
    $Res Function(_$HistoryStateLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? history = null, Object? stats = freezed}) {
    return _then(
      _$HistoryStateLoadedImpl(
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<PlayHistory>,
        stats: freezed == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as PlayHistoryStats?,
      ),
    );
  }

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayHistoryStatsCopyWith<$Res>? get stats {
    if (_value.stats == null) {
      return null;
    }

    return $PlayHistoryStatsCopyWith<$Res>(_value.stats!, (value) {
      return _then(_value.copyWith(stats: value));
    });
  }
}

/// @nodoc

class _$HistoryStateLoadedImpl implements HistoryStateLoaded {
  const _$HistoryStateLoadedImpl({
    required final List<PlayHistory> history,
    this.stats,
  }) : _history = history;

  final List<PlayHistory> _history;
  @override
  List<PlayHistory> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  final PlayHistoryStats? stats;

  @override
  String toString() {
    return 'HistoryState.loaded(history: $history, stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryStateLoadedImpl &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.stats, stats) || other.stats == stats));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_history),
    stats,
  );

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryStateLoadedImplCopyWith<_$HistoryStateLoadedImpl> get copyWith =>
      __$$HistoryStateLoadedImplCopyWithImpl<_$HistoryStateLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<PlayHistory> history,
      PlayHistoryStats? stats,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(history, stats);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(history, stats);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(history, stats);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HistoryStateInitial value) initial,
    required TResult Function(HistoryStateLoading value) loading,
    required TResult Function(HistoryStateLoaded value) loaded,
    required TResult Function(HistoryStateError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HistoryStateInitial value)? initial,
    TResult? Function(HistoryStateLoading value)? loading,
    TResult? Function(HistoryStateLoaded value)? loaded,
    TResult? Function(HistoryStateError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HistoryStateInitial value)? initial,
    TResult Function(HistoryStateLoading value)? loading,
    TResult Function(HistoryStateLoaded value)? loaded,
    TResult Function(HistoryStateError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class HistoryStateLoaded implements HistoryState {
  const factory HistoryStateLoaded({
    required final List<PlayHistory> history,
    final PlayHistoryStats? stats,
  }) = _$HistoryStateLoadedImpl;

  List<PlayHistory> get history;
  PlayHistoryStats? get stats;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryStateLoadedImplCopyWith<_$HistoryStateLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HistoryStateErrorImplCopyWith<$Res> {
  factory _$$HistoryStateErrorImplCopyWith(
    _$HistoryStateErrorImpl value,
    $Res Function(_$HistoryStateErrorImpl) then,
  ) = __$$HistoryStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$HistoryStateErrorImplCopyWithImpl<$Res>
    extends _$HistoryStateCopyWithImpl<$Res, _$HistoryStateErrorImpl>
    implements _$$HistoryStateErrorImplCopyWith<$Res> {
  __$$HistoryStateErrorImplCopyWithImpl(
    _$HistoryStateErrorImpl _value,
    $Res Function(_$HistoryStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$HistoryStateErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$HistoryStateErrorImpl implements HistoryStateError {
  const _$HistoryStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'HistoryState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryStateErrorImplCopyWith<_$HistoryStateErrorImpl> get copyWith =>
      __$$HistoryStateErrorImplCopyWithImpl<_$HistoryStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<PlayHistory> history,
      PlayHistoryStats? stats,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<PlayHistory> history, PlayHistoryStats? stats)?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HistoryStateInitial value) initial,
    required TResult Function(HistoryStateLoading value) loading,
    required TResult Function(HistoryStateLoaded value) loaded,
    required TResult Function(HistoryStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HistoryStateInitial value)? initial,
    TResult? Function(HistoryStateLoading value)? loading,
    TResult? Function(HistoryStateLoaded value)? loaded,
    TResult? Function(HistoryStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HistoryStateInitial value)? initial,
    TResult Function(HistoryStateLoading value)? loading,
    TResult Function(HistoryStateLoaded value)? loaded,
    TResult Function(HistoryStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class HistoryStateError implements HistoryState {
  const factory HistoryStateError({required final String message}) =
      _$HistoryStateErrorImpl;

  String get message;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryStateErrorImplCopyWith<_$HistoryStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayHistoryStats _$PlayHistoryStatsFromJson(Map<String, dynamic> json) {
  return _PlayHistoryStats.fromJson(json);
}

/// @nodoc
mixin _$PlayHistoryStats {
  int get totalPlays => throw _privateConstructorUsedError;
  int get uniqueTracks => throw _privateConstructorUsedError;
  int get totalDuration => throw _privateConstructorUsedError;
  PlayHistory? get lastPlayed => throw _privateConstructorUsedError;

  /// Serializes this PlayHistoryStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayHistoryStatsCopyWith<PlayHistoryStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayHistoryStatsCopyWith<$Res> {
  factory $PlayHistoryStatsCopyWith(
    PlayHistoryStats value,
    $Res Function(PlayHistoryStats) then,
  ) = _$PlayHistoryStatsCopyWithImpl<$Res, PlayHistoryStats>;
  @useResult
  $Res call({
    int totalPlays,
    int uniqueTracks,
    int totalDuration,
    PlayHistory? lastPlayed,
  });

  $PlayHistoryCopyWith<$Res>? get lastPlayed;
}

/// @nodoc
class _$PlayHistoryStatsCopyWithImpl<$Res, $Val extends PlayHistoryStats>
    implements $PlayHistoryStatsCopyWith<$Res> {
  _$PlayHistoryStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPlays = null,
    Object? uniqueTracks = null,
    Object? totalDuration = null,
    Object? lastPlayed = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalPlays: null == totalPlays
                ? _value.totalPlays
                : totalPlays // ignore: cast_nullable_to_non_nullable
                      as int,
            uniqueTracks: null == uniqueTracks
                ? _value.uniqueTracks
                : uniqueTracks // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDuration: null == totalDuration
                ? _value.totalDuration
                : totalDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPlayed: freezed == lastPlayed
                ? _value.lastPlayed
                : lastPlayed // ignore: cast_nullable_to_non_nullable
                      as PlayHistory?,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayHistoryCopyWith<$Res>? get lastPlayed {
    if (_value.lastPlayed == null) {
      return null;
    }

    return $PlayHistoryCopyWith<$Res>(_value.lastPlayed!, (value) {
      return _then(_value.copyWith(lastPlayed: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayHistoryStatsImplCopyWith<$Res>
    implements $PlayHistoryStatsCopyWith<$Res> {
  factory _$$PlayHistoryStatsImplCopyWith(
    _$PlayHistoryStatsImpl value,
    $Res Function(_$PlayHistoryStatsImpl) then,
  ) = __$$PlayHistoryStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalPlays,
    int uniqueTracks,
    int totalDuration,
    PlayHistory? lastPlayed,
  });

  @override
  $PlayHistoryCopyWith<$Res>? get lastPlayed;
}

/// @nodoc
class __$$PlayHistoryStatsImplCopyWithImpl<$Res>
    extends _$PlayHistoryStatsCopyWithImpl<$Res, _$PlayHistoryStatsImpl>
    implements _$$PlayHistoryStatsImplCopyWith<$Res> {
  __$$PlayHistoryStatsImplCopyWithImpl(
    _$PlayHistoryStatsImpl _value,
    $Res Function(_$PlayHistoryStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPlays = null,
    Object? uniqueTracks = null,
    Object? totalDuration = null,
    Object? lastPlayed = freezed,
  }) {
    return _then(
      _$PlayHistoryStatsImpl(
        totalPlays: null == totalPlays
            ? _value.totalPlays
            : totalPlays // ignore: cast_nullable_to_non_nullable
                  as int,
        uniqueTracks: null == uniqueTracks
            ? _value.uniqueTracks
            : uniqueTracks // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDuration: null == totalDuration
            ? _value.totalDuration
            : totalDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPlayed: freezed == lastPlayed
            ? _value.lastPlayed
            : lastPlayed // ignore: cast_nullable_to_non_nullable
                  as PlayHistory?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayHistoryStatsImpl implements _PlayHistoryStats {
  const _$PlayHistoryStatsImpl({
    this.totalPlays = 0,
    this.uniqueTracks = 0,
    this.totalDuration = 0,
    this.lastPlayed,
  });

  factory _$PlayHistoryStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayHistoryStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalPlays;
  @override
  @JsonKey()
  final int uniqueTracks;
  @override
  @JsonKey()
  final int totalDuration;
  @override
  final PlayHistory? lastPlayed;

  @override
  String toString() {
    return 'PlayHistoryStats(totalPlays: $totalPlays, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration, lastPlayed: $lastPlayed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayHistoryStatsImpl &&
            (identical(other.totalPlays, totalPlays) ||
                other.totalPlays == totalPlays) &&
            (identical(other.uniqueTracks, uniqueTracks) ||
                other.uniqueTracks == uniqueTracks) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalPlays,
    uniqueTracks,
    totalDuration,
    lastPlayed,
  );

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayHistoryStatsImplCopyWith<_$PlayHistoryStatsImpl> get copyWith =>
      __$$PlayHistoryStatsImplCopyWithImpl<_$PlayHistoryStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayHistoryStatsImplToJson(this);
  }
}

abstract class _PlayHistoryStats implements PlayHistoryStats {
  const factory _PlayHistoryStats({
    final int totalPlays,
    final int uniqueTracks,
    final int totalDuration,
    final PlayHistory? lastPlayed,
  }) = _$PlayHistoryStatsImpl;

  factory _PlayHistoryStats.fromJson(Map<String, dynamic> json) =
      _$PlayHistoryStatsImpl.fromJson;

  @override
  int get totalPlays;
  @override
  int get uniqueTracks;
  @override
  int get totalDuration;
  @override
  PlayHistory? get lastPlayed;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayHistoryStatsImplCopyWith<_$PlayHistoryStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
