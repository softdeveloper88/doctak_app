// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/display_identity.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/network/custom_cache_manager.dart';
import '../presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';

/// Safely convert a double to int, returning null if invalid (NaN, Infinity, or null)
int? _safeToInt(double? value, {int? defaultValue}) {
  if (value == null || value.isNaN || value.isInfinite || value <= 0) {
    return defaultValue;
  }
  return value.toInt();
}

class CustomImageView extends StatelessWidget {
  ///[imagePath] is required parameter for showing image
  String? imagePath;

  double? height;
  double? width;
  Color? color = Colors.blueGrey;
  BoxFit? fit;
  final String placeHolder;
  Alignment? alignment;
  VoidCallback? onTap;
  EdgeInsetsGeometry? margin;
  BorderRadius? radius;
  BoxBorder? border;

  ///a [CustomImageView] it can be used for showing any type of images
  /// it will shows the placeholder image if image is not found on network image
  CustomImageView({
    super.key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/image_not_found.png',
  });

  @override
  Widget build(BuildContext context) {
    return alignment != null ? Align(alignment: alignment!, child: _buildWidget()) : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: _buildCircleImage()),
            )
          : _buildCircleImage(),
    );
  }

  ///build the image with border radius
  dynamic _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: _buildImageWithBorder());
    } else {
      return _buildImageWithBorder();
    }
  }

  ///build the image with border and border radius style
  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  /// Validate and clean the image URL
  String? _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') {
      return null;
    }
    
    // Trim whitespace
    String cleanUrl = url.trim();
    
    // Check if it's a valid network URL
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      // Validate URL format
      try {
        final uri = Uri.parse(cleanUrl);
        if (uri.host.isEmpty) return null;
        return cleanUrl;
      } catch (_) {
        return null;
      }
    }
    
    return cleanUrl; // Return as-is for local paths
  }

  Widget _buildImageView() {
    final validPath = _getValidImageUrl(imagePath);

    if (validPath != null && isDefaultAvatarUrl(validPath)) {
      final size = width ?? height ?? 48;
      return buildDefaultAvatarWidget(size: size, kind: DefaultAvatarKind.user);
    }

    if (validPath != null) {
      switch (validPath.imageType) {
        case ImageType.svg:
          return SizedBox(
            width: width,
            height: height,
            child: SvgPicture.asset(
              validPath,
              width: width,
              height: height,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
              placeholderBuilder: (_) => _defaultAvatarPlaceholder(),
              errorBuilder: (_, __, ___) => _defaultAvatarPlaceholder(),
            ),
          );
        case ImageType.file:
          return Image.file(
            File(validPath),
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            color: color,
            errorBuilder: (_, __, ___) => _defaultAvatarPlaceholder(),
          );
        case ImageType.network:
          return CachedNetworkImage(
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            imageUrl: AppData.fullImageUrl(validPath),
            color: color,
            cacheManager: CustomCacheManager(),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
            httpHeaders: AppData.mediaHeadersFor(
              AppData.fullImageUrl(validPath),
              baseHeaders: const {
                'User-Agent': 'Mozilla/5.0 (compatible; DocTak/1.0)',
                'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/jpeg,image/png,image/gif,image/*,*/*;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
              },
            ),
            placeholder: (context, url) => Container(
              height: height ?? 200,
              width: width,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              assert(() {
                print('🖼️ Image load failed: $url');
                print('🖼️ Error: $error');
                return true;
              }());

              final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
              final lowerUrl = url.toLowerCase();
              final isVideoFile = videoExtensions.any((ext) => lowerUrl.endsWith(ext));

              if (isVideoFile) {
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(color: Colors.orange[100], borderRadius: radius),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          'VIDEO FILE',
                          style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (isDefaultAvatarUrl(url)) {
                return _defaultAvatarPlaceholder();
              }

              return Image.asset(
                placeHolder,
                width: width,
                height: height,
                fit: fit ?? BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatarPlaceholder(),
              );
            },
          );
        case ImageType.video:
          return VideoPlayerWidget(videoUrl: validPath);
        case ImageType.png:
        default:
          return Image.asset(
            validPath,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            color: color,
            errorBuilder: (_, __, ___) => _defaultAvatarPlaceholder(),
          );
      }
    }
    return const SizedBox();
  }

  Widget _defaultAvatarPlaceholder() {
    final size = width ?? height ?? 48;
    return buildDefaultAvatarWidget(size: size, kind: DefaultAvatarKind.user);
  }
}

extension ImageTypeExtension on String {
  ImageType get imageType {
    // Clean URL by removing query parameters
    String cleanPath = toLowerCase();
    final queryIndex = cleanPath.indexOf('?');
    if (queryIndex != -1) {
      cleanPath = cleanPath.substring(0, queryIndex);
    }
    
    if (startsWith('http') || startsWith('https')) {
      // Comprehensive list of video extensions
      final videoExtensions = [
        '.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v',
        '.3gp', '.ogv', '.mpeg', '.mpg', '.ts', '.mts', '.m2ts', '.vob',
        '.asf', '.rm', '.rmvb', '.divx', '.f4v', '.swf', '.3g2'
      ];

      for (String ext in videoExtensions) {
        if (cleanPath.endsWith(ext)) {
          return ImageType.video;
        }
      }

      return ImageType.network;
    } else if (cleanPath.endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, video, unknown }
