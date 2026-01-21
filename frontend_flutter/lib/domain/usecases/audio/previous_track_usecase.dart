import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/audio_repository.dart';

/// 上一曲 UseCase
///
/// 职责：封装切换到上一曲的业务逻辑
class PreviousTrackUseCase extends BaseUseCase<void, NoParams> {
  final AudioRepository repository;

  PreviousTrackUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.previousTrack();
  }
}
