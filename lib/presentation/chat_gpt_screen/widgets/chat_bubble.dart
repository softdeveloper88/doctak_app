import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:sizer/sizer.dart';

import '../../../core/utils/app/AppData.dart';
import '../../../widgets/custom_image_view.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Function? onTapReginarate;
  final File? imageUrl1;
  final File? imageUrl2;
  final String responseImageUrl1;
  final String responseImageUrl2;
  final List<int>? imageBytes1;
  final List<int>? imageBytes2;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUserMessage,
    this.onTapReginarate,
    required this.imageUrl1,
    required this.imageUrl2,
    this.responseImageUrl1 = '',
    this.responseImageUrl2 = '',
    this.imageBytes1,
    this.imageBytes2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double bubbleMaxWidth = screenWidth * 0.6;
    // print("response1 ${responseImageUrl}");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUserMessage) ...[
              Container(
                margin: const EdgeInsets.only(right: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary.withValues(alpha: 0.7), theme.primary]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: theme.primary.withAlpha(51), blurRadius: 4, spreadRadius: 0, offset: const Offset(0, 2))],
                  ),
                  child: const Center(child: Icon(Icons.psychology_rounded, color: Colors.white, size: 20)),
                ),
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)),
                    color: theme.cardBackground,
                    border: Border.all(color: theme.primary.withAlpha(26), width: 1),
                    boxShadow: [BoxShadow(color: theme.primary.withAlpha(13), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: text == translation(context).lbl_generating_response
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MarkdownBlock(
                                      data: text,
                                      config: MarkdownConfig(
                                        configs: [
                                          PreConfig(
                                            decoration: BoxDecoration(color: theme.isDark ? theme.inputBackground : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.all(12),
                                            textStyle: TextStyle(
                                              fontSize: 16.sp, // Responsive font size
                                              fontFamily: 'Poppins',
                                              color: theme.textPrimary,
                                            ),
                                          ),
                                          PConfig(
                                            textStyle: TextStyle(
                                              fontSize: 15.sp, // Responsive font size
                                              fontFamily: 'Poppins',
                                              height: 1.5,
                                              color: theme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CircularProgressIndicator(color: theme.primary),
                                  ],
                                )
                              : MarkdownBlock(
                                  data: text,
                                  config: MarkdownConfig(
                                    configs: [
                                      PreConfig(
                                        decoration: BoxDecoration(color: theme.isDark ? theme.inputBackground : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.all(12),
                                        textStyle: TextStyle(
                                          fontSize: 16.sp, // Responsive font size
                                          fontFamily: 'Poppins',
                                          color: theme.textPrimary,
                                        ),
                                      ),
                                      PConfig(
                                        textStyle: TextStyle(
                                          fontSize: 15.sp, // Responsive font size
                                          fontFamily: 'Poppins',
                                          height: 1.5,
                                          color: theme.textPrimary,
                                        ),
                                      ),
                                      H1Config(
                                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: theme.textPrimary),
                                      ),
                                      H2Config(
                                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: theme.textPrimary),
                                      ),
                                      H3Config(
                                        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: theme.textPrimary),
                                      ),
                                      CodeConfig(
                                        style: TextStyle(fontSize: 14.sp, fontFamily: 'monospace', color: theme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Divider(color: theme.isDark ? Colors.grey[700] : Colors.grey[200]),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).lbl_text_copied_clipboard)));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(left: 48),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4)),
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary.withValues(alpha: 0.85), theme.primary]),
                          boxShadow: [BoxShadow(color: theme.primary.withAlpha(51), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                            child: Column(
                              children: [
                                if (imageUrl2 != null)
                                  Row(
                                    children: [
                                      if (responseImageUrl1 != '')
                                        SizedBox(height: 100, width: 100, child: CustomImageView(imagePath: responseImageUrl1))
                                      else if (imageBytes1 != null && imageBytes1!.isNotEmpty)
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Image.memory(
                                            Uint8List.fromList(imageBytes1!),
                                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                              return const SizedBox();
                                            },
                                          ),
                                        )
                                      else if (imageUrl1 != null)
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Image.file(
                                            imageUrl1!,
                                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                              return const SizedBox();
                                            },
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      if (responseImageUrl2 != '')
                                        SizedBox(height: 100, width: 100, child: CustomImageView(imagePath: responseImageUrl2))
                                      else if (imageBytes2 != null && imageBytes2!.isNotEmpty)
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Image.memory(
                                            Uint8List.fromList(imageBytes2!),
                                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                              return const SizedBox();
                                            },
                                          ),
                                        )
                                      else if (imageUrl2 != null)
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Image.file(
                                            imageUrl2!,
                                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                              return const SizedBox();
                                            },
                                          ),
                                        ),
                                    ],
                                  )
                                else if (responseImageUrl1 != '')
                                  CustomImageView(imagePath: responseImageUrl1)
                                else if (imageBytes1 != null && imageBytes1!.isNotEmpty)
                                  Image.memory(
                                    Uint8List.fromList(imageBytes1!),
                                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                      return const SizedBox();
                                    },
                                  )
                                else if (imageUrl1 != null)
                                  Image.file(
                                    imageUrl1!,
                                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                      return const SizedBox();
                                    },
                                  ),
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 15.sp, // Responsive font size
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 12, bottom: 4),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primary.withAlpha(51), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: AppData.imageUrl + AppData.profile_pic,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
                            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                            'Accept-Encoding': 'gzip, deflate, br',
                            'Connection': 'keep-alive',
                            'Cache-Control': 'no-cache',
                          },
                          placeholder: (context, url) => Container(
                            color: theme.primary.withValues(alpha: 0.1),
                            child: Center(child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) {
                            // Enhanced error debugging for profile images
                            print('🚨 Profile image load error for URL: $url');
                            print('🚨 Error details: $error');
                            print('🚨 Error type: ${error.runtimeType}');

                            return Container(
                              color: theme.primary.withValues(alpha: 0.2),
                              child: Center(child: Icon(Icons.person, color: theme.primary, size: 20)),
                            );
                          },
                        ),
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
