import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 图片缓存工具类
///
/// 使用 cached_network_image 提供图片缓存功能
/// 减少网络请求，提升加载速度，降低流量消耗
/// 从 utils/image_helper.dart 迁移到 core/utils/
class ImageHelper {
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
    // 处理 // 开头的URL
    String url = imageUrl;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

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
