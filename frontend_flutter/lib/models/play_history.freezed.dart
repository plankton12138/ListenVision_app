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
PlaySource _$PlaySourceFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'playlist':
          return _FromPlaylist.fromJson(
            json
          );
                case 'search':
          return _FromSearch.fromJson(
            json
          );
                case 'history':
          return _FromHistory.fromJson(
            json
          );
                case 'manual':
          return _FromManual.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PlaySource',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PlaySource {



  /// Serializes this PlaySource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaySource);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaySource()';
}


}

/// @nodoc
class $PlaySourceCopyWith<$Res>  {
$PlaySourceCopyWith(PlaySource _, $Res Function(PlaySource) __);
}


/// Adds pattern-matching-related methods to [PlaySource].
extension PlaySourcePatterns on PlaySource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _FromPlaylist value)?  playlist,TResult Function( _FromSearch value)?  search,TResult Function( _FromHistory value)?  history,TResult Function( _FromManual value)?  manual,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FromPlaylist() when playlist != null:
return playlist(_that);case _FromSearch() when search != null:
return search(_that);case _FromHistory() when history != null:
return history(_that);case _FromManual() when manual != null:
return manual(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _FromPlaylist value)  playlist,required TResult Function( _FromSearch value)  search,required TResult Function( _FromHistory value)  history,required TResult Function( _FromManual value)  manual,}){
final _that = this;
switch (_that) {
case _FromPlaylist():
return playlist(_that);case _FromSearch():
return search(_that);case _FromHistory():
return history(_that);case _FromManual():
return manual(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _FromPlaylist value)?  playlist,TResult? Function( _FromSearch value)?  search,TResult? Function( _FromHistory value)?  history,TResult? Function( _FromManual value)?  manual,}){
final _that = this;
switch (_that) {
case _FromPlaylist() when playlist != null:
return playlist(_that);case _FromSearch() when search != null:
return search(_that);case _FromHistory() when history != null:
return history(_that);case _FromManual() when manual != null:
return manual(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String playlistId)?  playlist,TResult Function( String query)?  search,TResult Function()?  history,TResult Function()?  manual,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FromPlaylist() when playlist != null:
return playlist(_that.playlistId);case _FromSearch() when search != null:
return search(_that.query);case _FromHistory() when history != null:
return history();case _FromManual() when manual != null:
return manual();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String playlistId)  playlist,required TResult Function( String query)  search,required TResult Function()  history,required TResult Function()  manual,}) {final _that = this;
switch (_that) {
case _FromPlaylist():
return playlist(_that.playlistId);case _FromSearch():
return search(_that.query);case _FromHistory():
return history();case _FromManual():
return manual();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String playlistId)?  playlist,TResult? Function( String query)?  search,TResult? Function()?  history,TResult? Function()?  manual,}) {final _that = this;
switch (_that) {
case _FromPlaylist() when playlist != null:
return playlist(_that.playlistId);case _FromSearch() when search != null:
return search(_that.query);case _FromHistory() when history != null:
return history();case _FromManual() when manual != null:
return manual();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FromPlaylist implements PlaySource {
  const _FromPlaylist(this.playlistId, {final  String? $type}): $type = $type ?? 'playlist';
  factory _FromPlaylist.fromJson(Map<String, dynamic> json) => _$FromPlaylistFromJson(json);

 final  String playlistId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PlaySource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FromPlaylistCopyWith<_FromPlaylist> get copyWith => __$FromPlaylistCopyWithImpl<_FromPlaylist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FromPlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FromPlaylist&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playlistId);

@override
String toString() {
  return 'PlaySource.playlist(playlistId: $playlistId)';
}


}

/// @nodoc
abstract mixin class _$FromPlaylistCopyWith<$Res> implements $PlaySourceCopyWith<$Res> {
  factory _$FromPlaylistCopyWith(_FromPlaylist value, $Res Function(_FromPlaylist) _then) = __$FromPlaylistCopyWithImpl;
@useResult
$Res call({
 String playlistId
});




}
/// @nodoc
class __$FromPlaylistCopyWithImpl<$Res>
    implements _$FromPlaylistCopyWith<$Res> {
  __$FromPlaylistCopyWithImpl(this._self, this._then);

  final _FromPlaylist _self;
  final $Res Function(_FromPlaylist) _then;

/// Create a copy of PlaySource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,}) {
  return _then(_FromPlaylist(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _FromSearch implements PlaySource {
  const _FromSearch(this.query, {final  String? $type}): $type = $type ?? 'search';
  factory _FromSearch.fromJson(Map<String, dynamic> json) => _$FromSearchFromJson(json);

 final  String query;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PlaySource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FromSearchCopyWith<_FromSearch> get copyWith => __$FromSearchCopyWithImpl<_FromSearch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FromSearchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FromSearch&&(identical(other.query, query) || other.query == query));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'PlaySource.search(query: $query)';
}


}

/// @nodoc
abstract mixin class _$FromSearchCopyWith<$Res> implements $PlaySourceCopyWith<$Res> {
  factory _$FromSearchCopyWith(_FromSearch value, $Res Function(_FromSearch) _then) = __$FromSearchCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$FromSearchCopyWithImpl<$Res>
    implements _$FromSearchCopyWith<$Res> {
  __$FromSearchCopyWithImpl(this._self, this._then);

  final _FromSearch _self;
  final $Res Function(_FromSearch) _then;

/// Create a copy of PlaySource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_FromSearch(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _FromHistory implements PlaySource {
  const _FromHistory({final  String? $type}): $type = $type ?? 'history';
  factory _FromHistory.fromJson(Map<String, dynamic> json) => _$FromHistoryFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$FromHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FromHistory);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaySource.history()';
}


}




/// @nodoc
@JsonSerializable()

class _FromManual implements PlaySource {
  const _FromManual({final  String? $type}): $type = $type ?? 'manual';
  factory _FromManual.fromJson(Map<String, dynamic> json) => _$FromManualFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$FromManualToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FromManual);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaySource.manual()';
}


}





/// @nodoc
mixin _$PlayHistory {

 String get id; String get userId; Audio get audio; DateTime get playedAt; int get progress;// 播放进度（秒）
 PlaySource? get source; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayHistoryCopyWith<PlayHistory> get copyWith => _$PlayHistoryCopyWithImpl<PlayHistory>(this as PlayHistory, _$identity);

  /// Serializes this PlayHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,audio,playedAt,progress,source,createdAt,updatedAt);

@override
String toString() {
  return 'PlayHistory(id: $id, userId: $userId, audio: $audio, playedAt: $playedAt, progress: $progress, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlayHistoryCopyWith<$Res>  {
  factory $PlayHistoryCopyWith(PlayHistory value, $Res Function(PlayHistory) _then) = _$PlayHistoryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, Audio audio, DateTime playedAt, int progress, PlaySource? source, DateTime? createdAt, DateTime? updatedAt
});


$AudioCopyWith<$Res> get audio;$PlaySourceCopyWith<$Res>? get source;

}
/// @nodoc
class _$PlayHistoryCopyWithImpl<$Res>
    implements $PlayHistoryCopyWith<$Res> {
  _$PlayHistoryCopyWithImpl(this._self, this._then);

  final PlayHistory _self;
  final $Res Function(PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? audio = null,Object? playedAt = null,Object? progress = null,Object? source = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Audio,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PlaySource?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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
}/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaySourceCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $PlaySourceCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  PlaySource? source,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.source,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  PlaySource? source,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlayHistory():
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.source,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  Audio audio,  DateTime playedAt,  int progress,  PlaySource? source,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.userId,_that.audio,_that.playedAt,_that.progress,_that.source,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayHistory extends PlayHistory {
  const _PlayHistory({required this.id, required this.userId, required this.audio, required this.playedAt, this.progress = 0, this.source, this.createdAt, this.updatedAt}): super._();
  factory _PlayHistory.fromJson(Map<String, dynamic> json) => _$PlayHistoryFromJson(json);

@override final  String id;
@override final  String userId;
@override final  Audio audio;
@override final  DateTime playedAt;
@override@JsonKey() final  int progress;
// 播放进度（秒）
@override final  PlaySource? source;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,audio,playedAt,progress,source,createdAt,updatedAt);

@override
String toString() {
  return 'PlayHistory(id: $id, userId: $userId, audio: $audio, playedAt: $playedAt, progress: $progress, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayHistoryCopyWith<$Res> implements $PlayHistoryCopyWith<$Res> {
  factory _$PlayHistoryCopyWith(_PlayHistory value, $Res Function(_PlayHistory) _then) = __$PlayHistoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, Audio audio, DateTime playedAt, int progress, PlaySource? source, DateTime? createdAt, DateTime? updatedAt
});


@override $AudioCopyWith<$Res> get audio;@override $PlaySourceCopyWith<$Res>? get source;

}
/// @nodoc
class __$PlayHistoryCopyWithImpl<$Res>
    implements _$PlayHistoryCopyWith<$Res> {
  __$PlayHistoryCopyWithImpl(this._self, this._then);

  final _PlayHistory _self;
  final $Res Function(_PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? audio = null,Object? playedAt = null,Object? progress = null,Object? source = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PlayHistory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Audio,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PlaySource?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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
}/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaySourceCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $PlaySourceCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
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
