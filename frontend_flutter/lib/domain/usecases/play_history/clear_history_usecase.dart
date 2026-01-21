import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/play_history_repository.dart';
import '../base_usecase.dart';

/// 清空播放历史用例
///
/// 负责清空用户所有播放历史记录
class ClearHistoryUseCase extends UseCase<bool, ClearHistoryParams> {
  final PlayHistoryRepository _repository;

  ClearHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(ClearHistoryParams params) async {
    // 参数验证
    if (params.userId.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '用户ID不能为空',
      ));
    }

    // 调用仓储清空历史
    final result = await _repository.clearHistory(
      userId: params.userId,
    );

    return result;
  }
}

/// 清空播放历史参数
class ClearHistoryParams {
  final String userId;

  const ClearHistoryParams({
    required this.userId,
  });
}
