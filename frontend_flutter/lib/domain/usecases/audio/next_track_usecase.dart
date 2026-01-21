import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/audio_repository.dart';

/// 下一曲 UseCase
///
/// 职责：封装切换到下一曲的业务逻辑
class NextTrackUseCase extends BaseUseCase<void, NoParams> {
  final AudioRepository repository;

  NextTrackUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.nextTrack();
  }
}
