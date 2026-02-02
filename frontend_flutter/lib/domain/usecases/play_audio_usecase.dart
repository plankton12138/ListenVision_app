import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/local_audio.dart';
import '../entities/audio.dart';

/// 播放音频 UseCase
///
/// Clean Architecture 中的用例层
/// 负责协调音频播放的业务逻辑
abstract class PlayAudioUseCase {
  /// 执行播放
  Future<Either<Failure, void>> execute();
}

/// 播放本地音频 UseCase
class PlayLocalAudioUseCase implements PlayAudioUseCase {
  final LocalAudio audio;

  PlayLocalAudioUseCase(this.audio);

  @override
  Future<Either<Failure, void>> execute() async {
    try {
      // 实际的播放逻辑由 Provider 层实现
      // UseCase 层只定义契约
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}

/// 播放在线音频 UseCase
class PlayOnlineAudioUseCase implements PlayAudioUseCase {
  final Audio audio;
  final String? streamUrl;
  final String? proxyUrl;

  PlayOnlineAudioUseCase({
    required this.audio,
    this.streamUrl,
    this.proxyUrl,
  });

  @override
  Future<Either<Failure, void>> execute() async {
    try {
      // 实际的播放逻辑由 Provider 层实现
      // UseCase 层只定义契约
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.internalError(message: e.toString()));
    }
  }
}
