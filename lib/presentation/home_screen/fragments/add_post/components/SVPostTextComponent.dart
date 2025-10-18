import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:sizer/sizer.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
import '../bloc/add_post_event.dart';

class SVPostTextComponent extends StatefulWidget {
  final Function? onColorChange;
  final Color? colorValue;
  final AddPostBloc searchPeopleBloc;
  final TextEditingController? textController;

  const SVPostTextComponent({
    this.onColorChange,
    this.colorValue,
    required this.searchPeopleBloc,
    this.textController,
    Key? key,
  }) : super(key: key);

  @override
  State<SVPostTextComponent> createState() => _SVPostTextComponentState();
}

class _SVPostTextComponentState extends State<SVPostTextComponent> {
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = widget.textController ?? TextEditingController();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.textController == null) {
      textEditingController.dispose();
    }
    super.dispose();
  }

  // Function to determine text color based on background brightness
  Color _getTextColor(Color? backgroundColor) {
    if (backgroundColor == null) return Colors.black87;

    // Calculate luminance to determine if background is dark or light
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Function to determine hint text color based on background brightness
  Color _getHintTextColor(Color? backgroundColor) {
    if (backgroundColor == null) return Colors.grey[400]!;

    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.grey[600]! : Colors.grey[300]!;
  }

  void _onEditorChanged() {
    // This will be called whenever the document changes
    //String html = convertDeltaToHtml(_controller.document.toDelta());
    // final html = _controller.document.toDelta().toHtml();
    widget.searchPeopleBloc.add(TextFieldEvent(textEditingController.text));
    print(textEditingController.text);
    // Load Del-ta document using HTML
    //     _controller.document = quill.Document.fromDelta(quill.Document.fromHtml(html));
  }

  final FocusNode editorFocusNode = FocusNode();

  // final HtmlEditorController _controller = HtmlEditorController();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Input with Background Color
          Container(
            color: widget.colorValue ?? Colors.transparent,
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: textEditingController,
              focusNode: editorFocusNode,
              minLines: MediaQuery.of(context).size.height > 800 ? 6 : 4,
              maxLines: MediaQuery.of(context).size.height > 800 ? 12 : 8,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: _getTextColor(widget.colorValue),
                height: 1.4,
              ),
              onChanged: (value) {
                widget.searchPeopleBloc.add(TextFieldEvent(value));
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: translation(context).lbl_whats_on_your_mind,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: _getHintTextColor(widget.colorValue),
                ),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
          // PreferredSize(
          //   preferredSize: const Size.fromHeight(kToolbarHeight),
          //   child: quill.QuillToolbar.simple(
          //     configurations: quill.QuillSimpleToolbarConfigurations(
          //       controller: _controller,
          //       sharedConfigurations: const quill.QuillSharedConfigurations(
          //         locale: Locale("en"),
          //       ),
          //       color: Colors.transparent,
          //       axis: Axis.horizontal,
          //       multiRowsDisplay: false,
          //       showBackgroundColorButton: true,
          //       showDirection: true,
          //       fontFamilyValues: const {
          //         "Sem serifa": "sans-serif",
          //         "Condensada": "sans-serif-condensed",
          //         "Serifada": "serif",
          //         "Monoespaçada": "monospace",
          //       },
          //     ),
          //   ),
          // ),
          // Container(
          //   color: widget.colorValue,
          //   height: 20.h,
          //   child: quill.QuillEditor.basic(
          //     focusNode: editorFocusNode,
          //     configurations: quill.QuillEditorConfigurations(
          //       controller: _controller,
          //       placeholder: ' Share what’s on your mind',
          //       sharedConfigurations: const quill.QuillSharedConfigurations(
          //         locale: Locale('en'),
          //       ),
          //     ),
          //   ),
          //   //      QuillEditor(
          //   //   focusNode: FocusNode(),
          //   //   // scrollController: _scrollController,
          //   //   configurations: QuillEditorConfigurations(
          //   //     // embedBuilders: FlutterQuillEmbeds.editorBuilders(
          //   //     // imageEmbedConfigurations: QuillEditorImageEmbedConfigurations(
          //   //     // imageErrorWidgetBuilder: (context, error, stackTrace) {
          //   //     // return Text(
          //   //     // 'Error while loading an image: ${error.toString()}',
          //   //     // );
          //   //     // },
          //   //     // imageProviderBuilder: (context, imageUrl) => NetworkImage(
          //   //     // imageUrl,
          //   //     // ),
          //   //     // ),
          //   //     // ),
          //   //     requestKeyboardFocusOnCheckListChanged: true,
          //   //     padding: const EdgeInsets.all(16),
          //   //     controller: _controller,
          //   //     autoFocus: true,
          //   //     sharedConfigurations: const QuillSharedConfigurations(
          //   //       locale: Locale("en"),
          //   //     ),
          //   //   ),
          //   //   scrollController: ScrollController(),
          //   // )
          // ),
          // Color Selector Section - More compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Color Preview
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: widget.colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Color Picker Button
                InkWell(
                  onTap: () {
                    widget.onColorChange!();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Background',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
