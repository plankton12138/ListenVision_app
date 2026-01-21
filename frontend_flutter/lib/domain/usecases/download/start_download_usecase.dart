import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/download_repository.dart';

/// 开始下载 UseCase
class StartDownloadUseCase extends BaseUseCase<String, StartDownloadParams> {
  final DownloadRepository repository;

  StartDownloadUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(StartDownloadParams params) {
    return repository.startDownload(
      bvid: params.bvid,
      title: params.title,
      artist: params.artist,
      coverUrl: params.coverUrl,
    );
  }
}

/// 开始下载参数
class StartDownloadParams {
  final String bvid;
  final String? title;
  final String? artist;
  final String? coverUrl;

  const StartDownloadParams({
    required this.bvid,
    this.title,
    this.artist,
    this.coverUrl,
  });
}
