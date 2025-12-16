import 'package:flutter/material.dart';

/// A safe wrapper around Image.network that handles null/empty URLs and errors gracefully
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validate URL before attempting to load
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🖼️ Image load error: $error');
        debugPrint('🖼️ Image URL: $imageUrl');
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder(loadingProgress);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
  }

  Widget _buildPlaceholder(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
