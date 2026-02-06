// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryState()';
}


}

/// @nodoc
class $HistoryStateCopyWith<$Res>  {
$HistoryStateCopyWith(HistoryState _, $Res Function(HistoryState) __);
}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HistoryStateInitial value)?  initial,TResult Function( HistoryStateLoading value)?  loading,TResult Function( HistoryStateLoaded value)?  loaded,TResult Function( HistoryStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HistoryStateInitial() when initial != null:
return initial(_that);case HistoryStateLoading() when loading != null:
return loading(_that);case HistoryStateLoaded() when loaded != null:
return loaded(_that);case HistoryStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HistoryStateInitial value)  initial,required TResult Function( HistoryStateLoading value)  loading,required TResult Function( HistoryStateLoaded value)  loaded,required TResult Function( HistoryStateError value)  error,}){
final _that = this;
switch (_that) {
case HistoryStateInitial():
return initial(_that);case HistoryStateLoading():
return loading(_that);case HistoryStateLoaded():
return loaded(_that);case HistoryStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HistoryStateInitial value)?  initial,TResult? Function( HistoryStateLoading value)?  loading,TResult? Function( HistoryStateLoaded value)?  loaded,TResult? Function( HistoryStateError value)?  error,}){
final _that = this;
switch (_that) {
case HistoryStateInitial() when initial != null:
return initial(_that);case HistoryStateLoading() when loading != null:
return loading(_that);case HistoryStateLoaded() when loaded != null:
return loaded(_that);case HistoryStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<PlayHistory> history,  PlayHistoryStats? stats)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HistoryStateInitial() when initial != null:
return initial();case HistoryStateLoading() when loading != null:
return loading();case HistoryStateLoaded() when loaded != null:
return loaded(_that.history,_that.stats);case HistoryStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<PlayHistory> history,  PlayHistoryStats? stats)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case HistoryStateInitial():
return initial();case HistoryStateLoading():
return loading();case HistoryStateLoaded():
return loaded(_that.history,_that.stats);case HistoryStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<PlayHistory> history,  PlayHistoryStats? stats)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case HistoryStateInitial() when initial != null:
return initial();case HistoryStateLoading() when loading != null:
return loading();case HistoryStateLoaded() when loaded != null:
return loaded(_that.history,_that.stats);case HistoryStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class HistoryStateInitial implements HistoryState {
  const HistoryStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryState.initial()';
}


}




/// @nodoc


class HistoryStateLoading implements HistoryState {
  const HistoryStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryState.loading()';
}


}




/// @nodoc


class HistoryStateLoaded implements HistoryState {
  const HistoryStateLoaded({required final  List<PlayHistory> history, this.stats}): _history = history;
  

 final  List<PlayHistory> _history;
 List<PlayHistory> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

 final  PlayHistoryStats? stats;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateLoadedCopyWith<HistoryStateLoaded> get copyWith => _$HistoryStateLoadedCopyWithImpl<HistoryStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryStateLoaded&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.stats, stats) || other.stats == stats));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_history),stats);

@override
String toString() {
  return 'HistoryState.loaded(history: $history, stats: $stats)';
}


}

/// @nodoc
abstract mixin class $HistoryStateLoadedCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory $HistoryStateLoadedCopyWith(HistoryStateLoaded value, $Res Function(HistoryStateLoaded) _then) = _$HistoryStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<PlayHistory> history, PlayHistoryStats? stats
});


$PlayHistoryStatsCopyWith<$Res>? get stats;

}
/// @nodoc
class _$HistoryStateLoadedCopyWithImpl<$Res>
    implements $HistoryStateLoadedCopyWith<$Res> {
  _$HistoryStateLoadedCopyWithImpl(this._self, this._then);

  final HistoryStateLoaded _self;
  final $Res Function(HistoryStateLoaded) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? history = null,Object? stats = freezed,}) {
  return _then(HistoryStateLoaded(
history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<PlayHistory>,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as PlayHistoryStats?,
  ));
}

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayHistoryStatsCopyWith<$Res>? get stats {
    if (_self.stats == null) {
    return null;
  }

  return $PlayHistoryStatsCopyWith<$Res>(_self.stats!, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

/// @nodoc


class HistoryStateError implements HistoryState {
  const HistoryStateError({required this.message});
  

 final  String message;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateErrorCopyWith<HistoryStateError> get copyWith => _$HistoryStateErrorCopyWithImpl<HistoryStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HistoryState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $HistoryStateErrorCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory $HistoryStateErrorCopyWith(HistoryStateError value, $Res Function(HistoryStateError) _then) = _$HistoryStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$HistoryStateErrorCopyWithImpl<$Res>
    implements $HistoryStateErrorCopyWith<$Res> {
  _$HistoryStateErrorCopyWithImpl(this._self, this._then);

  final HistoryStateError _self;
  final $Res Function(HistoryStateError) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(HistoryStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlayHistoryStats {

 int get totalPlays; int get uniqueTracks; int get totalDuration; PlayHistory? get lastPlayed;
/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayHistoryStatsCopyWith<PlayHistoryStats> get copyWith => _$PlayHistoryStatsCopyWithImpl<PlayHistoryStats>(this as PlayHistoryStats, _$identity);

  /// Serializes this PlayHistoryStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayHistoryStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.uniqueTracks, uniqueTracks) || other.uniqueTracks == uniqueTracks)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.lastPlayed, lastPlayed) || other.lastPlayed == lastPlayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalPlays,uniqueTracks,totalDuration,lastPlayed);

@override
String toString() {
  return 'PlayHistoryStats(totalPlays: $totalPlays, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration, lastPlayed: $lastPlayed)';
}


}

/// @nodoc
abstract mixin class $PlayHistoryStatsCopyWith<$Res>  {
  factory $PlayHistoryStatsCopyWith(PlayHistoryStats value, $Res Function(PlayHistoryStats) _then) = _$PlayHistoryStatsCopyWithImpl;
@useResult
$Res call({
 int totalPlays, int uniqueTracks, int totalDuration, PlayHistory? lastPlayed
});


$PlayHistoryCopyWith<$Res>? get lastPlayed;

}
/// @nodoc
class _$PlayHistoryStatsCopyWithImpl<$Res>
    implements $PlayHistoryStatsCopyWith<$Res> {
  _$PlayHistoryStatsCopyWithImpl(this._self, this._then);

  final PlayHistoryStats _self;
  final $Res Function(PlayHistoryStats) _then;

/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalPlays = null,Object? uniqueTracks = null,Object? totalDuration = null,Object? lastPlayed = freezed,}) {
  return _then(_self.copyWith(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,uniqueTracks: null == uniqueTracks ? _self.uniqueTracks : uniqueTracks // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int,lastPlayed: freezed == lastPlayed ? _self.lastPlayed : lastPlayed // ignore: cast_nullable_to_non_nullable
as PlayHistory?,
  ));
}
/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayHistoryCopyWith<$Res>? get lastPlayed {
    if (_self.lastPlayed == null) {
    return null;
  }

  return $PlayHistoryCopyWith<$Res>(_self.lastPlayed!, (value) {
    return _then(_self.copyWith(lastPlayed: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayHistoryStats].
extension PlayHistoryStatsPatterns on PlayHistoryStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayHistoryStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayHistoryStats value)  $default,){
final _that = this;
switch (_that) {
case _PlayHistoryStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayHistoryStats value)?  $default,){
final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalPlays,  int uniqueTracks,  int totalDuration,  PlayHistory? lastPlayed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
return $default(_that.totalPlays,_that.uniqueTracks,_that.totalDuration,_that.lastPlayed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalPlays,  int uniqueTracks,  int totalDuration,  PlayHistory? lastPlayed)  $default,) {final _that = this;
switch (_that) {
case _PlayHistoryStats():
return $default(_that.totalPlays,_that.uniqueTracks,_that.totalDuration,_that.lastPlayed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalPlays,  int uniqueTracks,  int totalDuration,  PlayHistory? lastPlayed)?  $default,) {final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
return $default(_that.totalPlays,_that.uniqueTracks,_that.totalDuration,_that.lastPlayed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayHistoryStats implements PlayHistoryStats {
  const _PlayHistoryStats({this.totalPlays = 0, this.uniqueTracks = 0, this.totalDuration = 0, this.lastPlayed});
  factory _PlayHistoryStats.fromJson(Map<String, dynamic> json) => _$PlayHistoryStatsFromJson(json);

@override@JsonKey() final  int totalPlays;
@override@JsonKey() final  int uniqueTracks;
@override@JsonKey() final  int totalDuration;
@override final  PlayHistory? lastPlayed;

/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayHistoryStatsCopyWith<_PlayHistoryStats> get copyWith => __$PlayHistoryStatsCopyWithImpl<_PlayHistoryStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayHistoryStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayHistoryStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.uniqueTracks, uniqueTracks) || other.uniqueTracks == uniqueTracks)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.lastPlayed, lastPlayed) || other.lastPlayed == lastPlayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalPlays,uniqueTracks,totalDuration,lastPlayed);

@override
String toString() {
  return 'PlayHistoryStats(totalPlays: $totalPlays, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration, lastPlayed: $lastPlayed)';
}


}

/// @nodoc
abstract mixin class _$PlayHistoryStatsCopyWith<$Res> implements $PlayHistoryStatsCopyWith<$Res> {
  factory _$PlayHistoryStatsCopyWith(_PlayHistoryStats value, $Res Function(_PlayHistoryStats) _then) = __$PlayHistoryStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalPlays, int uniqueTracks, int totalDuration, PlayHistory? lastPlayed
});


@override $PlayHistoryCopyWith<$Res>? get lastPlayed;

}
/// @nodoc
class __$PlayHistoryStatsCopyWithImpl<$Res>
    implements _$PlayHistoryStatsCopyWith<$Res> {
  __$PlayHistoryStatsCopyWithImpl(this._self, this._then);

  final _PlayHistoryStats _self;
  final $Res Function(_PlayHistoryStats) _then;

/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalPlays = null,Object? uniqueTracks = null,Object? totalDuration = null,Object? lastPlayed = freezed,}) {
  return _then(_PlayHistoryStats(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,uniqueTracks: null == uniqueTracks ? _self.uniqueTracks : uniqueTracks // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int,lastPlayed: freezed == lastPlayed ? _self.lastPlayed : lastPlayed // ignore: cast_nullable_to_non_nullable
as PlayHistory?,
  ));
}

/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayHistoryCopyWith<$Res>? get lastPlayed {
    if (_self.lastPlayed == null) {
    return null;
  }

  return $PlayHistoryCopyWith<$Res>(_self.lastPlayed!, (value) {
    return _then(_self.copyWith(lastPlayed: value));
  });
}
}

// dart format on
