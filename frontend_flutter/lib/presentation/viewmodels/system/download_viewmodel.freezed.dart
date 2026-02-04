// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DownloadModelState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )
    loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DownloadModelStateInitial value) initial,
    required TResult Function(DownloadModelStateLoading value) loading,
    required TResult Function(DownloadModelStateLoaded value) loaded,
    required TResult Function(DownloadModelStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DownloadModelStateInitial value)? initial,
    TResult? Function(DownloadModelStateLoading value)? loading,
    TResult? Function(DownloadModelStateLoaded value)? loaded,
    TResult? Function(DownloadModelStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DownloadModelStateInitial value)? initial,
    TResult Function(DownloadModelStateLoading value)? loading,
    TResult Function(DownloadModelStateLoaded value)? loaded,
    TResult Function(DownloadModelStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DownloadModelStateCopyWith<$Res> {
  factory $DownloadModelStateCopyWith(
    DownloadModelState value,
    $Res Function(DownloadModelState) then,
  ) = _$DownloadModelStateCopyWithImpl<$Res, DownloadModelState>;
}

/// @nodoc
class _$DownloadModelStateCopyWithImpl<$Res, $Val extends DownloadModelState>
    implements $DownloadModelStateCopyWith<$Res> {
  _$DownloadModelStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DownloadModelStateInitialImplCopyWith<$Res> {
  factory _$$DownloadModelStateInitialImplCopyWith(
    _$DownloadModelStateInitialImpl value,
    $Res Function(_$DownloadModelStateInitialImpl) then,
  ) = __$$DownloadModelStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DownloadModelStateInitialImplCopyWithImpl<$Res>
    extends
        _$DownloadModelStateCopyWithImpl<$Res, _$DownloadModelStateInitialImpl>
    implements _$$DownloadModelStateInitialImplCopyWith<$Res> {
  __$$DownloadModelStateInitialImplCopyWithImpl(
    _$DownloadModelStateInitialImpl _value,
    $Res Function(_$DownloadModelStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DownloadModelStateInitialImpl implements DownloadModelStateInitial {
  const _$DownloadModelStateInitialImpl();

  @override
  String toString() {
    return 'DownloadModelState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadModelStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
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
    TResult? Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    required TResult Function(DownloadModelStateInitial value) initial,
    required TResult Function(DownloadModelStateLoading value) loading,
    required TResult Function(DownloadModelStateLoaded value) loaded,
    required TResult Function(DownloadModelStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DownloadModelStateInitial value)? initial,
    TResult? Function(DownloadModelStateLoading value)? loading,
    TResult? Function(DownloadModelStateLoaded value)? loaded,
    TResult? Function(DownloadModelStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DownloadModelStateInitial value)? initial,
    TResult Function(DownloadModelStateLoading value)? loading,
    TResult Function(DownloadModelStateLoaded value)? loaded,
    TResult Function(DownloadModelStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class DownloadModelStateInitial implements DownloadModelState {
  const factory DownloadModelStateInitial() = _$DownloadModelStateInitialImpl;
}

/// @nodoc
abstract class _$$DownloadModelStateLoadingImplCopyWith<$Res> {
  factory _$$DownloadModelStateLoadingImplCopyWith(
    _$DownloadModelStateLoadingImpl value,
    $Res Function(_$DownloadModelStateLoadingImpl) then,
  ) = __$$DownloadModelStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DownloadModelStateLoadingImplCopyWithImpl<$Res>
    extends
        _$DownloadModelStateCopyWithImpl<$Res, _$DownloadModelStateLoadingImpl>
    implements _$$DownloadModelStateLoadingImplCopyWith<$Res> {
  __$$DownloadModelStateLoadingImplCopyWithImpl(
    _$DownloadModelStateLoadingImpl _value,
    $Res Function(_$DownloadModelStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DownloadModelStateLoadingImpl implements DownloadModelStateLoading {
  const _$DownloadModelStateLoadingImpl();

  @override
  String toString() {
    return 'DownloadModelState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadModelStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
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
    TResult? Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    required TResult Function(DownloadModelStateInitial value) initial,
    required TResult Function(DownloadModelStateLoading value) loading,
    required TResult Function(DownloadModelStateLoaded value) loaded,
    required TResult Function(DownloadModelStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DownloadModelStateInitial value)? initial,
    TResult? Function(DownloadModelStateLoading value)? loading,
    TResult? Function(DownloadModelStateLoaded value)? loaded,
    TResult? Function(DownloadModelStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DownloadModelStateInitial value)? initial,
    TResult Function(DownloadModelStateLoading value)? loading,
    TResult Function(DownloadModelStateLoaded value)? loaded,
    TResult Function(DownloadModelStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class DownloadModelStateLoading implements DownloadModelState {
  const factory DownloadModelStateLoading() = _$DownloadModelStateLoadingImpl;
}

/// @nodoc
abstract class _$$DownloadModelStateLoadedImplCopyWith<$Res> {
  factory _$$DownloadModelStateLoadedImplCopyWith(
    _$DownloadModelStateLoadedImpl value,
    $Res Function(_$DownloadModelStateLoadedImpl) then,
  ) = __$$DownloadModelStateLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<DownloadTask> downloads,
    String downloadStage,
    int downloadProgress,
    DownloadTask? activeTask,
  });
}

/// @nodoc
class __$$DownloadModelStateLoadedImplCopyWithImpl<$Res>
    extends
        _$DownloadModelStateCopyWithImpl<$Res, _$DownloadModelStateLoadedImpl>
    implements _$$DownloadModelStateLoadedImplCopyWith<$Res> {
  __$$DownloadModelStateLoadedImplCopyWithImpl(
    _$DownloadModelStateLoadedImpl _value,
    $Res Function(_$DownloadModelStateLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? downloads = null,
    Object? downloadStage = null,
    Object? downloadProgress = null,
    Object? activeTask = freezed,
  }) {
    return _then(
      _$DownloadModelStateLoadedImpl(
        downloads: null == downloads
            ? _value._downloads
            : downloads // ignore: cast_nullable_to_non_nullable
                  as List<DownloadTask>,
        downloadStage: null == downloadStage
            ? _value.downloadStage
            : downloadStage // ignore: cast_nullable_to_non_nullable
                  as String,
        downloadProgress: null == downloadProgress
            ? _value.downloadProgress
            : downloadProgress // ignore: cast_nullable_to_non_nullable
                  as int,
        activeTask: freezed == activeTask
            ? _value.activeTask
            : activeTask // ignore: cast_nullable_to_non_nullable
                  as DownloadTask?,
      ),
    );
  }
}

/// @nodoc

class _$DownloadModelStateLoadedImpl implements DownloadModelStateLoaded {
  const _$DownloadModelStateLoadedImpl({
    required final List<DownloadTask> downloads,
    this.downloadStage = '',
    this.downloadProgress = 0,
    this.activeTask,
  }) : _downloads = downloads;

  final List<DownloadTask> _downloads;
  @override
  List<DownloadTask> get downloads {
    if (_downloads is EqualUnmodifiableListView) return _downloads;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_downloads);
  }

  @override
  @JsonKey()
  final String downloadStage;
  @override
  @JsonKey()
  final int downloadProgress;
  @override
  final DownloadTask? activeTask;

  @override
  String toString() {
    return 'DownloadModelState.loaded(downloads: $downloads, downloadStage: $downloadStage, downloadProgress: $downloadProgress, activeTask: $activeTask)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadModelStateLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._downloads,
              _downloads,
            ) &&
            (identical(other.downloadStage, downloadStage) ||
                other.downloadStage == downloadStage) &&
            (identical(other.downloadProgress, downloadProgress) ||
                other.downloadProgress == downloadProgress) &&
            (identical(other.activeTask, activeTask) ||
                other.activeTask == activeTask));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_downloads),
    downloadStage,
    downloadProgress,
    activeTask,
  );

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadModelStateLoadedImplCopyWith<_$DownloadModelStateLoadedImpl>
  get copyWith =>
      __$$DownloadModelStateLoadedImplCopyWithImpl<
        _$DownloadModelStateLoadedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(downloads, downloadStage, downloadProgress, activeTask);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(downloads, downloadStage, downloadProgress, activeTask);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(downloads, downloadStage, downloadProgress, activeTask);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DownloadModelStateInitial value) initial,
    required TResult Function(DownloadModelStateLoading value) loading,
    required TResult Function(DownloadModelStateLoaded value) loaded,
    required TResult Function(DownloadModelStateError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DownloadModelStateInitial value)? initial,
    TResult? Function(DownloadModelStateLoading value)? loading,
    TResult? Function(DownloadModelStateLoaded value)? loaded,
    TResult? Function(DownloadModelStateError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DownloadModelStateInitial value)? initial,
    TResult Function(DownloadModelStateLoading value)? loading,
    TResult Function(DownloadModelStateLoaded value)? loaded,
    TResult Function(DownloadModelStateError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class DownloadModelStateLoaded implements DownloadModelState {
  const factory DownloadModelStateLoaded({
    required final List<DownloadTask> downloads,
    final String downloadStage,
    final int downloadProgress,
    final DownloadTask? activeTask,
  }) = _$DownloadModelStateLoadedImpl;

  List<DownloadTask> get downloads;
  String get downloadStage;
  int get downloadProgress;
  DownloadTask? get activeTask;

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadModelStateLoadedImplCopyWith<_$DownloadModelStateLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DownloadModelStateErrorImplCopyWith<$Res> {
  factory _$$DownloadModelStateErrorImplCopyWith(
    _$DownloadModelStateErrorImpl value,
    $Res Function(_$DownloadModelStateErrorImpl) then,
  ) = __$$DownloadModelStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DownloadModelStateErrorImplCopyWithImpl<$Res>
    extends
        _$DownloadModelStateCopyWithImpl<$Res, _$DownloadModelStateErrorImpl>
    implements _$$DownloadModelStateErrorImplCopyWith<$Res> {
  __$$DownloadModelStateErrorImplCopyWithImpl(
    _$DownloadModelStateErrorImpl _value,
    $Res Function(_$DownloadModelStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$DownloadModelStateErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DownloadModelStateErrorImpl implements DownloadModelStateError {
  const _$DownloadModelStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'DownloadModelState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadModelStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadModelStateErrorImplCopyWith<_$DownloadModelStateErrorImpl>
  get copyWith =>
      __$$DownloadModelStateErrorImplCopyWithImpl<
        _$DownloadModelStateErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
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
    TResult? Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    TResult Function(
      List<DownloadTask> downloads,
      String downloadStage,
      int downloadProgress,
      DownloadTask? activeTask,
    )?
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
    required TResult Function(DownloadModelStateInitial value) initial,
    required TResult Function(DownloadModelStateLoading value) loading,
    required TResult Function(DownloadModelStateLoaded value) loaded,
    required TResult Function(DownloadModelStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DownloadModelStateInitial value)? initial,
    TResult? Function(DownloadModelStateLoading value)? loading,
    TResult? Function(DownloadModelStateLoaded value)? loaded,
    TResult? Function(DownloadModelStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DownloadModelStateInitial value)? initial,
    TResult Function(DownloadModelStateLoading value)? loading,
    TResult Function(DownloadModelStateLoaded value)? loaded,
    TResult Function(DownloadModelStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class DownloadModelStateError implements DownloadModelState {
  const factory DownloadModelStateError({required final String message}) =
      _$DownloadModelStateErrorImpl;

  String get message;

  /// Create a copy of DownloadModelState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadModelStateErrorImplCopyWith<_$DownloadModelStateErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}
