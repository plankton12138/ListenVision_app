import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/play_history.dart';
import '../repositories/play_history_repository.dart';

/// 获取播放历史 UseCase
///
/// Clean Architecture 中的用例层
/// 负责协调获取播放历史的业务逻辑
class GetPlayHistoryUseCase {
  final PlayHistoryRepository _repository;

  GetPlayHistoryUseCase(this._repository);

  /// 执行获取播放历史
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量限制
  /// [offset] 偏移量
  Future<Either<Failure, List<PlayHistory>>> execute({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    return await _repository.getHistory(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}

/// 获取最近播放 UseCase
class GetRecentPlaysUseCase {
  final PlayHistoryRepository _repository;

  GetRecentPlaysUseCase(this._repository);

  /// 执行获取最近播放
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量
  Future<Either<Failure, List<PlayHistory>>> execute({
    required String userId,
    int limit = 10,
  }) async {
    return await _repository.getRecentPlays(
      userId: userId,
      limit: limit,
    );
  }
}

/// 获取最常播放 UseCase
class GetMostPlayedUseCase {
  final PlayHistoryRepository _repository;

  GetMostPlayedUseCase(this._repository);

  /// 执行获取最常播放
  ///
  /// [userId] 用户 ID
  /// [limit] 返回数量
  Future<Either<Failure, List<PlayHistory>>> execute({
    required String userId,
    int limit = 10,
  }) async {
    return await _repository.getMostPlayed(
      userId: userId,
      limit: limit,
    );
  }
}
