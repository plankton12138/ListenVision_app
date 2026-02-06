// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_detail_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistDetailState()';
}


}

/// @nodoc
class $PlaylistDetailStateCopyWith<$Res>  {
$PlaylistDetailStateCopyWith(PlaylistDetailState _, $Res Function(PlaylistDetailState) __);
}


/// Adds pattern-matching-related methods to [PlaylistDetailState].
extension PlaylistDetailStatePatterns on PlaylistDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistDetailStateInitial value)?  initial,TResult Function( PlaylistDetailStateLoading value)?  loading,TResult Function( PlaylistDetailStateLoaded value)?  loaded,TResult Function( PlaylistDetailStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistDetailStateInitial() when initial != null:
return initial(_that);case PlaylistDetailStateLoading() when loading != null:
return loading(_that);case PlaylistDetailStateLoaded() when loaded != null:
return loaded(_that);case PlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistDetailStateInitial value)  initial,required TResult Function( PlaylistDetailStateLoading value)  loading,required TResult Function( PlaylistDetailStateLoaded value)  loaded,required TResult Function( PlaylistDetailStateError value)  error,}){
final _that = this;
switch (_that) {
case PlaylistDetailStateInitial():
return initial(_that);case PlaylistDetailStateLoading():
return loading(_that);case PlaylistDetailStateLoaded():
return loaded(_that);case PlaylistDetailStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistDetailStateInitial value)?  initial,TResult? Function( PlaylistDetailStateLoading value)?  loading,TResult? Function( PlaylistDetailStateLoaded value)?  loaded,TResult? Function( PlaylistDetailStateError value)?  error,}){
final _that = this;
switch (_that) {
case PlaylistDetailStateInitial() when initial != null:
return initial(_that);case PlaylistDetailStateLoading() when loading != null:
return loading(_that);case PlaylistDetailStateLoaded() when loaded != null:
return loaded(_that);case PlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Playlist playlist,  List<PlaylistItem> items,  bool isOwner)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistDetailStateInitial() when initial != null:
return initial();case PlaylistDetailStateLoading() when loading != null:
return loading();case PlaylistDetailStateLoaded() when loaded != null:
return loaded(_that.playlist,_that.items,_that.isOwner);case PlaylistDetailStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Playlist playlist,  List<PlaylistItem> items,  bool isOwner)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case PlaylistDetailStateInitial():
return initial();case PlaylistDetailStateLoading():
return loading();case PlaylistDetailStateLoaded():
return loaded(_that.playlist,_that.items,_that.isOwner);case PlaylistDetailStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Playlist playlist,  List<PlaylistItem> items,  bool isOwner)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case PlaylistDetailStateInitial() when initial != null:
return initial();case PlaylistDetailStateLoading() when loading != null:
return loading();case PlaylistDetailStateLoaded() when loaded != null:
return loaded(_that.playlist,_that.items,_that.isOwner);case PlaylistDetailStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistDetailStateInitial implements PlaylistDetailState {
  const PlaylistDetailStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistDetailState.initial()';
}


}




/// @nodoc


class PlaylistDetailStateLoading implements PlaylistDetailState {
  const PlaylistDetailStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistDetailState.loading()';
}


}




/// @nodoc


class PlaylistDetailStateLoaded implements PlaylistDetailState {
  const PlaylistDetailStateLoaded({required this.playlist, required final  List<PlaylistItem> items, this.isOwner = false}): _items = items;
  

 final  Playlist playlist;
 final  List<PlaylistItem> _items;
 List<PlaylistItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@JsonKey() final  bool isOwner;

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailStateLoadedCopyWith<PlaylistDetailStateLoaded> get copyWith => _$PlaylistDetailStateLoadedCopyWithImpl<PlaylistDetailStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateLoaded&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_items),isOwner);

@override
String toString() {
  return 'PlaylistDetailState.loaded(playlist: $playlist, items: $items, isOwner: $isOwner)';
}


}

/// @nodoc
abstract mixin class $PlaylistDetailStateLoadedCopyWith<$Res> implements $PlaylistDetailStateCopyWith<$Res> {
  factory $PlaylistDetailStateLoadedCopyWith(PlaylistDetailStateLoaded value, $Res Function(PlaylistDetailStateLoaded) _then) = _$PlaylistDetailStateLoadedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<PlaylistItem> items, bool isOwner
});


$PlaylistCopyWith<$Res> get playlist;

}
/// @nodoc
class _$PlaylistDetailStateLoadedCopyWithImpl<$Res>
    implements $PlaylistDetailStateLoadedCopyWith<$Res> {
  _$PlaylistDetailStateLoadedCopyWithImpl(this._self, this._then);

  final PlaylistDetailStateLoaded _self;
  final $Res Function(PlaylistDetailStateLoaded) _then;

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? items = null,Object? isOwner = null,}) {
  return _then(PlaylistDetailStateLoaded(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res> get playlist {
  
  return $PlaylistCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}

/// @nodoc


class PlaylistDetailStateError implements PlaylistDetailState {
  const PlaylistDetailStateError({required this.message});
  

 final  String message;

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailStateErrorCopyWith<PlaylistDetailStateError> get copyWith => _$PlaylistDetailStateErrorCopyWithImpl<PlaylistDetailStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaylistDetailState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaylistDetailStateErrorCopyWith<$Res> implements $PlaylistDetailStateCopyWith<$Res> {
  factory $PlaylistDetailStateErrorCopyWith(PlaylistDetailStateError value, $Res Function(PlaylistDetailStateError) _then) = _$PlaylistDetailStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PlaylistDetailStateErrorCopyWithImpl<$Res>
    implements $PlaylistDetailStateErrorCopyWith<$Res> {
  _$PlaylistDetailStateErrorCopyWithImpl(this._self, this._then);

  final PlaylistDetailStateError _self;
  final $Res Function(PlaylistDetailStateError) _then;

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PlaylistDetailStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
