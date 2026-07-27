import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

bool isNetworkImagePath(String path) {
  final lower = path.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

class ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.surfaceVariant,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textTertiary,
          ),
        );

    if (path.trim().isEmpty) return fallback;

    if (isNetworkImagePath(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: AppColors.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (_, _, _) => fallback,
      );
    }

    final file = File(path);
    if (!file.existsSync()) return fallback;

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
