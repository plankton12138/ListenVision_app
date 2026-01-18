import 'platform_account.dart';

/// Bilibili 用户信息模型
class BilibiliUserInfo {
  final String uid;
  final String uname;
  final String avatar;
  final String mid;

  BilibiliUserInfo({
    required this.uid,
    required this.uname,
    required this.avatar,
    required this.mid,
  });

  factory BilibiliUserInfo.fromJson(Map<String, dynamic> json) {
    // 兼容两种格式：
    // 1. 后端直接返回: { mid, uid, uname }
    // 2. B站 API 返回: { data: { mid, uname, face } }
    final isDirectFormat = json.containsKey('mid') || json.containsKey('uid');

    final Map<String, dynamic> data;
    if (isDirectFormat) {
      data = json;
    } else {
      data = json['data'] as Map<String, dynamic>;
    }

    return BilibiliUserInfo(
      uid: data['uid']?.toString() ?? data['mid']?.toString() ?? '',
      uname: data['uname'] ?? '',
      avatar: data['face'] ?? data['avatar'] ?? '',
      mid: data['mid']?.toString() ?? data['uid']?.toString() ?? '',
    );
  }
}

/// Bilibili 账号模型 - 实现 PlatformAccount 接口
class BilibiliAccount implements PlatformAccount {
  final String _platformUserId;
  final String _platformUsername;
  final String? _avatar;
  final DateTime _bindTime;
  final String _cookie;
  PlatformAccountStatus _status;
  final DateTime? _lastValidateTime;

  BilibiliAccount({
    required String platformUserId,
    required String platformUsername,
    String? avatar,
    required DateTime bindTime,
    required String cookie,
    PlatformAccountStatus status = PlatformAccountStatus.active,
    DateTime? lastValidateTime,
  })  : _platformUserId = platformUserId,
        _platformUsername = platformUsername,
        _avatar = avatar,
        _bindTime = bindTime,
        _cookie = cookie,
        _status = status,
        _lastValidateTime = lastValidateTime;

  @override
  PlatformType get platformType => PlatformType.bilibili;

  @override
  String get platformUserId => _platformUserId;

  @override
  String get platformUsername => _platformUsername;

  @override
  String? get avatar => _avatar;

  @override
  DateTime get bindTime => _bindTime;

  /// 获取存储的 Cookie
  String get cookie => _cookie;

  /// 获取最后验证时间
  DateTime? get lastValidateTime => _lastValidateTime;

  @override
  PlatformAccountStatus get status => _status;

  /// 设置账号状态
  void setStatus(PlatformAccountStatus status) {
    _status = status;
  }

  /// 验证 Cookie 是否有效
  /// 注意：实际验证由 BilibiliAuthService 完成
  @override
  Future<bool> validate() async {
    // 这个方法由 BilibiliAuthService 调用
    // 这里只是占位符
    return _status == PlatformAccountStatus.active;
  }

  /// 刷新账号信息
  /// 注意：实际刷新由 BilibiliAuthService 完成
  @override
  Future<void> refresh() async {
    // 这个方法由 BilibiliAuthService 调用
    // 这里只是占位符
  }

  /// 转换为 JSON（用于数据库存储）
  @override
  Map<String, dynamic> toJson() {
    return {
      'platformType': platformType.value,
      'platformUserId': _platformUserId,
      'platformUsername': _platformUsername,
      'avatar': _avatar,
      'bindTime': _bindTime.toIso8601String(),
      'status': _status.value,
      'lastValidateTime': _lastValidateTime?.toIso8601String(),
      // 注意：Cookie 不应该存储在这里，应该存储在加密存储中
    };
  }

  /// 从 JSON 创建 BilibiliAccount
  factory BilibiliAccount.fromJson(
    Map<String, dynamic> json, {
    required String cookie,
  }) {
    return BilibiliAccount(
      platformUserId: json['platformUserId'] ?? '',
      platformUsername: json['platformUsername'] ?? '',
      avatar: json['avatar'],
      bindTime: DateTime.parse(json['bindTime'] ?? DateTime.now().toIso8601String()),
      cookie: cookie,
      status: PlatformAccountStatusExtension.fromString(
        json['status'] ?? 'active',
      ),
      lastValidateTime: json['lastValidateTime'] != null
          ? DateTime.parse(json['lastValidateTime'])
          : null,
    );
  }

  /// 复制并修改字段
  BilibiliAccount copyWith({
    String? platformUserId,
    String? platformUsername,
    String? avatar,
    DateTime? bindTime,
    String? cookie,
    PlatformAccountStatus? status,
    DateTime? lastValidateTime,
  }) {
    return BilibiliAccount(
      platformUserId: platformUserId ?? _platformUserId,
      platformUsername: platformUsername ?? _platformUsername,
      avatar: avatar ?? _avatar,
      bindTime: bindTime ?? _bindTime,
      cookie: cookie ?? _cookie,
      status: status ?? _status,
      lastValidateTime: lastValidateTime ?? _lastValidateTime,
    );
  }

  @override
  String toString() => 'BilibiliAccount(uid: $_platformUserId, name: $_platformUsername)';
}
