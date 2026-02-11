import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/data/api/backend_api_client.dart';
import 'package:demo/models/audio.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/common/snackbar_helper.dart';
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
                            errorBuilder: (_, __, ___) => Container(
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
                      errorBuilder: (_, __, ___) => Container(
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
      onTap: () => _playTrack(track),
    );
  }

  void _playTrack(NeteaseTrack track) async {
    AppLogger.logUserAction(
      'NeteasePlaylistDetailPage',
      '播放网易云歌曲',
      parameters: {'id': track.id, 'name': track.name},
    );

    try {
      final apiClient = BackendApiClient();
      final urlData = await apiClient.getNeteaseSongUrl(track.id);
      final url = urlData['url'] as String?;

      if (url == null || url.isEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, '无法获取播放链接，可能需要VIP');
        }
        return;
      }

      final audio = Audio(
        id: 'netease_${track.id}',
        title: track.name,
        artist: track.artist,
        duration: track.duration ~/ 1000,
        coverUrl: track.cover,
      );

      await ref.read(playerViewModelProvider.notifier).playOnlineAudio(
        audio: audio,
        streamUrl: url,
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

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
