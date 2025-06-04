import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../core/utils/app/AppData.dart';
import '../../../widgets/custom_image_view.dart';
import '../../home_screen/utils/SVCommon.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Function? onTapReginarate;
  final File? imageUrl1;
  final File? imageUrl2;
  final String responseImageUrl1;
  final String responseImageUrl2;

  const ChatBubble({
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
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment:
          isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUserMessage) ...[
              Container(
                margin: const EdgeInsets.only(right: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(51),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    color: appStore.isDarkMode
                        ? Colors.blueGrey[800]
                        : Colors.white,
                    border: Border.all(
                      color: Colors.blue.withAlpha(26),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(13),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: text == translation(context).lbl_generating_response
                                ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MarkdownBlock(
                                    data: text,
                                    config: MarkdownConfig(
                                      configs: [
                                        PreConfig(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ],
                                    )),
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
                              config: MarkdownConfig(
                                configs: [
                                  PreConfig(
                                    decoration: BoxDecoration(
                                      color: appStore.isDarkMode 
                                        ? Colors.grey[800] 
                                        : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                  SnackBar(
                                    content: Text(translation(context).lbl_text_copied_clipboard),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ]

              else ...[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 48),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(4),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.blue[500]!, Colors.blue[700]!],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(51),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
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
                                            width: 100,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl1,
                                            ))
                                      else
                                        if (imageUrl1 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 100,
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
                                            width: 100,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl2,
                                            ))
                                      else
                                        if (imageUrl2 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 100,
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
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ],
                            )),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12, bottom: 4),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withAlpha(51),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                              AppData.imageUrl + AppData.profile_pic),
                          radius: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}