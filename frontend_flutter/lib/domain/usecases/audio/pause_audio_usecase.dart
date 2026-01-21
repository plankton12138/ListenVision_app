import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/audio_repository.dart';

/// 暂停音频 UseCase
///
/// 职责：封装暂停播放的业务逻辑
class PauseAudioUseCase extends BaseUseCase<void, NoParams> {
  final AudioRepository repository;

  PauseAudioUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.pauseAudio();
  }
}
