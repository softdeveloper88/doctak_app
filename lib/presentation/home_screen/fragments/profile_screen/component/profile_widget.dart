import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

class TextFieldEditWidget extends StatelessWidget {
  TextFieldEditWidget(
      {this.index,
      this.label,
      this.hints,
      this.isEditModeMap,
      this.value,
      this.onSave,
      this.onFieldSubmitted,
      this.maxLines,
      this.icon,
      this.textInputType,
      this.textInputAction,
      this.focusNode,
      super.key});

  int? index;
  String? label;
  String? hints;
  bool? isEditModeMap;
  String? value;
  Function(String)? onSave;
  Function(String)? onFieldSubmitted;
  int? maxLines;
  IconData? icon;
  TextInputType? textInputType;
  TextInputAction? textInputAction;
  FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (isEditModeMap ?? false) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              label ?? '',
              style:  const TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: CustomTextField(
                textInputAction: textInputAction,
                hintText: hints,
                filled: true,
                minLines: 1,
                focusNode: focusNode,
                fillColor: AppDecoration.fillGray.color,
                textInputType: textInputType ?? TextInputType.text,
                prefix: const SizedBox(
                  width: 10,
                ),
                prefixConstraints: const BoxConstraints(maxHeight: 56),
                initialValue: value,
                maxLines: maxLines,
                onSaved: (v) {
                  onSave?.call(v);
                },
                onFieldSubmitted: (v) {
                  onFieldSubmitted?.call(v);
                },
                contentPadding:
                    const EdgeInsets.only(top: 18, right: 30, bottom: 18)),
          ),
        ],
      );
    } else {
      return Padding(
        padding:
            const EdgeInsets.only(left: 8.0, right: 8.0, top: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                capitalizeWords(label ?? ''),
                style:  TextStyle(fontFamily: 'Poppins',
                    color: svGetBodyColor(),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                textAlign: TextAlign.end,
                capitalizeWords(value ?? ''),
                style:  TextStyle(fontFamily: 'Poppins',
                    color: svGetBodyColor(),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
  }
}
