// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_music_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalMusicState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalMusicState()';
}


}

/// @nodoc
class $LocalMusicStateCopyWith<$Res>  {
$LocalMusicStateCopyWith(LocalMusicState _, $Res Function(LocalMusicState) __);
}


/// Adds pattern-matching-related methods to [LocalMusicState].
extension LocalMusicStatePatterns on LocalMusicState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocalMusicStateInitial value)?  initial,TResult Function( LocalMusicStateLoading value)?  loading,TResult Function( LocalMusicStateLoaded value)?  loaded,TResult Function( LocalMusicStateImporting value)?  importing,TResult Function( LocalMusicStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocalMusicStateInitial() when initial != null:
return initial(_that);case LocalMusicStateLoading() when loading != null:
return loading(_that);case LocalMusicStateLoaded() when loaded != null:
return loaded(_that);case LocalMusicStateImporting() when importing != null:
return importing(_that);case LocalMusicStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocalMusicStateInitial value)  initial,required TResult Function( LocalMusicStateLoading value)  loading,required TResult Function( LocalMusicStateLoaded value)  loaded,required TResult Function( LocalMusicStateImporting value)  importing,required TResult Function( LocalMusicStateError value)  error,}){
final _that = this;
switch (_that) {
case LocalMusicStateInitial():
return initial(_that);case LocalMusicStateLoading():
return loading(_that);case LocalMusicStateLoaded():
return loaded(_that);case LocalMusicStateImporting():
return importing(_that);case LocalMusicStateError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocalMusicStateInitial value)?  initial,TResult? Function( LocalMusicStateLoading value)?  loading,TResult? Function( LocalMusicStateLoaded value)?  loaded,TResult? Function( LocalMusicStateImporting value)?  importing,TResult? Function( LocalMusicStateError value)?  error,}){
final _that = this;
switch (_that) {
case LocalMusicStateInitial() when initial != null:
return initial(_that);case LocalMusicStateLoading() when loading != null:
return loading(_that);case LocalMusicStateLoaded() when loaded != null:
return loaded(_that);case LocalMusicStateImporting() when importing != null:
return importing(_that);case LocalMusicStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<LocalAudio> audios)?  loaded,TResult Function( int current,  int total,  String currentFile)?  importing,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocalMusicStateInitial() when initial != null:
return initial();case LocalMusicStateLoading() when loading != null:
return loading();case LocalMusicStateLoaded() when loaded != null:
return loaded(_that.audios);case LocalMusicStateImporting() when importing != null:
return importing(_that.current,_that.total,_that.currentFile);case LocalMusicStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<LocalAudio> audios)  loaded,required TResult Function( int current,  int total,  String currentFile)  importing,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case LocalMusicStateInitial():
return initial();case LocalMusicStateLoading():
return loading();case LocalMusicStateLoaded():
return loaded(_that.audios);case LocalMusicStateImporting():
return importing(_that.current,_that.total,_that.currentFile);case LocalMusicStateError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<LocalAudio> audios)?  loaded,TResult? Function( int current,  int total,  String currentFile)?  importing,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case LocalMusicStateInitial() when initial != null:
return initial();case LocalMusicStateLoading() when loading != null:
return loading();case LocalMusicStateLoaded() when loaded != null:
return loaded(_that.audios);case LocalMusicStateImporting() when importing != null:
return importing(_that.current,_that.total,_that.currentFile);case LocalMusicStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class LocalMusicStateInitial implements LocalMusicState {
  const LocalMusicStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalMusicState.initial()';
}


}




/// @nodoc


class LocalMusicStateLoading implements LocalMusicState {
  const LocalMusicStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalMusicState.loading()';
}


}




/// @nodoc


class LocalMusicStateLoaded implements LocalMusicState {
  const LocalMusicStateLoaded({required final  List<LocalAudio> audios}): _audios = audios;
  

 final  List<LocalAudio> _audios;
 List<LocalAudio> get audios {
  if (_audios is EqualUnmodifiableListView) return _audios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audios);
}


/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalMusicStateLoadedCopyWith<LocalMusicStateLoaded> get copyWith => _$LocalMusicStateLoadedCopyWithImpl<LocalMusicStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicStateLoaded&&const DeepCollectionEquality().equals(other._audios, _audios));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_audios));

@override
String toString() {
  return 'LocalMusicState.loaded(audios: $audios)';
}


}

/// @nodoc
abstract mixin class $LocalMusicStateLoadedCopyWith<$Res> implements $LocalMusicStateCopyWith<$Res> {
  factory $LocalMusicStateLoadedCopyWith(LocalMusicStateLoaded value, $Res Function(LocalMusicStateLoaded) _then) = _$LocalMusicStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<LocalAudio> audios
});




}
/// @nodoc
class _$LocalMusicStateLoadedCopyWithImpl<$Res>
    implements $LocalMusicStateLoadedCopyWith<$Res> {
  _$LocalMusicStateLoadedCopyWithImpl(this._self, this._then);

  final LocalMusicStateLoaded _self;
  final $Res Function(LocalMusicStateLoaded) _then;

/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? audios = null,}) {
  return _then(LocalMusicStateLoaded(
audios: null == audios ? _self._audios : audios // ignore: cast_nullable_to_non_nullable
as List<LocalAudio>,
  ));
}


}

/// @nodoc


class LocalMusicStateImporting implements LocalMusicState {
  const LocalMusicStateImporting({required this.current, required this.total, required this.currentFile});
  

 final  int current;
 final  int total;
 final  String currentFile;

/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalMusicStateImportingCopyWith<LocalMusicStateImporting> get copyWith => _$LocalMusicStateImportingCopyWithImpl<LocalMusicStateImporting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicStateImporting&&(identical(other.current, current) || other.current == current)&&(identical(other.total, total) || other.total == total)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile));
}


@override
int get hashCode => Object.hash(runtimeType,current,total,currentFile);

@override
String toString() {
  return 'LocalMusicState.importing(current: $current, total: $total, currentFile: $currentFile)';
}


}

/// @nodoc
abstract mixin class $LocalMusicStateImportingCopyWith<$Res> implements $LocalMusicStateCopyWith<$Res> {
  factory $LocalMusicStateImportingCopyWith(LocalMusicStateImporting value, $Res Function(LocalMusicStateImporting) _then) = _$LocalMusicStateImportingCopyWithImpl;
@useResult
$Res call({
 int current, int total, String currentFile
});




}
/// @nodoc
class _$LocalMusicStateImportingCopyWithImpl<$Res>
    implements $LocalMusicStateImportingCopyWith<$Res> {
  _$LocalMusicStateImportingCopyWithImpl(this._self, this._then);

  final LocalMusicStateImporting _self;
  final $Res Function(LocalMusicStateImporting) _then;

/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = null,Object? total = null,Object? currentFile = null,}) {
  return _then(LocalMusicStateImporting(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentFile: null == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LocalMusicStateError implements LocalMusicState {
  const LocalMusicStateError({required this.message});
  

 final  String message;

/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalMusicStateErrorCopyWith<LocalMusicStateError> get copyWith => _$LocalMusicStateErrorCopyWithImpl<LocalMusicStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalMusicStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LocalMusicState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $LocalMusicStateErrorCopyWith<$Res> implements $LocalMusicStateCopyWith<$Res> {
  factory $LocalMusicStateErrorCopyWith(LocalMusicStateError value, $Res Function(LocalMusicStateError) _then) = _$LocalMusicStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LocalMusicStateErrorCopyWithImpl<$Res>
    implements $LocalMusicStateErrorCopyWith<$Res> {
  _$LocalMusicStateErrorCopyWithImpl(this._self, this._then);

  final LocalMusicStateError _self;
  final $Res Function(LocalMusicStateError) _then;

/// Create a copy of LocalMusicState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(LocalMusicStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
