import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';

/// 退出登录用例
///
/// 负责用户退出登录业务逻辑
class LogoutUseCase extends NoParamsUseCase<void> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  Future<Either<Failure, void>> execute() async {
    // 清除 token
    final clearTokenResult = await _repository.clearToken();

    // 执行退出登录
    return clearTokenResult.fold(
      (failure) => Left(failure),
      (_) => _repository.logout(),
    );
  }
}
