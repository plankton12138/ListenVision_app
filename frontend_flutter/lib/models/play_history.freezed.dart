// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayHistory {

 String get id; String get userId; Audio get audio; DateTime get playedAt; int get progress;// 播放进度（秒）
 DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayHistoryCopyWith<PlayHistory> get copyWith => _$PlayHistoryCopyWithImpl<PlayHistory>(this as PlayHistory, _$identity);

  /// Serializes this PlayHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,audio,playedAt,progress,createdAt,updatedAt);

@override
String toString() {
  return 'PlayHistory(id: $id, userId: $userId, audio: $audio, playedAt: $playedAt, progress: $progress, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlayHistoryCopyWith<$Res>  {
  factory $PlayHistoryCopyWith(PlayHistory value, $Res Function(PlayHistory) _then) = _$PlayHistoryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, Audio audio, DateTime playedAt, int progress, DateTime? createdAt, DateTime? updatedAt
});


$AudioCopyWith<$Res> get audio;

}
/// @nodoc
class _$PlayHistoryCopyWithImpl<$Res>
    implements $PlayHistoryCopyWith<$Res> {
  _$PlayHistoryCopyWithImpl(this._self, this._then);

  final PlayHistory _self;
  final $Res Function(PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? audio = null,Object? playedAt = null,Object? progress = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Audio,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioCopyWith<$Res> get audio {
  
  return $AudioCopyWith<$Res>(_self.audio, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayHistory].
extension PlayHistoryPatterns on PlayHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayHistory value)  $default,){
final _that = this;
switch (_that) {
case _PlayHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayHistory value)?  $default,){
final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlayHistory():
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayHistory extends PlayHistory {
  const _PlayHistory({required this.id, required this.userId, required this.audio, required this.playedAt, this.progress = 0, this.createdAt, this.updatedAt}): super._();
  factory _PlayHistory.fromJson(Map<String, dynamic> json) => _$PlayHistoryFromJson(json);

@override final  String id;
@override final  String userId;
@override final  Audio audio;
@override final  DateTime playedAt;
@override@JsonKey() final  int progress;
// 播放进度（秒）
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayHistoryCopyWith<_PlayHistory> get copyWith => __$PlayHistoryCopyWithImpl<_PlayHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,audio,playedAt,progress,createdAt,updatedAt);

@override
String toString() {
  return 'PlayHistory(id: $id, userId: $userId, audio: $audio, playedAt: $playedAt, progress: $progress, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayHistoryCopyWith<$Res> implements $PlayHistoryCopyWith<$Res> {
  factory _$PlayHistoryCopyWith(_PlayHistory value, $Res Function(_PlayHistory) _then) = __$PlayHistoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, Audio audio, DateTime playedAt, int progress, DateTime? createdAt, DateTime? updatedAt
});


@override $AudioCopyWith<$Res> get audio;

}
/// @nodoc
class __$PlayHistoryCopyWithImpl<$Res>
    implements _$PlayHistoryCopyWith<$Res> {
  __$PlayHistoryCopyWithImpl(this._self, this._then);

  final _PlayHistory _self;
  final $Res Function(_PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? audio = null,Object? playedAt = null,Object? progress = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PlayHistory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Audio,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioCopyWith<$Res> get audio {
  
  return $AudioCopyWith<$Res>(_self.audio, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// @nodoc
mixin _$PlayHistoryStats {

 int get totalPlays; PlayHistory? get lastPlayed; int get uniqueTracks; int get totalDuration;
/// Create a copy of PlayHistoryStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayHistoryStatsCopyWith<PlayHistoryStats> get copyWith => _$PlayHistoryStatsCopyWithImpl<PlayHistoryStats>(this as PlayHistoryStats, _$identity);

  /// Serializes this PlayHistoryStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayHistoryStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.lastPlayed, lastPlayed) || other.lastPlayed == lastPlayed)&&(identical(other.uniqueTracks, uniqueTracks) || other.uniqueTracks == uniqueTracks)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalPlays,lastPlayed,uniqueTracks,totalDuration);

@override
String toString() {
  return 'PlayHistoryStats(totalPlays: $totalPlays, lastPlayed: $lastPlayed, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration)';
}


}

/// @nodoc
abstract mixin class $PlayHistoryStatsCopyWith<$Res>  {
  factory $PlayHistoryStatsCopyWith(PlayHistoryStats value, $Res Function(PlayHistoryStats) _then) = _$PlayHistoryStatsCopyWithImpl;
@useResult
$Res call({
 int totalPlays, PlayHistory? lastPlayed, int uniqueTracks, int totalDuration
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
@pragma('vm:prefer-inline') @override $Res call({Object? totalPlays = null,Object? lastPlayed = freezed,Object? uniqueTracks = null,Object? totalDuration = null,}) {
  return _then(_self.copyWith(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,lastPlayed: freezed == lastPlayed ? _self.lastPlayed : lastPlayed // ignore: cast_nullable_to_non_nullable
as PlayHistory?,uniqueTracks: null == uniqueTracks ? _self.uniqueTracks : uniqueTracks // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalPlays,  PlayHistory? lastPlayed,  int uniqueTracks,  int totalDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
return $default(_that.totalPlays,_that.lastPlayed,_that.uniqueTracks,_that.totalDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalPlays,  PlayHistory? lastPlayed,  int uniqueTracks,  int totalDuration)  $default,) {final _that = this;
switch (_that) {
case _PlayHistoryStats():
return $default(_that.totalPlays,_that.lastPlayed,_that.uniqueTracks,_that.totalDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalPlays,  PlayHistory? lastPlayed,  int uniqueTracks,  int totalDuration)?  $default,) {final _that = this;
switch (_that) {
case _PlayHistoryStats() when $default != null:
return $default(_that.totalPlays,_that.lastPlayed,_that.uniqueTracks,_that.totalDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayHistoryStats implements PlayHistoryStats {
  const _PlayHistoryStats({this.totalPlays = 0, this.lastPlayed, this.uniqueTracks = 0, this.totalDuration = 0});
  factory _PlayHistoryStats.fromJson(Map<String, dynamic> json) => _$PlayHistoryStatsFromJson(json);

@override@JsonKey() final  int totalPlays;
@override final  PlayHistory? lastPlayed;
@override@JsonKey() final  int uniqueTracks;
@override@JsonKey() final  int totalDuration;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayHistoryStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.lastPlayed, lastPlayed) || other.lastPlayed == lastPlayed)&&(identical(other.uniqueTracks, uniqueTracks) || other.uniqueTracks == uniqueTracks)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalPlays,lastPlayed,uniqueTracks,totalDuration);

@override
String toString() {
  return 'PlayHistoryStats(totalPlays: $totalPlays, lastPlayed: $lastPlayed, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration)';
}


}

/// @nodoc
abstract mixin class _$PlayHistoryStatsCopyWith<$Res> implements $PlayHistoryStatsCopyWith<$Res> {
  factory _$PlayHistoryStatsCopyWith(_PlayHistoryStats value, $Res Function(_PlayHistoryStats) _then) = __$PlayHistoryStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalPlays, PlayHistory? lastPlayed, int uniqueTracks, int totalDuration
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
@override @pragma('vm:prefer-inline') $Res call({Object? totalPlays = null,Object? lastPlayed = freezed,Object? uniqueTracks = null,Object? totalDuration = null,}) {
  return _then(_PlayHistoryStats(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,lastPlayed: freezed == lastPlayed ? _self.lastPlayed : lastPlayed // ignore: cast_nullable_to_non_nullable
as PlayHistory?,uniqueTracks: null == uniqueTracks ? _self.uniqueTracks : uniqueTracks // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int,
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
