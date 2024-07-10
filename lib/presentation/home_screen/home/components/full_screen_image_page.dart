// full_screen_image_page.dart
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/utils/post_utils.dart';
import '../../../../data/models/post_model/post_data_model.dart';
import '../../fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'SVPostComponent.dart';

class FullScreenImagePage extends StatefulWidget {
  String? imageUrl;
  final Post post;
  int listCount;
  List<Map<String, String>>? mediaUrls = [];

  FullScreenImagePage(
      {super.key,
      required this.listCount,
      this.imageUrl,
      required this.post,
      this.mediaUrls});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  String percent = "0";

  ValueNotifier<String> downloadProgress = ValueNotifier('');

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

  bool isShown = true;

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
            child: widget.listCount == 2
                ? CarouselSlider(
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height - 100,
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
                    items: widget.mediaUrls?.map((i) {
                      return Builder(builder: (BuildContext context) {
                        if (i['type'] == "image") {
                          print(i['url']!);
                          return Stack(children: [
                            Center(
                              child: Image.network(
                                i['url']!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 30,
                              child: GestureDetector(
                                onTap: () => _downloadImage(i['url']!, context),
                                child: const Icon(Icons.download,
                                    color: Colors.white),
                              ),
                            ),
                          ]);
                        } else {
                          return Stack(children: [
                            Center(
                              child: VideoPlayerWidget(
                                videoUrl: i['url']!,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 30,
                              child: GestureDetector(
                                onTap: () => _downloadImage(i['url']!, context),
                                child: const Icon(Icons.download,
                                    color: Colors.white),
                              ),
                            ),
                          ]);
                        }
                      });
                    }).toList(),
                  )
                : Image.network(
                    widget.imageUrl!,
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow icon
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                      // Close icon
                      if (widget.listCount == 1)
                        GestureDetector(
                          onTap: () =>
                              _downloadImage(widget.imageUrl!, context),
                          child:
                              const Icon(Icons.download, color: Colors.white),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 100.w,
              height: 50,
              color: Colors.white,
              child: Align(
                alignment: Alignment.center,
                child: InkWell(
                    onTap: () {
                      bottomSheetDialog();
                    },
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                    )),
              ),
            ),
          )
          // Post Title, Likes, and Comments
          // Positioned(
          //   bottom: 20,
          //   top: 100,
          //   left: 0,
          //   right: 0,
          //   child: SingleChildScrollView(
          //     child: Container(
          //       color: Colors.white.withOpacity(0.2),
          //       child: Column(
          //         children: [
          //           if (isShown)
          //             InkWell(
          //                 onTap: () {
          //                   bottomSheetDialog();
          //                 },
          //                 child: Icon(
          //                   Icons.keyboard_arrow_down_rounded,
          //                   color: Colors.white,
          //                 ))
          //           else
          //             InkWell(
          //                 onTap: () {
          //                   setState(() {
          //                     isShown = true;
          //                   });
          //                 },
          //                 child: const Icon(
          //                   Icons.keyboard_arrow_up_rounded,
          //                   color: Colors.white,
          //                 )),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );

  }
bool _isExpanded=false;
  Future<void> bottomSheetDialog() {
    String fullText = widget.post.title ?? '' ?? '';
    List<String> words = fullText.split(' ');
    String textToShow = _isExpanded || words.length <= 25
        ? fullText
        : '${words.take(20).join(' ')}...';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: false, // Prevent dismissal by tapping outside
      backgroundColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.2,
              maxChildSize: 0.75,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.minimize, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    Navigator.of(context).pop();
                                    // Future.microtask(() => bottomSheetDialogWithInitialSize(0.2));
                                  });
                                },
                              ),
                            ],
                          ),
                          if(_isHtml(textToShow))  HtmlWidget(fullText, onTapUrl: (link) async {
                            print('link $link');
                            if (link.contains('doctak/jobs-detail')) {
                              String jobID = Uri.parse(link).pathSegments.last;
                              JobsDetailsScreen(
                                jobId: jobID,
                              ).launch(context);
                            } else {
                              PostUtils.launchURL(context, link);
                            }
                            return true;
                          })

                          else  Linkify(
                            onOpen: (link) {
                              if (link.url.contains('doctak/jobs-detail')) {
                                String jobID =
                                Uri.parse(link.url).pathSegments.last;
                                JobsDetailsScreen(
                                  jobId: jobID,
                                ).launch(context);
                              } else {
                                PostUtils.launchURL(context, link.url);
                              }
                            },
                            text: fullText,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            linkStyle: const TextStyle(
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          // if (words.length > 25)
                          //   TextButton(
                          //     onPressed: () => setState(() {
                          //       _isExpanded = !_isExpanded;
                          //     }),
                          //     child: Text(
                          //       _isExpanded ? 'Show Less' : 'Show More',
                          //       style: const TextStyle(
                          //         color: Colors.white,
                          //         shadows: [
                          //           Shadow(
                          //             offset: Offset(1.0, 1.0),
                          //             blurRadius: 3.0,
                          //             color: Color.fromARGB(255, 0, 0, 0),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // Text(
                          //   widget.post.title ?? '',
                          //   style: const TextStyle(color: Colors.white, fontSize: 20),
                          // ),
                            SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "${widget.post.likes?.length ?? 0} likes",
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                "${widget.post.comments?.length ?? 0} comments",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  bool _isHtml(String text) {
    // Simple regex to check if the string contains HTML tags
    final htmlTagPattern = RegExp(r'<[^>]*>');
    return htmlTagPattern.hasMatch(text);
  }
}