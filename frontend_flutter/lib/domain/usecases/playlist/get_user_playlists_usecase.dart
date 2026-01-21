import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/playlist_repository.dart';
import '../base_usecase.dart';
import '../../entities/playlist.dart';

/// 获取用户歌单用例
///
/// 负责获取用户所有歌单的业务逻辑
class GetUserPlaylistsUseCase extends UseCase<List<Playlist>, GetPlaylistsParams> {
  final PlaylistRepository _repository;

  GetUserPlaylistsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Playlist>>> call(GetPlaylistsParams params) async {
    // 参数验证
    if (params.userId.isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '用户ID不能为空',
      ));
    }

    // 调用仓储获取歌单
    return _repository.getUserPlaylists(
      userId: params.userId,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// 获取歌单参数
class GetPlaylistsParams {
  final String userId;
  final bool forceRefresh;

  const GetPlaylistsParams({
    required this.userId,
    this.forceRefresh = false,
  });
}
