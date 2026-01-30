import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// 认证仓储接口
///
/// Clean Architecture 中的 Repository 接口：
/// - 定义在 Domain 层
/// - 由 Data 层实现
/// - 返回 Either<Failure, T> 类型，左侧为失败，右侧为成功
abstract class AuthRepository {
  /// 用户登录
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// 返回登录成功的用户信息
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// 用户注册
  ///
  /// [username] 用户名
  /// [email] 邮箱
  /// [password] 密码
  /// [captchaCode] 验证码（可选）
  /// 返回注册成功的用户信息
  Future<Either<Failure, User>> register({
    required String username,
    required String email,
    required String password,
    String? captchaCode,
  });

  /// 发送验证码
  ///
  /// [email] 邮箱地址
  /// 返回发送是否成功
  Future<Either<Failure, bool>> sendVerificationCode({
    required String email,
  });

  /// 重置密码
  ///
  /// [email] 邮箱地址
  /// [code] 验证码
  /// [newPassword] 新密码
  /// 返回重置是否成功
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// 获取当前用户信息
  ///
  /// [token] JWT token
  /// 返回用户信息
  Future<Either<Failure, User>> getCurrentUser({
    required String token,
  });

  /// 退出登录
  ///
  /// 清除本地存储的 token
  Future<Either<Failure, void>> logout();

  /// 检查登录状态
  ///
  /// 返回当前登录的用户，未登录返回 null
  Future<Either<Failure, User?>> checkLoginStatus();

  /// 保存 token
  ///
  /// [token] JWT token
  Future<Either<Failure, void>> saveToken({
    required String token,
  });

  /// 获取保存的 token
  ///
  /// 返回 token，未保存返回 null
  Future<String?> getToken();

  /// 清除 token
  Future<Either<Failure, void>> clearToken();
}
