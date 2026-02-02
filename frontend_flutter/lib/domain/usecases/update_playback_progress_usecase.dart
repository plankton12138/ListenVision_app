import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/play_history_repository.dart';

/// 更新播放进度 UseCase
///
/// Clean Architecture 中的用例层
/// 负责协调更新播放进度的业务逻辑
class UpdatePlaybackProgressUseCase {
  final PlayHistoryRepository _repository;

  UpdatePlaybackProgressUseCase(this._repository);

  /// 执行更新播放进度
  ///
  /// [historyId] 历史记录 ID
  /// [progress] 新的播放进度（秒）
  Future<Either<Failure, bool>> execute({
    required String historyId,
    required int progress,
  }) async {
    return await _repository.updateProgress(
      historyId: historyId,
      progress: progress,
    );
  }
}
