import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TextViewWidget extends StatelessWidget {
  TextViewWidget({this.label, this.value, this.icon, this.iconColor, this.valueColor, super.key});

  String? label;
  String? value;
  IconData? icon;
  Color? iconColor;
  Color? valueColor;

  @override
  Widget build(BuildContext context) {
    // Default icon color if not provided
    final Color displayIconColor = iconColor ?? Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon (if provided)
          if (icon != null)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(color: displayIconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(icon, size: 16, color: displayIconColor)),
            ),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  capitalizeWords(label ?? ''),
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600], fontSize: 12.sp, fontWeight: FontWeight.w400),
                ),

                const SizedBox(height: 4),

                // Value
                value != null && value!.isNotEmpty
                    ? Text(
                        capitalizeWords(value ?? ''),
                        style: TextStyle(fontFamily: 'Poppins', color: valueColor ?? Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w500),
                      )
                    : Text(
                        translation(context).lbl_not_specified,
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[500], fontSize: 12.sp, fontStyle: FontStyle.italic),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
