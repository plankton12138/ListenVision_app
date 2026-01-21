import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';

/// 删除歌单 UseCase
class DeletePlaylistUseCase extends BaseUseCase<void, DeletePlaylistParams> {
  final PlaylistRepository repository;

  DeletePlaylistUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePlaylistParams params) {
    return repository.deletePlaylist(params.playlistId);
  }
}

/// 删除歌单参数
class DeletePlaylistParams {
  final String playlistId;

  const DeletePlaylistParams({required this.playlistId});
}
