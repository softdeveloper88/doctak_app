import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TextViewWidget extends StatelessWidget {
  TextViewWidget(
      {
        this.label,
        this.value,
        this.icon,

        super.key});

  String? label;
  String? value;
  IconData? icon;

  @override
  Widget build(BuildContext context) {
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
