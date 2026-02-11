// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'netease_auth_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NeteaseAuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseAuthState()';
}


}

/// @nodoc
class $NeteaseAuthStateCopyWith<$Res>  {
$NeteaseAuthStateCopyWith(NeteaseAuthState _, $Res Function(NeteaseAuthState) __);
}


/// Adds pattern-matching-related methods to [NeteaseAuthState].
extension NeteaseAuthStatePatterns on NeteaseAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NeteaseAuthStateInitial value)?  initial,TResult Function( NeteaseAuthStateLoading value)?  loading,TResult Function( NeteaseAuthStateBound value)?  bound,TResult Function( NeteaseAuthStateUnbound value)?  unbound,TResult Function( NeteaseAuthStateQRLogin value)?  qrLogin,TResult Function( NeteaseAuthStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NeteaseAuthStateInitial() when initial != null:
return initial(_that);case NeteaseAuthStateLoading() when loading != null:
return loading(_that);case NeteaseAuthStateBound() when bound != null:
return bound(_that);case NeteaseAuthStateUnbound() when unbound != null:
return unbound(_that);case NeteaseAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that);case NeteaseAuthStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NeteaseAuthStateInitial value)  initial,required TResult Function( NeteaseAuthStateLoading value)  loading,required TResult Function( NeteaseAuthStateBound value)  bound,required TResult Function( NeteaseAuthStateUnbound value)  unbound,required TResult Function( NeteaseAuthStateQRLogin value)  qrLogin,required TResult Function( NeteaseAuthStateError value)  error,}){
final _that = this;
switch (_that) {
case NeteaseAuthStateInitial():
return initial(_that);case NeteaseAuthStateLoading():
return loading(_that);case NeteaseAuthStateBound():
return bound(_that);case NeteaseAuthStateUnbound():
return unbound(_that);case NeteaseAuthStateQRLogin():
return qrLogin(_that);case NeteaseAuthStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NeteaseAuthStateInitial value)?  initial,TResult? Function( NeteaseAuthStateLoading value)?  loading,TResult? Function( NeteaseAuthStateBound value)?  bound,TResult? Function( NeteaseAuthStateUnbound value)?  unbound,TResult? Function( NeteaseAuthStateQRLogin value)?  qrLogin,TResult? Function( NeteaseAuthStateError value)?  error,}){
final _that = this;
switch (_that) {
case NeteaseAuthStateInitial() when initial != null:
return initial(_that);case NeteaseAuthStateLoading() when loading != null:
return loading(_that);case NeteaseAuthStateBound() when bound != null:
return bound(_that);case NeteaseAuthStateUnbound() when unbound != null:
return unbound(_that);case NeteaseAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that);case NeteaseAuthStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( NeteaseUserInfo account)?  bound,TResult Function()?  unbound,TResult Function( NeteaseQRLoginStatus status,  String? qrimg,  String? qrurl,  String? key)?  qrLogin,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NeteaseAuthStateInitial() when initial != null:
return initial();case NeteaseAuthStateLoading() when loading != null:
return loading();case NeteaseAuthStateBound() when bound != null:
return bound(_that.account);case NeteaseAuthStateUnbound() when unbound != null:
return unbound();case NeteaseAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that.status,_that.qrimg,_that.qrurl,_that.key);case NeteaseAuthStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( NeteaseUserInfo account)  bound,required TResult Function()  unbound,required TResult Function( NeteaseQRLoginStatus status,  String? qrimg,  String? qrurl,  String? key)  qrLogin,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case NeteaseAuthStateInitial():
return initial();case NeteaseAuthStateLoading():
return loading();case NeteaseAuthStateBound():
return bound(_that.account);case NeteaseAuthStateUnbound():
return unbound();case NeteaseAuthStateQRLogin():
return qrLogin(_that.status,_that.qrimg,_that.qrurl,_that.key);case NeteaseAuthStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( NeteaseUserInfo account)?  bound,TResult? Function()?  unbound,TResult? Function( NeteaseQRLoginStatus status,  String? qrimg,  String? qrurl,  String? key)?  qrLogin,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case NeteaseAuthStateInitial() when initial != null:
return initial();case NeteaseAuthStateLoading() when loading != null:
return loading();case NeteaseAuthStateBound() when bound != null:
return bound(_that.account);case NeteaseAuthStateUnbound() when unbound != null:
return unbound();case NeteaseAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that.status,_that.qrimg,_that.qrurl,_that.key);case NeteaseAuthStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class NeteaseAuthStateInitial implements NeteaseAuthState {
  const NeteaseAuthStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseAuthState.initial()';
}


}




/// @nodoc


class NeteaseAuthStateLoading implements NeteaseAuthState {
  const NeteaseAuthStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseAuthState.loading()';
}


}




/// @nodoc


class NeteaseAuthStateBound implements NeteaseAuthState {
  const NeteaseAuthStateBound({required this.account});
  

 final  NeteaseUserInfo account;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteaseAuthStateBoundCopyWith<NeteaseAuthStateBound> get copyWith => _$NeteaseAuthStateBoundCopyWithImpl<NeteaseAuthStateBound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateBound&&(identical(other.account, account) || other.account == account));
}


@override
int get hashCode => Object.hash(runtimeType,account);

@override
String toString() {
  return 'NeteaseAuthState.bound(account: $account)';
}


}

/// @nodoc
abstract mixin class $NeteaseAuthStateBoundCopyWith<$Res> implements $NeteaseAuthStateCopyWith<$Res> {
  factory $NeteaseAuthStateBoundCopyWith(NeteaseAuthStateBound value, $Res Function(NeteaseAuthStateBound) _then) = _$NeteaseAuthStateBoundCopyWithImpl;
@useResult
$Res call({
 NeteaseUserInfo account
});




}
/// @nodoc
class _$NeteaseAuthStateBoundCopyWithImpl<$Res>
    implements $NeteaseAuthStateBoundCopyWith<$Res> {
  _$NeteaseAuthStateBoundCopyWithImpl(this._self, this._then);

  final NeteaseAuthStateBound _self;
  final $Res Function(NeteaseAuthStateBound) _then;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? account = null,}) {
  return _then(NeteaseAuthStateBound(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as NeteaseUserInfo,
  ));
}


}

/// @nodoc


class NeteaseAuthStateUnbound implements NeteaseAuthState {
  const NeteaseAuthStateUnbound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateUnbound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NeteaseAuthState.unbound()';
}


}




/// @nodoc


class NeteaseAuthStateQRLogin implements NeteaseAuthState {
  const NeteaseAuthStateQRLogin({required this.status, this.qrimg, this.qrurl, this.key});
  

 final  NeteaseQRLoginStatus status;
 final  String? qrimg;
 final  String? qrurl;
 final  String? key;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteaseAuthStateQRLoginCopyWith<NeteaseAuthStateQRLogin> get copyWith => _$NeteaseAuthStateQRLoginCopyWithImpl<NeteaseAuthStateQRLogin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateQRLogin&&(identical(other.status, status) || other.status == status)&&(identical(other.qrimg, qrimg) || other.qrimg == qrimg)&&(identical(other.qrurl, qrurl) || other.qrurl == qrurl)&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,status,qrimg,qrurl,key);

@override
String toString() {
  return 'NeteaseAuthState.qrLogin(status: $status, qrimg: $qrimg, qrurl: $qrurl, key: $key)';
}


}

/// @nodoc
abstract mixin class $NeteaseAuthStateQRLoginCopyWith<$Res> implements $NeteaseAuthStateCopyWith<$Res> {
  factory $NeteaseAuthStateQRLoginCopyWith(NeteaseAuthStateQRLogin value, $Res Function(NeteaseAuthStateQRLogin) _then) = _$NeteaseAuthStateQRLoginCopyWithImpl;
@useResult
$Res call({
 NeteaseQRLoginStatus status, String? qrimg, String? qrurl, String? key
});




}
/// @nodoc
class _$NeteaseAuthStateQRLoginCopyWithImpl<$Res>
    implements $NeteaseAuthStateQRLoginCopyWith<$Res> {
  _$NeteaseAuthStateQRLoginCopyWithImpl(this._self, this._then);

  final NeteaseAuthStateQRLogin _self;
  final $Res Function(NeteaseAuthStateQRLogin) _then;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? qrimg = freezed,Object? qrurl = freezed,Object? key = freezed,}) {
  return _then(NeteaseAuthStateQRLogin(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NeteaseQRLoginStatus,qrimg: freezed == qrimg ? _self.qrimg : qrimg // ignore: cast_nullable_to_non_nullable
as String?,qrurl: freezed == qrurl ? _self.qrurl : qrurl // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class NeteaseAuthStateError implements NeteaseAuthState {
  const NeteaseAuthStateError({required this.message});
  

 final  String message;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeteaseAuthStateErrorCopyWith<NeteaseAuthStateError> get copyWith => _$NeteaseAuthStateErrorCopyWithImpl<NeteaseAuthStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeteaseAuthStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NeteaseAuthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $NeteaseAuthStateErrorCopyWith<$Res> implements $NeteaseAuthStateCopyWith<$Res> {
  factory $NeteaseAuthStateErrorCopyWith(NeteaseAuthStateError value, $Res Function(NeteaseAuthStateError) _then) = _$NeteaseAuthStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NeteaseAuthStateErrorCopyWithImpl<$Res>
    implements $NeteaseAuthStateErrorCopyWith<$Res> {
  _$NeteaseAuthStateErrorCopyWithImpl(this._self, this._then);

  final NeteaseAuthStateError _self;
  final $Res Function(NeteaseAuthStateError) _then;

/// Create a copy of NeteaseAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NeteaseAuthStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
