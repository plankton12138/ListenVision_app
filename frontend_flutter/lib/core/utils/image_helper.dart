import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../network/endpoints.dart';

/// 图片缓存工具类
///
/// 使用 cached_network_image 提供图片缓存功能
/// 减少网络请求，提升加载速度，降低流量消耗
/// 从 utils/image_helper.dart 迁移到 core/utils/
class ImageHelper {
  /// B站 CDN 域名列表
  static const List<String> _bilibiliCdnDomains = [
    'i0.hdslb.com',
    'i1.hdslb.com',
    'i2.hdslb.com',
    'i3.hdslb.com',
    'bfs.archive.bilibili.com',
    'bos.bilivideo.com',
  ];

  /// 将 B站 CDN URL 转换为后端代理 URL
  ///
  /// 用于解决线上 Web 环境的 CORS 问题
  /// 本地开发环境（flutter run）直接返回原 URL
  static String convertToProxyUrl(String url) {
    // 检查是否为 debug 模式或非 Web 平台，如果是则直接返回原 URL
    // 因为本地开发不需要代理，生产环境需要
    if (!appConfig.isProd && !appConfig.isStaging) {
      return url;
    }

    // 处理 // 开头的 URL
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // 检查是否为 B站 CDN 域名
    for (final cdnDomain in _bilibiliCdnDomains) {
      if (url.contains(cdnDomain)) {
        // 构建代理 URL
        final encodedUrl = Uri.encodeComponent(url);
        return '${appConfig.fullApiBaseUrl}${Endpoints.bilibiliProxyImage}?url=$encodedUrl';
      }
    }

    // 非 B站 CDN 图片，直接返回原 URL
    return url;
  }

  /// 缓存的网络图片
  ///
  /// [imageUrl] 图片URL
  /// [width] 图片宽度
  /// [height] 图片高度
  /// [fit] 填充方式
  /// [placeholder] 加载中的占位widget
  /// [errorWidget] 加载失败的错误widget
  static Widget cachedNetworkImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // 转换为代理 URL（解决线上 CORS 问题）
    final url = convertToProxyUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
      memCacheWidth: width?.toInt(), // 限制内存缓存尺寸
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000, // 限制磁盘缓存尺寸
      maxHeightDiskCache: 1000,
    );
  }

  /// 带圆角的缓存网络图片
  static Widget cachedNetworkImageWithRadius(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 8.0,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: cachedNetworkImage(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  /// 歌单封面图片（带默认图标）
  static Widget playlistCover(
    String? imageUrl, {
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width ?? 100,
        height: height ?? 80,
        color: Colors.grey[300],
        child: const Icon(Icons.playlist_play, size: 32, color: Colors.grey),
      );
    }

    return cachedNetworkImageWithRadius(
      imageUrl,
      width: width ?? 100,
      height: height ?? 80,
      borderRadius: 4,
    );
  }

  /// 视频封面图片（带默认图标）
  static Widget videoCover(
    String? imageUrl, {
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width ?? 100,
        height: height ?? 70,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
      );
    }

    return cachedNetworkImageWithRadius(
      imageUrl,
      width: width ?? 100,
      height: height ?? 70,
      borderRadius: 4,
    );
  }
}
