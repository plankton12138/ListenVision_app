// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayQueue {

/// 曲目列表
@PlayableAudioConverter() List<PlayableAudio> get tracks;/// 当前播放索引
 int get currentIndex;/// 播放模式，默认为顺序播放
 PlayMode get playMode;/// 随机播放顺序
 List<int> get shuffleOrder;/// 队列来源（从哪里发起的播放）
 QueueSource? get source;
/// Create a copy of PlayQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayQueueCopyWith<PlayQueue> get copyWith => _$PlayQueueCopyWithImpl<PlayQueue>(this as PlayQueue, _$identity);

  /// Serializes this PlayQueue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayQueue&&const DeepCollectionEquality().equals(other.tracks, tracks)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.playMode, playMode) || other.playMode == playMode)&&const DeepCollectionEquality().equals(other.shuffleOrder, shuffleOrder)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tracks),currentIndex,playMode,const DeepCollectionEquality().hash(shuffleOrder),source);

@override
String toString() {
  return 'PlayQueue(tracks: $tracks, currentIndex: $currentIndex, playMode: $playMode, shuffleOrder: $shuffleOrder, source: $source)';
}


}

/// @nodoc
abstract mixin class $PlayQueueCopyWith<$Res>  {
  factory $PlayQueueCopyWith(PlayQueue value, $Res Function(PlayQueue) _then) = _$PlayQueueCopyWithImpl;
@useResult
$Res call({
@PlayableAudioConverter() List<PlayableAudio> tracks, int currentIndex, PlayMode playMode, List<int> shuffleOrder, QueueSource? source
});




}
/// @nodoc
class _$PlayQueueCopyWithImpl<$Res>
    implements $PlayQueueCopyWith<$Res> {
  _$PlayQueueCopyWithImpl(this._self, this._then);

  final PlayQueue _self;
  final $Res Function(PlayQueue) _then;

/// Create a copy of PlayQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,Object? currentIndex = null,Object? playMode = null,Object? shuffleOrder = null,Object? source = freezed,}) {
  return _then(_self.copyWith(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<PlayableAudio>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,playMode: null == playMode ? _self.playMode : playMode // ignore: cast_nullable_to_non_nullable
as PlayMode,shuffleOrder: null == shuffleOrder ? _self.shuffleOrder : shuffleOrder // ignore: cast_nullable_to_non_nullable
as List<int>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QueueSource?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayQueue].
extension PlayQueuePatterns on PlayQueue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayQueue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayQueue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayQueue value)  $default,){
final _that = this;
switch (_that) {
case _PlayQueue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayQueue value)?  $default,){
final _that = this;
switch (_that) {
case _PlayQueue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PlayableAudioConverter()  List<PlayableAudio> tracks,  int currentIndex,  PlayMode playMode,  List<int> shuffleOrder,  QueueSource? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayQueue() when $default != null:
return $default(_that.tracks,_that.currentIndex,_that.playMode,_that.shuffleOrder,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PlayableAudioConverter()  List<PlayableAudio> tracks,  int currentIndex,  PlayMode playMode,  List<int> shuffleOrder,  QueueSource? source)  $default,) {final _that = this;
switch (_that) {
case _PlayQueue():
return $default(_that.tracks,_that.currentIndex,_that.playMode,_that.shuffleOrder,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PlayableAudioConverter()  List<PlayableAudio> tracks,  int currentIndex,  PlayMode playMode,  List<int> shuffleOrder,  QueueSource? source)?  $default,) {final _that = this;
switch (_that) {
case _PlayQueue() when $default != null:
return $default(_that.tracks,_that.currentIndex,_that.playMode,_that.shuffleOrder,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayQueue implements PlayQueue {
  const _PlayQueue({@PlayableAudioConverter() required final  List<PlayableAudio> tracks, required this.currentIndex, this.playMode = PlayMode.sequence, final  List<int> shuffleOrder = const [], this.source}): _tracks = tracks,_shuffleOrder = shuffleOrder;
  factory _PlayQueue.fromJson(Map<String, dynamic> json) => _$PlayQueueFromJson(json);

/// 曲目列表
 final  List<PlayableAudio> _tracks;
/// 曲目列表
@override@PlayableAudioConverter() List<PlayableAudio> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

/// 当前播放索引
@override final  int currentIndex;
/// 播放模式，默认为顺序播放
@override@JsonKey() final  PlayMode playMode;
/// 随机播放顺序
 final  List<int> _shuffleOrder;
/// 随机播放顺序
@override@JsonKey() List<int> get shuffleOrder {
  if (_shuffleOrder is EqualUnmodifiableListView) return _shuffleOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shuffleOrder);
}

/// 队列来源（从哪里发起的播放）
@override final  QueueSource? source;

/// Create a copy of PlayQueue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayQueueCopyWith<_PlayQueue> get copyWith => __$PlayQueueCopyWithImpl<_PlayQueue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayQueueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayQueue&&const DeepCollectionEquality().equals(other._tracks, _tracks)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.playMode, playMode) || other.playMode == playMode)&&const DeepCollectionEquality().equals(other._shuffleOrder, _shuffleOrder)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),currentIndex,playMode,const DeepCollectionEquality().hash(_shuffleOrder),source);

@override
String toString() {
  return 'PlayQueue(tracks: $tracks, currentIndex: $currentIndex, playMode: $playMode, shuffleOrder: $shuffleOrder, source: $source)';
}


}

/// @nodoc
abstract mixin class _$PlayQueueCopyWith<$Res> implements $PlayQueueCopyWith<$Res> {
  factory _$PlayQueueCopyWith(_PlayQueue value, $Res Function(_PlayQueue) _then) = __$PlayQueueCopyWithImpl;
@override @useResult
$Res call({
@PlayableAudioConverter() List<PlayableAudio> tracks, int currentIndex, PlayMode playMode, List<int> shuffleOrder, QueueSource? source
});




}
/// @nodoc
class __$PlayQueueCopyWithImpl<$Res>
    implements _$PlayQueueCopyWith<$Res> {
  __$PlayQueueCopyWithImpl(this._self, this._then);

  final _PlayQueue _self;
  final $Res Function(_PlayQueue) _then;

/// Create a copy of PlayQueue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? currentIndex = null,Object? playMode = null,Object? shuffleOrder = null,Object? source = freezed,}) {
  return _then(_PlayQueue(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<PlayableAudio>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,playMode: null == playMode ? _self.playMode : playMode // ignore: cast_nullable_to_non_nullable
as PlayMode,shuffleOrder: null == shuffleOrder ? _self._shuffleOrder : shuffleOrder // ignore: cast_nullable_to_non_nullable
as List<int>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QueueSource?,
  ));
}


}

// dart format on
