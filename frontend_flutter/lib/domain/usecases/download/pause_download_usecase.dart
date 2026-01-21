import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/download_repository.dart';

/// 暂停下载 UseCase
class PauseDownloadUseCase extends BaseUseCase<void, PauseDownloadParams> {
  final DownloadRepository repository;

  PauseDownloadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PauseDownloadParams params) {
    return repository.pauseDownload(params.taskId);
  }
}

/// 暂停下载参数
class PauseDownloadParams {
  final String taskId;

  const PauseDownloadParams({required this.taskId});
}
