/// API 端点常量
///
/// 统一管理所有后端 API 端点，避免硬编码
/// 按功能分组，使用前缀区分不同模块
class Endpoints {
  Endpoints._();

  // ==================== 认证相关 ====================
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authVerifyEmail = '/auth/verify-email';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
    static const String authRefresh = '/auth/refresh';
  static const String authSendCode = '/auth/send-code';
  static const String authResetPassword = '/auth/reset-pwd';
  static const String authVerifyCode = '/auth/verify-code';

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
      return '/bilibili/subtitle/$bvid?cid=$cid';
    }
    return '/bilibili/subtitle/$bvid';
  }

  static String bilibiliVideo(String bvid) => '/bilibili/video/$bvid';
  static String bilibiliAudio(String bvid) => '/bilibili/audio/$bvid';
  static String bilibiliUploader(String mid) => '/bilibili/uploader/$mid';
  static const String bilibiliProxyImage = '/bilibili/proxy/image';
  static const String bilibiliProxyAudio = '/bilibili/proxy/audio';
  static String bilibiliProxyAudioByBvid(String bvid) =>
      '/bilibili/proxy/audio/$bvid';

  // ==================== 网易云相关 ====================
  static const String neteaseQrcode = '/netease/qrcode';
  static const String neteaseQrcodeCheck = '/netease/qrcode/check';
  static const String neteaseCellphoneLogin = '/netease/login/cellphone';
  static const String neteaseStatus = '/netease/status';
  static const String neteaseUnbind = '/netease/unbind';
  static const String neteaseSearch = '/netease/search';
  static const String neteaseRecommendedPlaylists =
      '/netease/recommended-playlists';

  static String neteaseSongDetail(String ids) =>
      '/netease/song/detail?ids=$ids';
  static String neteaseSongUrl(String id) => '/netease/song/url?id=$id';
  static String neteaseSongLyric(String id) => '/netease/song/lyric/$id';
  static String neteasePlaylistDetail(String id) =>
      '/netease/playlist/detail/$id';
  static String neteaseUserPlaylist(String uid) =>
      '/netease/user/playlist/$uid';

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

  // ==================== 同步相关 ====================
  static const String syncFavorites = '/sync/favorites';
  static const String syncPlaylists = '/sync/playlists';
  static const String syncHistory = '/sync/history';
  static const String syncChanges = '/sync/changes';
  static const String syncStatus = '/sync/status';
}
