import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TextViewWidget extends StatelessWidget {
  TextViewWidget({this.label, this.value, this.icon, super.key});

  String? label;
  String? value;
  IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              textAlign: TextAlign.start,
              capitalizeWords(label ?? ''),
              style:  TextStyle(fontFamily: 'Poppins-Light',
                  color: svGetBodyColor(),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              textAlign: TextAlign.end,
              capitalizeWords(value ?? ''),
              style:  TextStyle(fontFamily: 'Poppins-Light',
                  color: svGetBodyColor(),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
