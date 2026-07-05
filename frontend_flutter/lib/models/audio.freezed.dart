// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Audio {

 String get id;// BV号或 local_{hash}
 String get title; String? get artist; String? get album; String? get coverUrl; String? get streamUrl; int? get duration;// 秒
 String? get description; int? get playCount; String? get uploader; String? get uploaderMid; DateTime? get publishedAt; DateTime? get createdAt; DateTime? get updatedAt; String? get localPath;// 本地音频文件路径（仅本地音频使用）
 int? get cid;// B站视频分P ID
 int get videos;
/// Create a copy of Audio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioCopyWith<Audio> get copyWith => _$AudioCopyWithImpl<Audio>(this as Audio, _$identity);

  /// Serializes this Audio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Audio&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.description, description) || other.description == description)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.uploaderMid, uploaderMid) || other.uploaderMid == uploaderMid)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.videos, videos) || other.videos == videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,artist,album,coverUrl,streamUrl,duration,description,playCount,uploader,uploaderMid,publishedAt,createdAt,updatedAt,localPath,cid,videos);

@override
String toString() {
  return 'Audio(id: $id, title: $title, artist: $artist, album: $album, coverUrl: $coverUrl, streamUrl: $streamUrl, duration: $duration, description: $description, playCount: $playCount, uploader: $uploader, uploaderMid: $uploaderMid, publishedAt: $publishedAt, createdAt: $createdAt, updatedAt: $updatedAt, localPath: $localPath, cid: $cid, videos: $videos)';
}


}

/// @nodoc
abstract mixin class $AudioCopyWith<$Res>  {
  factory $AudioCopyWith(Audio value, $Res Function(Audio) _then) = _$AudioCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? artist, String? album, String? coverUrl, String? streamUrl, int? duration, String? description, int? playCount, String? uploader, String? uploaderMid, DateTime? publishedAt, DateTime? createdAt, DateTime? updatedAt, String? localPath, int? cid, int videos
});




}
/// @nodoc
class _$AudioCopyWithImpl<$Res>
    implements $AudioCopyWith<$Res> {
  _$AudioCopyWithImpl(this._self, this._then);

  final Audio _self;
  final $Res Function(Audio) _then;

/// Create a copy of Audio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artist = freezed,Object? album = freezed,Object? coverUrl = freezed,Object? streamUrl = freezed,Object? duration = freezed,Object? description = freezed,Object? playCount = freezed,Object? uploader = freezed,Object? uploaderMid = freezed,Object? publishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? localPath = freezed,Object? cid = freezed,Object? videos = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,streamUrl: freezed == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,uploaderMid: freezed == uploaderMid ? _self.uploaderMid : uploaderMid // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,cid: freezed == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int?,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Audio].
extension AudioPatterns on Audio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Audio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Audio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Audio value)  $default,){
final _that = this;
switch (_that) {
case _Audio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Audio value)?  $default,){
final _that = this;
switch (_that) {
case _Audio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? artist,  String? album,  String? coverUrl,  String? streamUrl,  int? duration,  String? description,  int? playCount,  String? uploader,  String? uploaderMid,  DateTime? publishedAt,  DateTime? createdAt,  DateTime? updatedAt,  String? localPath,  int? cid,  int videos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Audio() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.album,_that.coverUrl,_that.streamUrl,_that.duration,_that.description,_that.playCount,_that.uploader,_that.uploaderMid,_that.publishedAt,_that.createdAt,_that.updatedAt,_that.localPath,_that.cid,_that.videos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? artist,  String? album,  String? coverUrl,  String? streamUrl,  int? duration,  String? description,  int? playCount,  String? uploader,  String? uploaderMid,  DateTime? publishedAt,  DateTime? createdAt,  DateTime? updatedAt,  String? localPath,  int? cid,  int videos)  $default,) {final _that = this;
switch (_that) {
case _Audio():
return $default(_that.id,_that.title,_that.artist,_that.album,_that.coverUrl,_that.streamUrl,_that.duration,_that.description,_that.playCount,_that.uploader,_that.uploaderMid,_that.publishedAt,_that.createdAt,_that.updatedAt,_that.localPath,_that.cid,_that.videos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? artist,  String? album,  String? coverUrl,  String? streamUrl,  int? duration,  String? description,  int? playCount,  String? uploader,  String? uploaderMid,  DateTime? publishedAt,  DateTime? createdAt,  DateTime? updatedAt,  String? localPath,  int? cid,  int videos)?  $default,) {final _that = this;
switch (_that) {
case _Audio() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.album,_that.coverUrl,_that.streamUrl,_that.duration,_that.description,_that.playCount,_that.uploader,_that.uploaderMid,_that.publishedAt,_that.createdAt,_that.updatedAt,_that.localPath,_that.cid,_that.videos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Audio extends Audio {
  const _Audio({required this.id, required this.title, this.artist, this.album, this.coverUrl, this.streamUrl, this.duration, this.description, this.playCount, this.uploader, this.uploaderMid, this.publishedAt, this.createdAt, this.updatedAt, this.localPath, this.cid, this.videos = 1}): super._();
  factory _Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);

@override final  String id;
// BV号或 local_{hash}
@override final  String title;
@override final  String? artist;
@override final  String? album;
@override final  String? coverUrl;
@override final  String? streamUrl;
@override final  int? duration;
// 秒
@override final  String? description;
@override final  int? playCount;
@override final  String? uploader;
@override final  String? uploaderMid;
@override final  DateTime? publishedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? localPath;
// 本地音频文件路径（仅本地音频使用）
@override final  int? cid;
// B站视频分P ID
@override@JsonKey() final  int videos;

/// Create a copy of Audio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioCopyWith<_Audio> get copyWith => __$AudioCopyWithImpl<_Audio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Audio&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.description, description) || other.description == description)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.uploaderMid, uploaderMid) || other.uploaderMid == uploaderMid)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.videos, videos) || other.videos == videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,artist,album,coverUrl,streamUrl,duration,description,playCount,uploader,uploaderMid,publishedAt,createdAt,updatedAt,localPath,cid,videos);

@override
String toString() {
  return 'Audio(id: $id, title: $title, artist: $artist, album: $album, coverUrl: $coverUrl, streamUrl: $streamUrl, duration: $duration, description: $description, playCount: $playCount, uploader: $uploader, uploaderMid: $uploaderMid, publishedAt: $publishedAt, createdAt: $createdAt, updatedAt: $updatedAt, localPath: $localPath, cid: $cid, videos: $videos)';
}


}

/// @nodoc
abstract mixin class _$AudioCopyWith<$Res> implements $AudioCopyWith<$Res> {
  factory _$AudioCopyWith(_Audio value, $Res Function(_Audio) _then) = __$AudioCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? artist, String? album, String? coverUrl, String? streamUrl, int? duration, String? description, int? playCount, String? uploader, String? uploaderMid, DateTime? publishedAt, DateTime? createdAt, DateTime? updatedAt, String? localPath, int? cid, int videos
});




}
/// @nodoc
class __$AudioCopyWithImpl<$Res>
    implements _$AudioCopyWith<$Res> {
  __$AudioCopyWithImpl(this._self, this._then);

  final _Audio _self;
  final $Res Function(_Audio) _then;

/// Create a copy of Audio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artist = freezed,Object? album = freezed,Object? coverUrl = freezed,Object? streamUrl = freezed,Object? duration = freezed,Object? description = freezed,Object? playCount = freezed,Object? uploader = freezed,Object? uploaderMid = freezed,Object? publishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? localPath = freezed,Object? cid = freezed,Object? videos = null,}) {
  return _then(_Audio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,streamUrl: freezed == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,uploaderMid: freezed == uploaderMid ? _self.uploaderMid : uploaderMid // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,cid: freezed == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int?,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
