import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/entities/playlist.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';

/// 更新歌单 UseCase
class UpdatePlaylistUseCase extends BaseUseCase<Playlist, UpdatePlaylistParams> {
  final PlaylistRepository repository;

  UpdatePlaylistUseCase(this.repository);

  @override
  Future<Either<Failure, Playlist>> call(UpdatePlaylistParams params) {
    return repository.updatePlaylist(
      playlistId: params.playlistId,
      name: params.name,
      description: params.description,
      coverUrl: params.coverUrl,
      isPublic: params.isPublic,
    );
  }
}

/// 更新歌单参数
class UpdatePlaylistParams {
  final String playlistId;
  final String? name;
  final String? description;
  final String? coverUrl;
  final bool? isPublic;

  const UpdatePlaylistParams({
    required this.playlistId,
    this.name,
    this.description,
    this.coverUrl,
    this.isPublic,
  });
}
