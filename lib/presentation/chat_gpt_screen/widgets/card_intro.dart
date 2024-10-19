import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

cardIntro(title, subTitle, onTap,{double? width}) {
  return Card(
      elevation: 1,
      child: InkWell(
        focusColor: Colors.grey,
        onTap: onTap,
        child: SizedBox(
          width: width??80.w,
          height: 20.h,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.normal),
                  ),
                ]),
          ),
        ),
      ));
}
