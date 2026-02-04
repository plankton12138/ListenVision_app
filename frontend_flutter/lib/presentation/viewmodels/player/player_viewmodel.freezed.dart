// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlayerState {
  /// 当前可播放音频
  PlayableAudio? get currentPlayable => throw _privateConstructorUsedError;

  /// 当前本地音频（向后兼容）
  LocalAudio? get currentAudio => throw _privateConstructorUsedError;

  /// 当前在线音频（向后兼容）
  Audio? get currentOnlineAudio => throw _privateConstructorUsedError;

  /// 标题
  String get title => throw _privateConstructorUsedError;

  /// 艺术家
  String get artist => throw _privateConstructorUsedError;

  /// 专辑封面
  Uint8List? get albumArt => throw _privateConstructorUsedError;

  /// 在线封面 URL
  String? get coverUrl => throw _privateConstructorUsedError;

  /// 是否正在播放
  bool get isPlaying => throw _privateConstructorUsedError;

  /// 是否已暂停
  bool get isPaused => throw _privateConstructorUsedError;

  /// 是否已完成
  bool get isCompleted => throw _privateConstructorUsedError;

  /// 是否正在加载
  bool get isLoading => throw _privateConstructorUsedError;

  /// 是否正在缓冲
  bool get isBuffering => throw _privateConstructorUsedError;

  /// 是否空闲
  bool get isIdle => throw _privateConstructorUsedError;

  /// 是否就绪
  bool get isReady => throw _privateConstructorUsedError;

  /// 是否可跳转
  bool get isSeekable => throw _privateConstructorUsedError;

  /// 当前播放位置
  Duration get position => throw _privateConstructorUsedError;

  /// 音频总时长
  Duration? get duration => throw _privateConstructorUsedError;

  /// 音量（0.0 - 1.0）
  double get volume => throw _privateConstructorUsedError;

  /// 播放倍速（0.5x - 2.0x）
  double get speed => throw _privateConstructorUsedError;

  /// 播放器状态消息
  String get statusMessage => throw _privateConstructorUsedError;

  /// 是否有播放错误
  bool get hasError => throw _privateConstructorUsedError;

  /// 当前是否为在线音频
  bool get isCurrentOnline => throw _privateConstructorUsedError;

  /// 当前 BVID（在线音频）
  String? get currentBvid => throw _privateConstructorUsedError;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
    PlayerState value,
    $Res Function(PlayerState) then,
  ) = _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call({
    PlayableAudio? currentPlayable,
    LocalAudio? currentAudio,
    Audio? currentOnlineAudio,
    String title,
    String artist,
    Uint8List? albumArt,
    String? coverUrl,
    bool isPlaying,
    bool isPaused,
    bool isCompleted,
    bool isLoading,
    bool isBuffering,
    bool isIdle,
    bool isReady,
    bool isSeekable,
    Duration position,
    Duration? duration,
    double volume,
    double speed,
    String statusMessage,
    bool hasError,
    bool isCurrentOnline,
    String? currentBvid,
  });

  $AudioCopyWith<$Res>? get currentOnlineAudio;
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPlayable = freezed,
    Object? currentAudio = freezed,
    Object? currentOnlineAudio = freezed,
    Object? title = null,
    Object? artist = null,
    Object? albumArt = freezed,
    Object? coverUrl = freezed,
    Object? isPlaying = null,
    Object? isPaused = null,
    Object? isCompleted = null,
    Object? isLoading = null,
    Object? isBuffering = null,
    Object? isIdle = null,
    Object? isReady = null,
    Object? isSeekable = null,
    Object? position = null,
    Object? duration = freezed,
    Object? volume = null,
    Object? speed = null,
    Object? statusMessage = null,
    Object? hasError = null,
    Object? isCurrentOnline = null,
    Object? currentBvid = freezed,
  }) {
    return _then(
      _value.copyWith(
            currentPlayable: freezed == currentPlayable
                ? _value.currentPlayable
                : currentPlayable // ignore: cast_nullable_to_non_nullable
                      as PlayableAudio?,
            currentAudio: freezed == currentAudio
                ? _value.currentAudio
                : currentAudio // ignore: cast_nullable_to_non_nullable
                      as LocalAudio?,
            currentOnlineAudio: freezed == currentOnlineAudio
                ? _value.currentOnlineAudio
                : currentOnlineAudio // ignore: cast_nullable_to_non_nullable
                      as Audio?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artist: null == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String,
            albumArt: freezed == albumArt
                ? _value.albumArt
                : albumArt // ignore: cast_nullable_to_non_nullable
                      as Uint8List?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isPlaying: null == isPlaying
                ? _value.isPlaying
                : isPlaying // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPaused: null == isPaused
                ? _value.isPaused
                : isPaused // ignore: cast_nullable_to_non_nullable
                      as bool,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isBuffering: null == isBuffering
                ? _value.isBuffering
                : isBuffering // ignore: cast_nullable_to_non_nullable
                      as bool,
            isIdle: null == isIdle
                ? _value.isIdle
                : isIdle // ignore: cast_nullable_to_non_nullable
                      as bool,
            isReady: null == isReady
                ? _value.isReady
                : isReady // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSeekable: null == isSeekable
                ? _value.isSeekable
                : isSeekable // ignore: cast_nullable_to_non_nullable
                      as bool,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Duration,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double,
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double,
            statusMessage: null == statusMessage
                ? _value.statusMessage
                : statusMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            hasError: null == hasError
                ? _value.hasError
                : hasError // ignore: cast_nullable_to_non_nullable
                      as bool,
            isCurrentOnline: null == isCurrentOnline
                ? _value.isCurrentOnline
                : isCurrentOnline // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentBvid: freezed == currentBvid
                ? _value.currentBvid
                : currentBvid // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioCopyWith<$Res>? get currentOnlineAudio {
    if (_value.currentOnlineAudio == null) {
      return null;
    }

    return $AudioCopyWith<$Res>(_value.currentOnlineAudio!, (value) {
      return _then(_value.copyWith(currentOnlineAudio: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
    _$PlayerStateImpl value,
    $Res Function(_$PlayerStateImpl) then,
  ) = __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PlayableAudio? currentPlayable,
    LocalAudio? currentAudio,
    Audio? currentOnlineAudio,
    String title,
    String artist,
    Uint8List? albumArt,
    String? coverUrl,
    bool isPlaying,
    bool isPaused,
    bool isCompleted,
    bool isLoading,
    bool isBuffering,
    bool isIdle,
    bool isReady,
    bool isSeekable,
    Duration position,
    Duration? duration,
    double volume,
    double speed,
    String statusMessage,
    bool hasError,
    bool isCurrentOnline,
    String? currentBvid,
  });

  @override
  $AudioCopyWith<$Res>? get currentOnlineAudio;
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
    _$PlayerStateImpl _value,
    $Res Function(_$PlayerStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPlayable = freezed,
    Object? currentAudio = freezed,
    Object? currentOnlineAudio = freezed,
    Object? title = null,
    Object? artist = null,
    Object? albumArt = freezed,
    Object? coverUrl = freezed,
    Object? isPlaying = null,
    Object? isPaused = null,
    Object? isCompleted = null,
    Object? isLoading = null,
    Object? isBuffering = null,
    Object? isIdle = null,
    Object? isReady = null,
    Object? isSeekable = null,
    Object? position = null,
    Object? duration = freezed,
    Object? volume = null,
    Object? speed = null,
    Object? statusMessage = null,
    Object? hasError = null,
    Object? isCurrentOnline = null,
    Object? currentBvid = freezed,
  }) {
    return _then(
      _$PlayerStateImpl(
        currentPlayable: freezed == currentPlayable
            ? _value.currentPlayable
            : currentPlayable // ignore: cast_nullable_to_non_nullable
                  as PlayableAudio?,
        currentAudio: freezed == currentAudio
            ? _value.currentAudio
            : currentAudio // ignore: cast_nullable_to_non_nullable
                  as LocalAudio?,
        currentOnlineAudio: freezed == currentOnlineAudio
            ? _value.currentOnlineAudio
            : currentOnlineAudio // ignore: cast_nullable_to_non_nullable
                  as Audio?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artist: null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String,
        albumArt: freezed == albumArt
            ? _value.albumArt
            : albumArt // ignore: cast_nullable_to_non_nullable
                  as Uint8List?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isPlaying: null == isPlaying
            ? _value.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPaused: null == isPaused
            ? _value.isPaused
            : isPaused // ignore: cast_nullable_to_non_nullable
                  as bool,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isBuffering: null == isBuffering
            ? _value.isBuffering
            : isBuffering // ignore: cast_nullable_to_non_nullable
                  as bool,
        isIdle: null == isIdle
            ? _value.isIdle
            : isIdle // ignore: cast_nullable_to_non_nullable
                  as bool,
        isReady: null == isReady
            ? _value.isReady
            : isReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSeekable: null == isSeekable
            ? _value.isSeekable
            : isSeekable // ignore: cast_nullable_to_non_nullable
                  as bool,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
        statusMessage: null == statusMessage
            ? _value.statusMessage
            : statusMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        hasError: null == hasError
            ? _value.hasError
            : hasError // ignore: cast_nullable_to_non_nullable
                  as bool,
        isCurrentOnline: null == isCurrentOnline
            ? _value.isCurrentOnline
            : isCurrentOnline // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentBvid: freezed == currentBvid
            ? _value.currentBvid
            : currentBvid // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PlayerStateImpl implements _PlayerState {
  const _$PlayerStateImpl({
    this.currentPlayable,
    this.currentAudio,
    this.currentOnlineAudio,
    this.title = '未知标题',
    this.artist = '未知艺术家',
    this.albumArt,
    this.coverUrl,
    this.isPlaying = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.isLoading = false,
    this.isBuffering = false,
    this.isIdle = true,
    this.isReady = false,
    this.isSeekable = true,
    this.position = Duration.zero,
    this.duration,
    this.volume = 1.0,
    this.speed = 1.0,
    this.statusMessage = '',
    this.hasError = false,
    this.isCurrentOnline = false,
    this.currentBvid,
  });

  /// 当前可播放音频
  @override
  final PlayableAudio? currentPlayable;

  /// 当前本地音频（向后兼容）
  @override
  final LocalAudio? currentAudio;

  /// 当前在线音频（向后兼容）
  @override
  final Audio? currentOnlineAudio;

  /// 标题
  @override
  @JsonKey()
  final String title;

  /// 艺术家
  @override
  @JsonKey()
  final String artist;

  /// 专辑封面
  @override
  final Uint8List? albumArt;

  /// 在线封面 URL
  @override
  final String? coverUrl;

  /// 是否正在播放
  @override
  @JsonKey()
  final bool isPlaying;

  /// 是否已暂停
  @override
  @JsonKey()
  final bool isPaused;

  /// 是否已完成
  @override
  @JsonKey()
  final bool isCompleted;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 是否正在缓冲
  @override
  @JsonKey()
  final bool isBuffering;

  /// 是否空闲
  @override
  @JsonKey()
  final bool isIdle;

  /// 是否就绪
  @override
  @JsonKey()
  final bool isReady;

  /// 是否可跳转
  @override
  @JsonKey()
  final bool isSeekable;

  /// 当前播放位置
  @override
  @JsonKey()
  final Duration position;

  /// 音频总时长
  @override
  final Duration? duration;

  /// 音量（0.0 - 1.0）
  @override
  @JsonKey()
  final double volume;

  /// 播放倍速（0.5x - 2.0x）
  @override
  @JsonKey()
  final double speed;

  /// 播放器状态消息
  @override
  @JsonKey()
  final String statusMessage;

  /// 是否有播放错误
  @override
  @JsonKey()
  final bool hasError;

  /// 当前是否为在线音频
  @override
  @JsonKey()
  final bool isCurrentOnline;

  /// 当前 BVID（在线音频）
  @override
  final String? currentBvid;

  @override
  String toString() {
    return 'PlayerState(currentPlayable: $currentPlayable, currentAudio: $currentAudio, currentOnlineAudio: $currentOnlineAudio, title: $title, artist: $artist, albumArt: $albumArt, coverUrl: $coverUrl, isPlaying: $isPlaying, isPaused: $isPaused, isCompleted: $isCompleted, isLoading: $isLoading, isBuffering: $isBuffering, isIdle: $isIdle, isReady: $isReady, isSeekable: $isSeekable, position: $position, duration: $duration, volume: $volume, speed: $speed, statusMessage: $statusMessage, hasError: $hasError, isCurrentOnline: $isCurrentOnline, currentBvid: $currentBvid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.currentPlayable, currentPlayable) ||
                other.currentPlayable == currentPlayable) &&
            (identical(other.currentAudio, currentAudio) ||
                other.currentAudio == currentAudio) &&
            (identical(other.currentOnlineAudio, currentOnlineAudio) ||
                other.currentOnlineAudio == currentOnlineAudio) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            const DeepCollectionEquality().equals(other.albumArt, albumArt) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.isPaused, isPaused) ||
                other.isPaused == isPaused) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isBuffering, isBuffering) ||
                other.isBuffering == isBuffering) &&
            (identical(other.isIdle, isIdle) || other.isIdle == isIdle) &&
            (identical(other.isReady, isReady) || other.isReady == isReady) &&
            (identical(other.isSeekable, isSeekable) ||
                other.isSeekable == isSeekable) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.statusMessage, statusMessage) ||
                other.statusMessage == statusMessage) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.isCurrentOnline, isCurrentOnline) ||
                other.isCurrentOnline == isCurrentOnline) &&
            (identical(other.currentBvid, currentBvid) ||
                other.currentBvid == currentBvid));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    currentPlayable,
    currentAudio,
    currentOnlineAudio,
    title,
    artist,
    const DeepCollectionEquality().hash(albumArt),
    coverUrl,
    isPlaying,
    isPaused,
    isCompleted,
    isLoading,
    isBuffering,
    isIdle,
    isReady,
    isSeekable,
    position,
    duration,
    volume,
    speed,
    statusMessage,
    hasError,
    isCurrentOnline,
    currentBvid,
  ]);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);
}

abstract class _PlayerState implements PlayerState {
  const factory _PlayerState({
    final PlayableAudio? currentPlayable,
    final LocalAudio? currentAudio,
    final Audio? currentOnlineAudio,
    final String title,
    final String artist,
    final Uint8List? albumArt,
    final String? coverUrl,
    final bool isPlaying,
    final bool isPaused,
    final bool isCompleted,
    final bool isLoading,
    final bool isBuffering,
    final bool isIdle,
    final bool isReady,
    final bool isSeekable,
    final Duration position,
    final Duration? duration,
    final double volume,
    final double speed,
    final String statusMessage,
    final bool hasError,
    final bool isCurrentOnline,
    final String? currentBvid,
  }) = _$PlayerStateImpl;

  /// 当前可播放音频
  @override
  PlayableAudio? get currentPlayable;

  /// 当前本地音频（向后兼容）
  @override
  LocalAudio? get currentAudio;

  /// 当前在线音频（向后兼容）
  @override
  Audio? get currentOnlineAudio;

  /// 标题
  @override
  String get title;

  /// 艺术家
  @override
  String get artist;

  /// 专辑封面
  @override
  Uint8List? get albumArt;

  /// 在线封面 URL
  @override
  String? get coverUrl;

  /// 是否正在播放
  @override
  bool get isPlaying;

  /// 是否已暂停
  @override
  bool get isPaused;

  /// 是否已完成
  @override
  bool get isCompleted;

  /// 是否正在加载
  @override
  bool get isLoading;

  /// 是否正在缓冲
  @override
  bool get isBuffering;

  /// 是否空闲
  @override
  bool get isIdle;

  /// 是否就绪
  @override
  bool get isReady;

  /// 是否可跳转
  @override
  bool get isSeekable;

  /// 当前播放位置
  @override
  Duration get position;

  /// 音频总时长
  @override
  Duration? get duration;

  /// 音量（0.0 - 1.0）
  @override
  double get volume;

  /// 播放倍速（0.5x - 2.0x）
  @override
  double get speed;

  /// 播放器状态消息
  @override
  String get statusMessage;

  /// 是否有播放错误
  @override
  bool get hasError;

  /// 当前是否为在线音频
  @override
  bool get isCurrentOnline;

  /// 当前 BVID（在线音频）
  @override
  String? get currentBvid;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
