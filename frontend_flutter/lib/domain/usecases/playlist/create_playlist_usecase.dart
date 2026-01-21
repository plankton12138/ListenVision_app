import 'package:dartz/dartz.dart';
import 'package:demo/core/errors/failures.dart';
import 'package:demo/domain/usecases/base_usecase.dart';
import 'package:demo/domain/entities/playlist.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';

/// 创建歌单 UseCase
class CreatePlaylistUseCase extends BaseUseCase<Playlist, CreatePlaylistParams> {
  final PlaylistRepository repository;

  CreatePlaylistUseCase(this.repository);

  @override
  Future<Either<Failure, Playlist>> call(CreatePlaylistParams params) {
    return repository.createPlaylist(
      name: params.name,
      description: params.description,
      coverUrl: params.coverUrl,
      isPublic: params.isPublic,
    );
  }
}

/// 创建歌单参数
class CreatePlaylistParams {
  final String name;
  final String? description;
  final String? coverUrl;
  final bool isPublic;

  const CreatePlaylistParams({
    required this.name,
    this.description,
    this.coverUrl,
    this.isPublic = false,
  });
}
