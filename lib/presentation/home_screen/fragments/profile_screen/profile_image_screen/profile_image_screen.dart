import 'package:doctak_app/core/app_export.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sizer/sizer.dart';

class ProfileImageScreen extends StatelessWidget {
  final String imageUrl;

  ProfileImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              maxScale: PhotoViewComputedScale.contained,
              filterQuality: FilterQuality.high,
              imageProvider: NetworkImage(
                // imagePath:
                imageUrl,

                // fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Positioned(
          //   bottom: 40,
          //   right: 20,
          //   child: Row(
          //     children: [
          //       IconButton(
          //         icon: const Icon(Icons.share, color: Colors.white),
          //         onPressed: () {
          //           // Implement share functionality
          //         },
          //       ),
          //       IconButton(
          //         icon: const Icon(Icons.download, color: Colors.white),
          //         onPressed: () {
          //           // Implement download functionality
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
