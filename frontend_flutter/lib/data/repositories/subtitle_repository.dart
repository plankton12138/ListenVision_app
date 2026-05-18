import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../models/subtitle.dart';
import '../../services/bilibili_api_service.dart';
import '../database/app_database.dart';
import '../database/subtitle_dao.dart';

final subtitleRepositoryProvider = Provider<SubtitleRepository>((ref) {
  return SubtitleRepository();
});

/// 字幕仓库 — 本地优先，网络回退
class SubtitleRepository {
  final BilibiliApiService _bilibiliApi;
  SubtitleDao? _dao;

  SubtitleRepository({BilibiliApiService? bilibiliApi})
      : _bilibiliApi = bilibiliApi ?? BilibiliApiService();

  Future<SubtitleDao> _getDao() async {
    if (_dao != null) return _dao!;
    final db = await AppDatabase.instance.database;
    _dao = SubtitleDao(db);
    return _dao!;
  }

  /// 获取字幕（本地缓存优先）
  /// [bvid] 视频 BV 号
  /// [cid] 可选，用于多 P 视频获取指定分 P 的字幕
  ///
  /// 注意：如果 cid 为 null，跳过本地缓存直接请求网络，
  /// 因为缓存键可能不匹配
  Future<SubtitleData?> getSubtitle(String bvid, {int? cid}) async {
    final dao = await _getDao();

    // 1. 尝试本地缓存（仅当 cid 明确指定时）
    if (cid != null) {
      try {
        final cached = await dao.getSubtitle(bvid, cid: cid);
        if (cached != null && cached.isNotEmpty) {
          AppLogger.info('SubtitleRepository', '命中本地缓存：bvid=$bvid, cid=$cid');
          return _buildFromCache(bvid, cid, cached);
        }
      } catch (e) {
        AppLogger.warn('SubtitleRepository', '读取字幕缓存失败：$e');
      }
    }

    // 2. 网络获取
    try {
      AppLogger.info('SubtitleRepository', '请求字幕：bvid=$bvid, cid=$cid');
      final cookies = await _bilibiliApi.getStoredCookies();
      final data = await _bilibiliApi.getSubtitles(bvid, cookies: cookies);

      // 使用返回的实际 cid 作为缓存键
      final actualCid = data.cid;
      AppLogger.info('SubtitleRepository', '获取字幕成功：bvid=$bvid, cid=$actualCid, 字幕数：${data.subtitles.length}, needLogin: ${data.needLogin}');

      // 3. 存入缓存（使用实际的 cid 区分不同分 P）
      for (final track in data.subtitles) {
        await dao.saveSubtitle(
          bvid,
          actualCid,
          track.lan,
          track.lanDoc,
          track.lines.map((l) => l.toJson()).toList(),
        );
      }
      return data;
    } catch (e) {
      AppLogger.warn('SubtitleRepository', '获取字幕失败：$e');
      rethrow;
    }
  }

  SubtitleData _buildFromCache(String bvid, int cid, List<Map<String, dynamic>> cached) {
    if (cached.isEmpty) {
      return SubtitleData(bvid: bvid, cid: cid, subtitles: []);
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
      cid: cid,
      subtitles: tracks,
    );
  }

  /// 清空字幕缓存
  Future<void> clearCache() async {
    final dao = await _getDao();
    await dao.clearAll();
    AppLogger.info('SubtitleRepository', '字幕缓存已清空');
  }
}