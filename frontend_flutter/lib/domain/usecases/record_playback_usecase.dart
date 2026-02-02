import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/playable_audio.dart';
import '../repositories/play_history_repository.dart';

/// 记录播放历史 UseCase
///
/// Clean Architecture 中的用例层
/// 负责协调播放历史记录的业务逻辑
class RecordPlaybackUseCase {
  final PlayHistoryRepository _repository;

  RecordPlaybackUseCase(this._repository);

  /// 执行记录播放历史
  ///
  /// [userId] 用户 ID
  /// [playable] 播放的音频对象
  /// [progress] 播放进度（秒）
  /// [duration] 音频时长（秒）
  Future<Either<Failure, bool>> execute({
    required String userId,
    required PlayableAudio playable,
    int progress = 0,
    int? duration,
  }) async {
    // 提取音频信息
    final String audioId;
    final String? coverUrl;

    if (playable.isOnline) {
      // 在线音频使用 ID
      audioId = playable.id;
      coverUrl = null; // 在线音频的封面 URL 在服务端获取
    } else {
      // 本地音频使用文件路径作为 ID
      audioId = 'local_${playable.id}';
      coverUrl = null;
    }

    return await _repository.recordPlay(
      userId: userId,
      audioId: audioId,
      title: playable.title,
      artist: playable.artist,
      duration: duration,
      progress: progress,
      coverUrl: coverUrl,
    );
  }
}
