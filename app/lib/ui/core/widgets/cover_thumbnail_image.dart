import 'dart:io';

import 'package:flutter/material.dart';

/// 解码缓存像素尺寸（物理像素，供 [Image.cacheWidth] / [cacheHeight]）。
class CoverThumbnailCacheSize {
  const CoverThumbnailCacheSize({required this.width, required this.height});

  final int width;
  final int height;
}

/// 由缩略图显示区逻辑尺寸与 [devicePixelRatio] 计算解码缓存尺寸。
CoverThumbnailCacheSize coverThumbnailCacheSize({
  required double displayWidth,
  required double displayHeight,
  required double devicePixelRatio,
}) {
  return CoverThumbnailCacheSize(
    width: (displayWidth * devicePixelRatio).ceil(),
    height: (displayHeight * devicePixelRatio).ceil(),
  );
}

/// 本地 Cover / Page 缩略图：[Image.file] + 解码 cache 尺寸 + 低质量滤波。
class CoverThumbnailImage extends StatelessWidget {
  const CoverThumbnailImage({
    super.key,
    required this.filePath,
    required this.cacheWidth,
    required this.cacheHeight,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.errorIcon = Icons.image_outlined,
    this.errorIconSize = 28,
    this.errorIconOpacity = 1,
  });

  final String filePath;
  final int cacheWidth;
  final int cacheHeight;
  final BoxFit fit;
  final Alignment alignment;
  final Color? backgroundColor;
  final IconData errorIcon;
  final double errorIconSize;
  final double errorIconOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? scheme.surfaceContainer;

    return ColoredBox(
      color: background,
      child: Image.file(
        File(filePath),
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, _, _) => ColoredBox(
          color: background,
          child: Center(
            child: Icon(
              errorIcon,
              size: errorIconSize,
              color: scheme.onSurfaceVariant.withValues(alpha: errorIconOpacity),
            ),
          ),
        ),
      ),
    );
  }
}
