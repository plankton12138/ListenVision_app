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
mixin _$PlaylistDetailState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaylistDetailState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
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


class PlaylistDetailStateInitial with DiagnosticableTreeMixin implements PlaylistDetailState {
  const PlaylistDetailStateInitial();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaylistDetailState.initial'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaylistDetailState.initial()';
}


}




/// @nodoc


class PlaylistDetailStateLoading with DiagnosticableTreeMixin implements PlaylistDetailState {
  const PlaylistDetailStateLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaylistDetailState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaylistDetailState.loading()';
}


}




/// @nodoc


class PlaylistDetailStateLoaded with DiagnosticableTreeMixin implements PlaylistDetailState {
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
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaylistDetailState.loaded'))
    ..add(DiagnosticsProperty('playlist', playlist))..add(DiagnosticsProperty('items', items))..add(DiagnosticsProperty('isOwner', isOwner));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateLoaded&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_items),isOwner);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
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


class PlaylistDetailStateError with DiagnosticableTreeMixin implements PlaylistDetailState {
  const PlaylistDetailStateError({required this.message});
  

 final  String message;

/// Create a copy of PlaylistDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailStateErrorCopyWith<PlaylistDetailStateError> get copyWith => _$PlaylistDetailStateErrorCopyWithImpl<PlaylistDetailStateError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaylistDetailState.error'))
    ..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetailStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
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

/// @nodoc
mixin _$BatchOperationState implements DiagnosticableTreeMixin {

 bool get isInBatchMode; Set<String> get selectedBvids; int get totalItems;
/// Create a copy of BatchOperationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchOperationStateCopyWith<BatchOperationState> get copyWith => _$BatchOperationStateCopyWithImpl<BatchOperationState>(this as BatchOperationState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BatchOperationState'))
    ..add(DiagnosticsProperty('isInBatchMode', isInBatchMode))..add(DiagnosticsProperty('selectedBvids', selectedBvids))..add(DiagnosticsProperty('totalItems', totalItems));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchOperationState&&(identical(other.isInBatchMode, isInBatchMode) || other.isInBatchMode == isInBatchMode)&&const DeepCollectionEquality().equals(other.selectedBvids, selectedBvids)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems));
}


@override
int get hashCode => Object.hash(runtimeType,isInBatchMode,const DeepCollectionEquality().hash(selectedBvids),totalItems);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BatchOperationState(isInBatchMode: $isInBatchMode, selectedBvids: $selectedBvids, totalItems: $totalItems)';
}


}

/// @nodoc
abstract mixin class $BatchOperationStateCopyWith<$Res>  {
  factory $BatchOperationStateCopyWith(BatchOperationState value, $Res Function(BatchOperationState) _then) = _$BatchOperationStateCopyWithImpl;
@useResult
$Res call({
 bool isInBatchMode, Set<String> selectedBvids, int totalItems
});




}
/// @nodoc
class _$BatchOperationStateCopyWithImpl<$Res>
    implements $BatchOperationStateCopyWith<$Res> {
  _$BatchOperationStateCopyWithImpl(this._self, this._then);

  final BatchOperationState _self;
  final $Res Function(BatchOperationState) _then;

/// Create a copy of BatchOperationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isInBatchMode = null,Object? selectedBvids = null,Object? totalItems = null,}) {
  return _then(_self.copyWith(
isInBatchMode: null == isInBatchMode ? _self.isInBatchMode : isInBatchMode // ignore: cast_nullable_to_non_nullable
as bool,selectedBvids: null == selectedBvids ? _self.selectedBvids : selectedBvids // ignore: cast_nullable_to_non_nullable
as Set<String>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchOperationState].
extension BatchOperationStatePatterns on BatchOperationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchOperationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchOperationState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchOperationState value)  $default,){
final _that = this;
switch (_that) {
case _BatchOperationState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchOperationState value)?  $default,){
final _that = this;
switch (_that) {
case _BatchOperationState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isInBatchMode,  Set<String> selectedBvids,  int totalItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchOperationState() when $default != null:
return $default(_that.isInBatchMode,_that.selectedBvids,_that.totalItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isInBatchMode,  Set<String> selectedBvids,  int totalItems)  $default,) {final _that = this;
switch (_that) {
case _BatchOperationState():
return $default(_that.isInBatchMode,_that.selectedBvids,_that.totalItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isInBatchMode,  Set<String> selectedBvids,  int totalItems)?  $default,) {final _that = this;
switch (_that) {
case _BatchOperationState() when $default != null:
return $default(_that.isInBatchMode,_that.selectedBvids,_that.totalItems);case _:
  return null;

}
}

}

/// @nodoc


class _BatchOperationState extends BatchOperationState with DiagnosticableTreeMixin {
  const _BatchOperationState({this.isInBatchMode = false, final  Set<String> selectedBvids = const {}, this.totalItems = 0}): _selectedBvids = selectedBvids,super._();
  

@override@JsonKey() final  bool isInBatchMode;
 final  Set<String> _selectedBvids;
@override@JsonKey() Set<String> get selectedBvids {
  if (_selectedBvids is EqualUnmodifiableSetView) return _selectedBvids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedBvids);
}

@override@JsonKey() final  int totalItems;

/// Create a copy of BatchOperationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchOperationStateCopyWith<_BatchOperationState> get copyWith => __$BatchOperationStateCopyWithImpl<_BatchOperationState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BatchOperationState'))
    ..add(DiagnosticsProperty('isInBatchMode', isInBatchMode))..add(DiagnosticsProperty('selectedBvids', selectedBvids))..add(DiagnosticsProperty('totalItems', totalItems));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchOperationState&&(identical(other.isInBatchMode, isInBatchMode) || other.isInBatchMode == isInBatchMode)&&const DeepCollectionEquality().equals(other._selectedBvids, _selectedBvids)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems));
}


@override
int get hashCode => Object.hash(runtimeType,isInBatchMode,const DeepCollectionEquality().hash(_selectedBvids),totalItems);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BatchOperationState(isInBatchMode: $isInBatchMode, selectedBvids: $selectedBvids, totalItems: $totalItems)';
}


}

/// @nodoc
abstract mixin class _$BatchOperationStateCopyWith<$Res> implements $BatchOperationStateCopyWith<$Res> {
  factory _$BatchOperationStateCopyWith(_BatchOperationState value, $Res Function(_BatchOperationState) _then) = __$BatchOperationStateCopyWithImpl;
@override @useResult
$Res call({
 bool isInBatchMode, Set<String> selectedBvids, int totalItems
});




}
/// @nodoc
class __$BatchOperationStateCopyWithImpl<$Res>
    implements _$BatchOperationStateCopyWith<$Res> {
  __$BatchOperationStateCopyWithImpl(this._self, this._then);

  final _BatchOperationState _self;
  final $Res Function(_BatchOperationState) _then;

/// Create a copy of BatchOperationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInBatchMode = null,Object? selectedBvids = null,Object? totalItems = null,}) {
  return _then(_BatchOperationState(
isInBatchMode: null == isInBatchMode ? _self.isInBatchMode : isInBatchMode // ignore: cast_nullable_to_non_nullable
as bool,selectedBvids: null == selectedBvids ? _self._selectedBvids : selectedBvids // ignore: cast_nullable_to_non_nullable
as Set<String>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BatchOperationResult implements DiagnosticableTreeMixin {

 int get success; int get failed; List<String> get failedItems;
/// Create a copy of BatchOperationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchOperationResultCopyWith<BatchOperationResult> get copyWith => _$BatchOperationResultCopyWithImpl<BatchOperationResult>(this as BatchOperationResult, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BatchOperationResult'))
    ..add(DiagnosticsProperty('success', success))..add(DiagnosticsProperty('failed', failed))..add(DiagnosticsProperty('failedItems', failedItems));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchOperationResult&&(identical(other.success, success) || other.success == success)&&(identical(other.failed, failed) || other.failed == failed)&&const DeepCollectionEquality().equals(other.failedItems, failedItems));
}


@override
int get hashCode => Object.hash(runtimeType,success,failed,const DeepCollectionEquality().hash(failedItems));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BatchOperationResult(success: $success, failed: $failed, failedItems: $failedItems)';
}


}

/// @nodoc
abstract mixin class $BatchOperationResultCopyWith<$Res>  {
  factory $BatchOperationResultCopyWith(BatchOperationResult value, $Res Function(BatchOperationResult) _then) = _$BatchOperationResultCopyWithImpl;
@useResult
$Res call({
 int success, int failed, List<String> failedItems
});




}
/// @nodoc
class _$BatchOperationResultCopyWithImpl<$Res>
    implements $BatchOperationResultCopyWith<$Res> {
  _$BatchOperationResultCopyWithImpl(this._self, this._then);

  final BatchOperationResult _self;
  final $Res Function(BatchOperationResult) _then;

/// Create a copy of BatchOperationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? failed = null,Object? failedItems = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,failedItems: null == failedItems ? _self.failedItems : failedItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchOperationResult].
extension BatchOperationResultPatterns on BatchOperationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchOperationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchOperationResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchOperationResult value)  $default,){
final _that = this;
switch (_that) {
case _BatchOperationResult():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchOperationResult value)?  $default,){
final _that = this;
switch (_that) {
case _BatchOperationResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int success,  int failed,  List<String> failedItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchOperationResult() when $default != null:
return $default(_that.success,_that.failed,_that.failedItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int success,  int failed,  List<String> failedItems)  $default,) {final _that = this;
switch (_that) {
case _BatchOperationResult():
return $default(_that.success,_that.failed,_that.failedItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int success,  int failed,  List<String> failedItems)?  $default,) {final _that = this;
switch (_that) {
case _BatchOperationResult() when $default != null:
return $default(_that.success,_that.failed,_that.failedItems);case _:
  return null;

}
}

}

/// @nodoc


class _BatchOperationResult extends BatchOperationResult with DiagnosticableTreeMixin {
  const _BatchOperationResult({required this.success, required this.failed, final  List<String> failedItems = const []}): _failedItems = failedItems,super._();
  

@override final  int success;
@override final  int failed;
 final  List<String> _failedItems;
@override@JsonKey() List<String> get failedItems {
  if (_failedItems is EqualUnmodifiableListView) return _failedItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failedItems);
}


/// Create a copy of BatchOperationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchOperationResultCopyWith<_BatchOperationResult> get copyWith => __$BatchOperationResultCopyWithImpl<_BatchOperationResult>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BatchOperationResult'))
    ..add(DiagnosticsProperty('success', success))..add(DiagnosticsProperty('failed', failed))..add(DiagnosticsProperty('failedItems', failedItems));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchOperationResult&&(identical(other.success, success) || other.success == success)&&(identical(other.failed, failed) || other.failed == failed)&&const DeepCollectionEquality().equals(other._failedItems, _failedItems));
}


@override
int get hashCode => Object.hash(runtimeType,success,failed,const DeepCollectionEquality().hash(_failedItems));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BatchOperationResult(success: $success, failed: $failed, failedItems: $failedItems)';
}


}

/// @nodoc
abstract mixin class _$BatchOperationResultCopyWith<$Res> implements $BatchOperationResultCopyWith<$Res> {
  factory _$BatchOperationResultCopyWith(_BatchOperationResult value, $Res Function(_BatchOperationResult) _then) = __$BatchOperationResultCopyWithImpl;
@override @useResult
$Res call({
 int success, int failed, List<String> failedItems
});




}
/// @nodoc
class __$BatchOperationResultCopyWithImpl<$Res>
    implements _$BatchOperationResultCopyWith<$Res> {
  __$BatchOperationResultCopyWithImpl(this._self, this._then);

  final _BatchOperationResult _self;
  final $Res Function(_BatchOperationResult) _then;

/// Create a copy of BatchOperationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? failed = null,Object? failedItems = null,}) {
  return _then(_BatchOperationResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,failedItems: null == failedItems ? _self._failedItems : failedItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
