import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/SVCommon.dart';

class ProfileDateWidget extends StatefulWidget {
  ProfileDateWidget({
    this.index,
    this.label,
    this.isEditModeMap,
    this.value,
    this.onSave,
    this.maxLines,
    this.icon,
    this.iconColor,
    this.required = false,
    this.editable = true,
    super.key
  });

  int? index;
  String? label;
  bool? isEditModeMap;
  String? value;
  Function(String)? onSave;
  int? maxLines;
  IconData? icon;
  Color? iconColor;
  bool required;
  bool editable;

  @override
  State<ProfileDateWidget> createState() => _ProfileDateWidgetState();
}

class _ProfileDateWidgetState extends State<ProfileDateWidget> {
  late TextEditingController textEditingController;

  // Display formatting for dates
  String? _formatDateForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat.yMMMMd().format(date); // e.g., "January 15, 2023"
    } catch (e) {
      // If the date couldn't be parsed, return the original string
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileDateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      textEditingController.text = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edit mode
    if (widget.isEditModeMap ?? false) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label with required indicator if necessary
            Row(
              children: [
                if (widget.icon != null)
                  Icon(
                    widget.icon ?? Icons.date_range_rounded,
                    size: 18,
                    color: widget.iconColor ?? Colors.blue[700],
                  ),
                if (widget.icon != null)
                  const SizedBox(width: 8),
                Text(
                  widget.label ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (widget.required)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Date picker field
            CustomTextFormField(
              // enabled: widget.editable,
              hintText: translation(context).hint_select_date,
              isReadOnly: true,
              filled: true,
              fillColor: widget.editable ? Colors.grey.shade50 : Colors.grey.shade100,
              textInputType: TextInputType.datetime,
              controller: textEditingController,
              onTap: widget.editable ? () async {
                FocusScope.of(context).requestFocus(FocusNode());

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.value != null && widget.value!.isNotEmpty
                      ? DateTime.parse(widget.value!)
                      : DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.blue[600]!,
                          onPrimary: Colors.white,
                          onSurface: Colors.grey[900]!,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  DateTime dateTime = DateTime.parse(pickedDate.toIso8601String());
                  String formattedDate = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                  setState(() {
                    textEditingController.text = formattedDate;
                  });
                  widget.onSave?.call(formattedDate);
                }
              } : null,
              prefix: const SizedBox(width: 16),
              suffix: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 22,
                  color: widget.editable ? Colors.blue[700] : Colors.grey[400],
                ),
              ),
              prefixConstraints: const BoxConstraints(maxHeight: 56),
              validator: widget.required
                  ? (value) {
                if (value == null || value.isEmpty) {
                  return translation(context).msg_required_field;
                }
                return null;
              }
                  : null,
              contentPadding: const EdgeInsets.only(top: 18, right: 30, bottom: 18),
            ),
          ],
        ),
      );
    }
    // View mode
    else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon ?? Icons.date_range_rounded,
                size: 18,
                color: Colors.blue[600],
              ),
            ),

            // Label and value
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      capitalizeWords(widget.label ?? ''),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey[700],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.value != null && widget.value!.isNotEmpty
                          ? _formatDateForDisplay(widget.value) ?? ''
                          : translation(context).lbl_not_specified,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: widget.value != null && widget.value!.isNotEmpty
                            ? Colors.grey[900]
                            : Colors.grey[500],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: widget.value != null && widget.value!.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
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
}