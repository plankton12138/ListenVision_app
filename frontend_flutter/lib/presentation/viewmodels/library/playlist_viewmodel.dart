import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../models/audio.dart';
import '../../../models/cached_track.dart';
import '../../../models/local_audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/playlist.dart';
import '../../../models/online_playable.dart';
import '../../../models/queue_source.dart';
import '../player/queue_viewmodel.dart';

part 'playlist_viewmodel.freezed.dart';
part 'playlist_viewmodel.g.dart';

/// 歌单状态
@freezed
abstract class PlaylistState with _$PlaylistState {
  /// 初始状态
  const factory PlaylistState.initial() = PlaylistStateInitial;

  /// 已加载
  const factory PlaylistState.loaded({
    required List<Playlist> playlists,
    required List<Playlist> userPlaylists,
    required List<Playlist> systemPlaylists,
    Playlist? favoritesPlaylist,
    Playlist? nowPlayingPlaylist,
    @Default([]) List<PlaylistItem> favoritesItems,
    @Default([]) List<PlaylistItem> nowPlayingItems,
  }) = PlaylistStateLoaded;

  /// 错误
  const factory PlaylistState.error({required String message}) =
      PlaylistStateError;
}

/// 歌单管理 ViewModel（Riverpod 3.0 AsyncNotifier 模式）
///
/// 负责歌单、收藏、播放队列的状态管理
@Riverpod(keepAlive: true)
class PlaylistViewModel extends _$PlaylistViewModel {
  PlaylistRepository? _repository;
  SharedStorageService? _storage;

  /// 收藏缓存（用于快速检查）
  final Set<String> _favoritedBvids = {};

  /// 当前正在查看的歌单ID
  String? _currentPlaylistId;

  String? get currentPlaylistId => _currentPlaylistId;

  @override
  Future<PlaylistState> build() async {
    _repository = ref.watch(playlistRepositoryProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    try {
      AppLogger.info('PlaylistViewModel', '初始化歌单管理');
      await _loadPlaylists();
      await _loadFavoritesFromLocal();
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '初始化失败: $e');
    }

    return state.valueOrNull ?? const PlaylistState.initial();
  }

  /// 从本地加载歌单列表
  Future<void> loadPlaylists() async {
    state = const AsyncLoading();
    await _loadPlaylists();
  }

  Future<PlaylistState> _loadPlaylists() async {
    try {
      final playlists = await _repository!.getUserPlaylists();

      // 分离系统歌单和用户歌单
      final systemPlaylists = playlists.where((p) => p.isSystem).toList();
      final userPlaylists = playlists.where((p) => p.isUserPlaylist).toList();

      // 查找系统歌单
      final favoritesPlaylist = systemPlaylists.firstWhere(
        (p) => p.isFavorites,
        orElse: () => Playlist.favorites,
      );

      final nowPlayingPlaylist = systemPlaylists.firstWhere(
        (p) => p.isNowPlaying,
        orElse: () => Playlist.nowPlaying,
      );

      // 保留当前列表数据
      final currentFavorites = state.valueOrNull?.favoritesItems ?? [];
      final currentNowPlaying = state.valueOrNull?.nowPlayingItems ?? [];

      final newState = PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        favoritesPlaylist: favoritesPlaylist,
        nowPlayingPlaylist: nowPlayingPlaylist,
        favoritesItems: currentFavorites,
        nowPlayingItems: currentNowPlaying,
      );

      if (!ref.mounted) return newState;
      state = AsyncData(newState);

      AppLogger.info('PlaylistViewModel', '加载歌单成功: ${playlists.length}个');
      return newState;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载歌单失败: $e');
      // 尝试从本地加载
      return await _loadPlaylistsFromLocal();
    }
  }

  /// 从本地加载收藏列表
  Future<void> loadFavorites() async {
    await _loadFavoritesFromLocal();
  }

  /// 加载播放队列
  Future<void> loadNowPlaying() async {
    try {
      final nowPlayingId = state.valueOrNull?.nowPlayingPlaylist?.id;
      if (nowPlayingId == null) return;

      final items = await _repository!.getPlaylistItems(nowPlayingId);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        final newState = PlaylistState.loaded(
          playlists: currentState.playlists,
          userPlaylists: currentState.userPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: items,
        );

        if (!ref.mounted) return;
        state = AsyncData(newState);

        if (items.isNotEmpty) {
          final queue = <PlayableAudio>[];
          for (final item in items) {
            if (item.bvid.startsWith('local_')) {
              if (item.localPath != null && item.localPath!.isNotEmpty) {
                final localAudio = LocalAudio(
                  filePath: item.localPath!,
                  title: item.title ?? '未知标题',
                  artist: item.artist ?? '未知艺术家',
                  duration: item.duration ?? 0,
                );
                queue.add(LocalPlayable(localAudio));
              } else {
                AppLogger.warn(
                  'PlaylistViewModel',
                  '跳过无本地路径的播放队列项: ${item.bvid}',
                );
              }
            } else {
              queue.add(OnlinePlayable.fromPlaylistItem(item));
            }
          }

          if (queue.isNotEmpty) {
            await ref
                .read(queueViewModelProvider.notifier)
                .setQueueFromPlaylist(
                  queue,
                  QueueSource.nowPlaying(),
                  initialIndex: 0,
                );
            AppLogger.info(
              'PlaylistViewModel',
              '已同步播放队列到 QueueViewModel: ${queue.length}个',
            );
          }
        }
      }

      AppLogger.info('PlaylistViewModel', '加载播放队列成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '加载播放队列失败: $e');
    }
  }

  /// 保存播放队列到后端
  ///
  /// 由 QueueViewModel 在队列变更时调用
  Future<void> saveNowPlayingQueue(List<PlaylistItem> items) async {
    try {
      AppLogger.info('PlaylistViewModel', '保存播放队列: ${items.length}个');
      await _repository!.saveNowPlaying(items);
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存播放队列失败: $e');
      // 不抛出错误，避免影响 UI
    }
  }

  /// 保存播放队列到后端（接受 Map 列表）
  ///
  /// 由 QueueViewModel 在队列变更时调用
  Future<void> saveNowPlayingQueueFromItems(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      AppLogger.info('PlaylistViewModel', '保存播放队列: ${items.length}个');

      // 转换为 PlaylistItem 列表
      final playlistItems = items
          .map(
            (item) => PlaylistItem(
              bvid: item['bvid'] as String,
              title: item['title'] as String?,
              artist: item['artist'] as String?,
              albumTitle: item["albumTitle"] as String?,
              duration: item['duration'] as int?,
              coverUrl: item['coverUrl'] as String?,
              position: 0,
            ),
          )
          .toList();

      await _repository!.saveNowPlaying(playlistItems);
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存播放队列失败: $e');
      // 不抛出错误，避免影响 UI
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '创建歌单: $name');

      final newPlaylist = await _repository!.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      final currentState = state.valueOrNull;
      if (currentState is PlaylistStateLoaded && newPlaylist != null) {
        final newState = currentState.copyWith(
          playlists: [...currentState.playlists, newPlaylist],
          userPlaylists: [
            ...currentState.userPlaylists.whereType<Playlist>(),
            newPlaylist,
          ],
        );

        if (!ref.mounted) return newPlaylist;
        state = AsyncData(newState);
      }

      if (newPlaylist != null) {
        AppLogger.info('PlaylistViewModel', '创建歌单成功: ${newPlaylist.id}');
      }
      return newPlaylist;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '创建歌单失败: $e');
      return null;
    }
  }

  /// 更新歌单
  Future<bool> updatePlaylist(
    String id, {
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '更新歌单: $id');

      final updatedPlaylist = await _repository!.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );

      final currentState = state.valueOrNull;
      if (currentState != null && updatedPlaylist != null) {
        final updatedPlaylists = currentState.playlists.map((p) {
          return p.id == id ? updatedPlaylist : p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          return p.id == id ? updatedPlaylist : p;
        }).toList();

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist?.id == id
              ? updatedPlaylist
              : currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist?.id == id
              ? updatedPlaylist
              : currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      if (updatedPlaylist != null) {
        AppLogger.info('PlaylistViewModel', '更新歌单成功: $id');
      }
      return updatedPlaylist != null;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '更新歌单失败: $e');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String id) async {
    try {
      AppLogger.info('PlaylistViewModel', '删除歌单: $id');

      await _repository!.deletePlaylist(id);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedPlaylists = currentState.playlists
            .where((p) => p.id != id)
            .toList();
        final updatedUserPlaylists = currentState.userPlaylists
            .where((p) => p.id != id)
            .toList();

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: currentState.systemPlaylists,
          favoritesPlaylist: currentState.favoritesPlaylist?.id == id
              ? null
              : currentState.favoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist?.id == id
              ? null
              : currentState.nowPlayingPlaylist,
          favoritesItems: currentState.favoritesItems,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '删除歌单失败: $e');
      return false;
    }
  }

  /// 添加音频到歌单
  Future<bool> addItem(
    String playlistId,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '添加音频到歌单: $bvid -> $playlistId');

      await _repository!.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        title: title,
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
        position: position,
      );

      final currentState = state.valueOrNull;
      if (currentState != null) {
        // 更新歌单的itemCount
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: p.itemCount + 1);
          }
          return p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: p.itemCount + 1);
          }
          return p;
        }).toList();

        List<PlaylistItem> updatedFavorites = currentState.favoritesItems;
        Playlist? updatedFavoritesPlaylist = currentState.favoritesPlaylist;
        List<Playlist> updatedSystemPlaylists = currentState.systemPlaylists;

        if (playlistId == currentState.favoritesPlaylist?.id) {
          final newItem = PlaylistItem(
            bvid: bvid,
            title: title,
            artist: artist,
            duration: duration,
            coverUrl: coverUrl,
            position: currentState.favoritesItems.length,
            addedAt: DateTime.now(),
          );
          updatedFavorites = [...currentState.favoritesItems, newItem];
          _favoritedBvids.add(bvid);
          _saveFavoritesToLocal();

          // 同步更新 favoritesPlaylist 的 itemCount
          updatedFavoritesPlaylist = currentState.favoritesPlaylist?.copyWith(
                itemCount: updatedFavorites.length,
              ) ??
              Playlist.favorites.copyWith(itemCount: updatedFavorites.length);

          // 更新 systemPlaylists 中的 favorites playlist
          updatedSystemPlaylists = currentState.systemPlaylists.map((p) {
            if (p.isFavorites) {
              return updatedFavoritesPlaylist!;
            }
            return p;
          }).toList();
        }

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: updatedSystemPlaylists,
          favoritesPlaylist: updatedFavoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: updatedFavorites,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '添加音频到歌单成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '添加音频到歌单失败: $e');
      return false;
    }
  }

  /// 从歌单移除音频
  Future<bool> removeItem(String playlistId, String bvid) async {
    try {
      AppLogger.info('PlaylistViewModel', '从歌单移除音频: $bvid from $playlistId');

      await _repository!.removePlaylistItem(playlistId: playlistId, bvid: bvid);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        // 更新歌单的itemCount
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
          }
          return p;
        }).toList();

        final updatedUserPlaylists = currentState.userPlaylists.map((p) {
          if (p.id == playlistId) {
            return p.copyWith(itemCount: (p.itemCount - 1).clamp(0, 999999));
          }
          return p;
        }).toList();

        List<PlaylistItem> updatedFavorites = currentState.favoritesItems;
        Playlist? updatedFavoritesPlaylist = currentState.favoritesPlaylist;
        List<Playlist> updatedSystemPlaylists = currentState.systemPlaylists;

        if (playlistId == currentState.favoritesPlaylist?.id) {
          updatedFavorites = currentState.favoritesItems
              .where((item) => item.bvid != bvid)
              .toList();
          _favoritedBvids.remove(bvid);
          _saveFavoritesToLocal();

          // 同步更新 favoritesPlaylist 的 itemCount
          updatedFavoritesPlaylist = currentState.favoritesPlaylist?.copyWith(
                itemCount: updatedFavorites.length,
              ) ??
              Playlist.favorites.copyWith(itemCount: updatedFavorites.length);

          // 更新 systemPlaylists 中的 favorites playlist
          updatedSystemPlaylists = currentState.systemPlaylists.map((p) {
            if (p.isFavorites) {
              return updatedFavoritesPlaylist!;
            }
            return p;
          }).toList();
        }

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: updatedUserPlaylists,
          systemPlaylists: updatedSystemPlaylists,
          favoritesPlaylist: updatedFavoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: updatedFavorites,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return true;
        state = AsyncData(newState);
      }

      AppLogger.info('PlaylistViewModel', '从歌单移除音频成功');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从歌单移除音频失败: $e');
      return false;
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
  }) async {
    try {
      AppLogger.info('PlaylistViewModel', '切换收藏状态: $bvid');

      final wasAlreadyFavorited = isFavorited(bvid);
      final target = !wasAlreadyFavorited;
      final incomingTitle = title?.trim();
      final incomingArtist = artist?.trim();

      // 1) 确保 Track 存在（离线可用：使用传入的基础信息写入本地）
      final trackDao = ref.read(trackDaoProvider);
      final isLocal = bvid.startsWith('local_');

      var track = await trackDao.getBySourceId(bvid);
      if (track == null) {
        if (isLocal) {
          final resolvedPath = (localPath != null && localPath.trim().isNotEmpty)
              ? localPath.trim()
              : '';

          if (resolvedPath.isNotEmpty) {
            track = await trackDao.saveFromLocalAudio(
              LocalAudio(
                filePath: resolvedPath,
                title: (incomingTitle != null && incomingTitle.isNotEmpty)
                    ? incomingTitle
                    : '未知标题',
                artist: (incomingArtist != null && incomingArtist.isNotEmpty)
                    ? incomingArtist
                    : '未知艺术家',
                duration: duration ?? 0,
              ),
            );
          }
        }

        // 在线音频 / 或无法解析本地路径时的兜底写入
        track ??= await trackDao.saveFromAudio(
          Audio(
            id: bvid,
            title: (incomingTitle != null && incomingTitle.isNotEmpty)
                ? incomingTitle
                : '未知标题',
            artist: (incomingArtist != null && incomingArtist.isNotEmpty)
                ? incomingArtist
                : null,
            duration: duration,
            coverUrl: coverUrl,
          ),
        );
      } else if (isLocal) {
        // 修复历史脏数据：本地 track 可能缺 local_path / source_type
        final shouldFixLocalPath =
            (track.localPath == null || track.localPath!.isEmpty) &&
                (localPath != null && localPath.trim().isNotEmpty);
        final shouldFixSourceType = track.sourceType != TrackSource.local;
        final shouldFixBvid = track.bvid != bvid;

        if (shouldFixLocalPath || shouldFixSourceType || shouldFixBvid) {
          final updatedTrack = track.copyWith(
            localPath: shouldFixLocalPath ? localPath.trim() : track.localPath,
            sourceType: shouldFixSourceType ? TrackSource.local : track.sourceType,
            bvid: shouldFixBvid ? bvid : track.bvid,
            isDownloaded: true,
          );
          await trackDao.update(updatedTrack);
          track = updatedTrack;
        }
      }

      // 优先补写默认元数据，避免收藏列表长期显示“未知标题/未知艺术家”
      final shouldBackfillTitle = (track.title == '未知标题') &&
          (incomingTitle != null && incomingTitle.isNotEmpty);
      final shouldBackfillArtist =
          ((track.artist == null ||
                  track.artist!.isEmpty ||
                  track.artist == '未知艺术家') &&
              (incomingArtist != null && incomingArtist.isNotEmpty));
      final shouldBackfillDuration =
          (track.duration == null && duration != null && duration > 0);
      final shouldBackfillCover =
          ((track.coverUrl == null || track.coverUrl!.isEmpty) &&
              (coverUrl != null && coverUrl.isNotEmpty));

      if (shouldBackfillTitle ||
          shouldBackfillArtist ||
          shouldBackfillDuration ||
          shouldBackfillCover) {
        final updatedTrack = track.copyWith(
          title: shouldBackfillTitle ? incomingTitle : track.title,
          artist: shouldBackfillArtist ? incomingArtist : track.artist,
          duration: shouldBackfillDuration ? duration : track.duration,
          coverUrl: shouldBackfillCover ? coverUrl : track.coverUrl,
        );
        await trackDao.update(updatedTrack);
        track = updatedTrack;
      }

      // 2) 本地优先：写入 tracks.is_favorite，并入队同步任务
      final trackRepo = ref.read(trackRepositoryProvider);
      await trackRepo.toggleFavorite(
        track.id,
        target,
        title: incomingTitle ?? track.title,
        artist: incomingArtist ?? track.artist,
        duration: duration ?? track.duration,
        coverUrl: coverUrl ?? track.coverUrl,
      );

      // 3) 刷新本地“我喜欢”列表（以本地 DB 为真值）
      await _loadFavoritesFromLocal();

      AppLogger.info('PlaylistViewModel', '切换收藏状态成功: $bvid, target=$target');
      return target;
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '切换收藏状态失败: $e');
      return false;
    }
  }

  /// 检查是否已收藏
  bool isFavorited(String bvid) {
    return _favoritedBvids.contains(bvid) ||
        (state.valueOrNull?.favoritesItems.any((item) => item.bvid == bvid) ??
            false);
  }

  /// 设置当前正在查看的歌单ID
  void setCurrentPlaylistId(String? playlistId) {
    _currentPlaylistId = playlistId;
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    _favoritedBvids.clear();
    _currentPlaylistId = null;

    await _storage!.remove('playlists_cache');
    await _storage!.remove('favorites_cache');

    if (!ref.mounted) return;
    state = const AsyncData(PlaylistState.initial());

    AppLogger.info('PlaylistViewModel', '已清空数据');
  }

  // ==================== 私有方法 ====================

  Future<PlaylistState> _loadPlaylistsFromLocal() async {
    try {
      final playlistsJson = _storage!.getString('playlists_cache');
      if (playlistsJson != null) {
        final data = jsonDecode(playlistsJson) as List;
        final playlists = data
            .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
            .toList();

        final systemPlaylists = playlists.where((p) => p.isSystem).toList();
        final userPlaylists = playlists.where((p) => p.isUserPlaylist).toList();

        final favoritesPlaylist = systemPlaylists.firstWhere(
          (p) => p.isFavorites,
          orElse: () => Playlist.favorites,
        );

        final nowPlayingPlaylist = systemPlaylists.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => Playlist.nowPlaying,
        );

        return PlaylistState.loaded(
          playlists: playlists,
          userPlaylists: userPlaylists,
          systemPlaylists: systemPlaylists,
          favoritesPlaylist: favoritesPlaylist,
          nowPlayingPlaylist: nowPlayingPlaylist,
          favoritesItems: const [],
          nowPlayingItems: const [],
        );
      }

      return const PlaylistState.initial();
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载歌单失败: $e');
      return const PlaylistState.initial();
    }
  }

  Future<void> _loadFavoritesFromLocal() async {
    try {
      // 以本地 tracks.is_favorite 为真值来源
      final trackDao = ref.read(trackDaoProvider);
      final tracks = await trackDao.getFavoriteTracks();

      final favoritesPlaylistId = state.valueOrNull?.favoritesPlaylist?.id ?? Playlist.favorites.id;
      final items = <PlaylistItem>[];
      for (var i = 0; i < tracks.length; i++) {
        final t = tracks[i];
        final bvid = t.bvid ?? t.sourceId;

        // 改进本地音频的元数据显示：如果标题是默认值，尝试从文件名提取
        var title = t.title;
        var artist = t.artist;
        if (t.localPath != null && t.localPath!.isNotEmpty) {
          if (title == '未知标题' || title.isEmpty) {
            // 从文件路径提取文件名（不含扩展名）作为标题
            final fileName = path.basenameWithoutExtension(t.localPath!);
            title = fileName.isNotEmpty ? fileName : '未知标题';
          }
          if (artist == null || artist.isEmpty || artist == '未知艺术家') {
            artist = '未知艺术家';
          }
        }

        items.add(
          PlaylistItem(
            playlistId: favoritesPlaylistId,
            bvid: bvid,
            title: title,
            artist: artist,
            duration: t.duration,
            coverUrl: t.coverUrl,
            localPath: t.localPath,
            position: i,
            addedAt: t.addedAt,
          ),
        );
      }

      final currentState = state.valueOrNull;
      if (currentState != null) {
        // 同步更新 favoritesPlaylist 的 itemCount 为实际 items 数量
        final updatedFavoritesPlaylist = currentState.favoritesPlaylist?.copyWith(
              itemCount: items.length,
            ) ??
            Playlist.favorites.copyWith(itemCount: items.length);

        // 更新 systemPlaylists 中的 favorites playlist
        final updatedSystemPlaylists = currentState.systemPlaylists.map((p) {
          if (p.isFavorites) {
            return updatedFavoritesPlaylist;
          }
          return p;
        }).toList();

        // 更新 playlists 中的 favorites playlist
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.isFavorites) {
            return updatedFavoritesPlaylist;
          }
          return p;
        }).toList();

        final newState = PlaylistState.loaded(
          playlists: updatedPlaylists,
          userPlaylists: currentState.userPlaylists,
          systemPlaylists: updatedSystemPlaylists,
          favoritesPlaylist: updatedFavoritesPlaylist,
          nowPlayingPlaylist: currentState.nowPlayingPlaylist,
          favoritesItems: items,
          nowPlayingItems: currentState.nowPlayingItems,
        );

        if (!ref.mounted) return;
        state = AsyncData(newState);
      }

      _updateFavoritedCache();
      await _saveFavoritesToLocal();

      AppLogger.info('PlaylistViewModel', '从本地 tracks 加载收藏成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '从本地加载收藏失败: $e');
    }
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final json = jsonEncode(
        state.valueOrNull?.favoritesItems.map((f) => f.toJson()).toList() ?? [],
      );
      await _storage!.setString('favorites_cache', json);
    } catch (e) {
      AppLogger.error('PlaylistViewModel', '保存本地收藏失败: $e');
    }
  }

  void _updateFavoritedCache() {
    _favoritedBvids.clear();
    for (final item in state.valueOrNull?.favoritesItems ?? []) {
      _favoritedBvids.add(item.bvid);
    }
  }
}

/// PlaylistState 扩展方法，方便访问属性
extension PlaylistStateX on PlaylistState {
  List<Playlist> get playlists => maybeWhen(
    loaded: (playlists, _, __, ___, ____, _____, ______) => playlists,
    orElse: () => const [],
  );

  List<Playlist> get userPlaylists => maybeWhen(
    loaded: (_, userPlaylists, __, ___, ____, _____, ______) => userPlaylists,
    orElse: () => const [],
  );

  List<Playlist> get systemPlaylists => maybeWhen(
    loaded: (_, __, systemPlaylists, ___, ____, _____, ______) =>
        systemPlaylists,
    orElse: () => const [],
  );

  Playlist? get favoritesPlaylist => maybeWhen(
    loaded: (_, __, ___, favorites, ____, _____, ______) => favorites,
    orElse: () => null,
  );

  Playlist? get nowPlayingPlaylist => maybeWhen(
    loaded: (_, __, ___, ____, nowPlaying, _____, ______) => nowPlaying,
    orElse: () => null,
  );

  List<PlaylistItem> get favoritesItems => maybeWhen(
    loaded: (_, __, ___, ____, _____, favoritesItems, ______) => favoritesItems,
    orElse: () => const [],
  );

  List<PlaylistItem> get nowPlayingItems => maybeWhen(
    loaded: (_, __, ___, ____, _____, ______, nowPlayingItems) =>
        nowPlayingItems,
    orElse: () => const [],
  );
}

/// Provider定义
@riverpod
PlaylistRepository playlistRepository(Ref ref) {
  return PlaylistRepository();
}

@riverpod
SharedStorageService sharedStorageService(Ref ref) {
  return SharedStorageService.instance;
}
