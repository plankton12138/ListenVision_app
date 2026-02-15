import '../../core/utils/app_logger.dart';
import '../../models/local_audio.dart';
import '../database/local_music_database.dart';

/// 本地音乐仓库
///
/// 负责本地音乐歌单的数据管理
class LocalMusicRepository {
  final LocalMusicDatabase _database;

  LocalMusicRepository({LocalMusicDatabase? database})
      : _database = database ?? LocalMusicDatabase.instance;

  /// 获取本地音乐歌单中的所有音频
  Future<List<LocalAudio>> getAllLocalMusic() async {
    try {
      return await _database.getAllItems();
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '获取本地音乐列表失败: $e');
      return [];
    }
  }

  /// 根据 ID 获取本地音频
  Future<LocalAudio?> getLocalMusicById(int id) async {
    try {
      return await _database.getItemById(id);
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '获取本地音频失败: $e');
      return null;
    }
  }

  /// 添加本地音频
  Future<LocalAudio> addLocalMusic(LocalAudio audio) async {
    try {
      final id = await _database.insertItem(audio);
      return audio.copyWith(id: id);
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '添加本地音频失败: $e');
      rethrow;
    }
  }

  /// 删除本地音频（仅删除数据库记录，不删除文件）
  Future<bool> deleteLocalMusic(int id) async {
    try {
      await _database.deleteItem(id);
      return true;
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '删除本地音频失败: $e');
      return false;
    }
  }

  /// 检查文件是否已导入
  Future<bool> isFileImported(String filePath) async {
    try {
      return await _database.existsByFilePath(filePath);
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '检查文件导入状态失败: $e');
      return false;
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _database.toggleFavorite(id, isFavorite);
      return true;
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '切换收藏状态失败: $e');
      return false;
    }
  }

  /// 获取收藏列表
  Future<List<LocalAudio>> getFavorites() async {
    try {
      return await _database.getFavorites();
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '获取收藏列表失败: $e');
      return [];
    }
  }

  /// 搜索本地音乐
  Future<List<LocalAudio>> searchLocalMusic(String keyword) async {
    try {
      return await _database.search(keyword);
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '搜索本地音乐失败: $e');
      return [];
    }
  }

  /// 获取总数
  Future<int> getCount() async {
    try {
      return await _database.getCount();
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '获取总数失败: $e');
      return 0;
    }
  }
}
