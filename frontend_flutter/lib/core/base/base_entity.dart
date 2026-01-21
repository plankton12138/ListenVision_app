import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_entity.freezed.dart';

/// 基础实体类
///
/// Clean Architecture 中的 Entity 是领域层的核心对象：
/// - 表示业务概念
/// - 与数据源格式无关（DTO 负责转换）
/// - 使用 freezed 确保不可变性和类型安全
///
/// 使用示例:
/// ```dart
/// @freezed
/// class User with _$User {
///   const factory User({
///     required String id,
///     required String username,
///     String? email,
///   }) = _User;
/// }
/// ```

/// 基础实体接口
///
/// 所有领域实体应实现此接口
abstract class BaseEntity {
  /// 实体唯一标识
  String get id;

  /// 创建时间
  DateTime? get createdAt;

  /// 更新时间
  DateTime? get updatedAt;
}

/// 带时间戳的基础实体
///
/// 提供创建/更新时间戳的通用实现
@freezed
class TimestampedEntity with _$TimestampedEntity implements BaseEntity {
  const TimestampedEntity._();

  const factory TimestampedEntity({
    required String id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TimestampedEntity;

  /// 从 JSON 创建（兼容旧数据格式）
  factory TimestampedEntity.fromJson(Map<String, dynamic> json) {
    return TimestampedEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// 解析 DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  /// 判断是否为新创建的实体
  bool get isNew => createdAt == null;

  /// 判断是否已修改（创建后有过更新）
  bool get isModified =>
      createdAt != null && updatedAt != null && updatedAt!.isAfter(createdAt!);
}

/// 带软删除的基础实体
///
/// 支持软删除功能（不真正删除数据，只标记）
@freezed
class SoftDeletableEntity with _$SoftDeletableEntity implements BaseEntity {
  const SoftDeletableEntity._();

  const factory SoftDeletableEntity({
    required String id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    @Default(false) bool isDeleted,
  }) = _SoftDeletableEntity;

  /// 从 JSON 创建
  factory SoftDeletableEntity.fromJson(Map<String, dynamic> json) {
    final deletedAt = _parseDateTime(json['deleted_at'] ?? json['deletedAt']);
    return SoftDeletableEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      deletedAt: deletedAt,
      isDeleted: deletedAt != null || json['is_deleted'] == true,
    );
  }

  /// 解析 DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  /// 判断是否已删除
  bool get isDeletedEffective => isDeleted || deletedAt != null;
}

/// 可更新的实体扩展
///
/// 提供更新字段的便捷方法
extension EntityUpdateExtension on BaseEntity {
  /// 创建更新时间戳的副本
  Map<String, dynamic> toUpdateJson() {
    return {
      'updated_at': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
