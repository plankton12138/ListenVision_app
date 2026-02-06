// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistState()';
}


}

/// @nodoc
class $PlaylistStateCopyWith<$Res>  {
$PlaylistStateCopyWith(PlaylistState _, $Res Function(PlaylistState) __);
}


/// Adds pattern-matching-related methods to [PlaylistState].
extension PlaylistStatePatterns on PlaylistState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistStateInitial value)?  initial,TResult Function( PlaylistStateLoaded value)?  loaded,TResult Function( PlaylistStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistStateInitial() when initial != null:
return initial(_that);case PlaylistStateLoaded() when loaded != null:
return loaded(_that);case PlaylistStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistStateInitial value)  initial,required TResult Function( PlaylistStateLoaded value)  loaded,required TResult Function( PlaylistStateError value)  error,}){
final _that = this;
switch (_that) {
case PlaylistStateInitial():
return initial(_that);case PlaylistStateLoaded():
return loaded(_that);case PlaylistStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistStateInitial value)?  initial,TResult? Function( PlaylistStateLoaded value)?  loaded,TResult? Function( PlaylistStateError value)?  error,}){
final _that = this;
switch (_that) {
case PlaylistStateInitial() when initial != null:
return initial(_that);case PlaylistStateLoaded() when loaded != null:
return loaded(_that);case PlaylistStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<Playlist> playlists,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists,  Playlist? favoritesPlaylist,  Playlist? nowPlayingPlaylist,  List<PlaylistItem> favoritesItems,  List<PlaylistItem> nowPlayingItems)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistStateInitial() when initial != null:
return initial();case PlaylistStateLoaded() when loaded != null:
return loaded(_that.playlists,_that.userPlaylists,_that.systemPlaylists,_that.favoritesPlaylist,_that.nowPlayingPlaylist,_that.favoritesItems,_that.nowPlayingItems);case PlaylistStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<Playlist> playlists,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists,  Playlist? favoritesPlaylist,  Playlist? nowPlayingPlaylist,  List<PlaylistItem> favoritesItems,  List<PlaylistItem> nowPlayingItems)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case PlaylistStateInitial():
return initial();case PlaylistStateLoaded():
return loaded(_that.playlists,_that.userPlaylists,_that.systemPlaylists,_that.favoritesPlaylist,_that.nowPlayingPlaylist,_that.favoritesItems,_that.nowPlayingItems);case PlaylistStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<Playlist> playlists,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists,  Playlist? favoritesPlaylist,  Playlist? nowPlayingPlaylist,  List<PlaylistItem> favoritesItems,  List<PlaylistItem> nowPlayingItems)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case PlaylistStateInitial() when initial != null:
return initial();case PlaylistStateLoaded() when loaded != null:
return loaded(_that.playlists,_that.userPlaylists,_that.systemPlaylists,_that.favoritesPlaylist,_that.nowPlayingPlaylist,_that.favoritesItems,_that.nowPlayingItems);case PlaylistStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistStateInitial implements PlaylistState {
  const PlaylistStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistState.initial()';
}


}




/// @nodoc


class PlaylistStateLoaded implements PlaylistState {
  const PlaylistStateLoaded({required final  List<Playlist> playlists, required final  List<Playlist> userPlaylists, required final  List<Playlist> systemPlaylists, this.favoritesPlaylist, this.nowPlayingPlaylist, final  List<PlaylistItem> favoritesItems = const [], final  List<PlaylistItem> nowPlayingItems = const []}): _playlists = playlists,_userPlaylists = userPlaylists,_systemPlaylists = systemPlaylists,_favoritesItems = favoritesItems,_nowPlayingItems = nowPlayingItems;
  

 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}

 final  List<Playlist> _userPlaylists;
 List<Playlist> get userPlaylists {
  if (_userPlaylists is EqualUnmodifiableListView) return _userPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userPlaylists);
}

 final  List<Playlist> _systemPlaylists;
 List<Playlist> get systemPlaylists {
  if (_systemPlaylists is EqualUnmodifiableListView) return _systemPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_systemPlaylists);
}

 final  Playlist? favoritesPlaylist;
 final  Playlist? nowPlayingPlaylist;
 final  List<PlaylistItem> _favoritesItems;
@JsonKey() List<PlaylistItem> get favoritesItems {
  if (_favoritesItems is EqualUnmodifiableListView) return _favoritesItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoritesItems);
}

 final  List<PlaylistItem> _nowPlayingItems;
@JsonKey() List<PlaylistItem> get nowPlayingItems {
  if (_nowPlayingItems is EqualUnmodifiableListView) return _nowPlayingItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nowPlayingItems);
}


/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistStateLoadedCopyWith<PlaylistStateLoaded> get copyWith => _$PlaylistStateLoadedCopyWithImpl<PlaylistStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistStateLoaded&&const DeepCollectionEquality().equals(other._playlists, _playlists)&&const DeepCollectionEquality().equals(other._userPlaylists, _userPlaylists)&&const DeepCollectionEquality().equals(other._systemPlaylists, _systemPlaylists)&&(identical(other.favoritesPlaylist, favoritesPlaylist) || other.favoritesPlaylist == favoritesPlaylist)&&(identical(other.nowPlayingPlaylist, nowPlayingPlaylist) || other.nowPlayingPlaylist == nowPlayingPlaylist)&&const DeepCollectionEquality().equals(other._favoritesItems, _favoritesItems)&&const DeepCollectionEquality().equals(other._nowPlayingItems, _nowPlayingItems));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists),const DeepCollectionEquality().hash(_userPlaylists),const DeepCollectionEquality().hash(_systemPlaylists),favoritesPlaylist,nowPlayingPlaylist,const DeepCollectionEquality().hash(_favoritesItems),const DeepCollectionEquality().hash(_nowPlayingItems));

@override
String toString() {
  return 'PlaylistState.loaded(playlists: $playlists, userPlaylists: $userPlaylists, systemPlaylists: $systemPlaylists, favoritesPlaylist: $favoritesPlaylist, nowPlayingPlaylist: $nowPlayingPlaylist, favoritesItems: $favoritesItems, nowPlayingItems: $nowPlayingItems)';
}


}

/// @nodoc
abstract mixin class $PlaylistStateLoadedCopyWith<$Res> implements $PlaylistStateCopyWith<$Res> {
  factory $PlaylistStateLoadedCopyWith(PlaylistStateLoaded value, $Res Function(PlaylistStateLoaded) _then) = _$PlaylistStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<Playlist> playlists, List<Playlist> userPlaylists, List<Playlist> systemPlaylists, Playlist? favoritesPlaylist, Playlist? nowPlayingPlaylist, List<PlaylistItem> favoritesItems, List<PlaylistItem> nowPlayingItems
});


$PlaylistCopyWith<$Res>? get favoritesPlaylist;$PlaylistCopyWith<$Res>? get nowPlayingPlaylist;

}
/// @nodoc
class _$PlaylistStateLoadedCopyWithImpl<$Res>
    implements $PlaylistStateLoadedCopyWith<$Res> {
  _$PlaylistStateLoadedCopyWithImpl(this._self, this._then);

  final PlaylistStateLoaded _self;
  final $Res Function(PlaylistStateLoaded) _then;

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlists = null,Object? userPlaylists = null,Object? systemPlaylists = null,Object? favoritesPlaylist = freezed,Object? nowPlayingPlaylist = freezed,Object? favoritesItems = null,Object? nowPlayingItems = null,}) {
  return _then(PlaylistStateLoaded(
playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,userPlaylists: null == userPlaylists ? _self._userPlaylists : userPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,systemPlaylists: null == systemPlaylists ? _self._systemPlaylists : systemPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,favoritesPlaylist: freezed == favoritesPlaylist ? _self.favoritesPlaylist : favoritesPlaylist // ignore: cast_nullable_to_non_nullable
as Playlist?,nowPlayingPlaylist: freezed == nowPlayingPlaylist ? _self.nowPlayingPlaylist : nowPlayingPlaylist // ignore: cast_nullable_to_non_nullable
as Playlist?,favoritesItems: null == favoritesItems ? _self._favoritesItems : favoritesItems // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,nowPlayingItems: null == nowPlayingItems ? _self._nowPlayingItems : nowPlayingItems // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,
  ));
}

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res>? get favoritesPlaylist {
    if (_self.favoritesPlaylist == null) {
    return null;
  }

  return $PlaylistCopyWith<$Res>(_self.favoritesPlaylist!, (value) {
    return _then(_self.copyWith(favoritesPlaylist: value));
  });
}/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res>? get nowPlayingPlaylist {
    if (_self.nowPlayingPlaylist == null) {
    return null;
  }

  return $PlaylistCopyWith<$Res>(_self.nowPlayingPlaylist!, (value) {
    return _then(_self.copyWith(nowPlayingPlaylist: value));
  });
}
}

/// @nodoc


class PlaylistStateError implements PlaylistState {
  const PlaylistStateError({required this.message});
  

 final  String message;

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistStateErrorCopyWith<PlaylistStateError> get copyWith => _$PlaylistStateErrorCopyWithImpl<PlaylistStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaylistState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaylistStateErrorCopyWith<$Res> implements $PlaylistStateCopyWith<$Res> {
  factory $PlaylistStateErrorCopyWith(PlaylistStateError value, $Res Function(PlaylistStateError) _then) = _$PlaylistStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PlaylistStateErrorCopyWithImpl<$Res>
    implements $PlaylistStateErrorCopyWith<$Res> {
  _$PlaylistStateErrorCopyWithImpl(this._self, this._then);

  final PlaylistStateError _self;
  final $Res Function(PlaylistStateError) _then;

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PlaylistStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
