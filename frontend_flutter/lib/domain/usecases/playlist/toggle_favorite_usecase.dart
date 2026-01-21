import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/playlist_repository.dart';
import '../base_usecase.dart';

/// 切换收藏用例
///
/// 负责切换音频收藏状态的业务逻辑
class ToggleFavoriteUseCase extends UseCase<bool, ToggleFavoriteParams> {
  final PlaylistRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(ToggleFavoriteParams params) async {
    // 参数验证
    if (params.userId.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '用户ID不能为空',
      ));
    }

    if (params.bvid.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '视频ID不能为空',
      ));
    }

    // 检查是否已收藏
    final checkResult = await _repository.isFavorited(
      userId: params.userId,
      bvid: params.bvid,
    );

    return checkResult.fold(
      (failure) => Left(failure),
      (isFavorited) async {
        // 如果已收藏，询问是否取消；否则直接添加
        // 这里返回 true 表示添加，false 表示移除
        return _repository.toggleFavorite(
          userId: params.userId,
          bvid: params.bvid,
          title: params.title,
          artist: params.artist,
          duration: params.duration,
        );
      },
    );
  }
}

/// 切换收藏参数
class ToggleFavoriteParams {
  final String userId;
  final String bvid;
  final String? title;
  final String? artist;
  final int? duration;

  const ToggleFavoriteParams({
    required this.userId,
    required this.bvid,
    this.title,
    this.artist,
    this.duration,
  });
}
