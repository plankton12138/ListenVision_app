// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) {
  return _Recommendation.fromJson(json);
}

/// @nodoc
mixin _$Recommendation {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get duration => throw _privateConstructorUsedError;
  String? get artist => throw _privateConstructorUsedError;
  int? get playCount => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  RecommendationType get type => throw _privateConstructorUsedError;

  /// Serializes this Recommendation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Recommendation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecommendationCopyWith<Recommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendationCopyWith<$Res> {
  factory $RecommendationCopyWith(
    Recommendation value,
    $Res Function(Recommendation) then,
  ) = _$RecommendationCopyWithImpl<$Res, Recommendation>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String? coverUrl,
    String? duration,
    String? artist,
    int? playCount,
    String? url,
    RecommendationType type,
  });
}

/// @nodoc
class _$RecommendationCopyWithImpl<$Res, $Val extends Recommendation>
    implements $RecommendationCopyWith<$Res> {
  _$RecommendationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Recommendation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? coverUrl = freezed,
    Object? duration = freezed,
    Object? artist = freezed,
    Object? playCount = freezed,
    Object? url = freezed,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as String?,
            artist: freezed == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String?,
            playCount: freezed == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            url: freezed == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as RecommendationType,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecommendationImplCopyWith<$Res>
    implements $RecommendationCopyWith<$Res> {
  factory _$$RecommendationImplCopyWith(
    _$RecommendationImpl value,
    $Res Function(_$RecommendationImpl) then,
  ) = __$$RecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String? coverUrl,
    String? duration,
    String? artist,
    int? playCount,
    String? url,
    RecommendationType type,
  });
}

/// @nodoc
class __$$RecommendationImplCopyWithImpl<$Res>
    extends _$RecommendationCopyWithImpl<$Res, _$RecommendationImpl>
    implements _$$RecommendationImplCopyWith<$Res> {
  __$$RecommendationImplCopyWithImpl(
    _$RecommendationImpl _value,
    $Res Function(_$RecommendationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Recommendation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? coverUrl = freezed,
    Object? duration = freezed,
    Object? artist = freezed,
    Object? playCount = freezed,
    Object? url = freezed,
    Object? type = null,
  }) {
    return _then(
      _$RecommendationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as String?,
        artist: freezed == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String?,
        playCount: freezed == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        url: freezed == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as RecommendationType,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendationImpl extends _Recommendation {
  const _$RecommendationImpl({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.duration,
    this.artist,
    this.playCount,
    this.url,
    this.type = RecommendationType.video,
  }) : super._();

  factory _$RecommendationImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecommendationImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? coverUrl;
  @override
  final String? duration;
  @override
  final String? artist;
  @override
  final int? playCount;
  @override
  final String? url;
  @override
  @JsonKey()
  final RecommendationType type;

  @override
  String toString() {
    return 'Recommendation(id: $id, title: $title, description: $description, coverUrl: $coverUrl, duration: $duration, artist: $artist, playCount: $playCount, url: $url, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    coverUrl,
    duration,
    artist,
    playCount,
    url,
    type,
  );

  /// Create a copy of Recommendation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendationImplCopyWith<_$RecommendationImpl> get copyWith =>
      __$$RecommendationImplCopyWithImpl<_$RecommendationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendationImplToJson(this);
  }
}

abstract class _Recommendation extends Recommendation {
  const factory _Recommendation({
    required final String id,
    required final String title,
    final String? description,
    final String? coverUrl,
    final String? duration,
    final String? artist,
    final int? playCount,
    final String? url,
    final RecommendationType type,
  }) = _$RecommendationImpl;
  const _Recommendation._() : super._();

  factory _Recommendation.fromJson(Map<String, dynamic> json) =
      _$RecommendationImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get coverUrl;
  @override
  String? get duration;
  @override
  String? get artist;
  @override
  int? get playCount;
  @override
  String? get url;
  @override
  RecommendationType get type;

  /// Create a copy of Recommendation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecommendationImplCopyWith<_$RecommendationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BiliPlaylist _$BiliPlaylistFromJson(Map<String, dynamic> json) {
  return _BiliPlaylist.fromJson(json);
}

/// @nodoc
mixin _$BiliPlaylist {
  int get menuId => throw _privateConstructorUsedError;
  int? get uid => throw _privateConstructorUsedError;
  String? get uploader => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get intro => throw _privateConstructorUsedError;
  int? get type => throw _privateConstructorUsedError;
  int get songCount => throw _privateConstructorUsedError;
  BiliPlaylistStats get stats => throw _privateConstructorUsedError;
  List<BiliAudioPreview> get previews => throw _privateConstructorUsedError;

  /// Serializes this BiliPlaylist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BiliPlaylistCopyWith<BiliPlaylist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BiliPlaylistCopyWith<$Res> {
  factory $BiliPlaylistCopyWith(
    BiliPlaylist value,
    $Res Function(BiliPlaylist) then,
  ) = _$BiliPlaylistCopyWithImpl<$Res, BiliPlaylist>;
  @useResult
  $Res call({
    int menuId,
    int? uid,
    String? uploader,
    String title,
    String? coverUrl,
    String? intro,
    int? type,
    int songCount,
    BiliPlaylistStats stats,
    List<BiliAudioPreview> previews,
  });

  $BiliPlaylistStatsCopyWith<$Res> get stats;
}

/// @nodoc
class _$BiliPlaylistCopyWithImpl<$Res, $Val extends BiliPlaylist>
    implements $BiliPlaylistCopyWith<$Res> {
  _$BiliPlaylistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuId = null,
    Object? uid = freezed,
    Object? uploader = freezed,
    Object? title = null,
    Object? coverUrl = freezed,
    Object? intro = freezed,
    Object? type = freezed,
    Object? songCount = null,
    Object? stats = null,
    Object? previews = null,
  }) {
    return _then(
      _value.copyWith(
            menuId: null == menuId
                ? _value.menuId
                : menuId // ignore: cast_nullable_to_non_nullable
                      as int,
            uid: freezed == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as int?,
            uploader: freezed == uploader
                ? _value.uploader
                : uploader // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            intro: freezed == intro
                ? _value.intro
                : intro // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int?,
            songCount: null == songCount
                ? _value.songCount
                : songCount // ignore: cast_nullable_to_non_nullable
                      as int,
            stats: null == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as BiliPlaylistStats,
            previews: null == previews
                ? _value.previews
                : previews // ignore: cast_nullable_to_non_nullable
                      as List<BiliAudioPreview>,
          )
          as $Val,
    );
  }

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BiliPlaylistStatsCopyWith<$Res> get stats {
    return $BiliPlaylistStatsCopyWith<$Res>(_value.stats, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BiliPlaylistImplCopyWith<$Res>
    implements $BiliPlaylistCopyWith<$Res> {
  factory _$$BiliPlaylistImplCopyWith(
    _$BiliPlaylistImpl value,
    $Res Function(_$BiliPlaylistImpl) then,
  ) = __$$BiliPlaylistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int menuId,
    int? uid,
    String? uploader,
    String title,
    String? coverUrl,
    String? intro,
    int? type,
    int songCount,
    BiliPlaylistStats stats,
    List<BiliAudioPreview> previews,
  });

  @override
  $BiliPlaylistStatsCopyWith<$Res> get stats;
}

/// @nodoc
class __$$BiliPlaylistImplCopyWithImpl<$Res>
    extends _$BiliPlaylistCopyWithImpl<$Res, _$BiliPlaylistImpl>
    implements _$$BiliPlaylistImplCopyWith<$Res> {
  __$$BiliPlaylistImplCopyWithImpl(
    _$BiliPlaylistImpl _value,
    $Res Function(_$BiliPlaylistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuId = null,
    Object? uid = freezed,
    Object? uploader = freezed,
    Object? title = null,
    Object? coverUrl = freezed,
    Object? intro = freezed,
    Object? type = freezed,
    Object? songCount = null,
    Object? stats = null,
    Object? previews = null,
  }) {
    return _then(
      _$BiliPlaylistImpl(
        menuId: null == menuId
            ? _value.menuId
            : menuId // ignore: cast_nullable_to_non_nullable
                  as int,
        uid: freezed == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as int?,
        uploader: freezed == uploader
            ? _value.uploader
            : uploader // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        intro: freezed == intro
            ? _value.intro
            : intro // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int?,
        songCount: null == songCount
            ? _value.songCount
            : songCount // ignore: cast_nullable_to_non_nullable
                  as int,
        stats: null == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as BiliPlaylistStats,
        previews: null == previews
            ? _value._previews
            : previews // ignore: cast_nullable_to_non_nullable
                  as List<BiliAudioPreview>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BiliPlaylistImpl extends _BiliPlaylist {
  const _$BiliPlaylistImpl({
    required this.menuId,
    this.uid,
    this.uploader,
    required this.title,
    this.coverUrl,
    this.intro,
    this.type,
    this.songCount = 0,
    required this.stats,
    final List<BiliAudioPreview> previews = const [],
  }) : _previews = previews,
       super._();

  factory _$BiliPlaylistImpl.fromJson(Map<String, dynamic> json) =>
      _$$BiliPlaylistImplFromJson(json);

  @override
  final int menuId;
  @override
  final int? uid;
  @override
  final String? uploader;
  @override
  final String title;
  @override
  final String? coverUrl;
  @override
  final String? intro;
  @override
  final int? type;
  @override
  @JsonKey()
  final int songCount;
  @override
  final BiliPlaylistStats stats;
  final List<BiliAudioPreview> _previews;
  @override
  @JsonKey()
  List<BiliAudioPreview> get previews {
    if (_previews is EqualUnmodifiableListView) return _previews;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previews);
  }

  @override
  String toString() {
    return 'BiliPlaylist(menuId: $menuId, uid: $uid, uploader: $uploader, title: $title, coverUrl: $coverUrl, intro: $intro, type: $type, songCount: $songCount, stats: $stats, previews: $previews)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BiliPlaylistImpl &&
            (identical(other.menuId, menuId) || other.menuId == menuId) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.uploader, uploader) ||
                other.uploader == uploader) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.intro, intro) || other.intro == intro) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.songCount, songCount) ||
                other.songCount == songCount) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            const DeepCollectionEquality().equals(other._previews, _previews));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    menuId,
    uid,
    uploader,
    title,
    coverUrl,
    intro,
    type,
    songCount,
    stats,
    const DeepCollectionEquality().hash(_previews),
  );

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BiliPlaylistImplCopyWith<_$BiliPlaylistImpl> get copyWith =>
      __$$BiliPlaylistImplCopyWithImpl<_$BiliPlaylistImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BiliPlaylistImplToJson(this);
  }
}

abstract class _BiliPlaylist extends BiliPlaylist {
  const factory _BiliPlaylist({
    required final int menuId,
    final int? uid,
    final String? uploader,
    required final String title,
    final String? coverUrl,
    final String? intro,
    final int? type,
    final int songCount,
    required final BiliPlaylistStats stats,
    final List<BiliAudioPreview> previews,
  }) = _$BiliPlaylistImpl;
  const _BiliPlaylist._() : super._();

  factory _BiliPlaylist.fromJson(Map<String, dynamic> json) =
      _$BiliPlaylistImpl.fromJson;

  @override
  int get menuId;
  @override
  int? get uid;
  @override
  String? get uploader;
  @override
  String get title;
  @override
  String? get coverUrl;
  @override
  String? get intro;
  @override
  int? get type;
  @override
  int get songCount;
  @override
  BiliPlaylistStats get stats;
  @override
  List<BiliAudioPreview> get previews;

  /// Create a copy of BiliPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BiliPlaylistImplCopyWith<_$BiliPlaylistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BiliPlaylistStats _$BiliPlaylistStatsFromJson(Map<String, dynamic> json) {
  return _BiliPlaylistStats.fromJson(json);
}

/// @nodoc
mixin _$BiliPlaylistStats {
  int get play => throw _privateConstructorUsedError;
  int get collect => throw _privateConstructorUsedError;
  int get comment => throw _privateConstructorUsedError;
  int get share => throw _privateConstructorUsedError;

  /// Serializes this BiliPlaylistStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BiliPlaylistStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BiliPlaylistStatsCopyWith<BiliPlaylistStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BiliPlaylistStatsCopyWith<$Res> {
  factory $BiliPlaylistStatsCopyWith(
    BiliPlaylistStats value,
    $Res Function(BiliPlaylistStats) then,
  ) = _$BiliPlaylistStatsCopyWithImpl<$Res, BiliPlaylistStats>;
  @useResult
  $Res call({int play, int collect, int comment, int share});
}

/// @nodoc
class _$BiliPlaylistStatsCopyWithImpl<$Res, $Val extends BiliPlaylistStats>
    implements $BiliPlaylistStatsCopyWith<$Res> {
  _$BiliPlaylistStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BiliPlaylistStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? play = null,
    Object? collect = null,
    Object? comment = null,
    Object? share = null,
  }) {
    return _then(
      _value.copyWith(
            play: null == play
                ? _value.play
                : play // ignore: cast_nullable_to_non_nullable
                      as int,
            collect: null == collect
                ? _value.collect
                : collect // ignore: cast_nullable_to_non_nullable
                      as int,
            comment: null == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as int,
            share: null == share
                ? _value.share
                : share // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BiliPlaylistStatsImplCopyWith<$Res>
    implements $BiliPlaylistStatsCopyWith<$Res> {
  factory _$$BiliPlaylistStatsImplCopyWith(
    _$BiliPlaylistStatsImpl value,
    $Res Function(_$BiliPlaylistStatsImpl) then,
  ) = __$$BiliPlaylistStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int play, int collect, int comment, int share});
}

/// @nodoc
class __$$BiliPlaylistStatsImplCopyWithImpl<$Res>
    extends _$BiliPlaylistStatsCopyWithImpl<$Res, _$BiliPlaylistStatsImpl>
    implements _$$BiliPlaylistStatsImplCopyWith<$Res> {
  __$$BiliPlaylistStatsImplCopyWithImpl(
    _$BiliPlaylistStatsImpl _value,
    $Res Function(_$BiliPlaylistStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BiliPlaylistStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? play = null,
    Object? collect = null,
    Object? comment = null,
    Object? share = null,
  }) {
    return _then(
      _$BiliPlaylistStatsImpl(
        play: null == play
            ? _value.play
            : play // ignore: cast_nullable_to_non_nullable
                  as int,
        collect: null == collect
            ? _value.collect
            : collect // ignore: cast_nullable_to_non_nullable
                  as int,
        comment: null == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as int,
        share: null == share
            ? _value.share
            : share // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BiliPlaylistStatsImpl implements _BiliPlaylistStats {
  const _$BiliPlaylistStatsImpl({
    this.play = 0,
    this.collect = 0,
    this.comment = 0,
    this.share = 0,
  });

  factory _$BiliPlaylistStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BiliPlaylistStatsImplFromJson(json);

  @override
  @JsonKey()
  final int play;
  @override
  @JsonKey()
  final int collect;
  @override
  @JsonKey()
  final int comment;
  @override
  @JsonKey()
  final int share;

  @override
  String toString() {
    return 'BiliPlaylistStats(play: $play, collect: $collect, comment: $comment, share: $share)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BiliPlaylistStatsImpl &&
            (identical(other.play, play) || other.play == play) &&
            (identical(other.collect, collect) || other.collect == collect) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.share, share) || other.share == share));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, play, collect, comment, share);

  /// Create a copy of BiliPlaylistStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BiliPlaylistStatsImplCopyWith<_$BiliPlaylistStatsImpl> get copyWith =>
      __$$BiliPlaylistStatsImplCopyWithImpl<_$BiliPlaylistStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BiliPlaylistStatsImplToJson(this);
  }
}

abstract class _BiliPlaylistStats implements BiliPlaylistStats {
  const factory _BiliPlaylistStats({
    final int play,
    final int collect,
    final int comment,
    final int share,
  }) = _$BiliPlaylistStatsImpl;

  factory _BiliPlaylistStats.fromJson(Map<String, dynamic> json) =
      _$BiliPlaylistStatsImpl.fromJson;

  @override
  int get play;
  @override
  int get collect;
  @override
  int get comment;
  @override
  int get share;

  /// Create a copy of BiliPlaylistStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BiliPlaylistStatsImplCopyWith<_$BiliPlaylistStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BiliAudioPreview _$BiliAudioPreviewFromJson(Map<String, dynamic> json) {
  return _BiliAudioPreview.fromJson(json);
}

/// @nodoc
mixin _$BiliAudioPreview {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int? get duration => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;

  /// Serializes this BiliAudioPreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BiliAudioPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BiliAudioPreviewCopyWith<BiliAudioPreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BiliAudioPreviewCopyWith<$Res> {
  factory $BiliAudioPreviewCopyWith(
    BiliAudioPreview value,
    $Res Function(BiliAudioPreview) then,
  ) = _$BiliAudioPreviewCopyWithImpl<$Res, BiliAudioPreview>;
  @useResult
  $Res call({int id, String title, int? duration, String? coverUrl});
}

/// @nodoc
class _$BiliAudioPreviewCopyWithImpl<$Res, $Val extends BiliAudioPreview>
    implements $BiliAudioPreviewCopyWith<$Res> {
  _$BiliAudioPreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BiliAudioPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? duration = freezed,
    Object? coverUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BiliAudioPreviewImplCopyWith<$Res>
    implements $BiliAudioPreviewCopyWith<$Res> {
  factory _$$BiliAudioPreviewImplCopyWith(
    _$BiliAudioPreviewImpl value,
    $Res Function(_$BiliAudioPreviewImpl) then,
  ) = __$$BiliAudioPreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String title, int? duration, String? coverUrl});
}

/// @nodoc
class __$$BiliAudioPreviewImplCopyWithImpl<$Res>
    extends _$BiliAudioPreviewCopyWithImpl<$Res, _$BiliAudioPreviewImpl>
    implements _$$BiliAudioPreviewImplCopyWith<$Res> {
  __$$BiliAudioPreviewImplCopyWithImpl(
    _$BiliAudioPreviewImpl _value,
    $Res Function(_$BiliAudioPreviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BiliAudioPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? duration = freezed,
    Object? coverUrl = freezed,
  }) {
    return _then(
      _$BiliAudioPreviewImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BiliAudioPreviewImpl extends _BiliAudioPreview {
  const _$BiliAudioPreviewImpl({
    required this.id,
    required this.title,
    this.duration,
    this.coverUrl,
  }) : super._();

  factory _$BiliAudioPreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$BiliAudioPreviewImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final int? duration;
  @override
  final String? coverUrl;

  @override
  String toString() {
    return 'BiliAudioPreview(id: $id, title: $title, duration: $duration, coverUrl: $coverUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BiliAudioPreviewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, duration, coverUrl);

  /// Create a copy of BiliAudioPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BiliAudioPreviewImplCopyWith<_$BiliAudioPreviewImpl> get copyWith =>
      __$$BiliAudioPreviewImplCopyWithImpl<_$BiliAudioPreviewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BiliAudioPreviewImplToJson(this);
  }
}

abstract class _BiliAudioPreview extends BiliAudioPreview {
  const factory _BiliAudioPreview({
    required final int id,
    required final String title,
    final int? duration,
    final String? coverUrl,
  }) = _$BiliAudioPreviewImpl;
  const _BiliAudioPreview._() : super._();

  factory _BiliAudioPreview.fromJson(Map<String, dynamic> json) =
      _$BiliAudioPreviewImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  int? get duration;
  @override
  String? get coverUrl;

  /// Create a copy of BiliAudioPreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BiliAudioPreviewImplCopyWith<_$BiliAudioPreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecommendationResponse _$RecommendationResponseFromJson(
  Map<String, dynamic> json,
) {
  return _RecommendationResponse.fromJson(json);
}

/// @nodoc
mixin _$RecommendationResponse {
  List<Recommendation> get items => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;

  /// Serializes this RecommendationResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecommendationResponseCopyWith<RecommendationResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendationResponseCopyWith<$Res> {
  factory $RecommendationResponseCopyWith(
    RecommendationResponse value,
    $Res Function(RecommendationResponse) then,
  ) = _$RecommendationResponseCopyWithImpl<$Res, RecommendationResponse>;
  @useResult
  $Res call({
    List<Recommendation> items,
    int page,
    int pageSize,
    int total,
    String? source,
  });
}

/// @nodoc
class _$RecommendationResponseCopyWithImpl<
  $Res,
  $Val extends RecommendationResponse
>
    implements $RecommendationResponseCopyWith<$Res> {
  _$RecommendationResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? page = null,
    Object? pageSize = null,
    Object? total = null,
    Object? source = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<Recommendation>,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            pageSize: null == pageSize
                ? _value.pageSize
                : pageSize // ignore: cast_nullable_to_non_nullable
                      as int,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecommendationResponseImplCopyWith<$Res>
    implements $RecommendationResponseCopyWith<$Res> {
  factory _$$RecommendationResponseImplCopyWith(
    _$RecommendationResponseImpl value,
    $Res Function(_$RecommendationResponseImpl) then,
  ) = __$$RecommendationResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Recommendation> items,
    int page,
    int pageSize,
    int total,
    String? source,
  });
}

/// @nodoc
class __$$RecommendationResponseImplCopyWithImpl<$Res>
    extends
        _$RecommendationResponseCopyWithImpl<$Res, _$RecommendationResponseImpl>
    implements _$$RecommendationResponseImplCopyWith<$Res> {
  __$$RecommendationResponseImplCopyWithImpl(
    _$RecommendationResponseImpl _value,
    $Res Function(_$RecommendationResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? page = null,
    Object? pageSize = null,
    Object? total = null,
    Object? source = freezed,
  }) {
    return _then(
      _$RecommendationResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<Recommendation>,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        pageSize: null == pageSize
            ? _value.pageSize
            : pageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendationResponseImpl extends _RecommendationResponse {
  const _$RecommendationResponseImpl({
    final List<Recommendation> items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.source,
  }) : _items = items,
       super._();

  factory _$RecommendationResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecommendationResponseImplFromJson(json);

  final List<Recommendation> _items;
  @override
  @JsonKey()
  List<Recommendation> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int pageSize;
  @override
  @JsonKey()
  final int total;
  @override
  final String? source;

  @override
  String toString() {
    return 'RecommendationResponse(items: $items, page: $page, pageSize: $pageSize, total: $total, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendationResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    page,
    pageSize,
    total,
    source,
  );

  /// Create a copy of RecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendationResponseImplCopyWith<_$RecommendationResponseImpl>
  get copyWith =>
      __$$RecommendationResponseImplCopyWithImpl<_$RecommendationResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendationResponseImplToJson(this);
  }
}

abstract class _RecommendationResponse extends RecommendationResponse {
  const factory _RecommendationResponse({
    final List<Recommendation> items,
    final int page,
    final int pageSize,
    final int total,
    final String? source,
  }) = _$RecommendationResponseImpl;
  const _RecommendationResponse._() : super._();

  factory _RecommendationResponse.fromJson(Map<String, dynamic> json) =
      _$RecommendationResponseImpl.fromJson;

  @override
  List<Recommendation> get items;
  @override
  int get page;
  @override
  int get pageSize;
  @override
  int get total;
  @override
  String? get source;

  /// Create a copy of RecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecommendationResponseImplCopyWith<_$RecommendationResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PersonalizedResponse _$PersonalizedResponseFromJson(Map<String, dynamic> json) {
  return _PersonalizedResponse.fromJson(json);
}

/// @nodoc
mixin _$PersonalizedResponse {
  String get source => throw _privateConstructorUsedError;
  List<String> get keywords => throw _privateConstructorUsedError;
  List<Recommendation> get videos => throw _privateConstructorUsedError;
  List<BiliPlaylist> get playlists => throw _privateConstructorUsedError;

  /// Serializes this PersonalizedResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersonalizedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalizedResponseCopyWith<PersonalizedResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalizedResponseCopyWith<$Res> {
  factory $PersonalizedResponseCopyWith(
    PersonalizedResponse value,
    $Res Function(PersonalizedResponse) then,
  ) = _$PersonalizedResponseCopyWithImpl<$Res, PersonalizedResponse>;
  @useResult
  $Res call({
    String source,
    List<String> keywords,
    List<Recommendation> videos,
    List<BiliPlaylist> playlists,
  });
}

/// @nodoc
class _$PersonalizedResponseCopyWithImpl<
  $Res,
  $Val extends PersonalizedResponse
>
    implements $PersonalizedResponseCopyWith<$Res> {
  _$PersonalizedResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalizedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? keywords = null,
    Object? videos = null,
    Object? playlists = null,
  }) {
    return _then(
      _value.copyWith(
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            keywords: null == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            videos: null == videos
                ? _value.videos
                : videos // ignore: cast_nullable_to_non_nullable
                      as List<Recommendation>,
            playlists: null == playlists
                ? _value.playlists
                : playlists // ignore: cast_nullable_to_non_nullable
                      as List<BiliPlaylist>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PersonalizedResponseImplCopyWith<$Res>
    implements $PersonalizedResponseCopyWith<$Res> {
  factory _$$PersonalizedResponseImplCopyWith(
    _$PersonalizedResponseImpl value,
    $Res Function(_$PersonalizedResponseImpl) then,
  ) = __$$PersonalizedResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String source,
    List<String> keywords,
    List<Recommendation> videos,
    List<BiliPlaylist> playlists,
  });
}

/// @nodoc
class __$$PersonalizedResponseImplCopyWithImpl<$Res>
    extends _$PersonalizedResponseCopyWithImpl<$Res, _$PersonalizedResponseImpl>
    implements _$$PersonalizedResponseImplCopyWith<$Res> {
  __$$PersonalizedResponseImplCopyWithImpl(
    _$PersonalizedResponseImpl _value,
    $Res Function(_$PersonalizedResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonalizedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? keywords = null,
    Object? videos = null,
    Object? playlists = null,
  }) {
    return _then(
      _$PersonalizedResponseImpl(
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        keywords: null == keywords
            ? _value._keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        videos: null == videos
            ? _value._videos
            : videos // ignore: cast_nullable_to_non_nullable
                  as List<Recommendation>,
        playlists: null == playlists
            ? _value._playlists
            : playlists // ignore: cast_nullable_to_non_nullable
                  as List<BiliPlaylist>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalizedResponseImpl extends _PersonalizedResponse {
  const _$PersonalizedResponseImpl({
    required this.source,
    final List<String> keywords = const [],
    final List<Recommendation> videos = const [],
    final List<BiliPlaylist> playlists = const [],
  }) : _keywords = keywords,
       _videos = videos,
       _playlists = playlists,
       super._();

  factory _$PersonalizedResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalizedResponseImplFromJson(json);

  @override
  final String source;
  final List<String> _keywords;
  @override
  @JsonKey()
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  final List<Recommendation> _videos;
  @override
  @JsonKey()
  List<Recommendation> get videos {
    if (_videos is EqualUnmodifiableListView) return _videos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_videos);
  }

  final List<BiliPlaylist> _playlists;
  @override
  @JsonKey()
  List<BiliPlaylist> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  @override
  String toString() {
    return 'PersonalizedResponse(source: $source, keywords: $keywords, videos: $videos, playlists: $playlists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalizedResponseImpl &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords) &&
            const DeepCollectionEquality().equals(other._videos, _videos) &&
            const DeepCollectionEquality().equals(
              other._playlists,
              _playlists,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    source,
    const DeepCollectionEquality().hash(_keywords),
    const DeepCollectionEquality().hash(_videos),
    const DeepCollectionEquality().hash(_playlists),
  );

  /// Create a copy of PersonalizedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalizedResponseImplCopyWith<_$PersonalizedResponseImpl>
  get copyWith =>
      __$$PersonalizedResponseImplCopyWithImpl<_$PersonalizedResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalizedResponseImplToJson(this);
  }
}

abstract class _PersonalizedResponse extends PersonalizedResponse {
  const factory _PersonalizedResponse({
    required final String source,
    final List<String> keywords,
    final List<Recommendation> videos,
    final List<BiliPlaylist> playlists,
  }) = _$PersonalizedResponseImpl;
  const _PersonalizedResponse._() : super._();

  factory _PersonalizedResponse.fromJson(Map<String, dynamic> json) =
      _$PersonalizedResponseImpl.fromJson;

  @override
  String get source;
  @override
  List<String> get keywords;
  @override
  List<Recommendation> get videos;
  @override
  List<BiliPlaylist> get playlists;

  /// Create a copy of PersonalizedResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalizedResponseImplCopyWith<_$PersonalizedResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
