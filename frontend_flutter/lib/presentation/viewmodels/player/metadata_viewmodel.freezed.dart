// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metadata_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MetadataState {

/// 是否正在加载
 bool get isLoading;/// 已加载的本地音频元数据（文件路径 -> 元数据）
 Map<String, AudioMetadata> get localMetadata;/// 封面缓存（URL -> Uint8List）
 Map<String, Uint8List> get coverCache;/// 错误消息
 String? get errorMessage;
/// Create a copy of MetadataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MetadataStateCopyWith<MetadataState> get copyWith => _$MetadataStateCopyWithImpl<MetadataState>(this as MetadataState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MetadataState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.localMetadata, localMetadata)&&const DeepCollectionEquality().equals(other.coverCache, coverCache)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(localMetadata),const DeepCollectionEquality().hash(coverCache),errorMessage);

@override
String toString() {
  return 'MetadataState(isLoading: $isLoading, localMetadata: $localMetadata, coverCache: $coverCache, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $MetadataStateCopyWith<$Res>  {
  factory $MetadataStateCopyWith(MetadataState value, $Res Function(MetadataState) _then) = _$MetadataStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, Map<String, AudioMetadata> localMetadata, Map<String, Uint8List> coverCache, String? errorMessage
});




}
/// @nodoc
class _$MetadataStateCopyWithImpl<$Res>
    implements $MetadataStateCopyWith<$Res> {
  _$MetadataStateCopyWithImpl(this._self, this._then);

  final MetadataState _self;
  final $Res Function(MetadataState) _then;

/// Create a copy of MetadataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? localMetadata = null,Object? coverCache = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,localMetadata: null == localMetadata ? _self.localMetadata : localMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, AudioMetadata>,coverCache: null == coverCache ? _self.coverCache : coverCache // ignore: cast_nullable_to_non_nullable
as Map<String, Uint8List>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MetadataState].
extension MetadataStatePatterns on MetadataState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MetadataState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MetadataState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MetadataState value)  $default,){
final _that = this;
switch (_that) {
case _MetadataState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MetadataState value)?  $default,){
final _that = this;
switch (_that) {
case _MetadataState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  Map<String, AudioMetadata> localMetadata,  Map<String, Uint8List> coverCache,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MetadataState() when $default != null:
return $default(_that.isLoading,_that.localMetadata,_that.coverCache,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  Map<String, AudioMetadata> localMetadata,  Map<String, Uint8List> coverCache,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _MetadataState():
return $default(_that.isLoading,_that.localMetadata,_that.coverCache,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  Map<String, AudioMetadata> localMetadata,  Map<String, Uint8List> coverCache,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _MetadataState() when $default != null:
return $default(_that.isLoading,_that.localMetadata,_that.coverCache,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _MetadataState implements MetadataState {
  const _MetadataState({this.isLoading = false, final  Map<String, AudioMetadata> localMetadata = const {}, final  Map<String, Uint8List> coverCache = const {}, this.errorMessage}): _localMetadata = localMetadata,_coverCache = coverCache;
  

/// 是否正在加载
@override@JsonKey() final  bool isLoading;
/// 已加载的本地音频元数据（文件路径 -> 元数据）
 final  Map<String, AudioMetadata> _localMetadata;
/// 已加载的本地音频元数据（文件路径 -> 元数据）
@override@JsonKey() Map<String, AudioMetadata> get localMetadata {
  if (_localMetadata is EqualUnmodifiableMapView) return _localMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localMetadata);
}

/// 封面缓存（URL -> Uint8List）
 final  Map<String, Uint8List> _coverCache;
/// 封面缓存（URL -> Uint8List）
@override@JsonKey() Map<String, Uint8List> get coverCache {
  if (_coverCache is EqualUnmodifiableMapView) return _coverCache;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_coverCache);
}

/// 错误消息
@override final  String? errorMessage;

/// Create a copy of MetadataState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MetadataStateCopyWith<_MetadataState> get copyWith => __$MetadataStateCopyWithImpl<_MetadataState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MetadataState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._localMetadata, _localMetadata)&&const DeepCollectionEquality().equals(other._coverCache, _coverCache)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_localMetadata),const DeepCollectionEquality().hash(_coverCache),errorMessage);

@override
String toString() {
  return 'MetadataState(isLoading: $isLoading, localMetadata: $localMetadata, coverCache: $coverCache, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$MetadataStateCopyWith<$Res> implements $MetadataStateCopyWith<$Res> {
  factory _$MetadataStateCopyWith(_MetadataState value, $Res Function(_MetadataState) _then) = __$MetadataStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, Map<String, AudioMetadata> localMetadata, Map<String, Uint8List> coverCache, String? errorMessage
});




}
/// @nodoc
class __$MetadataStateCopyWithImpl<$Res>
    implements _$MetadataStateCopyWith<$Res> {
  __$MetadataStateCopyWithImpl(this._self, this._then);

  final _MetadataState _self;
  final $Res Function(_MetadataState) _then;

/// Create a copy of MetadataState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? localMetadata = null,Object? coverCache = null,Object? errorMessage = freezed,}) {
  return _then(_MetadataState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,localMetadata: null == localMetadata ? _self._localMetadata : localMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, AudioMetadata>,coverCache: null == coverCache ? _self._coverCache : coverCache // ignore: cast_nullable_to_non_nullable
as Map<String, Uint8List>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AudioMetadata {

 String get title; String get artist; String get album; Uint8List? get cover;
/// Create a copy of AudioMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioMetadataCopyWith<AudioMetadata> get copyWith => _$AudioMetadataCopyWithImpl<AudioMetadata>(this as AudioMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other.cover, cover));
}


@override
int get hashCode => Object.hash(runtimeType,title,artist,album,const DeepCollectionEquality().hash(cover));

@override
String toString() {
  return 'AudioMetadata(title: $title, artist: $artist, album: $album, cover: $cover)';
}


}

/// @nodoc
abstract mixin class $AudioMetadataCopyWith<$Res>  {
  factory $AudioMetadataCopyWith(AudioMetadata value, $Res Function(AudioMetadata) _then) = _$AudioMetadataCopyWithImpl;
@useResult
$Res call({
 String title, String artist, String album, Uint8List? cover
});




}
/// @nodoc
class _$AudioMetadataCopyWithImpl<$Res>
    implements $AudioMetadataCopyWith<$Res> {
  _$AudioMetadataCopyWithImpl(this._self, this._then);

  final AudioMetadata _self;
  final $Res Function(AudioMetadata) _then;

/// Create a copy of AudioMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? cover = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioMetadata].
extension AudioMetadataPatterns on AudioMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioMetadata value)  $default,){
final _that = this;
switch (_that) {
case _AudioMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _AudioMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  Uint8List? cover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioMetadata() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.cover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  Uint8List? cover)  $default,) {final _that = this;
switch (_that) {
case _AudioMetadata():
return $default(_that.title,_that.artist,_that.album,_that.cover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String artist,  String album,  Uint8List? cover)?  $default,) {final _that = this;
switch (_that) {
case _AudioMetadata() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.cover);case _:
  return null;

}
}

}

/// @nodoc


class _AudioMetadata implements AudioMetadata {
  const _AudioMetadata({required this.title, required this.artist, required this.album, this.cover});
  

@override final  String title;
@override final  String artist;
@override final  String album;
@override final  Uint8List? cover;

/// Create a copy of AudioMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioMetadataCopyWith<_AudioMetadata> get copyWith => __$AudioMetadataCopyWithImpl<_AudioMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other.cover, cover));
}


@override
int get hashCode => Object.hash(runtimeType,title,artist,album,const DeepCollectionEquality().hash(cover));

@override
String toString() {
  return 'AudioMetadata(title: $title, artist: $artist, album: $album, cover: $cover)';
}


}

/// @nodoc
abstract mixin class _$AudioMetadataCopyWith<$Res> implements $AudioMetadataCopyWith<$Res> {
  factory _$AudioMetadataCopyWith(_AudioMetadata value, $Res Function(_AudioMetadata) _then) = __$AudioMetadataCopyWithImpl;
@override @useResult
$Res call({
 String title, String artist, String album, Uint8List? cover
});




}
/// @nodoc
class __$AudioMetadataCopyWithImpl<$Res>
    implements _$AudioMetadataCopyWith<$Res> {
  __$AudioMetadataCopyWithImpl(this._self, this._then);

  final _AudioMetadata _self;
  final $Res Function(_AudioMetadata) _then;

/// Create a copy of AudioMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? cover = freezed,}) {
  return _then(_AudioMetadata(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
