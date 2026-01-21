import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/download_repository.dart';

/// 恢复下载 UseCase
class ResumeDownloadUseCase extends BaseUseCase<void, ResumeDownloadParams> {
  final DownloadRepository repository;

  ResumeDownloadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResumeDownloadParams params) {
    return repository.resumeDownload(params.taskId);
  }
}

/// 恢复下载参数
class ResumeDownloadParams {
  final String taskId;

  const ResumeDownloadParams({required this.taskId});
}
