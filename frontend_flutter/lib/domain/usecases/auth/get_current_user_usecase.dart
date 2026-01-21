import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';
import '../../entities/user.dart';

/// 获取当前用户用例
///
/// 负责获取当前登录用户信息的业务逻辑
class GetCurrentUserUseCase extends NoParamsUseCase<User?> {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  @override
  Future<Either<Failure, User?>> execute() async {
    // 检查是否有 token
    final token = await _repository.getToken();

    if (token == null || token.isEmpty) {
      return const Right(null);
    }

    // 获取用户信息
    return _repository.getCurrentUser(token: token);
  }
}
