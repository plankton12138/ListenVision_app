import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/bilibili_repository.dart';

/// 检查 QR 码登录状态 UseCase
class CheckQRLoginUseCase extends BaseUseCase<QRLoginStatus, CheckQRLoginParams> {
  final BilibiliRepository repository;

  CheckQRLoginUseCase(this.repository);

  @override
  Future<Either<Failure, QRLoginStatus>> call(CheckQRLoginParams params) {
    return repository.checkQRLoginStatus(params.qrcodeKey);
  }
}

/// 检查 QR 码登录状态参数
class CheckQRLoginParams {
  final String qrcodeKey;

  const CheckQRLoginParams({required this.qrcodeKey});
}

/// QR 码登录状态
enum QRLoginStatus {
  /// 未扫描
  none,
  /// 已扫描
  scanned,
  /// 已确认
  confirmed,
  /// 已过期
  expired,
}
