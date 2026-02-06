// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'platform_auth_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlatformAuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlatformAuthState()';
}


}

/// @nodoc
class $PlatformAuthStateCopyWith<$Res>  {
$PlatformAuthStateCopyWith(PlatformAuthState _, $Res Function(PlatformAuthState) __);
}


/// Adds pattern-matching-related methods to [PlatformAuthState].
extension PlatformAuthStatePatterns on PlatformAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlatformAuthStateInitial value)?  initial,TResult Function( PlatformAuthStateLoading value)?  loading,TResult Function( PlatformAuthStateBound value)?  bound,TResult Function( PlatformAuthStateUnbound value)?  unbound,TResult Function( PlatformAuthStateQRLogin value)?  qrLogin,TResult Function( PlatformAuthStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlatformAuthStateInitial() when initial != null:
return initial(_that);case PlatformAuthStateLoading() when loading != null:
return loading(_that);case PlatformAuthStateBound() when bound != null:
return bound(_that);case PlatformAuthStateUnbound() when unbound != null:
return unbound(_that);case PlatformAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that);case PlatformAuthStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlatformAuthStateInitial value)  initial,required TResult Function( PlatformAuthStateLoading value)  loading,required TResult Function( PlatformAuthStateBound value)  bound,required TResult Function( PlatformAuthStateUnbound value)  unbound,required TResult Function( PlatformAuthStateQRLogin value)  qrLogin,required TResult Function( PlatformAuthStateError value)  error,}){
final _that = this;
switch (_that) {
case PlatformAuthStateInitial():
return initial(_that);case PlatformAuthStateLoading():
return loading(_that);case PlatformAuthStateBound():
return bound(_that);case PlatformAuthStateUnbound():
return unbound(_that);case PlatformAuthStateQRLogin():
return qrLogin(_that);case PlatformAuthStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlatformAuthStateInitial value)?  initial,TResult? Function( PlatformAuthStateLoading value)?  loading,TResult? Function( PlatformAuthStateBound value)?  bound,TResult? Function( PlatformAuthStateUnbound value)?  unbound,TResult? Function( PlatformAuthStateQRLogin value)?  qrLogin,TResult? Function( PlatformAuthStateError value)?  error,}){
final _that = this;
switch (_that) {
case PlatformAuthStateInitial() when initial != null:
return initial(_that);case PlatformAuthStateLoading() when loading != null:
return loading(_that);case PlatformAuthStateBound() when bound != null:
return bound(_that);case PlatformAuthStateUnbound() when unbound != null:
return unbound(_that);case PlatformAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that);case PlatformAuthStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( BilibiliUserInfo account)?  bound,TResult Function()?  unbound,TResult Function( QRLoginStatus status,  String? qrcodeUrl,  String? qrcodeKey,  DateTime? expiresAt)?  qrLogin,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlatformAuthStateInitial() when initial != null:
return initial();case PlatformAuthStateLoading() when loading != null:
return loading();case PlatformAuthStateBound() when bound != null:
return bound(_that.account);case PlatformAuthStateUnbound() when unbound != null:
return unbound();case PlatformAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that.status,_that.qrcodeUrl,_that.qrcodeKey,_that.expiresAt);case PlatformAuthStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( BilibiliUserInfo account)  bound,required TResult Function()  unbound,required TResult Function( QRLoginStatus status,  String? qrcodeUrl,  String? qrcodeKey,  DateTime? expiresAt)  qrLogin,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case PlatformAuthStateInitial():
return initial();case PlatformAuthStateLoading():
return loading();case PlatformAuthStateBound():
return bound(_that.account);case PlatformAuthStateUnbound():
return unbound();case PlatformAuthStateQRLogin():
return qrLogin(_that.status,_that.qrcodeUrl,_that.qrcodeKey,_that.expiresAt);case PlatformAuthStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( BilibiliUserInfo account)?  bound,TResult? Function()?  unbound,TResult? Function( QRLoginStatus status,  String? qrcodeUrl,  String? qrcodeKey,  DateTime? expiresAt)?  qrLogin,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case PlatformAuthStateInitial() when initial != null:
return initial();case PlatformAuthStateLoading() when loading != null:
return loading();case PlatformAuthStateBound() when bound != null:
return bound(_that.account);case PlatformAuthStateUnbound() when unbound != null:
return unbound();case PlatformAuthStateQRLogin() when qrLogin != null:
return qrLogin(_that.status,_that.qrcodeUrl,_that.qrcodeKey,_that.expiresAt);case PlatformAuthStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PlatformAuthStateInitial implements PlatformAuthState {
  const PlatformAuthStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlatformAuthState.initial()';
}


}




/// @nodoc


class PlatformAuthStateLoading implements PlatformAuthState {
  const PlatformAuthStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlatformAuthState.loading()';
}


}




/// @nodoc


class PlatformAuthStateBound implements PlatformAuthState {
  const PlatformAuthStateBound({required this.account});
  

 final  BilibiliUserInfo account;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformAuthStateBoundCopyWith<PlatformAuthStateBound> get copyWith => _$PlatformAuthStateBoundCopyWithImpl<PlatformAuthStateBound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateBound&&(identical(other.account, account) || other.account == account));
}


@override
int get hashCode => Object.hash(runtimeType,account);

@override
String toString() {
  return 'PlatformAuthState.bound(account: $account)';
}


}

/// @nodoc
abstract mixin class $PlatformAuthStateBoundCopyWith<$Res> implements $PlatformAuthStateCopyWith<$Res> {
  factory $PlatformAuthStateBoundCopyWith(PlatformAuthStateBound value, $Res Function(PlatformAuthStateBound) _then) = _$PlatformAuthStateBoundCopyWithImpl;
@useResult
$Res call({
 BilibiliUserInfo account
});




}
/// @nodoc
class _$PlatformAuthStateBoundCopyWithImpl<$Res>
    implements $PlatformAuthStateBoundCopyWith<$Res> {
  _$PlatformAuthStateBoundCopyWithImpl(this._self, this._then);

  final PlatformAuthStateBound _self;
  final $Res Function(PlatformAuthStateBound) _then;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? account = null,}) {
  return _then(PlatformAuthStateBound(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as BilibiliUserInfo,
  ));
}


}

/// @nodoc


class PlatformAuthStateUnbound implements PlatformAuthState {
  const PlatformAuthStateUnbound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateUnbound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlatformAuthState.unbound()';
}


}




/// @nodoc


class PlatformAuthStateQRLogin implements PlatformAuthState {
  const PlatformAuthStateQRLogin({required this.status, this.qrcodeUrl, this.qrcodeKey, this.expiresAt});
  

 final  QRLoginStatus status;
 final  String? qrcodeUrl;
 final  String? qrcodeKey;
 final  DateTime? expiresAt;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformAuthStateQRLoginCopyWith<PlatformAuthStateQRLogin> get copyWith => _$PlatformAuthStateQRLoginCopyWithImpl<PlatformAuthStateQRLogin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateQRLogin&&(identical(other.status, status) || other.status == status)&&(identical(other.qrcodeUrl, qrcodeUrl) || other.qrcodeUrl == qrcodeUrl)&&(identical(other.qrcodeKey, qrcodeKey) || other.qrcodeKey == qrcodeKey)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,qrcodeUrl,qrcodeKey,expiresAt);

@override
String toString() {
  return 'PlatformAuthState.qrLogin(status: $status, qrcodeUrl: $qrcodeUrl, qrcodeKey: $qrcodeKey, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PlatformAuthStateQRLoginCopyWith<$Res> implements $PlatformAuthStateCopyWith<$Res> {
  factory $PlatformAuthStateQRLoginCopyWith(PlatformAuthStateQRLogin value, $Res Function(PlatformAuthStateQRLogin) _then) = _$PlatformAuthStateQRLoginCopyWithImpl;
@useResult
$Res call({
 QRLoginStatus status, String? qrcodeUrl, String? qrcodeKey, DateTime? expiresAt
});




}
/// @nodoc
class _$PlatformAuthStateQRLoginCopyWithImpl<$Res>
    implements $PlatformAuthStateQRLoginCopyWith<$Res> {
  _$PlatformAuthStateQRLoginCopyWithImpl(this._self, this._then);

  final PlatformAuthStateQRLogin _self;
  final $Res Function(PlatformAuthStateQRLogin) _then;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? qrcodeUrl = freezed,Object? qrcodeKey = freezed,Object? expiresAt = freezed,}) {
  return _then(PlatformAuthStateQRLogin(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QRLoginStatus,qrcodeUrl: freezed == qrcodeUrl ? _self.qrcodeUrl : qrcodeUrl // ignore: cast_nullable_to_non_nullable
as String?,qrcodeKey: freezed == qrcodeKey ? _self.qrcodeKey : qrcodeKey // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class PlatformAuthStateError implements PlatformAuthState {
  const PlatformAuthStateError({required this.message});
  

 final  String message;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformAuthStateErrorCopyWith<PlatformAuthStateError> get copyWith => _$PlatformAuthStateErrorCopyWithImpl<PlatformAuthStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformAuthStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlatformAuthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlatformAuthStateErrorCopyWith<$Res> implements $PlatformAuthStateCopyWith<$Res> {
  factory $PlatformAuthStateErrorCopyWith(PlatformAuthStateError value, $Res Function(PlatformAuthStateError) _then) = _$PlatformAuthStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PlatformAuthStateErrorCopyWithImpl<$Res>
    implements $PlatformAuthStateErrorCopyWith<$Res> {
  _$PlatformAuthStateErrorCopyWithImpl(this._self, this._then);

  final PlatformAuthStateError _self;
  final $Res Function(PlatformAuthStateError) _then;

/// Create a copy of PlatformAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PlatformAuthStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
