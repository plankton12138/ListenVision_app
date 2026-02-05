// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_music_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocalMusicState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalMusicStateCopyWith<$Res> {
  factory $LocalMusicStateCopyWith(
    LocalMusicState value,
    $Res Function(LocalMusicState) then,
  ) = _$LocalMusicStateCopyWithImpl<$Res, LocalMusicState>;
}

/// @nodoc
class _$LocalMusicStateCopyWithImpl<$Res, $Val extends LocalMusicState>
    implements $LocalMusicStateCopyWith<$Res> {
  _$LocalMusicStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LocalMusicStateInitialImplCopyWith<$Res> {
  factory _$$LocalMusicStateInitialImplCopyWith(
    _$LocalMusicStateInitialImpl value,
    $Res Function(_$LocalMusicStateInitialImpl) then,
  ) = __$$LocalMusicStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LocalMusicStateInitialImplCopyWithImpl<$Res>
    extends _$LocalMusicStateCopyWithImpl<$Res, _$LocalMusicStateInitialImpl>
    implements _$$LocalMusicStateInitialImplCopyWith<$Res> {
  __$$LocalMusicStateInitialImplCopyWithImpl(
    _$LocalMusicStateInitialImpl _value,
    $Res Function(_$LocalMusicStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LocalMusicStateInitialImpl implements LocalMusicStateInitial {
  const _$LocalMusicStateInitialImpl();

  @override
  String toString() {
    return 'LocalMusicState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalMusicStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
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
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class LocalMusicStateInitial implements LocalMusicState {
  const factory LocalMusicStateInitial() = _$LocalMusicStateInitialImpl;
}

/// @nodoc
abstract class _$$LocalMusicStateLoadingImplCopyWith<$Res> {
  factory _$$LocalMusicStateLoadingImplCopyWith(
    _$LocalMusicStateLoadingImpl value,
    $Res Function(_$LocalMusicStateLoadingImpl) then,
  ) = __$$LocalMusicStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LocalMusicStateLoadingImplCopyWithImpl<$Res>
    extends _$LocalMusicStateCopyWithImpl<$Res, _$LocalMusicStateLoadingImpl>
    implements _$$LocalMusicStateLoadingImplCopyWith<$Res> {
  __$$LocalMusicStateLoadingImplCopyWithImpl(
    _$LocalMusicStateLoadingImpl _value,
    $Res Function(_$LocalMusicStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LocalMusicStateLoadingImpl implements LocalMusicStateLoading {
  const _$LocalMusicStateLoadingImpl();

  @override
  String toString() {
    return 'LocalMusicState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalMusicStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
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
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class LocalMusicStateLoading implements LocalMusicState {
  const factory LocalMusicStateLoading() = _$LocalMusicStateLoadingImpl;
}

/// @nodoc
abstract class _$$LocalMusicStateLoadedImplCopyWith<$Res> {
  factory _$$LocalMusicStateLoadedImplCopyWith(
    _$LocalMusicStateLoadedImpl value,
    $Res Function(_$LocalMusicStateLoadedImpl) then,
  ) = __$$LocalMusicStateLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<LocalAudio> audios});
}

/// @nodoc
class __$$LocalMusicStateLoadedImplCopyWithImpl<$Res>
    extends _$LocalMusicStateCopyWithImpl<$Res, _$LocalMusicStateLoadedImpl>
    implements _$$LocalMusicStateLoadedImplCopyWith<$Res> {
  __$$LocalMusicStateLoadedImplCopyWithImpl(
    _$LocalMusicStateLoadedImpl _value,
    $Res Function(_$LocalMusicStateLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? audios = null}) {
    return _then(
      _$LocalMusicStateLoadedImpl(
        audios: null == audios
            ? _value._audios
            : audios // ignore: cast_nullable_to_non_nullable
                  as List<LocalAudio>,
      ),
    );
  }
}

/// @nodoc

class _$LocalMusicStateLoadedImpl implements LocalMusicStateLoaded {
  const _$LocalMusicStateLoadedImpl({required final List<LocalAudio> audios})
    : _audios = audios;

  final List<LocalAudio> _audios;
  @override
  List<LocalAudio> get audios {
    if (_audios is EqualUnmodifiableListView) return _audios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_audios);
  }

  @override
  String toString() {
    return 'LocalMusicState.loaded(audios: $audios)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalMusicStateLoadedImpl &&
            const DeepCollectionEquality().equals(other._audios, _audios));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_audios));

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalMusicStateLoadedImplCopyWith<_$LocalMusicStateLoadedImpl>
  get copyWith =>
      __$$LocalMusicStateLoadedImplCopyWithImpl<_$LocalMusicStateLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) {
    return loaded(audios);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(audios);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(audios);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class LocalMusicStateLoaded implements LocalMusicState {
  const factory LocalMusicStateLoaded({
    required final List<LocalAudio> audios,
  }) = _$LocalMusicStateLoadedImpl;

  List<LocalAudio> get audios;

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalMusicStateLoadedImplCopyWith<_$LocalMusicStateLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LocalMusicStateImportingImplCopyWith<$Res> {
  factory _$$LocalMusicStateImportingImplCopyWith(
    _$LocalMusicStateImportingImpl value,
    $Res Function(_$LocalMusicStateImportingImpl) then,
  ) = __$$LocalMusicStateImportingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int current, int total, String currentFile});
}

/// @nodoc
class __$$LocalMusicStateImportingImplCopyWithImpl<$Res>
    extends _$LocalMusicStateCopyWithImpl<$Res, _$LocalMusicStateImportingImpl>
    implements _$$LocalMusicStateImportingImplCopyWith<$Res> {
  __$$LocalMusicStateImportingImplCopyWithImpl(
    _$LocalMusicStateImportingImpl _value,
    $Res Function(_$LocalMusicStateImportingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = null,
    Object? total = null,
    Object? currentFile = null,
  }) {
    return _then(
      _$LocalMusicStateImportingImpl(
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        currentFile: null == currentFile
            ? _value.currentFile
            : currentFile // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LocalMusicStateImportingImpl implements LocalMusicStateImporting {
  const _$LocalMusicStateImportingImpl({
    required this.current,
    required this.total,
    required this.currentFile,
  });

  @override
  final int current;
  @override
  final int total;
  @override
  final String currentFile;

  @override
  String toString() {
    return 'LocalMusicState.importing(current: $current, total: $total, currentFile: $currentFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalMusicStateImportingImpl &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.currentFile, currentFile) ||
                other.currentFile == currentFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, current, total, currentFile);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalMusicStateImportingImplCopyWith<_$LocalMusicStateImportingImpl>
  get copyWith =>
      __$$LocalMusicStateImportingImplCopyWithImpl<
        _$LocalMusicStateImportingImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) {
    return importing(current, total, currentFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) {
    return importing?.call(current, total, currentFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (importing != null) {
      return importing(current, total, currentFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) {
    return importing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) {
    return importing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) {
    if (importing != null) {
      return importing(this);
    }
    return orElse();
  }
}

abstract class LocalMusicStateImporting implements LocalMusicState {
  const factory LocalMusicStateImporting({
    required final int current,
    required final int total,
    required final String currentFile,
  }) = _$LocalMusicStateImportingImpl;

  int get current;
  int get total;
  String get currentFile;

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalMusicStateImportingImplCopyWith<_$LocalMusicStateImportingImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LocalMusicStateErrorImplCopyWith<$Res> {
  factory _$$LocalMusicStateErrorImplCopyWith(
    _$LocalMusicStateErrorImpl value,
    $Res Function(_$LocalMusicStateErrorImpl) then,
  ) = __$$LocalMusicStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$LocalMusicStateErrorImplCopyWithImpl<$Res>
    extends _$LocalMusicStateCopyWithImpl<$Res, _$LocalMusicStateErrorImpl>
    implements _$$LocalMusicStateErrorImplCopyWith<$Res> {
  __$$LocalMusicStateErrorImplCopyWithImpl(
    _$LocalMusicStateErrorImpl _value,
    $Res Function(_$LocalMusicStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$LocalMusicStateErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LocalMusicStateErrorImpl implements LocalMusicStateError {
  const _$LocalMusicStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'LocalMusicState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalMusicStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalMusicStateErrorImplCopyWith<_$LocalMusicStateErrorImpl>
  get copyWith =>
      __$$LocalMusicStateErrorImplCopyWithImpl<_$LocalMusicStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<LocalAudio> audios) loaded,
    required TResult Function(int current, int total, String currentFile)
    importing,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<LocalAudio> audios)? loaded,
    TResult? Function(int current, int total, String currentFile)? importing,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<LocalAudio> audios)? loaded,
    TResult Function(int current, int total, String currentFile)? importing,
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
    required TResult Function(LocalMusicStateInitial value) initial,
    required TResult Function(LocalMusicStateLoading value) loading,
    required TResult Function(LocalMusicStateLoaded value) loaded,
    required TResult Function(LocalMusicStateImporting value) importing,
    required TResult Function(LocalMusicStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocalMusicStateInitial value)? initial,
    TResult? Function(LocalMusicStateLoading value)? loading,
    TResult? Function(LocalMusicStateLoaded value)? loaded,
    TResult? Function(LocalMusicStateImporting value)? importing,
    TResult? Function(LocalMusicStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocalMusicStateInitial value)? initial,
    TResult Function(LocalMusicStateLoading value)? loading,
    TResult Function(LocalMusicStateLoaded value)? loaded,
    TResult Function(LocalMusicStateImporting value)? importing,
    TResult Function(LocalMusicStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class LocalMusicStateError implements LocalMusicState {
  const factory LocalMusicStateError({required final String message}) =
      _$LocalMusicStateErrorImpl;

  String get message;

  /// Create a copy of LocalMusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalMusicStateErrorImplCopyWith<_$LocalMusicStateErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}
