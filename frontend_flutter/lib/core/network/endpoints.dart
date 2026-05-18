/// API 端点常量
///
/// 统一管理所有后端 API 端点，避免硬编码
/// 按功能分组，使用前缀区分不同模块
class Endpoints {
  Endpoints._();

  // ==================== 歌单相关 ====================
  static const String playlistsList = '/playlists';
  static String playlistsDetail(int id) => '/playlists/$id';
  static String playlistsItems(int id) => '/playlists/$id/items';
  static const String playlistsFavorites = '/playlists/favorites';
  static const String playlistsFavoritesToggle =
      '/playlists/favorites/toggle';
  static String playlistsFavoritesCheck(String bvid) =>
      '/playlists/favorites/check/$bvid';
  static const String playlistsNowPlaying = '/playlists/now-playing';

  // ==================== B站相关 ====================
  static const String bilibiliQrcode = '/bilibili/qrcode';
  static const String bilibiliQrcodeCheck = '/bilibili/qrcode/check';
  static const String bilibiliStatus = '/bilibili/status';
  static const String bilibiliUnbind = '/bilibili/unbind';
  static const String bilibiliSearch = '/bilibili/search';
  static const String bilibiliSearchSuggest = '/bilibili/search/suggest';
  static const String bilibiliSearchRecent = '/bilibili/search/recent';
  static const String bilibiliRecommend = '/bilibili/recommend';
  static const String bilibiliRefreshCookie = '/bilibili/refresh-cookie';

  static String bilibiliSubtitle(String bvid, {int? cid}) {
    if (cid != null) {
      return '/bilibili/video/$bvid/subtitle?cid=$cid';
    }
    return '/bilibili/video/$bvid/subtitle';
  }

  static String bilibiliVideo(String bvid) => '/bilibili/video/$bvid';
  static String bilibiliAudio(String bvid) => '/bilibili/video/$bvid/audio';
  static String bilibiliUploader(String mid) => '/bilibili/uploader/$mid';
  static const String bilibiliProxyImage = '/bilibili/proxy/image';
  static const String bilibiliProxyAudio = '/bilibili/proxy/audio';
  static String bilibiliProxyAudioByBvid(String bvid) =>
      '/bilibili/proxy/audio/$bvid';

  // ==================== 播放历史相关 ====================
  static const String historyList = '/history';
  static String historyDelete(int id) => '/history/$id';

  // ==================== 搜索相关 ====================
  static const String searchLocal = '/search/local';
  static const String searchSuggestions = '/search/suggestions';
  static const String searchTrending = '/search/trending';
  static const String searchHistory = '/search/history';

  // ==================== 推荐相关 ====================
  static const String recommendationsHotPlaylists =
      '/recommendations/hot-playlists';
  static const String recommendationsRank = '/recommendations/rank';
  static const String recommendationsPersonalized =
      '/recommendations/personalized';

  // ==================== 音频相关 ====================
  static String audioMetadata(String bvid) => '/audio/metadata/$bvid';
  static String audioRefreshMetadata(String bvid) =>
      '/audio/metadata/$bvid/refresh';
  static String audioStream(String bvid) => '/audio/stream/$bvid';
  static const String audioSearchHistory = '/audio/search/history';
  static const String audioSearchRecent = '/audio/search/recent';
  static const String audioStats = '/audio/stats';
  static const String audioClean = '/audio/clean';

}
