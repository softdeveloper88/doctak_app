import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileWidget extends StatefulWidget {
  ProfileWidget(
      {this.index,
      this.label,
      this.isEditModeMap,
      this.value,
      this.onSave,
      this.maxLines,
      this.icon,
      super.key});

  int? index;
  String? label;
  bool? isEditModeMap;
  String? value;
  Function(String)? onSave;
  int? maxLines;
  IconData? icon;

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isEditModeMap ?? false) {
      return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.label ?? '',
                  style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: CustomTextField(
                    hintText: widget.label,
                    filled: true,
                    fillColor: AppDecoration.fillGray.color,
                    textInputType: TextInputType.text,
                    prefix: const SizedBox(width: 10,),
                    prefixConstraints: BoxConstraints(maxHeight: 56.v),
                    initialValue: widget.value,
                    maxLines: widget.maxLines,
                    onSaved: (v) {
                      widget.onSave?.call(v);
                    },
                    contentPadding:
                        EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v)),
              ),
            ],
          );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${capitalizeWords(widget.label!)}:',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  capitalizeWords(widget.value!),
                  style: const TextStyle(fontSize: 16),
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
                  margin: EdgeInsets.fromLTRB(24.h, 16.v, 16.h, 16.v),
                  child: Icon(
                    icon,
                    size: 24.adaptSize,
                    color: Colors.blueGrey,
                    // imagePath: Icon(Icons),
                    // height: 24.adaptSize,
                    // width: 24.adaptSize
                  )),
              prefixConstraints: BoxConstraints(maxHeight: 56.v),
              initialValue: value,
              maxLines: maxLines,
              onSaved: (v) {
                onSave?.call(v);
              },
              contentPadding:
                  EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v)),
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
