// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'netease_playlist_detail_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NeteasePlaylistDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteasePlaylistDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteasePlaylistDetailState()';
}


}

/// @nodoc
class $NeteasePlaylistDetailStateCopyWith<$Res>  {
$NeteasePlaylistDetailStateCopyWith(NeteasePlaylistDetailState _, $Res Function(NeteasePlaylistDetailState) __);
}


/// Adds pattern-matching-related methods to [NeteasePlaylistDetailState].
extension NeteasePlaylistDetailStatePatterns on NeteasePlaylistDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NeteasePlaylistDetailStateInitial value)?  initial,TResult Function( NeteasePlaylistDetailStateLoading value)?  loading,TResult Function( NeteasePlaylistDetailStateLoaded value)?  loaded,TResult Function( NeteasePlaylistDetailStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial() when initial != null:
return initial(_that);case NeteasePlaylistDetailStateLoading() when loading != null:
return loading(_that);case NeteasePlaylistDetailStateLoaded() when loaded != null:
return loaded(_that);case NeteasePlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NeteasePlaylistDetailStateInitial value)  initial,required TResult Function( NeteasePlaylistDetailStateLoading value)  loading,required TResult Function( NeteasePlaylistDetailStateLoaded value)  loaded,required TResult Function( NeteasePlaylistDetailStateError value)  error,}){
final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial():
return initial(_that);case NeteasePlaylistDetailStateLoading():
return loading(_that);case NeteasePlaylistDetailStateLoaded():
return loaded(_that);case NeteasePlaylistDetailStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NeteasePlaylistDetailStateInitial value)?  initial,TResult? Function( NeteasePlaylistDetailStateLoading value)?  loading,TResult? Function( NeteasePlaylistDetailStateLoaded value)?  loaded,TResult? Function( NeteasePlaylistDetailStateError value)?  error,}){
final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial() when initial != null:
return initial(_that);case NeteasePlaylistDetailStateLoading() when loading != null:
return loading(_that);case NeteasePlaylistDetailStateLoaded() when loaded != null:
return loaded(_that);case NeteasePlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( NeteasePlaylistDetail playlist)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial() when initial != null:
return initial();case NeteasePlaylistDetailStateLoading() when loading != null:
return loading();case NeteasePlaylistDetailStateLoaded() when loaded != null:
return loaded(_that.playlist);case NeteasePlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( NeteasePlaylistDetail playlist)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial():
return initial();case NeteasePlaylistDetailStateLoading():
return loading();case NeteasePlaylistDetailStateLoaded():
return loaded(_that.playlist);case NeteasePlaylistDetailStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( NeteasePlaylistDetail playlist)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case NeteasePlaylistDetailStateInitial() when initial != null:
return initial();case NeteasePlaylistDetailStateLoading() when loading != null:
return loading();case NeteasePlaylistDetailStateLoaded() when loaded != null:
return loaded(_that.playlist);case NeteasePlaylistDetailStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class NeteasePlaylistDetailStateInitial implements NeteasePlaylistDetailState {
  const NeteasePlaylistDetailStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteasePlaylistDetailStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteasePlaylistDetailState.initial()';
}


}




/// @nodoc


class NeteasePlaylistDetailStateLoading implements NeteasePlaylistDetailState {
  const NeteasePlaylistDetailStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteasePlaylistDetailStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteasePlaylistDetailState.loading()';
}


}




/// @nodoc


class NeteasePlaylistDetailStateLoaded implements NeteasePlaylistDetailState {
  const NeteasePlaylistDetailStateLoaded({required this.playlist});
  

 final  NeteasePlaylistDetail playlist;

/// Create a copy of NeteasePlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteasePlaylistDetailStateLoadedCopyWith<NeteasePlaylistDetailStateLoaded> get copyWith => _$NeteasePlaylistDetailStateLoadedCopyWithImpl<NeteasePlaylistDetailStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteasePlaylistDetailStateLoaded&&(identical(other.playlist, playlist) || other.playlist == playlist));
}


@override
int get hashCode => Object.hash(runtimeType,playlist);

@override
String toString() {
  return 'NeteasePlaylistDetailState.loaded(playlist: $playlist)';
}


}

/// @nodoc
abstract mixin class $NeteasePlaylistDetailStateLoadedCopyWith<$Res> implements $NeteasePlaylistDetailStateCopyWith<$Res> {
  factory $NeteasePlaylistDetailStateLoadedCopyWith(NeteasePlaylistDetailStateLoaded value, $Res Function(NeteasePlaylistDetailStateLoaded) _then) = _$NeteasePlaylistDetailStateLoadedCopyWithImpl;
@useResult
$Res call({
 NeteasePlaylistDetail playlist
});




}
/// @nodoc
class _$NeteasePlaylistDetailStateLoadedCopyWithImpl<$Res>
    implements $NeteasePlaylistDetailStateLoadedCopyWith<$Res> {
  _$NeteasePlaylistDetailStateLoadedCopyWithImpl(this._self, this._then);

  final NeteasePlaylistDetailStateLoaded _self;
  final $Res Function(NeteasePlaylistDetailStateLoaded) _then;

/// Create a copy of NeteasePlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,}) {
  return _then(NeteasePlaylistDetailStateLoaded(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as NeteasePlaylistDetail,
  ));
}


}

/// @nodoc


class NeteasePlaylistDetailStateError implements NeteasePlaylistDetailState {
  const NeteasePlaylistDetailStateError({required this.message});
  

 final  String message;

/// Create a copy of NeteasePlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteasePlaylistDetailStateErrorCopyWith<NeteasePlaylistDetailStateError> get copyWith => _$NeteasePlaylistDetailStateErrorCopyWithImpl<NeteasePlaylistDetailStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteasePlaylistDetailStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NeteasePlaylistDetailState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $NeteasePlaylistDetailStateErrorCopyWith<$Res> implements $NeteasePlaylistDetailStateCopyWith<$Res> {
  factory $NeteasePlaylistDetailStateErrorCopyWith(NeteasePlaylistDetailStateError value, $Res Function(NeteasePlaylistDetailStateError) _then) = _$NeteasePlaylistDetailStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NeteasePlaylistDetailStateErrorCopyWithImpl<$Res>
    implements $NeteasePlaylistDetailStateErrorCopyWith<$Res> {
  _$NeteasePlaylistDetailStateErrorCopyWithImpl(this._self, this._then);

  final NeteasePlaylistDetailStateError _self;
  final $Res Function(NeteasePlaylistDetailStateError) _then;

/// Create a copy of NeteasePlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NeteasePlaylistDetailStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
