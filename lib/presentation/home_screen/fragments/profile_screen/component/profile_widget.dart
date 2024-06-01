import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TextFieldEditWidget extends StatelessWidget {
  TextFieldEditWidget(
      {this.index,
      this.label,
      this.isEditModeMap,
      this.value,
      this.onSave,
      this.maxLines,
      this.icon,
      this.textInputType,
      super.key});

  int? index;
  String? label;
  bool? isEditModeMap;
  String? value;
  Function(String)? onSave;
  int? maxLines;
  IconData? icon;
  TextInputType? textInputType;

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
                  style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: CustomTextField(
                    hintText: label,
                    filled: true,
                    fillColor: AppDecoration.fillGray.color,
                    textInputType: textInputType ?? TextInputType.text,
                    prefix: const SizedBox(width: 10,),
                    prefixConstraints: const BoxConstraints(maxHeight: 56),
                    initialValue: value,
                    maxLines: maxLines,
                    onSaved: (v) {
                      onSave?.call(v);
                    },
                    contentPadding:
                        const EdgeInsets.only(top: 18, right: 30, bottom: 18)),
              ),
            ],
          );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 16,bottom: 16),
        child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  capitalizeWords(label??''),
                  style:GoogleFonts.poppins(color: svGetBodyColor(),fontSize: 10.sp,fontWeight: FontWeight.w500),
                ),
                Text(
                  capitalizeWords(value??''),
                    style:GoogleFonts.poppins(color: svGetBodyColor(),fontSize: 10.sp,fontWeight: FontWeight.w500),

    ),
              ],
            ),
      );
    }
  }
}

Widget _buildField(
    {required int index,
    required String label,
    required bool isEditModeMap,
    required String value,
    void Function(String)? onSave,
    int? maxLines,
    required IconData icon}) {
  return isEditModeMap
      ? Container(
          margin: const EdgeInsets.only(top: 4),
          child: CustomTextField(
              hintText: label,
              textInputType: TextInputType.text,
              prefix: Container(
                  margin: EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Colors.blueGrey,
                    // imagePath: Icon(Icons),
                    // height: 24.adaptSize,
                    // width: 24.adaptSize
                  )),
              prefixConstraints: BoxConstraints(maxHeight: 56),
              initialValue: value,
              maxLines: maxLines,
              onSaved: (v) {
                onSave?.call(v);
              },
              contentPadding:
                  EdgeInsets.only(top: 18, right: 30, bottom: 18)),
        )
      // ?  TextFormField(
      //           initialValue: value,
      //           decoration: InputDecoration(
      //               labelText: label,
      //               labelStyle: const TextStyle(
      //                   color: Colors.blueGrey, fontWeight: FontWeight.bold)),
      //           maxLines: maxLines,
      //           onSaved: (v) => onSave?.call(v!),
      //         )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${capitalizeWords(label)}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              capitalizeWords(value),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        );
}
