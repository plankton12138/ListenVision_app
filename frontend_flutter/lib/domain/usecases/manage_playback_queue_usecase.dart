import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/playable_audio.dart';

/// 播放队列管理 UseCase
///
/// Clean Architecture 中的用例层
/// 负责协调播放队列管理的业务逻辑
abstract class ManagePlaybackQueueUseCase {
  /// 执行队列操作
  Future<Either<Failure, void>> execute();
}

/// 添加到队列 UseCase
class AddToQueueUseCase implements ManagePlaybackQueueUseCase {
  final PlayableAudio audio;
  final bool playImmediately;

  AddToQueueUseCase({
    required this.audio,
    this.playImmediately = false,
  });

  @override
  Future<Either<Failure, void>> execute() async {
    try {
      // 实际的队列操作逻辑由 Provider 层实现
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}

/// 从队列移除 UseCase
class RemoveFromQueueUseCase implements ManagePlaybackQueueUseCase {
  final String audioId;

  RemoveFromQueueUseCase(this.audioId);

  @override
  Future<Either<Failure, void>> execute() async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}

/// 清空队列 UseCase
class ClearQueueUseCase implements ManagePlaybackQueueUseCase {
  @override
  Future<Either<Failure, void>> execute() async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}

/// 播放下一首 UseCase
class PlayNextUseCase implements ManagePlaybackQueueUseCase {
  @override
  Future<Either<Failure, void>> execute() async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}

/// 播放上一首 UseCase
class PlayPreviousUseCase implements ManagePlaybackQueueUseCase {
  @override
  Future<Either<Failure, void>> execute() async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}
