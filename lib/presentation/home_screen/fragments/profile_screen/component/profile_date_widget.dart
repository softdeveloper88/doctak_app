import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/SVCommon.dart';

class ProfileDateWidget extends StatelessWidget {
  ProfileDateWidget(
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
  Widget build(BuildContext context) {
    TextEditingController textEditingController =
        TextEditingController(text: value);

    return isEditModeMap ?? false
        ? Container(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                CustomTextFormField(
                  hintText: label,
                  isReadOnly: true,
                  filled: true,
                  fillColor: AppDecoration.fillGray.color,
                  textInputType: TextInputType.datetime,
                  controller: textEditingController,
                  // Pass the controller here
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      print(pickedDate);
                      DateTime dateTime =
                          DateTime.parse(pickedDate.toIso8601String());

                      // Format the DateTime object to display only the date portion
                      String formattedDate =
                          "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

                      // Update the text field value when a date is selected
                      textEditingController.text = formattedDate;
                      // Call onSave if provided

                      onSave?.call(formattedDate);
                    }
                  },
                  prefix: const SizedBox(
                    width: 10,
                  ),
                  suffix: Container(
                    margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                    child: const Icon(
                      Icons.date_range_outlined,
                      size: 24,
                      color: Colors.blueGrey,
                    ),
                  ),
                  prefixConstraints: const BoxConstraints(maxHeight: 56),
                  validator: (value) {
                    return null;
                  },
                  contentPadding:
                      const EdgeInsets.only(top: 18, right: 30, bottom: 18),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(
                right: 8.0, left: 8.0, top: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  capitalizeWords(label ?? ''),
                  style: GoogleFonts.poppins(
                    color: svGetBodyColor(),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  capitalizeWords(value ?? ''),
                  style: GoogleFonts.poppins(
                      color: svGetBodyColor(),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
  }
}
