import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/playlist.dart';

/// 歌单仓储接口
///
/// Clean Architecture 中的 Repository 接口
/// 管理用户歌单和收藏
abstract class PlaylistRepository {
  // ==================== 歌单管理 ====================

  /// 获取用户所有歌单
  ///
  /// [userId] 用户 ID
  /// [forceRefresh] 是否强制刷新（忽略缓存）
  /// 返回歌单列表
  Future<Either<Failure, List<Playlist>>> getUserPlaylists({
    required String userId,
    bool forceRefresh = false,
  });

  /// 获取歌单详情
  ///
  /// [playlistId] 歌单 ID
  /// 返回歌单详情（包含 items）
  Future<Either<Failure, PlaylistDetail>> getPlaylistDetail({
    required String playlistId,
  });

  /// 创建歌单
  ///
  /// [userId] 用户 ID
  /// [name] 歌单名称
  /// [description] 歌单描述（可选）
  /// [coverUrl] 封面 URL（可选）
  /// 返回创建的歌单
  Future<Either<Failure, Playlist>> createPlaylist({
    required String userId,
    required String name,
    String? description,
    String? coverUrl,
  });

  /// 更新歌单信息
  ///
  /// [playlistId] 歌单 ID
  /// [name] 新名称（可选）
  /// [description] 新描述（可选）
  /// [coverUrl] 新封面 URL（可选）
  /// 返回更新后的歌单
  Future<Either<Failure, Playlist>> updatePlaylist({
    required String playlistId,
    String? name,
    String? description,
    String? coverUrl,
  });

  /// 删除歌单
  ///
  /// [playlistId] 歌单 ID
  /// 返回删除是否成功
  Future<Either<Failure, bool>> deletePlaylist({
    required String playlistId,
  });

  // ==================== 歌单项管理 ====================

  /// 添加音频到歌单
  ///
  /// [playlistId] 歌单 ID
  /// [bvid] 视频 BV 号
  /// [title] 音频标题
  /// [artist] 艺术家
  /// [duration] 时长（秒）
  /// [coverUrl] 封面 URL（可选）
  /// 返回添加是否成功
  Future<Either<Failure, bool>> addItem({
    required String playlistId,
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  });

  /// 从歌单移除音频
  ///
  /// [playlistId] 歌单 ID
  /// [bvid] 视频 BV 号
  /// 返回移除是否成功
  Future<Either<Failure, bool>> removeItem({
    required String playlistId,
    required String bvid,
  });

  /// 批量添加音频到歌单
  ///
  /// [playlistId] 歌单 ID
  /// [items] 歌单项列表
  /// 返回添加成功的数量
  Future<Either<Failure, int>> addItems({
    required String playlistId,
    required List<PlaylistItem> items,
  });

  /// 更新歌单项位置
  ///
  /// [playlistId] 歌单 ID
  /// [bvid] 视频 BV 号
  /// [newPosition] 新位置
  /// 返回更新是否成功
  Future<Either<Failure, bool>> updateItemPosition({
    required String playlistId,
    required String bvid,
    required int newPosition,
  });

  // ==================== 收藏管理 ====================

  /// 切换收藏状态
  ///
  /// [userId] 用户 ID
  /// [bvid] 视频 BV 号
  /// [title] 音频标题
  /// [artist] 艺术家
  /// [duration] 时长（秒）
  /// 返回添加（true）或移除（false）
  Future<Either<Failure, bool>> toggleFavorite({
    required String userId,
    required String bvid,
    String? title,
    String? artist,
    int? duration,
  });

  /// 检查是否已收藏
  ///
  /// [userId] 用户 ID
  /// [bvid] 视频 BV 号
  /// 返回是否已收藏
  Future<Either<Failure, bool>> isFavorited({
    required String userId,
    required String bvid,
  });

  /// 获取"我喜欢"歌单
  ///
  /// [userId] 用户 ID
  /// 返回"我喜欢"歌单详情
  Future<Either<Failure, PlaylistDetail>> getFavorites({
    required String userId,
  });

  // ==================== 缓存管理 ====================

  /// 刷新歌单缓存
  ///
  /// [userId] 用户 ID
  /// 重新从服务器获取所有歌单数据
  Future<Either<Failure, List<Playlist>>> refreshPlaylists({
    required String userId,
  });

  /// 清除歌单缓存
  ///
  /// 清除本地缓存的所有歌单数据
  Future<Either<Failure, void>> clearCache();
}
