import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/audio_repository.dart';

/// 音频跳转 UseCase
///
/// 职责：封装播放位置跳转的业务逻辑
class SeekAudioUseCase extends BaseUseCase<void, SeekAudioParams> {
  final AudioRepository repository;

  SeekAudioUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SeekAudioParams params) {
    return repository.seekAudio(params.position);
  }
}

/// 音频跳转参数
class SeekAudioParams {
  final Duration position;

  const SeekAudioParams({required this.position});
}
