import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// A safe wrapper around Image.network with OneUI 8.5 theming
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({super.key, required this.imageUrl, this.width, this.height, this.fit = BoxFit.cover, this.placeholder, this.errorWidget, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Validate URL before attempting to load
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildErrorWidget(theme);
    }

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🖼️ Image load error: $error');
        debugPrint('🖼️ Image URL: $imageUrl');
        return _buildErrorWidget(theme);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder(theme, loadingProgress);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(OneUITheme theme) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: borderRadius),
          child: Center(child: Icon(Icons.broken_image_outlined, size: 48, color: theme.textTertiary)),
        );
  }

  Widget _buildPlaceholder(OneUITheme theme, ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: theme.inputBackground, borderRadius: borderRadius),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      ),
    );
  }
}
