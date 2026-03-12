// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleLine {

 double get from;// 起始时间（秒）
 double get to;// 结束时间（秒）
 String get content;
/// Create a copy of SubtitleLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleLineCopyWith<SubtitleLine> get copyWith => _$SubtitleLineCopyWithImpl<SubtitleLine>(this as SubtitleLine, _$identity);

  /// Serializes this SubtitleLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleLine&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,content);

@override
String toString() {
  return 'SubtitleLine(from: $from, to: $to, content: $content)';
}


}

/// @nodoc
abstract mixin class $SubtitleLineCopyWith<$Res>  {
  factory $SubtitleLineCopyWith(SubtitleLine value, $Res Function(SubtitleLine) _then) = _$SubtitleLineCopyWithImpl;
@useResult
$Res call({
 double from, double to, String content
});




}
/// @nodoc
class _$SubtitleLineCopyWithImpl<$Res>
    implements $SubtitleLineCopyWith<$Res> {
  _$SubtitleLineCopyWithImpl(this._self, this._then);

  final SubtitleLine _self;
  final $Res Function(SubtitleLine) _then;

/// Create a copy of SubtitleLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? content = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as double,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as double,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleLine].
extension SubtitleLinePatterns on SubtitleLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleLine value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleLine value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double from,  double to,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleLine() when $default != null:
return $default(_that.from,_that.to,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double from,  double to,  String content)  $default,) {final _that = this;
switch (_that) {
case _SubtitleLine():
return $default(_that.from,_that.to,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double from,  double to,  String content)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleLine() when $default != null:
return $default(_that.from,_that.to,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleLine implements SubtitleLine {
  const _SubtitleLine({required this.from, required this.to, required this.content});
  factory _SubtitleLine.fromJson(Map<String, dynamic> json) => _$SubtitleLineFromJson(json);

@override final  double from;
// 起始时间（秒）
@override final  double to;
// 结束时间（秒）
@override final  String content;

/// Create a copy of SubtitleLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleLineCopyWith<_SubtitleLine> get copyWith => __$SubtitleLineCopyWithImpl<_SubtitleLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleLine&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,content);

@override
String toString() {
  return 'SubtitleLine(from: $from, to: $to, content: $content)';
}


}

/// @nodoc
abstract mixin class _$SubtitleLineCopyWith<$Res> implements $SubtitleLineCopyWith<$Res> {
  factory _$SubtitleLineCopyWith(_SubtitleLine value, $Res Function(_SubtitleLine) _then) = __$SubtitleLineCopyWithImpl;
@override @useResult
$Res call({
 double from, double to, String content
});




}
/// @nodoc
class __$SubtitleLineCopyWithImpl<$Res>
    implements _$SubtitleLineCopyWith<$Res> {
  __$SubtitleLineCopyWithImpl(this._self, this._then);

  final _SubtitleLine _self;
  final $Res Function(_SubtitleLine) _then;

/// Create a copy of SubtitleLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? content = null,}) {
  return _then(_SubtitleLine(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as double,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as double,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubtitleTrack {

 String get lan;// 语言代码 (zh-Hans, en-US)
@JsonKey(name: 'lan_doc') String get lanDoc;// 语言名称 (中文（简体）)
 List<SubtitleLine> get lines;
/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<SubtitleTrack> get copyWith => _$SubtitleTrackCopyWithImpl<SubtitleTrack>(this as SubtitleTrack, _$identity);

  /// Serializes this SubtitleTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrack&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.lanDoc, lanDoc) || other.lanDoc == lanDoc)&&const DeepCollectionEquality().equals(other.lines, lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lan,lanDoc,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'SubtitleTrack(lan: $lan, lanDoc: $lanDoc, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackCopyWith<$Res>  {
  factory $SubtitleTrackCopyWith(SubtitleTrack value, $Res Function(SubtitleTrack) _then) = _$SubtitleTrackCopyWithImpl;
@useResult
$Res call({
 String lan,@JsonKey(name: 'lan_doc') String lanDoc, List<SubtitleLine> lines
});




}
/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._self, this._then);

  final SubtitleTrack _self;
  final $Res Function(SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lan = null,Object? lanDoc = null,Object? lines = null,}) {
  return _then(_self.copyWith(
lan: null == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String,lanDoc: null == lanDoc ? _self.lanDoc : lanDoc // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<SubtitleLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrack].
extension SubtitleTrackPatterns on SubtitleTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrack value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrack value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc,  List<SubtitleLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.lan,_that.lanDoc,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc,  List<SubtitleLine> lines)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack():
return $default(_that.lan,_that.lanDoc,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc,  List<SubtitleLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.lan,_that.lanDoc,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleTrack implements SubtitleTrack {
  const _SubtitleTrack({required this.lan, @JsonKey(name: 'lan_doc') required this.lanDoc, required final  List<SubtitleLine> lines}): _lines = lines;
  factory _SubtitleTrack.fromJson(Map<String, dynamic> json) => _$SubtitleTrackFromJson(json);

@override final  String lan;
// 语言代码 (zh-Hans, en-US)
@override@JsonKey(name: 'lan_doc') final  String lanDoc;
// 语言名称 (中文（简体）)
 final  List<SubtitleLine> _lines;
// 语言名称 (中文（简体）)
@override List<SubtitleLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackCopyWith<_SubtitleTrack> get copyWith => __$SubtitleTrackCopyWithImpl<_SubtitleTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleTrackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrack&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.lanDoc, lanDoc) || other.lanDoc == lanDoc)&&const DeepCollectionEquality().equals(other._lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lan,lanDoc,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'SubtitleTrack(lan: $lan, lanDoc: $lanDoc, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackCopyWith<$Res> implements $SubtitleTrackCopyWith<$Res> {
  factory _$SubtitleTrackCopyWith(_SubtitleTrack value, $Res Function(_SubtitleTrack) _then) = __$SubtitleTrackCopyWithImpl;
@override @useResult
$Res call({
 String lan,@JsonKey(name: 'lan_doc') String lanDoc, List<SubtitleLine> lines
});




}
/// @nodoc
class __$SubtitleTrackCopyWithImpl<$Res>
    implements _$SubtitleTrackCopyWith<$Res> {
  __$SubtitleTrackCopyWithImpl(this._self, this._then);

  final _SubtitleTrack _self;
  final $Res Function(_SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lan = null,Object? lanDoc = null,Object? lines = null,}) {
  return _then(_SubtitleTrack(
lan: null == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String,lanDoc: null == lanDoc ? _self.lanDoc : lanDoc // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<SubtitleLine>,
  ));
}


}


/// @nodoc
mixin _$SubtitleData {

 String get bvid; int get cid; List<SubtitleTrack> get subtitles;
/// Create a copy of SubtitleData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleDataCopyWith<SubtitleData> get copyWith => _$SubtitleDataCopyWithImpl<SubtitleData>(this as SubtitleData, _$identity);

  /// Serializes this SubtitleData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleData&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&const DeepCollectionEquality().equals(other.subtitles, subtitles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,const DeepCollectionEquality().hash(subtitles));

@override
String toString() {
  return 'SubtitleData(bvid: $bvid, cid: $cid, subtitles: $subtitles)';
}


}

/// @nodoc
abstract mixin class $SubtitleDataCopyWith<$Res>  {
  factory $SubtitleDataCopyWith(SubtitleData value, $Res Function(SubtitleData) _then) = _$SubtitleDataCopyWithImpl;
@useResult
$Res call({
 String bvid, int cid, List<SubtitleTrack> subtitles
});




}
/// @nodoc
class _$SubtitleDataCopyWithImpl<$Res>
    implements $SubtitleDataCopyWith<$Res> {
  _$SubtitleDataCopyWithImpl(this._self, this._then);

  final SubtitleData _self;
  final $Res Function(SubtitleData) _then;

/// Create a copy of SubtitleData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bvid = null,Object? cid = null,Object? subtitles = null,}) {
  return _then(_self.copyWith(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,subtitles: null == subtitles ? _self.subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleData].
extension SubtitleDataPatterns on SubtitleData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleData value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleData value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bvid,  int cid,  List<SubtitleTrack> subtitles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleData() when $default != null:
return $default(_that.bvid,_that.cid,_that.subtitles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bvid,  int cid,  List<SubtitleTrack> subtitles)  $default,) {final _that = this;
switch (_that) {
case _SubtitleData():
return $default(_that.bvid,_that.cid,_that.subtitles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bvid,  int cid,  List<SubtitleTrack> subtitles)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleData() when $default != null:
return $default(_that.bvid,_that.cid,_that.subtitles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleData implements SubtitleData {
  const _SubtitleData({required this.bvid, required this.cid, required final  List<SubtitleTrack> subtitles}): _subtitles = subtitles;
  factory _SubtitleData.fromJson(Map<String, dynamic> json) => _$SubtitleDataFromJson(json);

@override final  String bvid;
@override final  int cid;
 final  List<SubtitleTrack> _subtitles;
@override List<SubtitleTrack> get subtitles {
  if (_subtitles is EqualUnmodifiableListView) return _subtitles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtitles);
}


/// Create a copy of SubtitleData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleDataCopyWith<_SubtitleData> get copyWith => __$SubtitleDataCopyWithImpl<_SubtitleData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleData&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&const DeepCollectionEquality().equals(other._subtitles, _subtitles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,const DeepCollectionEquality().hash(_subtitles));

@override
String toString() {
  return 'SubtitleData(bvid: $bvid, cid: $cid, subtitles: $subtitles)';
}


}

/// @nodoc
abstract mixin class _$SubtitleDataCopyWith<$Res> implements $SubtitleDataCopyWith<$Res> {
  factory _$SubtitleDataCopyWith(_SubtitleData value, $Res Function(_SubtitleData) _then) = __$SubtitleDataCopyWithImpl;
@override @useResult
$Res call({
 String bvid, int cid, List<SubtitleTrack> subtitles
});




}
/// @nodoc
class __$SubtitleDataCopyWithImpl<$Res>
    implements _$SubtitleDataCopyWith<$Res> {
  __$SubtitleDataCopyWithImpl(this._self, this._then);

  final _SubtitleData _self;
  final $Res Function(_SubtitleData) _then;

/// Create a copy of SubtitleData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? cid = null,Object? subtitles = null,}) {
  return _then(_SubtitleData(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,subtitles: null == subtitles ? _self._subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}


}

// dart format on
