import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:sizer/sizer.dart';

import '../../../core/utils/app/AppData.dart';
import '../../../widgets/custom_image_view.dart';
import '../../home_screen/utils/SVCommon.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Function? onTapReginarate;
  File? imageUrl1;
  File? imageUrl2;
  String responseImageUrl1;
  String responseImageUrl2;

  ChatBubble({
    Key? key,
    required this.text,
    required this.isUserMessage,
    this.onTapReginarate,
    required this.imageUrl1,
    required this.imageUrl2,
    this.responseImageUrl1 = '',
    this.responseImageUrl2 = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double bubbleMaxWidth = screenWidth * 0.6;
    // print("response1 ${responseImageUrl}");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment:
          isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUserMessage) ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8.0,
                children: [
                  CircleAvatar(
                    backgroundColor: svGetBodyColor(),
                    child: Image.asset(
                      'assets/logo/ic_web.png',
                      width: 25,
                      height: 25,
                    ),
                  ),
                  Container(
                    width: 75.w,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                      color:
                      appStore.isDarkMode ? Colors.white30 : Colors.white,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 6.0),
                          child: ConstrainedBox(
                              constraints:
                              BoxConstraints(maxWidth: bubbleMaxWidth),
                              child: text == 'Generating response...'
                                  ? Column(
                                children: [
                                  MarkdownBlock(
                                      data: text,
                                      config: MarkdownConfig(configs: [])),
                                  // Text(
                                  //   // fitContent: true,
                                  //   // selectable: true,
                                  //   // softLineBreak: true,
                                  //   // shrinkWrap: true,
                                  //   text
                                  //       .replaceAll("*", '')
                                  //       .replaceAll('#', ''),
                                  //   style:  TextStyle(fontFamily: 'Poppins',
                                  //       color: Colors.black,
                                  //       fontSize: 12.sp),
                                  // ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  CircularProgressIndicator(
                                    color: svGetBodyColor(),
                                  ),
                                ],
                              )
                                  : MarkdownBlock(
                                data: text,
                              )),
                        ),
                        Divider(
                          color: Colors.grey[200],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // InkWell(
                            //   onTap: () => onTapReginarate!(),
                            //   child: const Padding(
                            //     padding: EdgeInsets.all(8.0),
                            //     child: Row(
                            //       children: [
                            //         Icon(Icons.change_circle_outlined),
                            //         Text(' Regenerate')
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                // Copy text to clipboard
                                Clipboard.setData(ClipboardData(text: text));
                                // You can show a snackbar or any other feedback here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Text copied to clipboard'),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              // Expanded(
              //   flex: 1,
              //   child: Align(
              //     alignment: Alignment.topLeft,
              //     child: IconButton(
              //       icon: const Icon(Icons.copy),
              //       onPressed: () {
              //         // Copy text to clipboard
              //         Clipboard.setData(ClipboardData(text: text));
              //         // You can show a snackbar or any other feedback here
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(
              //             content: Text('Text copied to clipboard'),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ] else
              ...[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8.0,
                  children: [
                    Material(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10)),
                      color: Colors.blue[300],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: bubbleMaxWidth),
                            child: Column(
                              children: [
                                if (imageUrl2 != null)
                                  Row(
                                    children: [
                                      if (responseImageUrl1 != '')
                                        SizedBox(
                                            height: 100,
                                            width: 25.w,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl1,
                                            ))
                                      else
                                        if (imageUrl1 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 25.w,
                                              child: imageUrl1 != null
                                                  ? Image.file(
                                                imageUrl1!,
                                                errorBuilder: (BuildContext
                                                context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return const SizedBox();
                                                },
                                              )
                                                  : const SizedBox()),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      if (responseImageUrl2 != '')
                                        SizedBox(
                                            height: 100,
                                            width: 25.w,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl2,
                                            ))
                                      else
                                        if (imageUrl2 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 25.w,
                                              child: imageUrl2 != null
                                                  ? Image.file(
                                                imageUrl2!,
                                                errorBuilder: (BuildContext
                                                context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return const SizedBox();
                                                },
                                              )
                                                  : const SizedBox()),
                                    ],
                                  )
                                else
                                  if (responseImageUrl1 != '')
                                    CustomImageView(
                                      imagePath: responseImageUrl1,
                                    )
                                  else
                                    if (imageUrl1 != null)
                                      Image.file(
                                        imageUrl1!, errorBuilder: (BuildContext
                                      context,
                                          Object exception,
                                          StackTrace? stackTrace) {
                                        return const SizedBox();
                                      },),
                                Text(text,
                                    style: const TextStyle(
                                        color: Colors.white,fontFamily: 'Poppins')),
                              ],
                            )),
                      ),
                    ),
                    CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                          AppData.imageUrl + AppData.profile_pic),
                      radius: 12,
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}
