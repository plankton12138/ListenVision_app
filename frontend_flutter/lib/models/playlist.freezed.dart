// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Playlist {

 String get id; String get userId; String get name; String? get description; String? get coverUrl; PlaylistType get type; SystemPlaylistType? get systemType; bool get isPublic; int get playCount; int get itemCount; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCopyWith<Playlist> get copyWith => _$PlaylistCopyWithImpl<Playlist>(this as Playlist, _$identity);

  /// Serializes this Playlist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Playlist&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.systemType, systemType) || other.systemType == systemType)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,coverUrl,type,systemType,isPublic,playCount,itemCount,createdAt,updatedAt);

@override
String toString() {
  return 'Playlist(id: $id, userId: $userId, name: $name, description: $description, coverUrl: $coverUrl, type: $type, systemType: $systemType, isPublic: $isPublic, playCount: $playCount, itemCount: $itemCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlaylistCopyWith<$Res>  {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) _then) = _$PlaylistCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, String? description, String? coverUrl, PlaylistType type, SystemPlaylistType? systemType, bool isPublic, int playCount, int itemCount, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PlaylistCopyWithImpl<$Res>
    implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._self, this._then);

  final Playlist _self;
  final $Res Function(Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? coverUrl = freezed,Object? type = null,Object? systemType = freezed,Object? isPublic = null,Object? playCount = null,Object? itemCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlaylistType,systemType: freezed == systemType ? _self.systemType : systemType // ignore: cast_nullable_to_non_nullable
as SystemPlaylistType?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Playlist].
extension PlaylistPatterns on Playlist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Playlist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Playlist value)  $default,){
final _that = this;
switch (_that) {
case _Playlist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Playlist value)?  $default,){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String? description,  String? coverUrl,  PlaylistType type,  SystemPlaylistType? systemType,  bool isPublic,  int playCount,  int itemCount,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.coverUrl,_that.type,_that.systemType,_that.isPublic,_that.playCount,_that.itemCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String? description,  String? coverUrl,  PlaylistType type,  SystemPlaylistType? systemType,  bool isPublic,  int playCount,  int itemCount,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Playlist():
return $default(_that.id,_that.userId,_that.name,_that.description,_that.coverUrl,_that.type,_that.systemType,_that.isPublic,_that.playCount,_that.itemCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  String? description,  String? coverUrl,  PlaylistType type,  SystemPlaylistType? systemType,  bool isPublic,  int playCount,  int itemCount,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.coverUrl,_that.type,_that.systemType,_that.isPublic,_that.playCount,_that.itemCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Playlist extends Playlist {
  const _Playlist({required this.id, required this.userId, required this.name, this.description, this.coverUrl, required this.type, this.systemType, this.isPublic = false, this.playCount = 0, this.itemCount = 0, this.createdAt, this.updatedAt}): super._();
  factory _Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  String? description;
@override final  String? coverUrl;
@override final  PlaylistType type;
@override final  SystemPlaylistType? systemType;
@override@JsonKey() final  bool isPublic;
@override@JsonKey() final  int playCount;
@override@JsonKey() final  int itemCount;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistCopyWith<_Playlist> get copyWith => __$PlaylistCopyWithImpl<_Playlist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Playlist&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.systemType, systemType) || other.systemType == systemType)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,coverUrl,type,systemType,isPublic,playCount,itemCount,createdAt,updatedAt);

@override
String toString() {
  return 'Playlist(id: $id, userId: $userId, name: $name, description: $description, coverUrl: $coverUrl, type: $type, systemType: $systemType, isPublic: $isPublic, playCount: $playCount, itemCount: $itemCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaylistCopyWith<$Res> implements $PlaylistCopyWith<$Res> {
  factory _$PlaylistCopyWith(_Playlist value, $Res Function(_Playlist) _then) = __$PlaylistCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, String? description, String? coverUrl, PlaylistType type, SystemPlaylistType? systemType, bool isPublic, int playCount, int itemCount, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PlaylistCopyWithImpl<$Res>
    implements _$PlaylistCopyWith<$Res> {
  __$PlaylistCopyWithImpl(this._self, this._then);

  final _Playlist _self;
  final $Res Function(_Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? coverUrl = freezed,Object? type = null,Object? systemType = freezed,Object? isPublic = null,Object? playCount = null,Object? itemCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Playlist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlaylistType,systemType: freezed == systemType ? _self.systemType : systemType // ignore: cast_nullable_to_non_nullable
as SystemPlaylistType?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlaylistItem {

 String? get id; String? get playlistId; String get bvid; int? get cid;// B站视频分P ID
 String? get title; String? get artist; String? get albumTitle; int? get duration; String? get coverUrl; String? get localPath; int get position; DateTime? get addedAt;
/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistItemCopyWith<PlaylistItem> get copyWith => _$PlaylistItemCopyWithImpl<PlaylistItem>(this as PlaylistItem, _$identity);

  /// Serializes this PlaylistItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.albumTitle, albumTitle) || other.albumTitle == albumTitle)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.position, position) || other.position == position)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,playlistId,bvid,cid,title,artist,albumTitle,duration,coverUrl,localPath,position,addedAt);

@override
String toString() {
  return 'PlaylistItem(id: $id, playlistId: $playlistId, bvid: $bvid, cid: $cid, title: $title, artist: $artist, albumTitle: $albumTitle, duration: $duration, coverUrl: $coverUrl, localPath: $localPath, position: $position, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $PlaylistItemCopyWith<$Res>  {
  factory $PlaylistItemCopyWith(PlaylistItem value, $Res Function(PlaylistItem) _then) = _$PlaylistItemCopyWithImpl;
@useResult
$Res call({
 String? id, String? playlistId, String bvid, int? cid, String? title, String? artist, String? albumTitle, int? duration, String? coverUrl, String? localPath, int position, DateTime? addedAt
});




}
/// @nodoc
class _$PlaylistItemCopyWithImpl<$Res>
    implements $PlaylistItemCopyWith<$Res> {
  _$PlaylistItemCopyWithImpl(this._self, this._then);

  final PlaylistItem _self;
  final $Res Function(PlaylistItem) _then;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? playlistId = freezed,Object? bvid = null,Object? cid = freezed,Object? title = freezed,Object? artist = freezed,Object? albumTitle = freezed,Object? duration = freezed,Object? coverUrl = freezed,Object? localPath = freezed,Object? position = null,Object? addedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,playlistId: freezed == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String?,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: freezed == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistItem].
extension PlaylistItemPatterns on PlaylistItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistItem value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? playlistId,  String bvid,  int? cid,  String? title,  String? artist,  String? albumTitle,  int? duration,  String? coverUrl,  String? localPath,  int position,  DateTime? addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
return $default(_that.id,_that.playlistId,_that.bvid,_that.cid,_that.title,_that.artist,_that.albumTitle,_that.duration,_that.coverUrl,_that.localPath,_that.position,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? playlistId,  String bvid,  int? cid,  String? title,  String? artist,  String? albumTitle,  int? duration,  String? coverUrl,  String? localPath,  int position,  DateTime? addedAt)  $default,) {final _that = this;
switch (_that) {
case _PlaylistItem():
return $default(_that.id,_that.playlistId,_that.bvid,_that.cid,_that.title,_that.artist,_that.albumTitle,_that.duration,_that.coverUrl,_that.localPath,_that.position,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? playlistId,  String bvid,  int? cid,  String? title,  String? artist,  String? albumTitle,  int? duration,  String? coverUrl,  String? localPath,  int position,  DateTime? addedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
return $default(_that.id,_that.playlistId,_that.bvid,_that.cid,_that.title,_that.artist,_that.albumTitle,_that.duration,_that.coverUrl,_that.localPath,_that.position,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistItem extends PlaylistItem {
  const _PlaylistItem({this.id, this.playlistId, required this.bvid, this.cid, this.title, this.artist, this.albumTitle, this.duration, this.coverUrl, this.localPath, required this.position, this.addedAt}): super._();
  factory _PlaylistItem.fromJson(Map<String, dynamic> json) => _$PlaylistItemFromJson(json);

@override final  String? id;
@override final  String? playlistId;
@override final  String bvid;
@override final  int? cid;
// B站视频分P ID
@override final  String? title;
@override final  String? artist;
@override final  String? albumTitle;
@override final  int? duration;
@override final  String? coverUrl;
@override final  String? localPath;
@override final  int position;
@override final  DateTime? addedAt;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistItemCopyWith<_PlaylistItem> get copyWith => __$PlaylistItemCopyWithImpl<_PlaylistItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.albumTitle, albumTitle) || other.albumTitle == albumTitle)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.position, position) || other.position == position)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,playlistId,bvid,cid,title,artist,albumTitle,duration,coverUrl,localPath,position,addedAt);

@override
String toString() {
  return 'PlaylistItem(id: $id, playlistId: $playlistId, bvid: $bvid, cid: $cid, title: $title, artist: $artist, albumTitle: $albumTitle, duration: $duration, coverUrl: $coverUrl, localPath: $localPath, position: $position, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaylistItemCopyWith<$Res> implements $PlaylistItemCopyWith<$Res> {
  factory _$PlaylistItemCopyWith(_PlaylistItem value, $Res Function(_PlaylistItem) _then) = __$PlaylistItemCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? playlistId, String bvid, int? cid, String? title, String? artist, String? albumTitle, int? duration, String? coverUrl, String? localPath, int position, DateTime? addedAt
});




}
/// @nodoc
class __$PlaylistItemCopyWithImpl<$Res>
    implements _$PlaylistItemCopyWith<$Res> {
  __$PlaylistItemCopyWithImpl(this._self, this._then);

  final _PlaylistItem _self;
  final $Res Function(_PlaylistItem) _then;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? playlistId = freezed,Object? bvid = null,Object? cid = freezed,Object? title = freezed,Object? artist = freezed,Object? albumTitle = freezed,Object? duration = freezed,Object? coverUrl = freezed,Object? localPath = freezed,Object? position = null,Object? addedAt = freezed,}) {
  return _then(_PlaylistItem(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,playlistId: freezed == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String?,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: freezed == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlaylistDetail {

 Playlist get playlist; List<PlaylistItem> get items;
/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailCopyWith<PlaylistDetail> get copyWith => _$PlaylistDetailCopyWithImpl<PlaylistDetail>(this as PlaylistDetail, _$identity);

  /// Serializes this PlaylistDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetail&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'PlaylistDetail(playlist: $playlist, items: $items)';
}


}

/// @nodoc
abstract mixin class $PlaylistDetailCopyWith<$Res>  {
  factory $PlaylistDetailCopyWith(PlaylistDetail value, $Res Function(PlaylistDetail) _then) = _$PlaylistDetailCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<PlaylistItem> items
});


$PlaylistCopyWith<$Res> get playlist;

}
/// @nodoc
class _$PlaylistDetailCopyWithImpl<$Res>
    implements $PlaylistDetailCopyWith<$Res> {
  _$PlaylistDetailCopyWithImpl(this._self, this._then);

  final PlaylistDetail _self;
  final $Res Function(PlaylistDetail) _then;

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playlist = null,Object? items = null,}) {
  return _then(_self.copyWith(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,
  ));
}
/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res> get playlist {
  
  return $PlaylistCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistDetail].
extension PlaylistDetailPatterns on PlaylistDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistDetail value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Playlist playlist,  List<PlaylistItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
return $default(_that.playlist,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Playlist playlist,  List<PlaylistItem> items)  $default,) {final _that = this;
switch (_that) {
case _PlaylistDetail():
return $default(_that.playlist,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Playlist playlist,  List<PlaylistItem> items)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
return $default(_that.playlist,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistDetail implements PlaylistDetail {
  const _PlaylistDetail({required this.playlist, final  List<PlaylistItem> items = const []}): _items = items;
  factory _PlaylistDetail.fromJson(Map<String, dynamic> json) => _$PlaylistDetailFromJson(json);

@override final  Playlist playlist;
 final  List<PlaylistItem> _items;
@override@JsonKey() List<PlaylistItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistDetailCopyWith<_PlaylistDetail> get copyWith => __$PlaylistDetailCopyWithImpl<_PlaylistDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistDetail&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'PlaylistDetail(playlist: $playlist, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PlaylistDetailCopyWith<$Res> implements $PlaylistDetailCopyWith<$Res> {
  factory _$PlaylistDetailCopyWith(_PlaylistDetail value, $Res Function(_PlaylistDetail) _then) = __$PlaylistDetailCopyWithImpl;
@override @useResult
$Res call({
 Playlist playlist, List<PlaylistItem> items
});


@override $PlaylistCopyWith<$Res> get playlist;

}
/// @nodoc
class __$PlaylistDetailCopyWithImpl<$Res>
    implements _$PlaylistDetailCopyWith<$Res> {
  __$PlaylistDetailCopyWithImpl(this._self, this._then);

  final _PlaylistDetail _self;
  final $Res Function(_PlaylistDetail) _then;

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? items = null,}) {
  return _then(_PlaylistDetail(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,
  ));
}

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res> get playlist {
  
  return $PlaylistCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}

// dart format on
