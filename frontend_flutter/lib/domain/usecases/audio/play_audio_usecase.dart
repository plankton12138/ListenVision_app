import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/repositories/audio_repository.dart';

/// 播放音频 UseCase
///
/// 职责：封装播放音频的业务逻辑
class PlayAudioUseCase extends BaseUseCase<void, PlayAudioParams> {
  final AudioRepository repository;

  PlayAudioUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PlayAudioParams params) {
    return repository.playAudio(params.audio);
  }
}

/// 播放音频参数
class PlayAudioParams {
  final Audio audio;

  const PlayAudioParams({required this.audio});
}
