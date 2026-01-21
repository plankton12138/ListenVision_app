import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/download_repository.dart';

/// 取消下载 UseCase
class CancelDownloadUseCase extends BaseUseCase<void, CancelDownloadParams> {
  final DownloadRepository repository;

  CancelDownloadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelDownloadParams params) {
    return repository.cancelDownload(params.taskId);
  }
}

/// 取消下载参数
class CancelDownloadParams {
  final String taskId;

  const CancelDownloadParams({required this.taskId});
}
