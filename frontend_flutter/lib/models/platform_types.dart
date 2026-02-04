/// 平台账号枚举 - 支持未来扩展到微信、QQ、网易音乐等
enum PlatformType {
  bilibili,
  wechat,
  qq,
  neteaseMusic,
}

extension PlatformTypeExtension on PlatformType {
  String get value {
    switch (this) {
      case PlatformType.bilibili:
        return 'bilibili';
      case PlatformType.wechat:
        return 'wechat';
      case PlatformType.qq:
        return 'qq';
      case PlatformType.neteaseMusic:
        return 'netease_music';
    }
  }

  String get displayName {
    switch (this) {
      case PlatformType.bilibili:
        return 'Bilibili';
      case PlatformType.wechat:
        return '微信';
      case PlatformType.qq:
        return 'QQ';
      case PlatformType.neteaseMusic:
        return '网易音乐';
    }
  }

  static PlatformType fromString(String value) {
    switch (value) {
      case 'bilibili':
        return PlatformType.bilibili;
      case 'wechat':
        return PlatformType.wechat;
      case 'qq':
        return PlatformType.qq;
      case 'netease_music':
        return PlatformType.neteaseMusic;
      default:
        throw ArgumentError('Unknown platform type: $value');
    }
  }
}

/// 平台账号状态枚举
enum PlatformAccountStatus {
  active,      // 有效
  expired,     // 已过期
  revoked,     // 已撤销
  unknown,     // 未知
}

extension PlatformAccountStatusExtension on PlatformAccountStatus {
  String get value {
    switch (this) {
      case PlatformAccountStatus.active:
        return 'active';
      case PlatformAccountStatus.expired:
        return 'expired';
      case PlatformAccountStatus.revoked:
        return 'revoked';
      case PlatformAccountStatus.unknown:
        return 'unknown';
    }
  }

  static PlatformAccountStatus fromString(String value) {
    switch (value) {
      case 'active':
        return PlatformAccountStatus.active;
      case 'expired':
        return PlatformAccountStatus.expired;
      case 'revoked':
        return PlatformAccountStatus.revoked;
      case 'unknown':
        return PlatformAccountStatus.unknown;
      default:
        throw ArgumentError('Unknown status: $value');
    }
  }
}

/// 平台账号抽象基类
/// 支持多平台账号绑定，可扩展以支持微信、QQ、网易等平台
abstract class PlatformAccount {
  /// 平台类型（Bilibili、微信、QQ等）
  PlatformType get platformType;

  /// 平台用户ID
  String get platformUserId;

  /// 平台用户名
  String get platformUsername;

  /// 用户头像URL
  String? get avatar;

  /// 绑定时间
  DateTime get bindTime;

  /// 账号状态
  PlatformAccountStatus get status;

  /// 验证账号是否有效
  Future<bool> validate();

  /// 刷新账号信息
  Future<void> refresh();

  /// 转换为JSON
  Map<String, dynamic> toJson();
}
