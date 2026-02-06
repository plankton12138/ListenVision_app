// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadModelState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadModelState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadModelState()';
}


}

/// @nodoc
class $DownloadModelStateCopyWith<$Res>  {
$DownloadModelStateCopyWith(DownloadModelState _, $Res Function(DownloadModelState) __);
}


/// Adds pattern-matching-related methods to [DownloadModelState].
extension DownloadModelStatePatterns on DownloadModelState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DownloadModelStateInitial value)?  initial,TResult Function( DownloadModelStateLoaded value)?  loaded,TResult Function( DownloadModelStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DownloadModelStateInitial() when initial != null:
return initial(_that);case DownloadModelStateLoaded() when loaded != null:
return loaded(_that);case DownloadModelStateError() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DownloadModelStateInitial value)  initial,required TResult Function( DownloadModelStateLoaded value)  loaded,required TResult Function( DownloadModelStateError value)  error,}){
final _that = this;
switch (_that) {
case DownloadModelStateInitial():
return initial(_that);case DownloadModelStateLoaded():
return loaded(_that);case DownloadModelStateError():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DownloadModelStateInitial value)?  initial,TResult? Function( DownloadModelStateLoaded value)?  loaded,TResult? Function( DownloadModelStateError value)?  error,}){
final _that = this;
switch (_that) {
case DownloadModelStateInitial() when initial != null:
return initial(_that);case DownloadModelStateLoaded() when loaded != null:
return loaded(_that);case DownloadModelStateError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<DownloadTask> downloads)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DownloadModelStateInitial() when initial != null:
return initial();case DownloadModelStateLoaded() when loaded != null:
return loaded(_that.downloads);case DownloadModelStateError() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<DownloadTask> downloads)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case DownloadModelStateInitial():
return initial();case DownloadModelStateLoaded():
return loaded(_that.downloads);case DownloadModelStateError():
return error(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<DownloadTask> downloads)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case DownloadModelStateInitial() when initial != null:
return initial();case DownloadModelStateLoaded() when loaded != null:
return loaded(_that.downloads);case DownloadModelStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DownloadModelStateInitial implements DownloadModelState {
  const DownloadModelStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadModelStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadModelState.initial()';
}


}




/// @nodoc


class DownloadModelStateLoaded implements DownloadModelState {
  const DownloadModelStateLoaded({required final  List<DownloadTask> downloads}): _downloads = downloads;
  

 final  List<DownloadTask> _downloads;
 List<DownloadTask> get downloads {
  if (_downloads is EqualUnmodifiableListView) return _downloads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_downloads);
}


/// Create a copy of DownloadModelState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadModelStateLoadedCopyWith<DownloadModelStateLoaded> get copyWith => _$DownloadModelStateLoadedCopyWithImpl<DownloadModelStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadModelStateLoaded&&const DeepCollectionEquality().equals(other._downloads, _downloads));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_downloads));

@override
String toString() {
  return 'DownloadModelState.loaded(downloads: $downloads)';
}


}

/// @nodoc
abstract mixin class $DownloadModelStateLoadedCopyWith<$Res> implements $DownloadModelStateCopyWith<$Res> {
  factory $DownloadModelStateLoadedCopyWith(DownloadModelStateLoaded value, $Res Function(DownloadModelStateLoaded) _then) = _$DownloadModelStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<DownloadTask> downloads
});




}
/// @nodoc
class _$DownloadModelStateLoadedCopyWithImpl<$Res>
    implements $DownloadModelStateLoadedCopyWith<$Res> {
  _$DownloadModelStateLoadedCopyWithImpl(this._self, this._then);

  final DownloadModelStateLoaded _self;
  final $Res Function(DownloadModelStateLoaded) _then;

/// Create a copy of DownloadModelState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? downloads = null,}) {
  return _then(DownloadModelStateLoaded(
downloads: null == downloads ? _self._downloads : downloads // ignore: cast_nullable_to_non_nullable
as List<DownloadTask>,
  ));
}


}

/// @nodoc


class DownloadModelStateError implements DownloadModelState {
  const DownloadModelStateError({required this.message});
  

 final  String message;

/// Create a copy of DownloadModelState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadModelStateErrorCopyWith<DownloadModelStateError> get copyWith => _$DownloadModelStateErrorCopyWithImpl<DownloadModelStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadModelStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DownloadModelState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $DownloadModelStateErrorCopyWith<$Res> implements $DownloadModelStateCopyWith<$Res> {
  factory $DownloadModelStateErrorCopyWith(DownloadModelStateError value, $Res Function(DownloadModelStateError) _then) = _$DownloadModelStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DownloadModelStateErrorCopyWithImpl<$Res>
    implements $DownloadModelStateErrorCopyWith<$Res> {
  _$DownloadModelStateErrorCopyWithImpl(this._self, this._then);

  final DownloadModelStateError _self;
  final $Res Function(DownloadModelStateError) _then;

/// Create a copy of DownloadModelState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DownloadModelStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
