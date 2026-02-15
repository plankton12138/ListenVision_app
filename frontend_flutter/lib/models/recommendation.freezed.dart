// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recommendation {

 String get id; String get title; String? get description; String? get coverUrl; String? get duration; String? get artist; int? get playCount; String? get url; RecommendationType get type;
/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationCopyWith<Recommendation> get copyWith => _$RecommendationCopyWithImpl<Recommendation>(this as Recommendation, _$identity);

  /// Serializes this Recommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommendation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,coverUrl,duration,artist,playCount,url,type);

@override
String toString() {
  return 'Recommendation(id: $id, title: $title, description: $description, coverUrl: $coverUrl, duration: $duration, artist: $artist, playCount: $playCount, url: $url, type: $type)';
}


}

/// @nodoc
abstract mixin class $RecommendationCopyWith<$Res>  {
  factory $RecommendationCopyWith(Recommendation value, $Res Function(Recommendation) _then) = _$RecommendationCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String? coverUrl, String? duration, String? artist, int? playCount, String? url, RecommendationType type
});




}
/// @nodoc
class _$RecommendationCopyWithImpl<$Res>
    implements $RecommendationCopyWith<$Res> {
  _$RecommendationCopyWithImpl(this._self, this._then);

  final Recommendation _self;
  final $Res Function(Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? duration = freezed,Object? artist = freezed,Object? playCount = freezed,Object? url = freezed,Object? type = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RecommendationType,
  ));
}

}


/// Adds pattern-matching-related methods to [Recommendation].
extension RecommendationPatterns on Recommendation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommendation value)  $default,){
final _that = this;
switch (_that) {
case _Recommendation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommendation value)?  $default,){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? coverUrl,  String? duration,  String? artist,  int? playCount,  String? url,  RecommendationType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.duration,_that.artist,_that.playCount,_that.url,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? coverUrl,  String? duration,  String? artist,  int? playCount,  String? url,  RecommendationType type)  $default,) {final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.duration,_that.artist,_that.playCount,_that.url,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String? coverUrl,  String? duration,  String? artist,  int? playCount,  String? url,  RecommendationType type)?  $default,) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.duration,_that.artist,_that.playCount,_that.url,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recommendation extends Recommendation {
  const _Recommendation({required this.id, required this.title, this.description, this.coverUrl, this.duration, this.artist, this.playCount, this.url, this.type = RecommendationType.video}): super._();
  factory _Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  String? coverUrl;
@override final  String? duration;
@override final  String? artist;
@override final  int? playCount;
@override final  String? url;
@override@JsonKey() final  RecommendationType type;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationCopyWith<_Recommendation> get copyWith => __$RecommendationCopyWithImpl<_Recommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommendation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,coverUrl,duration,artist,playCount,url,type);

@override
String toString() {
  return 'Recommendation(id: $id, title: $title, description: $description, coverUrl: $coverUrl, duration: $duration, artist: $artist, playCount: $playCount, url: $url, type: $type)';
}


}

/// @nodoc
abstract mixin class _$RecommendationCopyWith<$Res> implements $RecommendationCopyWith<$Res> {
  factory _$RecommendationCopyWith(_Recommendation value, $Res Function(_Recommendation) _then) = __$RecommendationCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String? coverUrl, String? duration, String? artist, int? playCount, String? url, RecommendationType type
});




}
/// @nodoc
class __$RecommendationCopyWithImpl<$Res>
    implements _$RecommendationCopyWith<$Res> {
  __$RecommendationCopyWithImpl(this._self, this._then);

  final _Recommendation _self;
  final $Res Function(_Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? duration = freezed,Object? artist = freezed,Object? playCount = freezed,Object? url = freezed,Object? type = null,}) {
  return _then(_Recommendation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RecommendationType,
  ));
}


}


/// @nodoc
mixin _$BiliPlaylist {

 int get menuId; int? get uid; String? get uploader; String get title; String? get coverUrl; String? get intro; int? get type; int get songCount; BiliPlaylistStats get stats; List<BiliAudioPreview> get previews;
/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiliPlaylistCopyWith<BiliPlaylist> get copyWith => _$BiliPlaylistCopyWithImpl<BiliPlaylist>(this as BiliPlaylist, _$identity);

  /// Serializes this BiliPlaylist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiliPlaylist&&(identical(other.menuId, menuId) || other.menuId == menuId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.intro, intro) || other.intro == intro)&&(identical(other.type, type) || other.type == type)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other.previews, previews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuId,uid,uploader,title,coverUrl,intro,type,songCount,stats,const DeepCollectionEquality().hash(previews));

@override
String toString() {
  return 'BiliPlaylist(menuId: $menuId, uid: $uid, uploader: $uploader, title: $title, coverUrl: $coverUrl, intro: $intro, type: $type, songCount: $songCount, stats: $stats, previews: $previews)';
}


}

/// @nodoc
abstract mixin class $BiliPlaylistCopyWith<$Res>  {
  factory $BiliPlaylistCopyWith(BiliPlaylist value, $Res Function(BiliPlaylist) _then) = _$BiliPlaylistCopyWithImpl;
@useResult
$Res call({
 int menuId, int? uid, String? uploader, String title, String? coverUrl, String? intro, int? type, int songCount, BiliPlaylistStats stats, List<BiliAudioPreview> previews
});


$BiliPlaylistStatsCopyWith<$Res> get stats;

}
/// @nodoc
class _$BiliPlaylistCopyWithImpl<$Res>
    implements $BiliPlaylistCopyWith<$Res> {
  _$BiliPlaylistCopyWithImpl(this._self, this._then);

  final BiliPlaylist _self;
  final $Res Function(BiliPlaylist) _then;

/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menuId = null,Object? uid = freezed,Object? uploader = freezed,Object? title = null,Object? coverUrl = freezed,Object? intro = freezed,Object? type = freezed,Object? songCount = null,Object? stats = null,Object? previews = null,}) {
  return _then(_self.copyWith(
menuId: null == menuId ? _self.menuId : menuId // ignore: cast_nullable_to_non_nullable
as int,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as BiliPlaylistStats,previews: null == previews ? _self.previews : previews // ignore: cast_nullable_to_non_nullable
as List<BiliAudioPreview>,
  ));
}
/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiliPlaylistStatsCopyWith<$Res> get stats {
  
  return $BiliPlaylistStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}


/// Adds pattern-matching-related methods to [BiliPlaylist].
extension BiliPlaylistPatterns on BiliPlaylist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiliPlaylist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiliPlaylist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiliPlaylist value)  $default,){
final _that = this;
switch (_that) {
case _BiliPlaylist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiliPlaylist value)?  $default,){
final _that = this;
switch (_that) {
case _BiliPlaylist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int menuId,  int? uid,  String? uploader,  String title,  String? coverUrl,  String? intro,  int? type,  int songCount,  BiliPlaylistStats stats,  List<BiliAudioPreview> previews)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiliPlaylist() when $default != null:
return $default(_that.menuId,_that.uid,_that.uploader,_that.title,_that.coverUrl,_that.intro,_that.type,_that.songCount,_that.stats,_that.previews);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int menuId,  int? uid,  String? uploader,  String title,  String? coverUrl,  String? intro,  int? type,  int songCount,  BiliPlaylistStats stats,  List<BiliAudioPreview> previews)  $default,) {final _that = this;
switch (_that) {
case _BiliPlaylist():
return $default(_that.menuId,_that.uid,_that.uploader,_that.title,_that.coverUrl,_that.intro,_that.type,_that.songCount,_that.stats,_that.previews);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int menuId,  int? uid,  String? uploader,  String title,  String? coverUrl,  String? intro,  int? type,  int songCount,  BiliPlaylistStats stats,  List<BiliAudioPreview> previews)?  $default,) {final _that = this;
switch (_that) {
case _BiliPlaylist() when $default != null:
return $default(_that.menuId,_that.uid,_that.uploader,_that.title,_that.coverUrl,_that.intro,_that.type,_that.songCount,_that.stats,_that.previews);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BiliPlaylist extends BiliPlaylist {
  const _BiliPlaylist({required this.menuId, this.uid, this.uploader, required this.title, this.coverUrl, this.intro, this.type, this.songCount = 0, required this.stats, final  List<BiliAudioPreview> previews = const []}): _previews = previews,super._();
  factory _BiliPlaylist.fromJson(Map<String, dynamic> json) => _$BiliPlaylistFromJson(json);

@override final  int menuId;
@override final  int? uid;
@override final  String? uploader;
@override final  String title;
@override final  String? coverUrl;
@override final  String? intro;
@override final  int? type;
@override@JsonKey() final  int songCount;
@override final  BiliPlaylistStats stats;
 final  List<BiliAudioPreview> _previews;
@override@JsonKey() List<BiliAudioPreview> get previews {
  if (_previews is EqualUnmodifiableListView) return _previews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_previews);
}


/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiliPlaylistCopyWith<_BiliPlaylist> get copyWith => __$BiliPlaylistCopyWithImpl<_BiliPlaylist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BiliPlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiliPlaylist&&(identical(other.menuId, menuId) || other.menuId == menuId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.intro, intro) || other.intro == intro)&&(identical(other.type, type) || other.type == type)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other._previews, _previews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuId,uid,uploader,title,coverUrl,intro,type,songCount,stats,const DeepCollectionEquality().hash(_previews));

@override
String toString() {
  return 'BiliPlaylist(menuId: $menuId, uid: $uid, uploader: $uploader, title: $title, coverUrl: $coverUrl, intro: $intro, type: $type, songCount: $songCount, stats: $stats, previews: $previews)';
}


}

/// @nodoc
abstract mixin class _$BiliPlaylistCopyWith<$Res> implements $BiliPlaylistCopyWith<$Res> {
  factory _$BiliPlaylistCopyWith(_BiliPlaylist value, $Res Function(_BiliPlaylist) _then) = __$BiliPlaylistCopyWithImpl;
@override @useResult
$Res call({
 int menuId, int? uid, String? uploader, String title, String? coverUrl, String? intro, int? type, int songCount, BiliPlaylistStats stats, List<BiliAudioPreview> previews
});


@override $BiliPlaylistStatsCopyWith<$Res> get stats;

}
/// @nodoc
class __$BiliPlaylistCopyWithImpl<$Res>
    implements _$BiliPlaylistCopyWith<$Res> {
  __$BiliPlaylistCopyWithImpl(this._self, this._then);

  final _BiliPlaylist _self;
  final $Res Function(_BiliPlaylist) _then;

/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menuId = null,Object? uid = freezed,Object? uploader = freezed,Object? title = null,Object? coverUrl = freezed,Object? intro = freezed,Object? type = freezed,Object? songCount = null,Object? stats = null,Object? previews = null,}) {
  return _then(_BiliPlaylist(
menuId: null == menuId ? _self.menuId : menuId // ignore: cast_nullable_to_non_nullable
as int,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as BiliPlaylistStats,previews: null == previews ? _self._previews : previews // ignore: cast_nullable_to_non_nullable
as List<BiliAudioPreview>,
  ));
}

/// Create a copy of BiliPlaylist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiliPlaylistStatsCopyWith<$Res> get stats {
  
  return $BiliPlaylistStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}


/// @nodoc
mixin _$BiliPlaylistStats {

 int get play; int get collect; int get comment;
/// Create a copy of BiliPlaylistStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiliPlaylistStatsCopyWith<BiliPlaylistStats> get copyWith => _$BiliPlaylistStatsCopyWithImpl<BiliPlaylistStats>(this as BiliPlaylistStats, _$identity);

  /// Serializes this BiliPlaylistStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiliPlaylistStats&&(identical(other.play, play) || other.play == play)&&(identical(other.collect, collect) || other.collect == collect)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,play,collect,comment);

@override
String toString() {
  return 'BiliPlaylistStats(play: $play, collect: $collect, comment: $comment)';
}


}

/// @nodoc
abstract mixin class $BiliPlaylistStatsCopyWith<$Res>  {
  factory $BiliPlaylistStatsCopyWith(BiliPlaylistStats value, $Res Function(BiliPlaylistStats) _then) = _$BiliPlaylistStatsCopyWithImpl;
@useResult
$Res call({
 int play, int collect, int comment
});




}
/// @nodoc
class _$BiliPlaylistStatsCopyWithImpl<$Res>
    implements $BiliPlaylistStatsCopyWith<$Res> {
  _$BiliPlaylistStatsCopyWithImpl(this._self, this._then);

  final BiliPlaylistStats _self;
  final $Res Function(BiliPlaylistStats) _then;

/// Create a copy of BiliPlaylistStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? play = null,Object? collect = null,Object? comment = null,}) {
  return _then(_self.copyWith(
play: null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as int,collect: null == collect ? _self.collect : collect // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BiliPlaylistStats].
extension BiliPlaylistStatsPatterns on BiliPlaylistStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiliPlaylistStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiliPlaylistStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiliPlaylistStats value)  $default,){
final _that = this;
switch (_that) {
case _BiliPlaylistStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiliPlaylistStats value)?  $default,){
final _that = this;
switch (_that) {
case _BiliPlaylistStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int play,  int collect,  int comment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiliPlaylistStats() when $default != null:
return $default(_that.play,_that.collect,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int play,  int collect,  int comment)  $default,) {final _that = this;
switch (_that) {
case _BiliPlaylistStats():
return $default(_that.play,_that.collect,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int play,  int collect,  int comment)?  $default,) {final _that = this;
switch (_that) {
case _BiliPlaylistStats() when $default != null:
return $default(_that.play,_that.collect,_that.comment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BiliPlaylistStats implements BiliPlaylistStats {
  const _BiliPlaylistStats({this.play = 0, this.collect = 0, this.comment = 0});
  factory _BiliPlaylistStats.fromJson(Map<String, dynamic> json) => _$BiliPlaylistStatsFromJson(json);

@override@JsonKey() final  int play;
@override@JsonKey() final  int collect;
@override@JsonKey() final  int comment;

/// Create a copy of BiliPlaylistStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiliPlaylistStatsCopyWith<_BiliPlaylistStats> get copyWith => __$BiliPlaylistStatsCopyWithImpl<_BiliPlaylistStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BiliPlaylistStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiliPlaylistStats&&(identical(other.play, play) || other.play == play)&&(identical(other.collect, collect) || other.collect == collect)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,play,collect,comment);

@override
String toString() {
  return 'BiliPlaylistStats(play: $play, collect: $collect, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$BiliPlaylistStatsCopyWith<$Res> implements $BiliPlaylistStatsCopyWith<$Res> {
  factory _$BiliPlaylistStatsCopyWith(_BiliPlaylistStats value, $Res Function(_BiliPlaylistStats) _then) = __$BiliPlaylistStatsCopyWithImpl;
@override @useResult
$Res call({
 int play, int collect, int comment
});




}
/// @nodoc
class __$BiliPlaylistStatsCopyWithImpl<$Res>
    implements _$BiliPlaylistStatsCopyWith<$Res> {
  __$BiliPlaylistStatsCopyWithImpl(this._self, this._then);

  final _BiliPlaylistStats _self;
  final $Res Function(_BiliPlaylistStats) _then;

/// Create a copy of BiliPlaylistStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? play = null,Object? collect = null,Object? comment = null,}) {
  return _then(_BiliPlaylistStats(
play: null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as int,collect: null == collect ? _self.collect : collect // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BiliAudioPreview {

 int get id; String get title; int? get duration; String? get coverUrl;
/// Create a copy of BiliAudioPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiliAudioPreviewCopyWith<BiliAudioPreview> get copyWith => _$BiliAudioPreviewCopyWithImpl<BiliAudioPreview>(this as BiliAudioPreview, _$identity);

  /// Serializes this BiliAudioPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiliAudioPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,duration,coverUrl);

@override
String toString() {
  return 'BiliAudioPreview(id: $id, title: $title, duration: $duration, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $BiliAudioPreviewCopyWith<$Res>  {
  factory $BiliAudioPreviewCopyWith(BiliAudioPreview value, $Res Function(BiliAudioPreview) _then) = _$BiliAudioPreviewCopyWithImpl;
@useResult
$Res call({
 int id, String title, int? duration, String? coverUrl
});




}
/// @nodoc
class _$BiliAudioPreviewCopyWithImpl<$Res>
    implements $BiliAudioPreviewCopyWith<$Res> {
  _$BiliAudioPreviewCopyWithImpl(this._self, this._then);

  final BiliAudioPreview _self;
  final $Res Function(BiliAudioPreview) _then;

/// Create a copy of BiliAudioPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? duration = freezed,Object? coverUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BiliAudioPreview].
extension BiliAudioPreviewPatterns on BiliAudioPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiliAudioPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiliAudioPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiliAudioPreview value)  $default,){
final _that = this;
switch (_that) {
case _BiliAudioPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiliAudioPreview value)?  $default,){
final _that = this;
switch (_that) {
case _BiliAudioPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  int? duration,  String? coverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiliAudioPreview() when $default != null:
return $default(_that.id,_that.title,_that.duration,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  int? duration,  String? coverUrl)  $default,) {final _that = this;
switch (_that) {
case _BiliAudioPreview():
return $default(_that.id,_that.title,_that.duration,_that.coverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  int? duration,  String? coverUrl)?  $default,) {final _that = this;
switch (_that) {
case _BiliAudioPreview() when $default != null:
return $default(_that.id,_that.title,_that.duration,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BiliAudioPreview extends BiliAudioPreview {
  const _BiliAudioPreview({required this.id, required this.title, this.duration, this.coverUrl}): super._();
  factory _BiliAudioPreview.fromJson(Map<String, dynamic> json) => _$BiliAudioPreviewFromJson(json);

@override final  int id;
@override final  String title;
@override final  int? duration;
@override final  String? coverUrl;

/// Create a copy of BiliAudioPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiliAudioPreviewCopyWith<_BiliAudioPreview> get copyWith => __$BiliAudioPreviewCopyWithImpl<_BiliAudioPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BiliAudioPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiliAudioPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,duration,coverUrl);

@override
String toString() {
  return 'BiliAudioPreview(id: $id, title: $title, duration: $duration, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class _$BiliAudioPreviewCopyWith<$Res> implements $BiliAudioPreviewCopyWith<$Res> {
  factory _$BiliAudioPreviewCopyWith(_BiliAudioPreview value, $Res Function(_BiliAudioPreview) _then) = __$BiliAudioPreviewCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, int? duration, String? coverUrl
});




}
/// @nodoc
class __$BiliAudioPreviewCopyWithImpl<$Res>
    implements _$BiliAudioPreviewCopyWith<$Res> {
  __$BiliAudioPreviewCopyWithImpl(this._self, this._then);

  final _BiliAudioPreview _self;
  final $Res Function(_BiliAudioPreview) _then;

/// Create a copy of BiliAudioPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? duration = freezed,Object? coverUrl = freezed,}) {
  return _then(_BiliAudioPreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RecommendationResponse {

 List<Recommendation> get items; int get page; int get pageSize; int get total; String? get source;
/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationResponseCopyWith<RecommendationResponse> get copyWith => _$RecommendationResponseCopyWithImpl<RecommendationResponse>(this as RecommendationResponse, _$identity);

  /// Serializes this RecommendationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,total,source);

@override
String toString() {
  return 'RecommendationResponse(items: $items, page: $page, pageSize: $pageSize, total: $total, source: $source)';
}


}

/// @nodoc
abstract mixin class $RecommendationResponseCopyWith<$Res>  {
  factory $RecommendationResponseCopyWith(RecommendationResponse value, $Res Function(RecommendationResponse) _then) = _$RecommendationResponseCopyWithImpl;
@useResult
$Res call({
 List<Recommendation> items, int page, int pageSize, int total, String? source
});




}
/// @nodoc
class _$RecommendationResponseCopyWithImpl<$Res>
    implements $RecommendationResponseCopyWith<$Res> {
  _$RecommendationResponseCopyWithImpl(this._self, this._then);

  final RecommendationResponse _self;
  final $Res Function(RecommendationResponse) _then;

/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? source = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendationResponse].
extension RecommendationResponsePatterns on RecommendationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendationResponse value)  $default,){
final _that = this;
switch (_that) {
case _RecommendationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Recommendation> items,  int page,  int pageSize,  int total,  String? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Recommendation> items,  int page,  int pageSize,  int total,  String? source)  $default,) {final _that = this;
switch (_that) {
case _RecommendationResponse():
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Recommendation> items,  int page,  int pageSize,  int total,  String? source)?  $default,) {final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendationResponse extends RecommendationResponse {
  const _RecommendationResponse({final  List<Recommendation> items = const [], this.page = 1, this.pageSize = 20, this.total = 0, this.source}): _items = items,super._();
  factory _RecommendationResponse.fromJson(Map<String, dynamic> json) => _$RecommendationResponseFromJson(json);

 final  List<Recommendation> _items;
@override@JsonKey() List<Recommendation> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int total;
@override final  String? source;

/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationResponseCopyWith<_RecommendationResponse> get copyWith => __$RecommendationResponseCopyWithImpl<_RecommendationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,total,source);

@override
String toString() {
  return 'RecommendationResponse(items: $items, page: $page, pageSize: $pageSize, total: $total, source: $source)';
}


}

/// @nodoc
abstract mixin class _$RecommendationResponseCopyWith<$Res> implements $RecommendationResponseCopyWith<$Res> {
  factory _$RecommendationResponseCopyWith(_RecommendationResponse value, $Res Function(_RecommendationResponse) _then) = __$RecommendationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<Recommendation> items, int page, int pageSize, int total, String? source
});




}
/// @nodoc
class __$RecommendationResponseCopyWithImpl<$Res>
    implements _$RecommendationResponseCopyWith<$Res> {
  __$RecommendationResponseCopyWithImpl(this._self, this._then);

  final _RecommendationResponse _self;
  final $Res Function(_RecommendationResponse) _then;

/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? source = freezed,}) {
  return _then(_RecommendationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PersonalizedResponse {

 String get source; List<String> get keywords; List<Recommendation> get videos; List<BiliPlaylist> get playlists;
/// Create a copy of PersonalizedResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalizedResponseCopyWith<PersonalizedResponse> get copyWith => _$PersonalizedResponseCopyWithImpl<PersonalizedResponse>(this as PersonalizedResponse, _$identity);

  /// Serializes this PersonalizedResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalizedResponse&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&const DeepCollectionEquality().equals(other.videos, videos)&&const DeepCollectionEquality().equals(other.playlists, playlists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,const DeepCollectionEquality().hash(keywords),const DeepCollectionEquality().hash(videos),const DeepCollectionEquality().hash(playlists));

@override
String toString() {
  return 'PersonalizedResponse(source: $source, keywords: $keywords, videos: $videos, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PersonalizedResponseCopyWith<$Res>  {
  factory $PersonalizedResponseCopyWith(PersonalizedResponse value, $Res Function(PersonalizedResponse) _then) = _$PersonalizedResponseCopyWithImpl;
@useResult
$Res call({
 String source, List<String> keywords, List<Recommendation> videos, List<BiliPlaylist> playlists
});




}
/// @nodoc
class _$PersonalizedResponseCopyWithImpl<$Res>
    implements $PersonalizedResponseCopyWith<$Res> {
  _$PersonalizedResponseCopyWithImpl(this._self, this._then);

  final PersonalizedResponse _self;
  final $Res Function(PersonalizedResponse) _then;

/// Create a copy of PersonalizedResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? keywords = null,Object? videos = null,Object? playlists = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,playlists: null == playlists ? _self.playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<BiliPlaylist>,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalizedResponse].
extension PersonalizedResponsePatterns on PersonalizedResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalizedResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalizedResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalizedResponse value)  $default,){
final _that = this;
switch (_that) {
case _PersonalizedResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalizedResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalizedResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  List<String> keywords,  List<Recommendation> videos,  List<BiliPlaylist> playlists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalizedResponse() when $default != null:
return $default(_that.source,_that.keywords,_that.videos,_that.playlists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  List<String> keywords,  List<Recommendation> videos,  List<BiliPlaylist> playlists)  $default,) {final _that = this;
switch (_that) {
case _PersonalizedResponse():
return $default(_that.source,_that.keywords,_that.videos,_that.playlists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  List<String> keywords,  List<Recommendation> videos,  List<BiliPlaylist> playlists)?  $default,) {final _that = this;
switch (_that) {
case _PersonalizedResponse() when $default != null:
return $default(_that.source,_that.keywords,_that.videos,_that.playlists);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalizedResponse extends PersonalizedResponse {
  const _PersonalizedResponse({required this.source, final  List<String> keywords = const [], final  List<Recommendation> videos = const [], final  List<BiliPlaylist> playlists = const []}): _keywords = keywords,_videos = videos,_playlists = playlists,super._();
  factory _PersonalizedResponse.fromJson(Map<String, dynamic> json) => _$PersonalizedResponseFromJson(json);

@override final  String source;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

 final  List<Recommendation> _videos;
@override@JsonKey() List<Recommendation> get videos {
  if (_videos is EqualUnmodifiableListView) return _videos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videos);
}

 final  List<BiliPlaylist> _playlists;
@override@JsonKey() List<BiliPlaylist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PersonalizedResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalizedResponseCopyWith<_PersonalizedResponse> get copyWith => __$PersonalizedResponseCopyWithImpl<_PersonalizedResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalizedResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalizedResponse&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&const DeepCollectionEquality().equals(other._videos, _videos)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,const DeepCollectionEquality().hash(_keywords),const DeepCollectionEquality().hash(_videos),const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PersonalizedResponse(source: $source, keywords: $keywords, videos: $videos, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class _$PersonalizedResponseCopyWith<$Res> implements $PersonalizedResponseCopyWith<$Res> {
  factory _$PersonalizedResponseCopyWith(_PersonalizedResponse value, $Res Function(_PersonalizedResponse) _then) = __$PersonalizedResponseCopyWithImpl;
@override @useResult
$Res call({
 String source, List<String> keywords, List<Recommendation> videos, List<BiliPlaylist> playlists
});




}
/// @nodoc
class __$PersonalizedResponseCopyWithImpl<$Res>
    implements _$PersonalizedResponseCopyWith<$Res> {
  __$PersonalizedResponseCopyWithImpl(this._self, this._then);

  final _PersonalizedResponse _self;
  final $Res Function(_PersonalizedResponse) _then;

/// Create a copy of PersonalizedResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? keywords = null,Object? videos = null,Object? playlists = null,}) {
  return _then(_PersonalizedResponse(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,videos: null == videos ? _self._videos : videos // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<BiliPlaylist>,
  ));
}


}

// dart format on
