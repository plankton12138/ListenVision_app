import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

/// 推荐内容实体
///
/// Clean Architecture 中的推荐内容领域对象
@freezed
abstract class Recommendation with _$Recommendation {
  const Recommendation._();

  const factory Recommendation({
    required String id,
    required String title,
    String? description,
    String? coverUrl,
    String? duration,
    String? artist,
    int? playCount,
    String? url,
    @Default(RecommendationType.video) RecommendationType type,
  }) = _Recommendation;

  /// 从 JSON 创建
  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);

  /// 从 DTO 创建
  factory Recommendation.fromDto(Map<String, dynamic> json) {
    return Recommendation(
      id: json['bvid'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? json['desc'] as String?,
      coverUrl: json['cover'] as String? ?? json['pic'] as String? ?? json['coverUrl'] as String?,
      duration: json['duration']?.toString() ?? json['formattedDuration'] as String?,
      artist: json['artist'] as String? ?? json['author'] as String? ?? json['uname'] as String?,
      playCount: _parsePlayCount(json['play'] as dynamic),
      url: json['arcurl'] as String? ?? json['url'] as String?,
      type: _parseType(json['type'] as String?),
    );
  }

  /// 从 Audio 转换
  factory Recommendation.fromAudio(dynamic audio, {RecommendationType type = RecommendationType.video}) {
    // 支持 Audio 实体或 Map 格式
    if (audio is Map<String, dynamic>) {
      return Recommendation.fromDto(audio);
    }
    // 假设是 Audio 实体（这里需要避免循环引用，所以简化处理）
    return Recommendation(
      id: '',
      title: '',
      type: type,
    );
  }

  /// 格式化播放次数
  String get formattedPlayCount {
    if (playCount == null || playCount == 0) return '0';
    if (playCount! < 1000) return playCount.toString();
    if (playCount! < 10000) return '${(playCount! / 1000).toStringAsFixed(1)}k';
    if (playCount! < 100000000) return '${(playCount! / 10000).toStringAsFixed(1)}w';
    return '${(playCount! / 100000000).toStringAsFixed(1)}亿';
  }

  /// 是否有封面
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 是否有描述
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// 是否为视频类型
  bool get isVideo => type == RecommendationType.video;

  /// 是否为歌单类型
  bool get isPlaylist => type == RecommendationType.playlist;

  /// 解析播放次数
  static int? _parsePlayCount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 解析类型
  static RecommendationType _parseType(String? value) {
    if (value == 'playlist') return RecommendationType.playlist;
    return RecommendationType.video;
  }
}

/// 推荐类型
enum RecommendationType {
  @JsonValue('video')
  video,
  @JsonValue('playlist')
  playlist,
}

/// B站热门歌单实体
@freezed
abstract class BiliPlaylist with _$BiliPlaylist {
  const BiliPlaylist._();

  const factory BiliPlaylist({
    required int menuId,
    int? uid,
    String? uploader,
    required String title,
    String? coverUrl,
    String? intro,
    int? type,
    @Default(0) int songCount,
    required BiliPlaylistStats stats,
    @Default([]) List<BiliAudioPreview> previews,
  }) = _BiliPlaylist;

  /// 从 JSON 创建
  factory BiliPlaylist.fromJson(Map<String, dynamic> json) => _$BiliPlaylistFromJson(json);

  /// 从 DTO 创建
  factory BiliPlaylist.fromDto(Map<String, dynamic> json) {
    final previewsJson = json['previews'] as List?;
    return BiliPlaylist(
      menuId: json['menuId'] as int? ?? json['menu_id'] as int? ?? 0,
      uid: json['uid'] as int?,
      uploader: json['uname'] as String? ?? json['uploader'] as String?,
      title: json['title'] as String? ?? '',
      coverUrl: json['cover'] as String? ?? json['coverUrl'] as String?,
      intro: json['intro'] as String? ?? json['description'] as String?,
      type: json['type'] as int?,
      songCount: json['songCount'] as int? ?? json['snum'] as int? ?? json['song_count'] as int? ?? 0,
      stats: BiliPlaylistStats.fromDto(json['statistic'] as Map<String, dynamic>? ?? json),
      previews: previewsJson
          ?.map((p) => BiliAudioPreview.fromDto(p as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// 格式化播放次数
  String get formattedPlayCount {
    if (stats.play < 1000) return stats.play.toString();
    if (stats.play < 10000) return '${(stats.play / 1000).toStringAsFixed(1)}k';
    if (stats.play < 100000000) return '${(stats.play / 10000).toStringAsFixed(1)}w';
    return '${(stats.play / 100000000).toStringAsFixed(1)}亿';
  }

  /// 是否有封面
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 是否有介绍
  bool get hasIntro => intro != null && intro!.isNotEmpty;

  /// 是否有预览
  bool get hasPreviews => previews.isNotEmpty;
}

/// B站歌单统计信息
@freezed
abstract class BiliPlaylistStats with _$BiliPlaylistStats {
  const factory BiliPlaylistStats({
    @Default(0) int play,
    @Default(0) int collect,
    @Default(0) int comment,
  }) = _BiliPlaylistStats;

  /// 从 JSON 创建
  factory BiliPlaylistStats.fromJson(Map<String, dynamic> json) => _$BiliPlaylistStatsFromJson(json);

  /// 从 DTO 创建
  factory BiliPlaylistStats.fromDto(Map<String, dynamic> json) {
    return BiliPlaylistStats(
      play: json['play'] as int? ?? 0,
      collect: json['collect'] as int? ?? 0,
      comment: json['comment'] as int? ?? 0,
    );
  }
}

/// B站音频预览
@freezed
abstract class BiliAudioPreview with _$BiliAudioPreview {
  const BiliAudioPreview._();

  const factory BiliAudioPreview({
    required int id,
    required String title,
    int? duration,
    String? coverUrl,
  }) = _BiliAudioPreview;

  /// 从 JSON 创建
  factory BiliAudioPreview.fromJson(Map<String, dynamic> json) => _$BiliAudioPreviewFromJson(json);

  /// 从 DTO 创建
  factory BiliAudioPreview.fromDto(Map<String, dynamic> json) {
    return BiliAudioPreview(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      duration: json['duration'] as int?,
      coverUrl: json['cover'] as String?,
    );
  }

  /// 格式化时长
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 推荐响应（分页）
@freezed
abstract class RecommendationResponse with _$RecommendationResponse {
  const RecommendationResponse._();

  const factory RecommendationResponse({
    @Default([]) List<Recommendation> items,
    @Default(1) int page,
    @Default(20) int pageSize,
    @Default(0) int total,
    String? source, // 'hot' 或 'personalized'
  }) = _RecommendationResponse;

  /// 从 JSON 创建
  factory RecommendationResponse.fromJson(Map<String, dynamic> json) => _$RecommendationResponseFromJson(json);

  /// 是否有更多数据
  bool get hasMore => (page * pageSize) < total;

  /// 总页数
  int get totalPages => (total / pageSize).ceil();
}

/// 个性化推荐响应
@freezed
abstract class PersonalizedResponse with _$PersonalizedResponse {
  const PersonalizedResponse._();

  const factory PersonalizedResponse({
    required String source,
    @Default([]) List<String> keywords,
    @Default([]) List<Recommendation> videos,
    @Default([]) List<BiliPlaylist> playlists,
  }) = _PersonalizedResponse;

  /// 从 JSON 创建
  factory PersonalizedResponse.fromJson(Map<String, dynamic> json) => _$PersonalizedResponseFromJson(json);

  /// 是否有任何内容
  bool get hasContent => videos.isNotEmpty || playlists.isNotEmpty;

  /// 总内容数
  int get totalContentCount => videos.length + playlists.length;
}
