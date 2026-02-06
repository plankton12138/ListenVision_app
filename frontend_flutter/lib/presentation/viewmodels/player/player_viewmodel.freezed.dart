// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerState {

/// 当前可播放音频
 PlayableAudio? get currentPlayable;/// 当前本地音频（向后兼容）
 LocalAudio? get currentAudio;/// 当前在线音频（向后兼容）
 Audio? get currentOnlineAudio;/// 标题
 String get title;/// 艺术家
 String get artist;/// 专辑封面
 Uint8List? get albumArt;/// 在线封面 URL
 String? get coverUrl;/// 是否正在播放
 bool get isPlaying;/// 是否已暂停
 bool get isPaused;/// 是否已完成
 bool get isCompleted;/// 是否正在加载
 bool get isLoading;/// 是否正在缓冲
 bool get isBuffering;/// 是否空闲
 bool get isIdle;/// 是否就绪
 bool get isReady;/// 是否可跳转
 bool get isSeekable;/// 当前播放位置
 Duration get position;/// 音频总时长
 Duration? get duration;/// 音量（0.0 - 1.0）
 double get volume;/// 播放倍速（0.5x - 2.0x）
 double get speed;/// 播放器状态消息
 String get statusMessage;/// 是否有播放错误
 bool get hasError;/// 当前是否为在线音频
 bool get isCurrentOnline;/// 当前 BVID（在线音频）
 String? get currentBvid;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.currentPlayable, currentPlayable) || other.currentPlayable == currentPlayable)&&(identical(other.currentAudio, currentAudio) || other.currentAudio == currentAudio)&&(identical(other.currentOnlineAudio, currentOnlineAudio) || other.currentOnlineAudio == currentOnlineAudio)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other.albumArt, albumArt)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering)&&(identical(other.isIdle, isIdle) || other.isIdle == isIdle)&&(identical(other.isReady, isReady) || other.isReady == isReady)&&(identical(other.isSeekable, isSeekable) || other.isSeekable == isSeekable)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.hasError, hasError) || other.hasError == hasError)&&(identical(other.isCurrentOnline, isCurrentOnline) || other.isCurrentOnline == isCurrentOnline)&&(identical(other.currentBvid, currentBvid) || other.currentBvid == currentBvid));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentPlayable,currentAudio,currentOnlineAudio,title,artist,const DeepCollectionEquality().hash(albumArt),coverUrl,isPlaying,isPaused,isCompleted,isLoading,isBuffering,isIdle,isReady,isSeekable,position,duration,volume,speed,statusMessage,hasError,isCurrentOnline,currentBvid]);

@override
String toString() {
  return 'PlayerState(currentPlayable: $currentPlayable, currentAudio: $currentAudio, currentOnlineAudio: $currentOnlineAudio, title: $title, artist: $artist, albumArt: $albumArt, coverUrl: $coverUrl, isPlaying: $isPlaying, isPaused: $isPaused, isCompleted: $isCompleted, isLoading: $isLoading, isBuffering: $isBuffering, isIdle: $isIdle, isReady: $isReady, isSeekable: $isSeekable, position: $position, duration: $duration, volume: $volume, speed: $speed, statusMessage: $statusMessage, hasError: $hasError, isCurrentOnline: $isCurrentOnline, currentBvid: $currentBvid)';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 PlayableAudio? currentPlayable, LocalAudio? currentAudio, Audio? currentOnlineAudio, String title, String artist, Uint8List? albumArt, String? coverUrl, bool isPlaying, bool isPaused, bool isCompleted, bool isLoading, bool isBuffering, bool isIdle, bool isReady, bool isSeekable, Duration position, Duration? duration, double volume, double speed, String statusMessage, bool hasError, bool isCurrentOnline, String? currentBvid
});


$AudioCopyWith<$Res>? get currentOnlineAudio;

}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPlayable = freezed,Object? currentAudio = freezed,Object? currentOnlineAudio = freezed,Object? title = null,Object? artist = null,Object? albumArt = freezed,Object? coverUrl = freezed,Object? isPlaying = null,Object? isPaused = null,Object? isCompleted = null,Object? isLoading = null,Object? isBuffering = null,Object? isIdle = null,Object? isReady = null,Object? isSeekable = null,Object? position = null,Object? duration = freezed,Object? volume = null,Object? speed = null,Object? statusMessage = null,Object? hasError = null,Object? isCurrentOnline = null,Object? currentBvid = freezed,}) {
  return _then(_self.copyWith(
currentPlayable: freezed == currentPlayable ? _self.currentPlayable : currentPlayable // ignore: cast_nullable_to_non_nullable
as PlayableAudio?,currentAudio: freezed == currentAudio ? _self.currentAudio : currentAudio // ignore: cast_nullable_to_non_nullable
as LocalAudio?,currentOnlineAudio: freezed == currentOnlineAudio ? _self.currentOnlineAudio : currentOnlineAudio // ignore: cast_nullable_to_non_nullable
as Audio?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,albumArt: freezed == albumArt ? _self.albumArt : albumArt // ignore: cast_nullable_to_non_nullable
as Uint8List?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isIdle: null == isIdle ? _self.isIdle : isIdle // ignore: cast_nullable_to_non_nullable
as bool,isReady: null == isReady ? _self.isReady : isReady // ignore: cast_nullable_to_non_nullable
as bool,isSeekable: null == isSeekable ? _self.isSeekable : isSeekable // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,statusMessage: null == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String,hasError: null == hasError ? _self.hasError : hasError // ignore: cast_nullable_to_non_nullable
as bool,isCurrentOnline: null == isCurrentOnline ? _self.isCurrentOnline : isCurrentOnline // ignore: cast_nullable_to_non_nullable
as bool,currentBvid: freezed == currentBvid ? _self.currentBvid : currentBvid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioCopyWith<$Res>? get currentOnlineAudio {
    if (_self.currentOnlineAudio == null) {
    return null;
  }

  return $AudioCopyWith<$Res>(_self.currentOnlineAudio!, (value) {
    return _then(_self.copyWith(currentOnlineAudio: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayableAudio? currentPlayable,  LocalAudio? currentAudio,  Audio? currentOnlineAudio,  String title,  String artist,  Uint8List? albumArt,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isCompleted,  bool isLoading,  bool isBuffering,  bool isIdle,  bool isReady,  bool isSeekable,  Duration position,  Duration? duration,  double volume,  double speed,  String statusMessage,  bool hasError,  bool isCurrentOnline,  String? currentBvid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.currentPlayable,_that.currentAudio,_that.currentOnlineAudio,_that.title,_that.artist,_that.albumArt,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isCompleted,_that.isLoading,_that.isBuffering,_that.isIdle,_that.isReady,_that.isSeekable,_that.position,_that.duration,_that.volume,_that.speed,_that.statusMessage,_that.hasError,_that.isCurrentOnline,_that.currentBvid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayableAudio? currentPlayable,  LocalAudio? currentAudio,  Audio? currentOnlineAudio,  String title,  String artist,  Uint8List? albumArt,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isCompleted,  bool isLoading,  bool isBuffering,  bool isIdle,  bool isReady,  bool isSeekable,  Duration position,  Duration? duration,  double volume,  double speed,  String statusMessage,  bool hasError,  bool isCurrentOnline,  String? currentBvid)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.currentPlayable,_that.currentAudio,_that.currentOnlineAudio,_that.title,_that.artist,_that.albumArt,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isCompleted,_that.isLoading,_that.isBuffering,_that.isIdle,_that.isReady,_that.isSeekable,_that.position,_that.duration,_that.volume,_that.speed,_that.statusMessage,_that.hasError,_that.isCurrentOnline,_that.currentBvid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayableAudio? currentPlayable,  LocalAudio? currentAudio,  Audio? currentOnlineAudio,  String title,  String artist,  Uint8List? albumArt,  String? coverUrl,  bool isPlaying,  bool isPaused,  bool isCompleted,  bool isLoading,  bool isBuffering,  bool isIdle,  bool isReady,  bool isSeekable,  Duration position,  Duration? duration,  double volume,  double speed,  String statusMessage,  bool hasError,  bool isCurrentOnline,  String? currentBvid)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.currentPlayable,_that.currentAudio,_that.currentOnlineAudio,_that.title,_that.artist,_that.albumArt,_that.coverUrl,_that.isPlaying,_that.isPaused,_that.isCompleted,_that.isLoading,_that.isBuffering,_that.isIdle,_that.isReady,_that.isSeekable,_that.position,_that.duration,_that.volume,_that.speed,_that.statusMessage,_that.hasError,_that.isCurrentOnline,_that.currentBvid);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerState implements PlayerState {
  const _PlayerState({this.currentPlayable, this.currentAudio, this.currentOnlineAudio, this.title = '未知标题', this.artist = '未知艺术家', this.albumArt, this.coverUrl, this.isPlaying = false, this.isPaused = false, this.isCompleted = false, this.isLoading = false, this.isBuffering = false, this.isIdle = true, this.isReady = false, this.isSeekable = true, this.position = Duration.zero, this.duration, this.volume = 1.0, this.speed = 1.0, this.statusMessage = '', this.hasError = false, this.isCurrentOnline = false, this.currentBvid});
  

/// 当前可播放音频
@override final  PlayableAudio? currentPlayable;
/// 当前本地音频（向后兼容）
@override final  LocalAudio? currentAudio;
/// 当前在线音频（向后兼容）
@override final  Audio? currentOnlineAudio;
/// 标题
@override@JsonKey() final  String title;
/// 艺术家
@override@JsonKey() final  String artist;
/// 专辑封面
@override final  Uint8List? albumArt;
/// 在线封面 URL
@override final  String? coverUrl;
/// 是否正在播放
@override@JsonKey() final  bool isPlaying;
/// 是否已暂停
@override@JsonKey() final  bool isPaused;
/// 是否已完成
@override@JsonKey() final  bool isCompleted;
/// 是否正在加载
@override@JsonKey() final  bool isLoading;
/// 是否正在缓冲
@override@JsonKey() final  bool isBuffering;
/// 是否空闲
@override@JsonKey() final  bool isIdle;
/// 是否就绪
@override@JsonKey() final  bool isReady;
/// 是否可跳转
@override@JsonKey() final  bool isSeekable;
/// 当前播放位置
@override@JsonKey() final  Duration position;
/// 音频总时长
@override final  Duration? duration;
/// 音量（0.0 - 1.0）
@override@JsonKey() final  double volume;
/// 播放倍速（0.5x - 2.0x）
@override@JsonKey() final  double speed;
/// 播放器状态消息
@override@JsonKey() final  String statusMessage;
/// 是否有播放错误
@override@JsonKey() final  bool hasError;
/// 当前是否为在线音频
@override@JsonKey() final  bool isCurrentOnline;
/// 当前 BVID（在线音频）
@override final  String? currentBvid;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.currentPlayable, currentPlayable) || other.currentPlayable == currentPlayable)&&(identical(other.currentAudio, currentAudio) || other.currentAudio == currentAudio)&&(identical(other.currentOnlineAudio, currentOnlineAudio) || other.currentOnlineAudio == currentOnlineAudio)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other.albumArt, albumArt)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering)&&(identical(other.isIdle, isIdle) || other.isIdle == isIdle)&&(identical(other.isReady, isReady) || other.isReady == isReady)&&(identical(other.isSeekable, isSeekable) || other.isSeekable == isSeekable)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.hasError, hasError) || other.hasError == hasError)&&(identical(other.isCurrentOnline, isCurrentOnline) || other.isCurrentOnline == isCurrentOnline)&&(identical(other.currentBvid, currentBvid) || other.currentBvid == currentBvid));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentPlayable,currentAudio,currentOnlineAudio,title,artist,const DeepCollectionEquality().hash(albumArt),coverUrl,isPlaying,isPaused,isCompleted,isLoading,isBuffering,isIdle,isReady,isSeekable,position,duration,volume,speed,statusMessage,hasError,isCurrentOnline,currentBvid]);

@override
String toString() {
  return 'PlayerState(currentPlayable: $currentPlayable, currentAudio: $currentAudio, currentOnlineAudio: $currentOnlineAudio, title: $title, artist: $artist, albumArt: $albumArt, coverUrl: $coverUrl, isPlaying: $isPlaying, isPaused: $isPaused, isCompleted: $isCompleted, isLoading: $isLoading, isBuffering: $isBuffering, isIdle: $isIdle, isReady: $isReady, isSeekable: $isSeekable, position: $position, duration: $duration, volume: $volume, speed: $speed, statusMessage: $statusMessage, hasError: $hasError, isCurrentOnline: $isCurrentOnline, currentBvid: $currentBvid)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 PlayableAudio? currentPlayable, LocalAudio? currentAudio, Audio? currentOnlineAudio, String title, String artist, Uint8List? albumArt, String? coverUrl, bool isPlaying, bool isPaused, bool isCompleted, bool isLoading, bool isBuffering, bool isIdle, bool isReady, bool isSeekable, Duration position, Duration? duration, double volume, double speed, String statusMessage, bool hasError, bool isCurrentOnline, String? currentBvid
});


@override $AudioCopyWith<$Res>? get currentOnlineAudio;

}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPlayable = freezed,Object? currentAudio = freezed,Object? currentOnlineAudio = freezed,Object? title = null,Object? artist = null,Object? albumArt = freezed,Object? coverUrl = freezed,Object? isPlaying = null,Object? isPaused = null,Object? isCompleted = null,Object? isLoading = null,Object? isBuffering = null,Object? isIdle = null,Object? isReady = null,Object? isSeekable = null,Object? position = null,Object? duration = freezed,Object? volume = null,Object? speed = null,Object? statusMessage = null,Object? hasError = null,Object? isCurrentOnline = null,Object? currentBvid = freezed,}) {
  return _then(_PlayerState(
currentPlayable: freezed == currentPlayable ? _self.currentPlayable : currentPlayable // ignore: cast_nullable_to_non_nullable
as PlayableAudio?,currentAudio: freezed == currentAudio ? _self.currentAudio : currentAudio // ignore: cast_nullable_to_non_nullable
as LocalAudio?,currentOnlineAudio: freezed == currentOnlineAudio ? _self.currentOnlineAudio : currentOnlineAudio // ignore: cast_nullable_to_non_nullable
as Audio?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,albumArt: freezed == albumArt ? _self.albumArt : albumArt // ignore: cast_nullable_to_non_nullable
as Uint8List?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isIdle: null == isIdle ? _self.isIdle : isIdle // ignore: cast_nullable_to_non_nullable
as bool,isReady: null == isReady ? _self.isReady : isReady // ignore: cast_nullable_to_non_nullable
as bool,isSeekable: null == isSeekable ? _self.isSeekable : isSeekable // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,statusMessage: null == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String,hasError: null == hasError ? _self.hasError : hasError // ignore: cast_nullable_to_non_nullable
as bool,isCurrentOnline: null == isCurrentOnline ? _self.isCurrentOnline : isCurrentOnline // ignore: cast_nullable_to_non_nullable
as bool,currentBvid: freezed == currentBvid ? _self.currentBvid : currentBvid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioCopyWith<$Res>? get currentOnlineAudio {
    if (_self.currentOnlineAudio == null) {
    return null;
  }

  return $AudioCopyWith<$Res>(_self.currentOnlineAudio!, (value) {
    return _then(_self.copyWith(currentOnlineAudio: value));
  });
}
}

// dart format on
