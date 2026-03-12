import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../models/subtitle.dart';
import '../database/app_database.dart';
import '../database/subtitle_dao.dart';

final subtitleRepositoryProvider = Provider<SubtitleRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SubtitleRepository(apiClient);
});

/// 字幕仓库 — 本地优先，网络回退
class SubtitleRepository {
  final ApiClient _apiClient;
  SubtitleDao? _dao;

  SubtitleRepository(this._apiClient);

  Future<SubtitleDao> _getDao() async {
    if (_dao != null) return _dao!;
    final db = await AppDatabase.instance.database;
    _dao = SubtitleDao(db);
    // ignore: null_check_always_fails
    return _dao!;
  }

  /// 获取字幕（本地缓存优先）
  Future<SubtitleData?> getSubtitle(String bvid) async {
    final dao = await _getDao();

    // 1. 尝试本地缓存
    try {
      final cached = await dao.getSubtitle(bvid);
      if (cached != null && cached.isNotEmpty) {
        return _buildFromCache(bvid, cached);
      }
    } catch (e) {
      AppLogger.warn('SubtitleRepository', '读取字幕缓存失败: $e');
    }

    // 2. 网络获取
    try {
      final data = await _apiClient.getBilibiliSubtitle(bvid);
      // 3. 存入缓存
      for (final track in data.subtitles) {
        await dao.saveSubtitle(
          bvid,
          track.lan,
          track.lanDoc,
          track.lines.map((l) => l.toJson()).toList(),
        );
      }
      return data;
    } catch (e) {
      AppLogger.warn('SubtitleRepository', '获取字幕失败: $e');
      return null;
    }
  }

  SubtitleData _buildFromCache(String bvid, List<Map<String, dynamic>> cached) {
    if (cached.isEmpty) {
      return SubtitleData(bvid: bvid, cid: 0, subtitles: []);
    }

    final tracks = cached.map((row) {
      final content = row['content'] as String;
      final linesList = (jsonDecode(content) as List).cast<Map<String, dynamic>>();

      final lines = linesList.map((l) => SubtitleLine.fromJson(l)).toList();

      return SubtitleTrack(
        lan: row['lan'] as String,
        lanDoc: row['lan_doc'] as String,
        lines: lines,
      );
    }).toList();

    return SubtitleData(
      bvid: bvid,
      cid: 0,
      subtitles: tracks,
    );
  }
}
