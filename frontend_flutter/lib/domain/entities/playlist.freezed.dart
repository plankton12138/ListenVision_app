// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Playlist _$PlaylistFromJson(Map<String, dynamic> json) {
  return _Playlist.fromJson(json);
}

/// @nodoc
mixin _$Playlist {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  PlaylistType get type => throw _privateConstructorUsedError;
  SystemPlaylistType? get systemType => throw _privateConstructorUsedError;
  bool get isPublic => throw _privateConstructorUsedError;
  int get playCount => throw _privateConstructorUsedError;
  int get itemCount => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Playlist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistCopyWith<Playlist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistCopyWith<$Res> {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) then) =
      _$PlaylistCopyWithImpl<$Res, Playlist>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String? description,
    String? coverUrl,
    PlaylistType type,
    SystemPlaylistType? systemType,
    bool isPublic,
    int playCount,
    int itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$PlaylistCopyWithImpl<$Res, $Val extends Playlist>
    implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? description = freezed,
    Object? coverUrl = freezed,
    Object? type = null,
    Object? systemType = freezed,
    Object? isPublic = null,
    Object? playCount = null,
    Object? itemCount = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PlaylistType,
            systemType: freezed == systemType
                ? _value.systemType
                : systemType // ignore: cast_nullable_to_non_nullable
                      as SystemPlaylistType?,
            isPublic: null == isPublic
                ? _value.isPublic
                : isPublic // ignore: cast_nullable_to_non_nullable
                      as bool,
            playCount: null == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int,
            itemCount: null == itemCount
                ? _value.itemCount
                : itemCount // ignore: cast_nullable_to_non_nullable
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
}

/// @nodoc
abstract class _$$PlaylistImplCopyWith<$Res>
    implements $PlaylistCopyWith<$Res> {
  factory _$$PlaylistImplCopyWith(
    _$PlaylistImpl value,
    $Res Function(_$PlaylistImpl) then,
  ) = __$$PlaylistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String? description,
    String? coverUrl,
    PlaylistType type,
    SystemPlaylistType? systemType,
    bool isPublic,
    int playCount,
    int itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PlaylistImplCopyWithImpl<$Res>
    extends _$PlaylistCopyWithImpl<$Res, _$PlaylistImpl>
    implements _$$PlaylistImplCopyWith<$Res> {
  __$$PlaylistImplCopyWithImpl(
    _$PlaylistImpl _value,
    $Res Function(_$PlaylistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? description = freezed,
    Object? coverUrl = freezed,
    Object? type = null,
    Object? systemType = freezed,
    Object? isPublic = null,
    Object? playCount = null,
    Object? itemCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PlaylistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PlaylistType,
        systemType: freezed == systemType
            ? _value.systemType
            : systemType // ignore: cast_nullable_to_non_nullable
                  as SystemPlaylistType?,
        isPublic: null == isPublic
            ? _value.isPublic
            : isPublic // ignore: cast_nullable_to_non_nullable
                  as bool,
        playCount: null == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int,
        itemCount: null == itemCount
            ? _value.itemCount
            : itemCount // ignore: cast_nullable_to_non_nullable
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
class _$PlaylistImpl extends _Playlist {
  const _$PlaylistImpl({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    required this.type,
    this.systemType,
    this.isPublic = false,
    this.playCount = 0,
    this.itemCount = 0,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$PlaylistImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? coverUrl;
  @override
  final PlaylistType type;
  @override
  final SystemPlaylistType? systemType;
  @override
  @JsonKey()
  final bool isPublic;
  @override
  @JsonKey()
  final int playCount;
  @override
  @JsonKey()
  final int itemCount;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Playlist(id: $id, userId: $userId, name: $name, description: $description, coverUrl: $coverUrl, type: $type, systemType: $systemType, isPublic: $isPublic, playCount: $playCount, itemCount: $itemCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.systemType, systemType) ||
                other.systemType == systemType) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
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
    name,
    description,
    coverUrl,
    type,
    systemType,
    isPublic,
    playCount,
    itemCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistImplCopyWith<_$PlaylistImpl> get copyWith =>
      __$$PlaylistImplCopyWithImpl<_$PlaylistImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistImplToJson(this);
  }
}

abstract class _Playlist extends Playlist {
  const factory _Playlist({
    required final String id,
    required final String userId,
    required final String name,
    final String? description,
    final String? coverUrl,
    required final PlaylistType type,
    final SystemPlaylistType? systemType,
    final bool isPublic,
    final int playCount,
    final int itemCount,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$PlaylistImpl;
  const _Playlist._() : super._();

  factory _Playlist.fromJson(Map<String, dynamic> json) =
      _$PlaylistImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get coverUrl;
  @override
  PlaylistType get type;
  @override
  SystemPlaylistType? get systemType;
  @override
  bool get isPublic;
  @override
  int get playCount;
  @override
  int get itemCount;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistImplCopyWith<_$PlaylistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) {
  return _PlaylistItem.fromJson(json);
}

/// @nodoc
mixin _$PlaylistItem {
  String? get id => throw _privateConstructorUsedError;
  String? get playlistId => throw _privateConstructorUsedError;
  String get bvid => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get artist => throw _privateConstructorUsedError;
  int? get duration => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get localPath => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  DateTime? get addedAt => throw _privateConstructorUsedError;

  /// Serializes this PlaylistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistItemCopyWith<PlaylistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistItemCopyWith<$Res> {
  factory $PlaylistItemCopyWith(
    PlaylistItem value,
    $Res Function(PlaylistItem) then,
  ) = _$PlaylistItemCopyWithImpl<$Res, PlaylistItem>;
  @useResult
  $Res call({
    String? id,
    String? playlistId,
    String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
    int position,
    DateTime? addedAt,
  });
}

/// @nodoc
class _$PlaylistItemCopyWithImpl<$Res, $Val extends PlaylistItem>
    implements $PlaylistItemCopyWith<$Res> {
  _$PlaylistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? playlistId = freezed,
    Object? bvid = null,
    Object? title = freezed,
    Object? artist = freezed,
    Object? duration = freezed,
    Object? coverUrl = freezed,
    Object? localPath = freezed,
    Object? position = null,
    Object? addedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            playlistId: freezed == playlistId
                ? _value.playlistId
                : playlistId // ignore: cast_nullable_to_non_nullable
                      as String?,
            bvid: null == bvid
                ? _value.bvid
                : bvid // ignore: cast_nullable_to_non_nullable
                      as String,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            artist: freezed == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            localPath: freezed == localPath
                ? _value.localPath
                : localPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int,
            addedAt: freezed == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaylistItemImplCopyWith<$Res>
    implements $PlaylistItemCopyWith<$Res> {
  factory _$$PlaylistItemImplCopyWith(
    _$PlaylistItemImpl value,
    $Res Function(_$PlaylistItemImpl) then,
  ) = __$$PlaylistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String? playlistId,
    String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
    int position,
    DateTime? addedAt,
  });
}

/// @nodoc
class __$$PlaylistItemImplCopyWithImpl<$Res>
    extends _$PlaylistItemCopyWithImpl<$Res, _$PlaylistItemImpl>
    implements _$$PlaylistItemImplCopyWith<$Res> {
  __$$PlaylistItemImplCopyWithImpl(
    _$PlaylistItemImpl _value,
    $Res Function(_$PlaylistItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? playlistId = freezed,
    Object? bvid = null,
    Object? title = freezed,
    Object? artist = freezed,
    Object? duration = freezed,
    Object? coverUrl = freezed,
    Object? localPath = freezed,
    Object? position = null,
    Object? addedAt = freezed,
  }) {
    return _then(
      _$PlaylistItemImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        playlistId: freezed == playlistId
            ? _value.playlistId
            : playlistId // ignore: cast_nullable_to_non_nullable
                  as String?,
        bvid: null == bvid
            ? _value.bvid
            : bvid // ignore: cast_nullable_to_non_nullable
                  as String,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        artist: freezed == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        localPath: freezed == localPath
            ? _value.localPath
            : localPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        addedAt: freezed == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistItemImpl extends _PlaylistItem {
  const _$PlaylistItemImpl({
    this.id,
    this.playlistId,
    required this.bvid,
    this.title,
    this.artist,
    this.duration,
    this.coverUrl,
    this.localPath,
    required this.position,
    this.addedAt,
  }) : super._();

  factory _$PlaylistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistItemImplFromJson(json);

  @override
  final String? id;
  @override
  final String? playlistId;
  @override
  final String bvid;
  @override
  final String? title;
  @override
  final String? artist;
  @override
  final int? duration;
  @override
  final String? coverUrl;
  @override
  final String? localPath;
  @override
  final int position;
  @override
  final DateTime? addedAt;

  @override
  String toString() {
    return 'PlaylistItem(id: $id, playlistId: $playlistId, bvid: $bvid, title: $title, artist: $artist, duration: $duration, coverUrl: $coverUrl, localPath: $localPath, position: $position, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId) &&
            (identical(other.bvid, bvid) || other.bvid == bvid) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    playlistId,
    bvid,
    title,
    artist,
    duration,
    coverUrl,
    localPath,
    position,
    addedAt,
  );

  /// Create a copy of PlaylistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      __$$PlaylistItemImplCopyWithImpl<_$PlaylistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistItemImplToJson(this);
  }
}

abstract class _PlaylistItem extends PlaylistItem {
  const factory _PlaylistItem({
    final String? id,
    final String? playlistId,
    required final String bvid,
    final String? title,
    final String? artist,
    final int? duration,
    final String? coverUrl,
    final String? localPath,
    required final int position,
    final DateTime? addedAt,
  }) = _$PlaylistItemImpl;
  const _PlaylistItem._() : super._();

  factory _PlaylistItem.fromJson(Map<String, dynamic> json) =
      _$PlaylistItemImpl.fromJson;

  @override
  String? get id;
  @override
  String? get playlistId;
  @override
  String get bvid;
  @override
  String? get title;
  @override
  String? get artist;
  @override
  int? get duration;
  @override
  String? get coverUrl;
  @override
  String? get localPath;
  @override
  int get position;
  @override
  DateTime? get addedAt;

  /// Create a copy of PlaylistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistDetail _$PlaylistDetailFromJson(Map<String, dynamic> json) {
  return _PlaylistDetail.fromJson(json);
}

/// @nodoc
mixin _$PlaylistDetail {
  Playlist get playlist => throw _privateConstructorUsedError;
  List<PlaylistItem> get items => throw _privateConstructorUsedError;

  /// Serializes this PlaylistDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistDetailCopyWith<PlaylistDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistDetailCopyWith<$Res> {
  factory $PlaylistDetailCopyWith(
    PlaylistDetail value,
    $Res Function(PlaylistDetail) then,
  ) = _$PlaylistDetailCopyWithImpl<$Res, PlaylistDetail>;
  @useResult
  $Res call({Playlist playlist, List<PlaylistItem> items});

  $PlaylistCopyWith<$Res> get playlist;
}

/// @nodoc
class _$PlaylistDetailCopyWithImpl<$Res, $Val extends PlaylistDetail>
    implements $PlaylistDetailCopyWith<$Res> {
  _$PlaylistDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playlist = null, Object? items = null}) {
    return _then(
      _value.copyWith(
            playlist: null == playlist
                ? _value.playlist
                : playlist // ignore: cast_nullable_to_non_nullable
                      as Playlist,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<PlaylistItem>,
          )
          as $Val,
    );
  }

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res> get playlist {
    return $PlaylistCopyWith<$Res>(_value.playlist, (value) {
      return _then(_value.copyWith(playlist: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlaylistDetailImplCopyWith<$Res>
    implements $PlaylistDetailCopyWith<$Res> {
  factory _$$PlaylistDetailImplCopyWith(
    _$PlaylistDetailImpl value,
    $Res Function(_$PlaylistDetailImpl) then,
  ) = __$$PlaylistDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Playlist playlist, List<PlaylistItem> items});

  @override
  $PlaylistCopyWith<$Res> get playlist;
}

/// @nodoc
class __$$PlaylistDetailImplCopyWithImpl<$Res>
    extends _$PlaylistDetailCopyWithImpl<$Res, _$PlaylistDetailImpl>
    implements _$$PlaylistDetailImplCopyWith<$Res> {
  __$$PlaylistDetailImplCopyWithImpl(
    _$PlaylistDetailImpl _value,
    $Res Function(_$PlaylistDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playlist = null, Object? items = null}) {
    return _then(
      _$PlaylistDetailImpl(
        playlist: null == playlist
            ? _value.playlist
            : playlist // ignore: cast_nullable_to_non_nullable
                  as Playlist,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistDetailImpl implements _PlaylistDetail {
  const _$PlaylistDetailImpl({
    required this.playlist,
    final List<PlaylistItem> items = const [],
  }) : _items = items;

  factory _$PlaylistDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistDetailImplFromJson(json);

  @override
  final Playlist playlist;
  final List<PlaylistItem> _items;
  @override
  @JsonKey()
  List<PlaylistItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'PlaylistDetail(playlist: $playlist, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistDetailImpl &&
            (identical(other.playlist, playlist) ||
                other.playlist == playlist) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    playlist,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistDetailImplCopyWith<_$PlaylistDetailImpl> get copyWith =>
      __$$PlaylistDetailImplCopyWithImpl<_$PlaylistDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistDetailImplToJson(this);
  }
}

abstract class _PlaylistDetail implements PlaylistDetail {
  const factory _PlaylistDetail({
    required final Playlist playlist,
    final List<PlaylistItem> items,
  }) = _$PlaylistDetailImpl;

  factory _PlaylistDetail.fromJson(Map<String, dynamic> json) =
      _$PlaylistDetailImpl.fromJson;

  @override
  Playlist get playlist;
  @override
  List<PlaylistItem> get items;

  /// Create a copy of PlaylistDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistDetailImplCopyWith<_$PlaylistDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
