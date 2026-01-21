import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/bilibili_repository.dart';

/// 初始化 QR 码登录 UseCase
class InitQRLoginUseCase extends BaseUseCase<String, NoParams> {
  final BilibiliRepository repository;

  InitQRLoginUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return repository.initQRLogin();
  }
}
