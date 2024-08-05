import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AutoDetectImageView extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  AutoDetectImageView({
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Uri uri = Uri.parse(imagePath);

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder ??
                (context, url) => Center(child: CircularProgressIndicator()),
        errorWidget: errorWidget ??
                (context, url, error) => Center(child: Icon(Icons.error)),
      );
    } else {
      // Local file image
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget != null
              ? errorWidget!(context, imagePath, error)
              : Center(child: Icon(Icons.error));
        },
      );
    }
  }
}