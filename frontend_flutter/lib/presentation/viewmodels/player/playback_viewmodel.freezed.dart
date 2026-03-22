// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackState {

/// 当前可播放音频
 PlayableAudio? get currentPlayable;/// 标题
 String get title;/// 艺术家
 String get artist;/// 封面 URL
 String? get coverUrl;/// 是否正在播放
 bool get isPlaying;/// 是否已暂停
 bool get isPaused;/// 是否正在加载
 bool get isLoading;/// 是否已完成
 bool get isCompleted;/// 当前播放位置
 Duration get position;/// 音频总时长
 Duration? get duration;/// 音量
 double get volume;/// 播放倍速
 double get speed;/// 错误消息
 String? get errorMessage;/// 当前播放索引
 int get currentIndex;
/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackStateCopyWith<PlaybackState> get copyWith => _$PlaybackStateCopyWithImpl<PlaybackState>(this as PlaybackState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackState&&(identical(other.currentPlayable, currentPlayable) || other.currentPlayable == currentPlayable)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentPlayable,title,artist,coverUrl,isPlaying,isPaused,isLoading,isCompleted,position,duration,volume,speed,errorMessage,currentIndex);

@override
String toString() {
  return 'PlaybackState(currentPlayable: $currentPlayable, title: $title, artist: $artist, coverUrl: $coverUrl, isPlaying: $isPlaying, isPaused: $isPaused, isLoading: $isLoading, isCompleted: $isCompleted, position: $position, duration: $duration, volume: $volume, speed: $speed, errorMessage: $errorMessage, currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class $PlaybackStateCopyWith<$Res>  {
  factory $PlaybackStateCopyWith(PlaybackState value, $Res Function(PlaybackState) _then) = _$PlaybackStateCopyWithImpl;
@useResult
$Res call({
 PlayableAudio? currentPlayable, String title, String artist, String? coverUrl, bool isPlaying, bool isPaused, bool isLoading, bool isCompleted, Duration position, Duration? duration, double volume, double speed, String? errorMessage, int currentIndex
});




}
/// @nodoc
class _$PlaybackStateCopyWithImpl<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  _$PlaybackStateCopyWithImpl(this._self, this._then);

  final PlaybackState _self;
  final $Res Function(PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPlayable = freezed,Object? title = null,Object? artist = null,Object? coverUrl = freezed,Object? isPlaying = null,Object? isPaused = null,Object? isLoading = null,Object? isCompleted = null,Object? position = null,Object? duration = freezed,Object? volume = null,Object? speed = null,Object? errorMessage = freezed,Object? currentIndex = null,}) {
  return _then(_self.copyWith(
currentPlayable: freezed == currentPlayable ? _self.currentPlayable : currentPlayable // ignore: cast_nullable_to_non_nullable
as PlayableAudio?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackState].
extension PlaybackStatePatterns on PlaybackState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackState value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackState value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayableAudio? currentPlayable,  String title,  String artist,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isLoading,  bool isCompleted,  Duration position,  Duration? duration,  double volume,  double speed,  String? errorMessage,  int currentIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
return $default(_that.currentPlayable,_that.title,_that.artist,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isLoading,_that.isCompleted,_that.position,_that.duration,_that.volume,_that.speed,_that.errorMessage,_that.currentIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayableAudio? currentPlayable,  String title,  String artist,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isLoading,  bool isCompleted,  Duration position,  Duration? duration,  double volume,  double speed,  String? errorMessage,  int currentIndex)  $default,) {final _that = this;
switch (_that) {
case _PlaybackState():
return $default(_that.currentPlayable,_that.title,_that.artist,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isLoading,_that.isCompleted,_that.position,_that.duration,_that.volume,_that.speed,_that.errorMessage,_that.currentIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayableAudio? currentPlayable,  String title,  String artist,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isLoading,  bool isCompleted,  Duration position,  Duration? duration,  double volume,  double speed,  String? errorMessage,  int currentIndex)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
return $default(_that.currentPlayable,_that.title,_that.artist,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isLoading,_that.isCompleted,_that.position,_that.duration,_that.volume,_that.speed,_that.errorMessage,_that.currentIndex);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackState implements PlaybackState {
  const _PlaybackState({this.currentPlayable, this.title = '未知标题', this.artist = '未知艺术家', this.coverUrl, this.isPlaying = false, this.isPaused = false, this.isLoading = false, this.isCompleted = false, this.position = Duration.zero, this.duration, this.volume = 1.0, this.speed = 1.0, this.errorMessage, this.currentIndex = -1});
  

/// 当前可播放音频
@override final  PlayableAudio? currentPlayable;
/// 标题
@override@JsonKey() final  String title;
/// 艺术家
@override@JsonKey() final  String artist;
/// 封面 URL
@override final  String? coverUrl;
/// 是否正在播放
@override@JsonKey() final  bool isPlaying;
/// 是否已暂停
@override@JsonKey() final  bool isPaused;
/// 是否正在加载
@override@JsonKey() final  bool isLoading;
/// 是否已完成
@override@JsonKey() final  bool isCompleted;
/// 当前播放位置
@override@JsonKey() final  Duration position;
/// 音频总时长
@override final  Duration? duration;
/// 音量
@override@JsonKey() final  double volume;
/// 播放倍速
@override@JsonKey() final  double speed;
/// 错误消息
@override final  String? errorMessage;
/// 当前播放索引
@override@JsonKey() final  int currentIndex;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackStateCopyWith<_PlaybackState> get copyWith => __$PlaybackStateCopyWithImpl<_PlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackState&&(identical(other.currentPlayable, currentPlayable) || other.currentPlayable == currentPlayable)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentPlayable,title,artist,coverUrl,isPlaying,isPaused,isLoading,isCompleted,position,duration,volume,speed,errorMessage,currentIndex);

@override
String toString() {
  return 'PlaybackState(currentPlayable: $currentPlayable, title: $title, artist: $artist, coverUrl: $coverUrl, isPlaying: $isPlaying, isPaused: $isPaused, isLoading: $isLoading, isCompleted: $isCompleted, position: $position, duration: $duration, volume: $volume, speed: $speed, errorMessage: $errorMessage, currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class _$PlaybackStateCopyWith<$Res> implements $PlaybackStateCopyWith<$Res> {
  factory _$PlaybackStateCopyWith(_PlaybackState value, $Res Function(_PlaybackState) _then) = __$PlaybackStateCopyWithImpl;
@override @useResult
$Res call({
 PlayableAudio? currentPlayable, String title, String artist, String? coverUrl, bool isPlaying, bool isPaused, bool isLoading, bool isCompleted, Duration position, Duration? duration, double volume, double speed, String? errorMessage, int currentIndex
});




}
/// @nodoc
class __$PlaybackStateCopyWithImpl<$Res>
    implements _$PlaybackStateCopyWith<$Res> {
  __$PlaybackStateCopyWithImpl(this._self, this._then);

  final _PlaybackState _self;
  final $Res Function(_PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPlayable = freezed,Object? title = null,Object? artist = null,Object? coverUrl = freezed,Object? isPlaying = null,Object? isPaused = null,Object? isLoading = null,Object? isCompleted = null,Object? position = null,Object? duration = freezed,Object? volume = null,Object? speed = null,Object? errorMessage = freezed,Object? currentIndex = null,}) {
  return _then(_PlaybackState(
currentPlayable: freezed == currentPlayable ? _self.currentPlayable : currentPlayable // ignore: cast_nullable_to_non_nullable
as PlayableAudio?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
