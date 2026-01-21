// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlayHistory _$PlayHistoryFromJson(Map<String, dynamic> json) {
  return _PlayHistory.fromJson(json);
}

/// @nodoc
mixin _$PlayHistory {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  Audio get audio => throw _privateConstructorUsedError;
  DateTime get playedAt => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError; // 播放进度（秒）
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PlayHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayHistoryCopyWith<PlayHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayHistoryCopyWith<$Res> {
  factory $PlayHistoryCopyWith(
    PlayHistory value,
    $Res Function(PlayHistory) then,
  ) = _$PlayHistoryCopyWithImpl<$Res, PlayHistory>;
  @useResult
  $Res call({
    String id,
    String userId,
    Audio audio,
    DateTime playedAt,
    int progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  $AudioCopyWith<$Res> get audio;
}

/// @nodoc
class _$PlayHistoryCopyWithImpl<$Res, $Val extends PlayHistory>
    implements $PlayHistoryCopyWith<$Res> {
  _$PlayHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? audio = null,
    Object? playedAt = null,
    Object? progress = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            audio: null == audio
                ? _value.audio
                : audio // ignore: cast_nullable_to_non_nullable
                      as Audio,
            playedAt: null == playedAt
                ? _value.playedAt
                : playedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioCopyWith<$Res> get audio {
    return $AudioCopyWith<$Res>(_value.audio, (value) {
      return _then(_value.copyWith(audio: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayHistoryImplCopyWith<$Res>
    implements $PlayHistoryCopyWith<$Res> {
  factory _$$PlayHistoryImplCopyWith(
    _$PlayHistoryImpl value,
    $Res Function(_$PlayHistoryImpl) then,
  ) = __$$PlayHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    Audio audio,
    DateTime playedAt,
    int progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  $AudioCopyWith<$Res> get audio;
}

/// @nodoc
class __$$PlayHistoryImplCopyWithImpl<$Res>
    extends _$PlayHistoryCopyWithImpl<$Res, _$PlayHistoryImpl>
    implements _$$PlayHistoryImplCopyWith<$Res> {
  __$$PlayHistoryImplCopyWithImpl(
    _$PlayHistoryImpl _value,
    $Res Function(_$PlayHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? audio = null,
    Object? playedAt = null,
    Object? progress = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PlayHistoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        audio: null == audio
            ? _value.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as Audio,
        playedAt: null == playedAt
            ? _value.playedAt
            : playedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayHistoryImpl extends _PlayHistory {
  const _$PlayHistoryImpl({
    required this.id,
    required this.userId,
    required this.audio,
    required this.playedAt,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$PlayHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final Audio audio;
  @override
  final DateTime playedAt;
  @override
  @JsonKey()
  final int progress;
  // 播放进度（秒）
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PlayHistory(id: $id, userId: $userId, audio: $audio, playedAt: $playedAt, progress: $progress, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    audio,
    playedAt,
    progress,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayHistoryImplCopyWith<_$PlayHistoryImpl> get copyWith =>
      __$$PlayHistoryImplCopyWithImpl<_$PlayHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayHistoryImplToJson(this);
  }
}

abstract class _PlayHistory extends PlayHistory {
  const factory _PlayHistory({
    required final String id,
    required final String userId,
    required final Audio audio,
    required final DateTime playedAt,
    final int progress,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$PlayHistoryImpl;
  const _PlayHistory._() : super._();

  factory _PlayHistory.fromJson(Map<String, dynamic> json) =
      _$PlayHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  Audio get audio;
  @override
  DateTime get playedAt;
  @override
  int get progress; // 播放进度（秒）
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of PlayHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayHistoryImplCopyWith<_$PlayHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayHistoryStats _$PlayHistoryStatsFromJson(Map<String, dynamic> json) {
  return _PlayHistoryStats.fromJson(json);
}

/// @nodoc
mixin _$PlayHistoryStats {
  int get totalPlays => throw _privateConstructorUsedError;
  PlayHistory? get lastPlayed => throw _privateConstructorUsedError;
  int get uniqueTracks => throw _privateConstructorUsedError;
  int get totalDuration => throw _privateConstructorUsedError;

  /// Serializes this PlayHistoryStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayHistoryStatsCopyWith<PlayHistoryStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayHistoryStatsCopyWith<$Res> {
  factory $PlayHistoryStatsCopyWith(
    PlayHistoryStats value,
    $Res Function(PlayHistoryStats) then,
  ) = _$PlayHistoryStatsCopyWithImpl<$Res, PlayHistoryStats>;
  @useResult
  $Res call({
    int totalPlays,
    PlayHistory? lastPlayed,
    int uniqueTracks,
    int totalDuration,
  });

  $PlayHistoryCopyWith<$Res>? get lastPlayed;
}

/// @nodoc
class _$PlayHistoryStatsCopyWithImpl<$Res, $Val extends PlayHistoryStats>
    implements $PlayHistoryStatsCopyWith<$Res> {
  _$PlayHistoryStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPlays = null,
    Object? lastPlayed = freezed,
    Object? uniqueTracks = null,
    Object? totalDuration = null,
  }) {
    return _then(
      _value.copyWith(
            totalPlays: null == totalPlays
                ? _value.totalPlays
                : totalPlays // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPlayed: freezed == lastPlayed
                ? _value.lastPlayed
                : lastPlayed // ignore: cast_nullable_to_non_nullable
                      as PlayHistory?,
            uniqueTracks: null == uniqueTracks
                ? _value.uniqueTracks
                : uniqueTracks // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDuration: null == totalDuration
                ? _value.totalDuration
                : totalDuration // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayHistoryCopyWith<$Res>? get lastPlayed {
    if (_value.lastPlayed == null) {
      return null;
    }

    return $PlayHistoryCopyWith<$Res>(_value.lastPlayed!, (value) {
      return _then(_value.copyWith(lastPlayed: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayHistoryStatsImplCopyWith<$Res>
    implements $PlayHistoryStatsCopyWith<$Res> {
  factory _$$PlayHistoryStatsImplCopyWith(
    _$PlayHistoryStatsImpl value,
    $Res Function(_$PlayHistoryStatsImpl) then,
  ) = __$$PlayHistoryStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalPlays,
    PlayHistory? lastPlayed,
    int uniqueTracks,
    int totalDuration,
  });

  @override
  $PlayHistoryCopyWith<$Res>? get lastPlayed;
}

/// @nodoc
class __$$PlayHistoryStatsImplCopyWithImpl<$Res>
    extends _$PlayHistoryStatsCopyWithImpl<$Res, _$PlayHistoryStatsImpl>
    implements _$$PlayHistoryStatsImplCopyWith<$Res> {
  __$$PlayHistoryStatsImplCopyWithImpl(
    _$PlayHistoryStatsImpl _value,
    $Res Function(_$PlayHistoryStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPlays = null,
    Object? lastPlayed = freezed,
    Object? uniqueTracks = null,
    Object? totalDuration = null,
  }) {
    return _then(
      _$PlayHistoryStatsImpl(
        totalPlays: null == totalPlays
            ? _value.totalPlays
            : totalPlays // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPlayed: freezed == lastPlayed
            ? _value.lastPlayed
            : lastPlayed // ignore: cast_nullable_to_non_nullable
                  as PlayHistory?,
        uniqueTracks: null == uniqueTracks
            ? _value.uniqueTracks
            : uniqueTracks // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDuration: null == totalDuration
            ? _value.totalDuration
            : totalDuration // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayHistoryStatsImpl implements _PlayHistoryStats {
  const _$PlayHistoryStatsImpl({
    this.totalPlays = 0,
    this.lastPlayed,
    this.uniqueTracks = 0,
    this.totalDuration = 0,
  });

  factory _$PlayHistoryStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayHistoryStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalPlays;
  @override
  final PlayHistory? lastPlayed;
  @override
  @JsonKey()
  final int uniqueTracks;
  @override
  @JsonKey()
  final int totalDuration;

  @override
  String toString() {
    return 'PlayHistoryStats(totalPlays: $totalPlays, lastPlayed: $lastPlayed, uniqueTracks: $uniqueTracks, totalDuration: $totalDuration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayHistoryStatsImpl &&
            (identical(other.totalPlays, totalPlays) ||
                other.totalPlays == totalPlays) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.uniqueTracks, uniqueTracks) ||
                other.uniqueTracks == uniqueTracks) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalPlays,
    lastPlayed,
    uniqueTracks,
    totalDuration,
  );

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayHistoryStatsImplCopyWith<_$PlayHistoryStatsImpl> get copyWith =>
      __$$PlayHistoryStatsImplCopyWithImpl<_$PlayHistoryStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayHistoryStatsImplToJson(this);
  }
}

abstract class _PlayHistoryStats implements PlayHistoryStats {
  const factory _PlayHistoryStats({
    final int totalPlays,
    final PlayHistory? lastPlayed,
    final int uniqueTracks,
    final int totalDuration,
  }) = _$PlayHistoryStatsImpl;

  factory _PlayHistoryStats.fromJson(Map<String, dynamic> json) =
      _$PlayHistoryStatsImpl.fromJson;

  @override
  int get totalPlays;
  @override
  PlayHistory? get lastPlayed;
  @override
  int get uniqueTracks;
  @override
  int get totalDuration;

  /// Create a copy of PlayHistoryStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayHistoryStatsImplCopyWith<_$PlayHistoryStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
