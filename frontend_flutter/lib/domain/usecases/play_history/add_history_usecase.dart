import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/play_history_repository.dart';
import '../base_usecase.dart';

/// 添加播放历史用例
///
/// 负责记录用户播放历史
class AddHistoryUseCase extends UseCase<bool, AddHistoryParams> {
  final PlayHistoryRepository _repository;

  AddHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(AddHistoryParams params) async {
    // 参数验证
    if (params.userId.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '用户ID不能为空',
      ));
    }

    if (params.audioId.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '音频ID不能为空',
      ));
    }

    if (params.title.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '音频标题不能为空',
      ));
    }

    // 进度范围验证
    if (params.progress < 0) {
      return const Left(DataFailure.invalidData(
        message: '播放进度不能为负数',
      ));
    }

    // 调用仓储记录播放
    final result = await _repository.recordPlay(
      userId: params.userId,
      audioId: params.audioId,
      title: params.title,
      artist: params.artist,
      duration: params.duration,
      progress: params.progress,
      coverUrl: params.coverUrl,
    );

    return result;
  }
}

/// 添加播放历史参数
class AddHistoryParams {
  final String userId;
  final String audioId;
  final String title;
  final String? artist;
  final int? duration;
  final int progress;
  final String? coverUrl;

  const AddHistoryParams({
    required this.userId,
    required this.audioId,
    required this.title,
    this.artist,
    this.duration,
    this.progress = 0,
    this.coverUrl,
  });
}
