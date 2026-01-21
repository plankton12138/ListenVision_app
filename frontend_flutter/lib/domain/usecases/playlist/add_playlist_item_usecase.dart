import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';

/// 添加歌单项 UseCase
class AddPlaylistItemUseCase extends BaseUseCase<void, AddPlaylistItemParams> {
  final PlaylistRepository repository;

  AddPlaylistItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddPlaylistItemParams params) {
    return repository.addPlaylistItem(
      playlistId: params.playlistId,
      bvid: params.bvid,
      position: params.position,
    );
  }
}

/// 添加歌单项参数
class AddPlaylistItemParams {
  final String playlistId;
  final String bvid;
  final int position;

  const AddPlaylistItemParams({
    required this.playlistId,
    required this.bvid,
    required this.position,
  });
}
