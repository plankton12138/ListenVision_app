import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';

/// 移除歌单项 UseCase
class RemovePlaylistItemUseCase extends BaseUseCase<void, RemovePlaylistItemParams> {
  final PlaylistRepository repository;

  RemovePlaylistItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemovePlaylistItemParams params) {
    return repository.removePlaylistItem(
      playlistId: params.playlistId,
      bvid: params.bvid,
    );
  }
}

/// 移除歌单项参数
class RemovePlaylistItemParams {
  final String playlistId;
  final String bvid;

  const RemovePlaylistItemParams({
    required this.playlistId,
    required this.bvid,
  });
}
