import 'platform_binding_model.dart';
import 'platform_account.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String token;

  /// 平台绑定列表（一个用户可以绑定多个平台）
  final List<PlatformBindingModel> platformBindings;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
    this.platformBindings = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      final bindingsJson = json['platformBindings'] as List?;
      final bindings = bindingsJson?.map((b) => PlatformBindingModel.fromJson(b as Map<String, dynamic>)).toList() ?? [];

      return User(
        id: int.parse(json['id'].toString()),
        username: json['username'].toString(),
        email: json['email'].toString(),
        // token 可能为空（如注册响应），使用默认值
        token: json['token']?.toString() ?? '',
        platformBindings: bindings,
      );
    } catch (e) {
      throw FormatException('无效的用户格式 $e');
    }
  }

  /// 检查用户是否已绑定指定平台
  bool isPlatformBound(PlatformType platform) {
    return platformBindings.any((binding) => binding.platformType == platform && binding.isActive);
  }

  /// 获取指定平台的绑定信息
  PlatformBindingModel? getPlatformBinding(PlatformType platform) {
    try {
      return platformBindings.firstWhere((binding) => binding.platformType == platform);
    } catch (e) {
      return null;
    }
  }

  /// 获取所有活跃的绑定
  List<PlatformBindingModel> getActiveBindings() {
    return platformBindings.where((binding) => binding.isActive).toList();
  }

  /// 复制并修改
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? token,
    List<PlatformBindingModel>? platformBindings,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
      platformBindings: platformBindings ?? this.platformBindings,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, bindings: ${platformBindings.length}}';
  }
}