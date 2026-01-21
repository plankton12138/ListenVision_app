import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/bilibili_repository.dart';
import '../base_usecase.dart';
import '../../entities/audio.dart';

/// 获取音频信息用例
///
/// 负责获取音频元数据的业务逻辑
class GetAudioInfoUseCase extends UseCase<Audio, GetAudioParams> {
  final BilibiliRepository _repository;

  GetAudioInfoUseCase(this._repository);

  @override
  Future<Either<Failure, Audio>> call(GetAudioParams params) async {
    // 参数验证
    if (params.bvid.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: 'BV号不能为空',
      ));
    }

    // BV号格式验证
    final bvidRegex = RegExp(r'^BV[\w]{10}$');
    if (!bvidRegex.hasMatch(params.bvid)) {
      return const Left(DataFailure.invalidData(
        message: 'BV号格式不正确',
      ));
    }

    // 调用仓储获取音频信息
    return _repository.getAudioInfo(
      bvid: params.bvid,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// 获取音频参数
class GetAudioParams {
  final String bvid;
  final bool forceRefresh;

  const GetAudioParams({
    required this.bvid,
    this.forceRefresh = false,
  });
}

/// 获取音频流用例
class GetAudioStreamUseCase extends UseCase<String, String> {
  final BilibiliRepository _repository;

  GetAudioStreamUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(String bvid) async {
    if (bvid.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: 'BV号不能为空',
      ));
    }

    return _repository.getAudioStream(bvid: bvid);
  }
}
