import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/data/api/backend_api_client.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/queue_source.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'netease_playlist_detail_page.freezed.dart';
part 'netease_playlist_detail_page.g.dart';

class NeteaseTrack {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String cover;
  final int duration;

  NeteaseTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.cover,
    required this.duration,
  });

  factory NeteaseTrack.fromJson(Map<String, dynamic> json) {
    return NeteaseTrack(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
    );
  }
}

class NeteasePlaylistDetail {
  final String id;
  final String name;
  final String cover;
  final String? description;
  final int playCount;
  final int trackCount;
  final String? creatorName;
  final List<NeteaseTrack> tracks;

  NeteasePlaylistDetail({
    required this.id,
    required this.name,
    required this.cover,
    this.description,
    required this.playCount,
    required this.trackCount,
    this.creatorName,
    required this.tracks,
  });

  factory NeteasePlaylistDetail.fromJson(Map<String, dynamic> json) {
    final tracksData = json['tracks'] as List? ?? [];
    return NeteasePlaylistDetail(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      description: json['description'] as String?,
      playCount: json['playCount'] as int? ?? 0,
      trackCount: json['trackCount'] as int? ?? 0,
      creatorName: json['creator']?['name'] as String?,
      tracks: tracksData.map((t) => NeteaseTrack.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

@freezed
abstract class NeteasePlaylistDetailState with _$NeteasePlaylistDetailState {
  const factory NeteasePlaylistDetailState.initial() = NeteasePlaylistDetailStateInitial;
  const factory NeteasePlaylistDetailState.loading() = NeteasePlaylistDetailStateLoading;
  const factory NeteasePlaylistDetailState.loaded({
    required NeteasePlaylistDetail playlist,
  }) = NeteasePlaylistDetailStateLoaded;
  const factory NeteasePlaylistDetailState.error({
    required String message,
  }) = NeteasePlaylistDetailStateError;
}

@riverpod
class NeteasePlaylistDetailViewModel extends _$NeteasePlaylistDetailViewModel {
  BackendApiClient? _apiClient;

  @override
  Future<NeteasePlaylistDetailState> build(String playlistId) async {
    _apiClient = BackendApiClient();
    return const NeteasePlaylistDetailState.initial();
  }

  Future<bool> loadPlaylist(String id) async {
    try {
      AppLogger.info('NeteasePlaylistDetailViewModel', '加载歌单详情: id=$id');

      if (!ref.mounted) return false;
      state = const AsyncLoading();

      final data = await _apiClient!.getNeteasePlaylistDetail(id);
      final playlist = NeteasePlaylistDetail.fromJson(data);

      if (!ref.mounted) return false;
      state = AsyncData(NeteasePlaylistDetailState.loaded(playlist: playlist));

      AppLogger.info('NeteasePlaylistDetailViewModel', '歌单详情加载成功: ${playlist.name}');
      return true;
    } catch (e) {
      AppLogger.error('NeteasePlaylistDetailViewModel', '加载歌单详情失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

class NeteasePlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;

  const NeteasePlaylistDetailPage({super.key, required this.playlistId});

  @override
  ConsumerState<NeteasePlaylistDetailPage> createState() => _NeteasePlaylistDetailPageState();
}

class _NeteasePlaylistDetailPageState extends ConsumerState<NeteasePlaylistDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(neteasePlaylistDetailViewModelProvider(widget.playlistId).notifier).loadPlaylist(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(neteasePlaylistDetailViewModelProvider(widget.playlistId));

    return Scaffold(
      body: state.when(
        loading: () => _buildLoadingView(),
        error: (e, _) => _buildErrorView(e.toString()),
        data: (detailState) => detailState.when(
          initial: () => _buildLoadingView(),
          loading: () => _buildLoadingView(),
          loaded: (playlist) => _buildContent(playlist),
          error: (message) => _buildErrorView(message),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(neteasePlaylistDetailViewModelProvider(widget.playlistId).notifier).loadPlaylist(widget.playlistId);
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(NeteasePlaylistDetail playlist) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          floating: false,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(playlist),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildActionButtons(playlist),
        ),
        const SliverToBoxAdapter(
          child: Divider(height: 1),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = playlist.tracks[index];
              return _buildTrackItem(track, index);
            },
            childCount: playlist.tracks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(NeteasePlaylistDetail playlist) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red[400]!, Colors.red[700]!],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: playlist.cover.isNotEmpty
                        ? Image.network(
                            playlist.cover,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.library_music, size: 48),
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.library_music, size: 48),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (playlist.creatorName != null)
                          Text(
                            playlist.creatorName!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${playlist.trackCount} 首',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (playlist.description != null && playlist.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  playlist.description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(NeteasePlaylistDetail playlist) {
    if (playlist.tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _playAll(playlist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(NeteaseTrack track, int index) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.cover.isNotEmpty
                  ? Image.network(
                      track.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 24),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 24),
                    ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: Colors.black54,
                child: Text(
                  _formatDuration(track.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () => _playTrack(track, index),
    );
  }

  Future<void> _playAll(NeteasePlaylistDetail playlist) async {
    if (playlist.tracks.isEmpty) return;

    AppLogger.logUserAction(
      'NeteasePlaylistDetailPage',
      '播放全部',
      parameters: {'id': playlist.id, 'name': playlist.name},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('正在加载播放列表...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await _buildPlayablesWithUrls(playlist.tracks);
    final playables = result.playables;

    if (playables.isEmpty) {
      if (mounted) {
        SnackbarHelper.showError(context, '没有可播放的歌曲');
      }
      return;
    }
    final source = QueueSource.neteasePlaylist(
      playlist.id,
      playlist.name,
      coverUrl: playlist.cover,
    );

    await ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
      playables,
      source,
      initialIndex: 0,
    );

    // 使用 PlaybackViewModel 播放
    ref.read(playbackViewModelProvider.notifier).play(playables.first, index: 0);

    if (mounted) {
      final first = playables.first.original;
      SnackbarHelper.showPlaying(context, first.title, artist: first.artist);
    }
  }

  Future<void> _playTrack(NeteaseTrack track, int index) async {
    AppLogger.logUserAction(
      'NeteasePlaylistDetailPage',
      '播放网易云歌曲',
      parameters: {'id': track.id, 'name': track.name},
    );

    try {
      final state = ref.read(neteasePlaylistDetailViewModelProvider(widget.playlistId));
      final playlist = state.value?.maybeWhen(
        loaded: (playlist) => playlist,
        orElse: () => null,
      );

      if (playlist == null || playlist.tracks.isEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, '歌单数据未就绪');
        }
        return;
      }

      final result = await _buildPlayablesWithUrls(
        playlist.tracks,
        selectedId: track.id,
      );
      final playables = result.playables;
      final selectedIndex = result.selectedIndex;

      if (playables.isEmpty || selectedIndex < 0) {
        if (mounted) {
          SnackbarHelper.showError(context, '无法获取播放链接，可能需要VIP');
        }
        return;
      }
      final source = QueueSource.neteasePlaylist(
        playlist.id,
        playlist.name,
        coverUrl: playlist.cover,
      );

      await ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
        playables,
        source,
        initialIndex: selectedIndex,
      );

      // 使用 PlaybackViewModel 播放
      ref.read(playbackViewModelProvider.notifier).play(
        playables[selectedIndex],
        index: selectedIndex,
      );

      if (mounted) {
        SnackbarHelper.showPlaying(context, track.name, artist: track.artist);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  Future<({List<OnlinePlayable> playables, int selectedIndex})> _buildPlayablesWithUrls(
    List<NeteaseTrack> tracks, {
    String? selectedId,
  }) async {
    final playables = <OnlinePlayable>[];
    var selectedIndex = -1;
    final apiClient = BackendApiClient();

    for (final track in tracks) {
      final urlData = await apiClient.getNeteaseSongUrl(track.id);
      final url = urlData['url'] as String?;
      if (url == null || url.isEmpty) {
        AppLogger.warn('NeteasePlaylistDetailPage', '跳过不可播放歌曲: ${track.name}');
        continue;
      }
      playables.add(_buildPlayable(track, streamUrl: url));
      if (selectedId != null && track.id == selectedId) {
        selectedIndex = playables.length - 1;
      }
    }

    return (playables: playables, selectedIndex: selectedIndex);
  }

  OnlinePlayable _buildPlayable(NeteaseTrack track, {String? streamUrl}) {
    final audio = Audio(
      id: _neteaseHistoryId(track.id),
      title: track.name,
      artist: track.artist,
      duration: track.duration ~/ 1000,
      coverUrl: track.cover,
      streamUrl: streamUrl,
    );
    return OnlinePlayable.fromAudio(audio, null);
  }

  String _neteaseHistoryId(String id) => 'netease_$id';

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
