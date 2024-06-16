import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:quill_html_converter/quill_html_converter.dart';
import 'package:sizer/sizer.dart';

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
  final quill.QuillController _controller = quill.QuillController.basic();

  // TextEditingController textEditingController = TextEditingController();
  @override
  void initState() {
    _controller.readOnly = false;
    _controller.addListener(_onEditorChanged);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller.removeListener(_onEditorChanged);

    super.dispose();
  }

  void _onEditorChanged() {
    // This will be called whenever the document changes
    //String html = convertDeltaToHtml(_controller.document.toDelta());
    final html = _controller.document.toDelta().toHtml();
    widget.searchPeopleBloc.add(TextFieldEvent(html));
    print(html);
// Load Delta document using HTML
//     _controller.document = quill.Document.fromDelta(quill.Document.fromHtml(html));
  }

  final FocusNode editorFocusNode = FocusNode();

  // final HtmlEditorController _controller = HtmlEditorController();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      // margin: const EdgeInsets.only(left: 16,right: 8),
      decoration: BoxDecoration(
          color: svGetScaffoldColor(),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(SVAppCommonRadius),
              topRight: Radius.circular(SVAppCommonRadius))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: quill.QuillToolbar.simple(
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(
                  locale: Locale("en"),
                ),
                color: Colors.transparent,
                axis: Axis.horizontal,
                multiRowsDisplay: false,
                showBackgroundColorButton: false,
                showDirection: false,
                fontFamilyValues: const {
                  "Sem serifa": "sans-serif",
                  "Condensada": "sans-serif-condensed",
                  "Serifada": "serif",
                  "Monoespaçada": "monospace",
                },
              ),
            ),
          ),
          SizedBox(
            height: 20.h,
            child: quill.QuillEditor.basic(
              focusNode: editorFocusNode,
              configurations: quill.QuillEditorConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
              ),
            ),
            //      QuillEditor(
            //   focusNode: FocusNode(),
            //   // scrollController: _scrollController,
            //   configurations: QuillEditorConfigurations(
            //     // embedBuilders: FlutterQuillEmbeds.editorBuilders(
            //     // imageEmbedConfigurations: QuillEditorImageEmbedConfigurations(
            //     // imageErrorWidgetBuilder: (context, error, stackTrace) {
            //     // return Text(
            //     // 'Error while loading an image: ${error.toString()}',
            //     // );
            //     // },
            //     // imageProviderBuilder: (context, imageUrl) => NetworkImage(
            //     // imageUrl,
            //     // ),
            //     // ),
            //     // ),
            //     requestKeyboardFocusOnCheckListChanged: true,
            //     padding: const EdgeInsets.all(16),
            //     controller: _controller,
            //     autoFocus: true,
            //     sharedConfigurations: const QuillSharedConfigurations(
            //       locale: Locale("en"),
            //     ),
            //   ),
            //   scrollController: ScrollController(),
            // )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                      color: widget.colorValue,
                      border: Border.all(color: svGetBodyColor(), width: 1),
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: widget.onColorChange!(),
                    icon: Icon(
                      Icons.color_lens,
                      color: svGetBodyColor(),
                      size: 40,
                    )),
              ),
            ],
          )
        ],
      ),
    );
  }
}
