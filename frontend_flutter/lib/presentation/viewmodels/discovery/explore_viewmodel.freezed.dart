// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExploreState()';
}


}

/// @nodoc
class $ExploreStateCopyWith<$Res>  {
$ExploreStateCopyWith(ExploreState _, $Res Function(ExploreState) __);
}


/// Adds pattern-matching-related methods to [ExploreState].
extension ExploreStatePatterns on ExploreState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExploreStateInitial value)?  initial,TResult Function( ExploreStateLoading value)?  loading,TResult Function( ExploreStateNotBound value)?  notBound,TResult Function( ExploreStateLoaded value)?  loaded,TResult Function( ExploreStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExploreStateInitial() when initial != null:
return initial(_that);case ExploreStateLoading() when loading != null:
return loading(_that);case ExploreStateNotBound() when notBound != null:
return notBound(_that);case ExploreStateLoaded() when loaded != null:
return loaded(_that);case ExploreStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExploreStateInitial value)  initial,required TResult Function( ExploreStateLoading value)  loading,required TResult Function( ExploreStateNotBound value)  notBound,required TResult Function( ExploreStateLoaded value)  loaded,required TResult Function( ExploreStateError value)  error,}){
final _that = this;
switch (_that) {
case ExploreStateInitial():
return initial(_that);case ExploreStateLoading():
return loading(_that);case ExploreStateNotBound():
return notBound(_that);case ExploreStateLoaded():
return loaded(_that);case ExploreStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExploreStateInitial value)?  initial,TResult? Function( ExploreStateLoading value)?  loading,TResult? Function( ExploreStateNotBound value)?  notBound,TResult? Function( ExploreStateLoaded value)?  loaded,TResult? Function( ExploreStateError value)?  error,}){
final _that = this;
switch (_that) {
case ExploreStateInitial() when initial != null:
return initial(_that);case ExploreStateLoading() when loading != null:
return loading(_that);case ExploreStateNotBound() when notBound != null:
return notBound(_that);case ExploreStateLoaded() when loaded != null:
return loaded(_that);case ExploreStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  notBound,TResult Function( List<ExploreItem> items,  bool hasMore,  int currentPage,  ExploreType type)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExploreStateInitial() when initial != null:
return initial();case ExploreStateLoading() when loading != null:
return loading();case ExploreStateNotBound() when notBound != null:
return notBound();case ExploreStateLoaded() when loaded != null:
return loaded(_that.items,_that.hasMore,_that.currentPage,_that.type);case ExploreStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  notBound,required TResult Function( List<ExploreItem> items,  bool hasMore,  int currentPage,  ExploreType type)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ExploreStateInitial():
return initial();case ExploreStateLoading():
return loading();case ExploreStateNotBound():
return notBound();case ExploreStateLoaded():
return loaded(_that.items,_that.hasMore,_that.currentPage,_that.type);case ExploreStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  notBound,TResult? Function( List<ExploreItem> items,  bool hasMore,  int currentPage,  ExploreType type)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ExploreStateInitial() when initial != null:
return initial();case ExploreStateLoading() when loading != null:
return loading();case ExploreStateNotBound() when notBound != null:
return notBound();case ExploreStateLoaded() when loaded != null:
return loaded(_that.items,_that.hasMore,_that.currentPage,_that.type);case ExploreStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ExploreStateInitial implements ExploreState {
  const ExploreStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExploreState.initial()';
}


}




/// @nodoc


class ExploreStateLoading implements ExploreState {
  const ExploreStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExploreState.loading()';
}


}




/// @nodoc


class ExploreStateNotBound implements ExploreState {
  const ExploreStateNotBound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreStateNotBound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExploreState.notBound()';
}


}




/// @nodoc


class ExploreStateLoaded implements ExploreState {
  const ExploreStateLoaded({required final  List<ExploreItem> items, required this.hasMore, required this.currentPage, required this.type}): _items = items;
  

 final  List<ExploreItem> _items;
 List<ExploreItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  bool hasMore;
 final  int currentPage;
 final  ExploreType type;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreStateLoadedCopyWith<ExploreStateLoaded> get copyWith => _$ExploreStateLoadedCopyWithImpl<ExploreStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreStateLoaded&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,currentPage,type);

@override
String toString() {
  return 'ExploreState.loaded(items: $items, hasMore: $hasMore, currentPage: $currentPage, type: $type)';
}


}

/// @nodoc
abstract mixin class $ExploreStateLoadedCopyWith<$Res> implements $ExploreStateCopyWith<$Res> {
  factory $ExploreStateLoadedCopyWith(ExploreStateLoaded value, $Res Function(ExploreStateLoaded) _then) = _$ExploreStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<ExploreItem> items, bool hasMore, int currentPage, ExploreType type
});




}
/// @nodoc
class _$ExploreStateLoadedCopyWithImpl<$Res>
    implements $ExploreStateLoadedCopyWith<$Res> {
  _$ExploreStateLoadedCopyWithImpl(this._self, this._then);

  final ExploreStateLoaded _self;
  final $Res Function(ExploreStateLoaded) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? currentPage = null,Object? type = null,}) {
  return _then(ExploreStateLoaded(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ExploreItem>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ExploreType,
  ));
}


}

/// @nodoc


class ExploreStateError implements ExploreState {
  const ExploreStateError({required this.message});
  

 final  String message;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreStateErrorCopyWith<ExploreStateError> get copyWith => _$ExploreStateErrorCopyWithImpl<ExploreStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ExploreState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ExploreStateErrorCopyWith<$Res> implements $ExploreStateCopyWith<$Res> {
  factory $ExploreStateErrorCopyWith(ExploreStateError value, $Res Function(ExploreStateError) _then) = _$ExploreStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ExploreStateErrorCopyWithImpl<$Res>
    implements $ExploreStateErrorCopyWith<$Res> {
  _$ExploreStateErrorCopyWithImpl(this._self, this._then);

  final ExploreStateError _self;
  final $Res Function(ExploreStateError) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ExploreStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$NeteaseExploreState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseExploreState()';
}


}

/// @nodoc
class $NeteaseExploreStateCopyWith<$Res>  {
$NeteaseExploreStateCopyWith(NeteaseExploreState _, $Res Function(NeteaseExploreState) __);
}


/// Adds pattern-matching-related methods to [NeteaseExploreState].
extension NeteaseExploreStatePatterns on NeteaseExploreState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NeteaseExploreStateInitial value)?  initial,TResult Function( NeteaseExploreStateLoading value)?  loading,TResult Function( NeteaseExploreStateNotBound value)?  notBound,TResult Function( NeteaseExploreStateLoaded value)?  loaded,TResult Function( NeteaseExploreStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NeteaseExploreStateInitial() when initial != null:
return initial(_that);case NeteaseExploreStateLoading() when loading != null:
return loading(_that);case NeteaseExploreStateNotBound() when notBound != null:
return notBound(_that);case NeteaseExploreStateLoaded() when loaded != null:
return loaded(_that);case NeteaseExploreStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NeteaseExploreStateInitial value)  initial,required TResult Function( NeteaseExploreStateLoading value)  loading,required TResult Function( NeteaseExploreStateNotBound value)  notBound,required TResult Function( NeteaseExploreStateLoaded value)  loaded,required TResult Function( NeteaseExploreStateError value)  error,}){
final _that = this;
switch (_that) {
case NeteaseExploreStateInitial():
return initial(_that);case NeteaseExploreStateLoading():
return loading(_that);case NeteaseExploreStateNotBound():
return notBound(_that);case NeteaseExploreStateLoaded():
return loaded(_that);case NeteaseExploreStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NeteaseExploreStateInitial value)?  initial,TResult? Function( NeteaseExploreStateLoading value)?  loading,TResult? Function( NeteaseExploreStateNotBound value)?  notBound,TResult? Function( NeteaseExploreStateLoaded value)?  loaded,TResult? Function( NeteaseExploreStateError value)?  error,}){
final _that = this;
switch (_that) {
case NeteaseExploreStateInitial() when initial != null:
return initial(_that);case NeteaseExploreStateLoading() when loading != null:
return loading(_that);case NeteaseExploreStateNotBound() when notBound != null:
return notBound(_that);case NeteaseExploreStateLoaded() when loaded != null:
return loaded(_that);case NeteaseExploreStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  notBound,TResult Function( List<NeteasePlaylistItem> playlists)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NeteaseExploreStateInitial() when initial != null:
return initial();case NeteaseExploreStateLoading() when loading != null:
return loading();case NeteaseExploreStateNotBound() when notBound != null:
return notBound();case NeteaseExploreStateLoaded() when loaded != null:
return loaded(_that.playlists);case NeteaseExploreStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  notBound,required TResult Function( List<NeteasePlaylistItem> playlists)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case NeteaseExploreStateInitial():
return initial();case NeteaseExploreStateLoading():
return loading();case NeteaseExploreStateNotBound():
return notBound();case NeteaseExploreStateLoaded():
return loaded(_that.playlists);case NeteaseExploreStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  notBound,TResult? Function( List<NeteasePlaylistItem> playlists)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case NeteaseExploreStateInitial() when initial != null:
return initial();case NeteaseExploreStateLoading() when loading != null:
return loading();case NeteaseExploreStateNotBound() when notBound != null:
return notBound();case NeteaseExploreStateLoaded() when loaded != null:
return loaded(_that.playlists);case NeteaseExploreStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class NeteaseExploreStateInitial implements NeteaseExploreState {
  const NeteaseExploreStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseExploreState.initial()';
}


}




/// @nodoc


class NeteaseExploreStateLoading implements NeteaseExploreState {
  const NeteaseExploreStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseExploreState.loading()';
}


}




/// @nodoc


class NeteaseExploreStateNotBound implements NeteaseExploreState {
  const NeteaseExploreStateNotBound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreStateNotBound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseExploreState.notBound()';
}


}




/// @nodoc


class NeteaseExploreStateLoaded implements NeteaseExploreState {
  const NeteaseExploreStateLoaded({required final  List<NeteasePlaylistItem> playlists}): _playlists = playlists;
  

 final  List<NeteasePlaylistItem> _playlists;
 List<NeteasePlaylistItem> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of NeteaseExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteaseExploreStateLoadedCopyWith<NeteaseExploreStateLoaded> get copyWith => _$NeteaseExploreStateLoadedCopyWithImpl<NeteaseExploreStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreStateLoaded&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'NeteaseExploreState.loaded(playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $NeteaseExploreStateLoadedCopyWith<$Res> implements $NeteaseExploreStateCopyWith<$Res> {
  factory $NeteaseExploreStateLoadedCopyWith(NeteaseExploreStateLoaded value, $Res Function(NeteaseExploreStateLoaded) _then) = _$NeteaseExploreStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<NeteasePlaylistItem> playlists
});




}
/// @nodoc
class _$NeteaseExploreStateLoadedCopyWithImpl<$Res>
    implements $NeteaseExploreStateLoadedCopyWith<$Res> {
  _$NeteaseExploreStateLoadedCopyWithImpl(this._self, this._then);

  final NeteaseExploreStateLoaded _self;
  final $Res Function(NeteaseExploreStateLoaded) _then;

/// Create a copy of NeteaseExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlists = null,}) {
  return _then(NeteaseExploreStateLoaded(
playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<NeteasePlaylistItem>,
  ));
}


}

/// @nodoc


class NeteaseExploreStateError implements NeteaseExploreState {
  const NeteaseExploreStateError({required this.message});
  

 final  String message;

/// Create a copy of NeteaseExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteaseExploreStateErrorCopyWith<NeteaseExploreStateError> get copyWith => _$NeteaseExploreStateErrorCopyWithImpl<NeteaseExploreStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseExploreStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NeteaseExploreState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $NeteaseExploreStateErrorCopyWith<$Res> implements $NeteaseExploreStateCopyWith<$Res> {
  factory $NeteaseExploreStateErrorCopyWith(NeteaseExploreStateError value, $Res Function(NeteaseExploreStateError) _then) = _$NeteaseExploreStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NeteaseExploreStateErrorCopyWithImpl<$Res>
    implements $NeteaseExploreStateErrorCopyWith<$Res> {
  _$NeteaseExploreStateErrorCopyWithImpl(this._self, this._then);

  final NeteaseExploreStateError _self;
  final $Res Function(NeteaseExploreStateError) _then;

/// Create a copy of NeteaseExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NeteaseExploreStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
