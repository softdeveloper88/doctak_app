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
  Function? onColorChange;
  Color? colorValue;
  AddPostBloc searchPeopleBloc;

  SVPostTextComponent({
    this.onColorChange,
    this.colorValue,
    required this.searchPeopleBloc,
    Key? key,
  }) : super(key: key);

  @override
  State<SVPostTextComponent> createState() => _SVPostTextComponentState();
}

class _SVPostTextComponentState extends State<SVPostTextComponent> {
  // final quill.QuillController _controller = quill.QuillController.basic();

  TextEditingController textEditingController = TextEditingController();
  // @override
  // void initState() {
  //   // _controller.readOnly = false;
  //   textEditingController.addListener(_onEditorChanged);
  //   super.initState();
  // }

  @override
  void dispose() {
    textEditingController.dispose();
    // textEditingController.removeListener(_onEditorChanged);

    super.dispose();
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Text Input Field
          Container(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: textEditingController,
              focusNode: editorFocusNode,
              minLines: 5,
              maxLines: 10,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              onChanged: (value) {
                print(value);
                widget.searchPeopleBloc.add(TextFieldEvent(value));
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: translation(context).lbl_whats_on_your_mind,
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.grey[400],
                ),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
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
          // Color Selector Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Color Preview
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: widget.colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colorValue!.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Color Picker Button
                InkWell(
                  onTap: widget.onColorChange!(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Background',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
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
