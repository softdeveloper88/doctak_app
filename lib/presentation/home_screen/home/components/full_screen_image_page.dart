// full_screen_image_page.dart
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../data/models/post_model/post_data_model.dart';
import 'SVPostComponent.dart';

class FullScreenImagePage extends StatelessWidget {
  String? imageUrl;
  final Post post;
  String percent = "0";
  int listCount;
  List<Map<String, String>>? mediaUrls = [];
  ValueNotifier<String> downloadProgress = ValueNotifier('');

  FullScreenImagePage(
      {super.key, required this.listCount,
      this.imageUrl,
      required this.post,
      this.mediaUrls});

  Future<void> _downloadImage(String url, BuildContext context) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final Dio dio = Dio();
      String fileName = 'DocTak_${DateTime.now().millisecondsSinceEpoch}.jpg';

      try {
        final dir = await getApplicationDocumentsDirectory();
        final String filePath = '${dir.path}/$fileName';

        // Start showing the Snackbar before the download begins
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: ValueListenableBuilder(
        //       valueListenable: downloadProgress,
        //       builder: (context, value, widget) {
        //         return Text(
        //             'Downloading... $value'); // Display the download progress
        //       },
        //     ),
        //     duration: const Duration(
        //         days: 1), // Keep it open - it will be closed manually
        //   ),
        // );

        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              String percent =
                  (received / total * 100).toStringAsFixed(0) + '%';
              // Update the download progress
              downloadProgress.value = percent;
              if (percent == '100%') {
                // Hide the Snackbar when download is complete
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloaded to $filePath')),
                );
              }
            }
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while downloading.')),
        );
      }
    } else {
      // Handle the case when the user declines the permissions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image with interactive viewer
          InteractiveViewer(
            panEnabled: false,
            // Set it to false to prevent panning.
            // boundaryMargin: const EdgeInsets.all(10),
            // minScale: 5.5,
            // maxScale: 10,
            child: listCount == 2
                ? CarouselSlider(
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height-100,
                  // aspectRatio: 16/12,
                  viewportFraction: 0.9,
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  reverse: false,
                  autoPlay: false,
                  // autoPlayInterval: Duration(seconds: 3),
                  // autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  // enlargeFactor: 0.3,
                  // onPageChanged: callbackFunction,
                  scrollDirection: Axis.horizontal,
                ),
                    // options: CarouselOptions(height: 400.0),
                    items: mediaUrls?.map((i) {
                      return Builder(builder: (BuildContext context) {
                        if (i['type'] == "image") {
                         return Stack(
                           children:[
                             Center(
                               child: Image.network(
                                i['url']!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (BuildContext context, Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                            ),
                             ),
                             Positioned(
                               right:0,
                               top: 30,
                               child: GestureDetector(
                                 onTap: () => _downloadImage(i['url']!, context),
                                 child: const Icon(Icons.download, color: Colors.white),
                               ),
                             ),
                         ]);
                        } else {
                          return Stack(
                            children:[
                           Center(
                             child: VideoPlayerWidget(
                                videoUrl: i['url']!,
                              ),
                           ),
                              Positioned(
                                right:0,
                                top: 30,
                                child: GestureDetector(
                                  onTap: () => _downloadImage(i['url']!, context),
                                  child: const Icon(Icons.download, color: Colors.white),
                                ),
                              ),
                         ]);
                        }
                      });
                    }).toList(),
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          // Back Arrow and Close Icon
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back arrow icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  // Close icon
                 if(listCount ==1) GestureDetector(
                    onTap: () => _downloadImage(imageUrl!, context),
                    child: const Icon(Icons.download, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // Post Title, Likes, and Comments
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  post.title??'', // Use the title from the Datum object
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Likes
                    Text(
                      "${post.likes?.length} likes",
                      // Use the likes count from the Datum object
                      style: const TextStyle(color: Colors.white),
                    ),
                    // Comments
                    Text(
                      "${post.comments?.length} comments",
                      // Use the comments count from the Datum object
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
