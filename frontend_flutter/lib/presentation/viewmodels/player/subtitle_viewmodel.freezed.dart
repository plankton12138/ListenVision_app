// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubtitleState {

 SubtitleData? get data;// 字幕数据
 SubtitleTrack? get activeTrack;// 当前激活的语言
 int get currentLineIndex;// 当前高亮行索引
 bool get isLoading; bool get isVisible;// 字幕面板是否展开
 String? get error;
/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleStateCopyWith<SubtitleState> get copyWith => _$SubtitleStateCopyWithImpl<SubtitleState>(this as SubtitleState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleState&&(identical(other.data, data) || other.data == data)&&(identical(other.activeTrack, activeTrack) || other.activeTrack == activeTrack)&&(identical(other.currentLineIndex, currentLineIndex) || other.currentLineIndex == currentLineIndex)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,data,activeTrack,currentLineIndex,isLoading,isVisible,error);

@override
String toString() {
  return 'SubtitleState(data: $data, activeTrack: $activeTrack, currentLineIndex: $currentLineIndex, isLoading: $isLoading, isVisible: $isVisible, error: $error)';
}


}

/// @nodoc
abstract mixin class $SubtitleStateCopyWith<$Res>  {
  factory $SubtitleStateCopyWith(SubtitleState value, $Res Function(SubtitleState) _then) = _$SubtitleStateCopyWithImpl;
@useResult
$Res call({
 SubtitleData? data, SubtitleTrack? activeTrack, int currentLineIndex, bool isLoading, bool isVisible, String? error
});


$SubtitleDataCopyWith<$Res>? get data;$SubtitleTrackCopyWith<$Res>? get activeTrack;

}
/// @nodoc
class _$SubtitleStateCopyWithImpl<$Res>
    implements $SubtitleStateCopyWith<$Res> {
  _$SubtitleStateCopyWithImpl(this._self, this._then);

  final SubtitleState _self;
  final $Res Function(SubtitleState) _then;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = freezed,Object? activeTrack = freezed,Object? currentLineIndex = null,Object? isLoading = null,Object? isVisible = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SubtitleData?,activeTrack: freezed == activeTrack ? _self.activeTrack : activeTrack // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,currentLineIndex: null == currentLineIndex ? _self.currentLineIndex : currentLineIndex // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $SubtitleDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get activeTrack {
    if (_self.activeTrack == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.activeTrack!, (value) {
    return _then(_self.copyWith(activeTrack: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubtitleState].
extension SubtitleStatePatterns on SubtitleState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleState value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleState value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubtitleData? data,  SubtitleTrack? activeTrack,  int currentLineIndex,  bool isLoading,  bool isVisible,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
return $default(_that.data,_that.activeTrack,_that.currentLineIndex,_that.isLoading,_that.isVisible,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubtitleData? data,  SubtitleTrack? activeTrack,  int currentLineIndex,  bool isLoading,  bool isVisible,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SubtitleState():
return $default(_that.data,_that.activeTrack,_that.currentLineIndex,_that.isLoading,_that.isVisible,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubtitleData? data,  SubtitleTrack? activeTrack,  int currentLineIndex,  bool isLoading,  bool isVisible,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
return $default(_that.data,_that.activeTrack,_that.currentLineIndex,_that.isLoading,_that.isVisible,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleState implements SubtitleState {
  const _SubtitleState({this.data = null, this.activeTrack = null, this.currentLineIndex = -1, this.isLoading = false, this.isVisible = false, this.error = null});
  

@override@JsonKey() final  SubtitleData? data;
// 字幕数据
@override@JsonKey() final  SubtitleTrack? activeTrack;
// 当前激活的语言
@override@JsonKey() final  int currentLineIndex;
// 当前高亮行索引
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isVisible;
// 字幕面板是否展开
@override@JsonKey() final  String? error;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleStateCopyWith<_SubtitleState> get copyWith => __$SubtitleStateCopyWithImpl<_SubtitleState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleState&&(identical(other.data, data) || other.data == data)&&(identical(other.activeTrack, activeTrack) || other.activeTrack == activeTrack)&&(identical(other.currentLineIndex, currentLineIndex) || other.currentLineIndex == currentLineIndex)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,data,activeTrack,currentLineIndex,isLoading,isVisible,error);

@override
String toString() {
  return 'SubtitleState(data: $data, activeTrack: $activeTrack, currentLineIndex: $currentLineIndex, isLoading: $isLoading, isVisible: $isVisible, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SubtitleStateCopyWith<$Res> implements $SubtitleStateCopyWith<$Res> {
  factory _$SubtitleStateCopyWith(_SubtitleState value, $Res Function(_SubtitleState) _then) = __$SubtitleStateCopyWithImpl;
@override @useResult
$Res call({
 SubtitleData? data, SubtitleTrack? activeTrack, int currentLineIndex, bool isLoading, bool isVisible, String? error
});


@override $SubtitleDataCopyWith<$Res>? get data;@override $SubtitleTrackCopyWith<$Res>? get activeTrack;

}
/// @nodoc
class __$SubtitleStateCopyWithImpl<$Res>
    implements _$SubtitleStateCopyWith<$Res> {
  __$SubtitleStateCopyWithImpl(this._self, this._then);

  final _SubtitleState _self;
  final $Res Function(_SubtitleState) _then;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = freezed,Object? activeTrack = freezed,Object? currentLineIndex = null,Object? isLoading = null,Object? isVisible = null,Object? error = freezed,}) {
  return _then(_SubtitleState(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SubtitleData?,activeTrack: freezed == activeTrack ? _self.activeTrack : activeTrack // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,currentLineIndex: null == currentLineIndex ? _self.currentLineIndex : currentLineIndex // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $SubtitleDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get activeTrack {
    if (_self.activeTrack == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.activeTrack!, (value) {
    return _then(_self.copyWith(activeTrack: value));
  });
}
}

// dart format on
