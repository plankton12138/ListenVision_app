// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimestampedEntity {
  String get id => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of TimestampedEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimestampedEntityCopyWith<TimestampedEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimestampedEntityCopyWith<$Res> {
  factory $TimestampedEntityCopyWith(
    TimestampedEntity value,
    $Res Function(TimestampedEntity) then,
  ) = _$TimestampedEntityCopyWithImpl<$Res, TimestampedEntity>;
  @useResult
  $Res call({String id, DateTime? createdAt, DateTime? updatedAt});
}

/// @nodoc
class _$TimestampedEntityCopyWithImpl<$Res, $Val extends TimestampedEntity>
    implements $TimestampedEntityCopyWith<$Res> {
  _$TimestampedEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimestampedEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$TimestampedEntityImplCopyWith<$Res>
    implements $TimestampedEntityCopyWith<$Res> {
  factory _$$TimestampedEntityImplCopyWith(
    _$TimestampedEntityImpl value,
    $Res Function(_$TimestampedEntityImpl) then,
  ) = __$$TimestampedEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, DateTime? createdAt, DateTime? updatedAt});
}

/// @nodoc
class __$$TimestampedEntityImplCopyWithImpl<$Res>
    extends _$TimestampedEntityCopyWithImpl<$Res, _$TimestampedEntityImpl>
    implements _$$TimestampedEntityImplCopyWith<$Res> {
  __$$TimestampedEntityImplCopyWithImpl(
    _$TimestampedEntityImpl _value,
    $Res Function(_$TimestampedEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimestampedEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$TimestampedEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
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

class _$TimestampedEntityImpl extends _TimestampedEntity {
  const _$TimestampedEntityImpl({
    required this.id,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  @override
  final String id;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'TimestampedEntity(id: $id, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimestampedEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, createdAt, updatedAt);

  /// Create a copy of TimestampedEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimestampedEntityImplCopyWith<_$TimestampedEntityImpl> get copyWith =>
      __$$TimestampedEntityImplCopyWithImpl<_$TimestampedEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _TimestampedEntity extends TimestampedEntity {
  const factory _TimestampedEntity({
    required final String id,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$TimestampedEntityImpl;
  const _TimestampedEntity._() : super._();

  @override
  String get id;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of TimestampedEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimestampedEntityImplCopyWith<_$TimestampedEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SoftDeletableEntity {
  String get id => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Create a copy of SoftDeletableEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SoftDeletableEntityCopyWith<SoftDeletableEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SoftDeletableEntityCopyWith<$Res> {
  factory $SoftDeletableEntityCopyWith(
    SoftDeletableEntity value,
    $Res Function(SoftDeletableEntity) then,
  ) = _$SoftDeletableEntityCopyWithImpl<$Res, SoftDeletableEntity>;
  @useResult
  $Res call({
    String id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool isDeleted,
  });
}

/// @nodoc
class _$SoftDeletableEntityCopyWithImpl<$Res, $Val extends SoftDeletableEntity>
    implements $SoftDeletableEntityCopyWith<$Res> {
  _$SoftDeletableEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SoftDeletableEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? isDeleted = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SoftDeletableEntityImplCopyWith<$Res>
    implements $SoftDeletableEntityCopyWith<$Res> {
  factory _$$SoftDeletableEntityImplCopyWith(
    _$SoftDeletableEntityImpl value,
    $Res Function(_$SoftDeletableEntityImpl) then,
  ) = __$$SoftDeletableEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool isDeleted,
  });
}

/// @nodoc
class __$$SoftDeletableEntityImplCopyWithImpl<$Res>
    extends _$SoftDeletableEntityCopyWithImpl<$Res, _$SoftDeletableEntityImpl>
    implements _$$SoftDeletableEntityImplCopyWith<$Res> {
  __$$SoftDeletableEntityImplCopyWithImpl(
    _$SoftDeletableEntityImpl _value,
    $Res Function(_$SoftDeletableEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SoftDeletableEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? isDeleted = null,
  }) {
    return _then(
      _$SoftDeletableEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SoftDeletableEntityImpl extends _SoftDeletableEntity {
  const _$SoftDeletableEntityImpl({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  }) : super._();

  @override
  final String id;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  @JsonKey()
  final bool isDeleted;

  @override
  String toString() {
    return 'SoftDeletableEntity(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SoftDeletableEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, createdAt, updatedAt, deletedAt, isDeleted);

  /// Create a copy of SoftDeletableEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SoftDeletableEntityImplCopyWith<_$SoftDeletableEntityImpl> get copyWith =>
      __$$SoftDeletableEntityImplCopyWithImpl<_$SoftDeletableEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _SoftDeletableEntity extends SoftDeletableEntity {
  const factory _SoftDeletableEntity({
    required final String id,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final DateTime? deletedAt,
    final bool isDeleted,
  }) = _$SoftDeletableEntityImpl;
  const _SoftDeletableEntity._() : super._();

  @override
  String get id;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get deletedAt;
  @override
  bool get isDeleted;

  /// Create a copy of SoftDeletableEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SoftDeletableEntityImplCopyWith<_$SoftDeletableEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
