// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/network/custom_cache_manager.dart';
import '../presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';

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

  Widget _buildImageView() {
    if (imagePath != null) {
      switch (imagePath!.imageType) {
        case ImageType.svg:
          return SizedBox(
            // height: height,
            width: width,
            child: SvgPicture.asset(
              imagePath!,
              // height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn),
            ),
          );
        case ImageType.file:
          return Image.file(
            File(imagePath!),
            // height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
          );
        case ImageType.network:
          return CachedNetworkImage(
            // height: height,
            width: width,
            fit: fit,
            imageUrl: imagePath!,
            color: color,
            cacheManager: CustomCacheManager(),
            httpHeaders: const {
              'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
              'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
              'Accept-Encoding': 'gzip, deflate, br',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
            placeholder: (context, url) => Center(
              child: SizedBox(
                height: height ?? 300,
                width: 60,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.grey[300], strokeWidth: 8, strokeCap: StrokeCap.round, backgroundColor: Colors.white),
                ),
              ),
            ),
            // errorWidget: (context, url,error) =>  Center(
            //   child: SizedBox(
            //     height: 60,
            //     width: 60,
            //     child: CircularProgressIndicator(
            //       color: Colors.grey[300],
            //       strokeWidth: 8,
            //       strokeCap: StrokeCap.round,
            //       backgroundColor: Colors.white,
            //     ),
            //   ),
            // ),
            errorWidget: (context, url, error) {
              // Enhanced error debugging for S3 URLs
              print('🚨 CustomImageView load error for URL: $url');
              print('🚨 Error details: $error');
              print('🚨 Error type: ${error.runtimeType}');

              // Check if it's actually a video file being loaded as image
              final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
              final lowerUrl = url.toLowerCase();
              final isVideoFile = videoExtensions.any((ext) => lowerUrl.endsWith(ext));

              if (isVideoFile) {
                print('⚠️ WARNING: Attempting to load video file as image: $url');
                print('💡 SOLUTION: Use VideoPlayerWidget instead of CustomImageView for video files');

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

              return Image.asset(
                placeHolder,
                // height: height,
                width: width,
                fit: fit ?? BoxFit.cover,
              );
            },
          );
        case ImageType.video:
          // return Container(
          //   width: width,
          //   height: height??300,
          //   decoration: BoxDecoration(
          //     color: Colors.black87,
          //     borderRadius: radius,
          //   ),
          //   child: Stack(
          //     alignment: Alignment.center,
          //     children: [
          //       Icon(
          //         Icons.play_circle_filled,
          //         color: Colors.white,
          //         size: 48,
          //       ),
          //       Positioned(
          //         bottom: 8,
          //         left: 8,
          //         child: Container(
          //           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //           decoration: BoxDecoration(
          //             color: Colors.black54,
          //             borderRadius: BorderRadius.circular(4),
          //           ),
          //           child: const Text(
          //             'VIDEO',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 10,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // );
          return VideoPlayerWidget(videoUrl: imagePath!);
        case ImageType.png:
        default:
          return Image.asset(
            imagePath!,
            // height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
          );
      }
    }
    return const SizedBox();
  }
}

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https')) {
      // Check if it's a video file
      final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
      final lowerPath = toLowerCase();

      for (String ext in videoExtensions) {
        if (lowerPath.endsWith(ext)) {
          return ImageType.video;
        }
      }

      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, video, unknown }
