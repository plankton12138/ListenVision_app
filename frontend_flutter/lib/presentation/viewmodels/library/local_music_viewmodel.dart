import 'package:file_selector/file_selector.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/local_music_repository.dart';
import '../../../models/local_audio.dart';
import '../../../services/metadata_service.dart';

part 'local_music_viewmodel.freezed.dart';
part 'local_music_viewmodel.g.dart';

/// 本地音乐状态
@freezed
class LocalMusicState with _$LocalMusicState {
  const factory LocalMusicState.initial() = LocalMusicStateInitial;
  const factory LocalMusicState.loading() = LocalMusicStateLoading;
  const factory LocalMusicState.loaded({
    required List<LocalAudio> audios,
  }) = LocalMusicStateLoaded;
  const factory LocalMusicState.importing({
    required int current,
    required int total,
    required String currentFile,
  }) = LocalMusicStateImporting;
  const factory LocalMusicState.error({
    required String message,
  }) = LocalMusicStateError;
}

/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入
@Riverpod(keepAlive: true)
class LocalMusicViewModel extends _$LocalMusicViewModel {
  LocalMusicRepository? _repository;
  MetadataService? _metadataService;

  @override
  Future<LocalMusicState> build() async {
    _repository = ref.watch(localMusicRepositoryProvider);
    _metadataService = MetadataService();

    return await _loadPlaylist();
  }

  /// 加载本地音乐歌单
  Future<LocalMusicState> _loadPlaylist() async {
    try {
      final audios = await _repository!.getAllLocalMusic();
      return LocalMusicState.loaded(audios: audios);
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '加载歌单失败: $e');
      return LocalMusicState.error(message: e.toString());
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    state = AsyncData(await _loadPlaylist());
  }

  /// 导入音频文件
  ///
  /// 选择文件并提取元数据，保存到"本地音乐"歌单
  Future<void> importAudioFiles() async {
    try {
      // 选择文件
      const XTypeGroup audioType = XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'm4a', 'flac', 'wav', 'aac', 'ogg'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [audioType]);
      if (file == null) return;

      final filePath = file.path;

      // 检查文件是否已导入
      final isImported = await _repository!.isFileImported(filePath);
      if (isImported) {
        AppLogger.info('LocalMusicViewModel', '文件已导入: $filePath');
        if (!ref.mounted) return;
        state = AsyncData(LocalMusicState.error(message: '该文件已存在于本地音乐中'));
        return;
      }

      if (!ref.mounted) return;
      state = AsyncData(const LocalMusicState.importing(
        current: 1,
        total: 1,
        currentFile: '',
      ));

      // 提取元数据
      final metadata = await _metadataService!.extractFromFile(filePath);

      // 创建本地音频对象
      final localAudio = LocalAudio(
        filePath: filePath,
        title: metadata.title.isNotEmpty ? metadata.title : _getFileName(filePath),
        artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
        duration: metadata.duration ?? 0,
        albumArt: metadata.cover,
      );

      // 保存到数据库
      await _repository!.addLocalMusic(localAudio);

      // 刷新列表
      if (!ref.mounted) return;
      state = AsyncData(await _loadPlaylist());

      AppLogger.info('LocalMusicViewModel', '导入成功: ${localAudio.title}');
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '导入失败: $e');
      if (!ref.mounted) return;
      state = AsyncData(LocalMusicState.error(message: e.toString()));
    }
  }

  /// 批量导入音频文件
  Future<void> importMultipleFiles() async {
    try {
      const XTypeGroup audioType = XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'm4a', 'flac', 'wav', 'aac', 'ogg'],
      );

      final List<XFile> files = await openFiles(acceptedTypeGroups: [audioType]);
      if (files.isEmpty) return;

      int successCount = 0;
      int skipCount = 0;
      int failCount = 0;

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final filePath = file.path;

        if (!ref.mounted) return;
        state = AsyncData(LocalMusicState.importing(
          current: i + 1,
          total: files.length,
          currentFile: file.name,
        ));

        try {
          // 检查是否已导入
          final isImported = await _repository!.isFileImported(filePath);
          if (isImported) {
            skipCount++;
            continue;
          }

          // 提取元数据
          final metadata = await _metadataService!.extractFromFile(filePath);

          // 创建并保存
          final localAudio = LocalAudio(
            filePath: filePath,
            title: metadata.title.isNotEmpty ? metadata.title : _getFileName(filePath),
            artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
            duration: metadata.duration ?? 0,
            albumArt: metadata.cover,
          );

          await _repository!.addLocalMusic(localAudio);
          successCount++;
        } catch (e) {
          AppLogger.error('LocalMusicViewModel', '导入文件失败: $filePath - $e');
          failCount++;
        }
      }

      if (!ref.mounted) return;
      state = AsyncData(await _loadPlaylist());

      AppLogger.info('LocalMusicViewModel',
          '批量导入完成: 成功 $successCount, 跳过 $skipCount, 失败 $failCount');
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '批量导入失败: $e');
      if (!ref.mounted) return;
      state = AsyncData(LocalMusicState.error(message: e.toString()));
    }
  }

  /// 删除本地音乐（仅从歌单移除，不删除文件）
  Future<void> deleteLocalMusic(int id) async {
    try {
      final success = await _repository!.deleteLocalMusic(id);
      if (success && ref.mounted) {
        state = AsyncData(await _loadPlaylist());
      }
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '删除失败: $e');
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      final success = await _repository!.toggleFavorite(id, isFavorite);
      if (success && ref.mounted) {
        state = AsyncData(await _loadPlaylist());
      }
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '切换收藏状态失败: $e');
    }
  }

  /// 从文件路径获取文件名（无扩展名）
  String _getFileName(String filePath) {
    final fileName = filePath.split(RegExp(r'[\/]')).last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }
}

/// Provider 定义
@riverpod
LocalMusicRepository localMusicRepository(Ref ref) {
  return LocalMusicRepository();
}
