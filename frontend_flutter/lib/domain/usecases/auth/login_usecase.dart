import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';
import '../../entities/user.dart';

/// 登录用例
///
/// 负责用户登录业务逻辑
class LoginUseCase extends UseCase<User, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    // 参数验证
    if (params.email.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '邮箱不能为空',
      ));
    }

    if (params.password.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '密码不能为空',
      ));
    }

    // 邮箱格式验证
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(params.email)) {
      return const Left(DataFailure.invalidData(
        message: '邮箱格式不正确',
      ));
    }

    // 调用仓储登录
    final result = await _repository.login(
      email: params.email,
      password: params.password,
    );

    // 登录成功后保存 token
    return result.fold(
      (failure) => Left(failure),
      (user) async {
        if (user.token != null) {
          await _repository.saveToken(token: user.token!);
        }
        return Right(user);
      },
    );
  }
}

/// 登录参数
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}
