import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

class ProfileDateWidget extends StatefulWidget {
  ProfileDateWidget({this.index, this.label, this.isEditModeMap, this.value, this.onSave, this.maxLines, this.icon, this.iconColor, this.required = false, this.editable = true, super.key});

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
    final theme = OneUITheme.of(context);

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
                if (widget.icon != null) Icon(widget.icon ?? Icons.date_range_rounded, size: 18, color: widget.iconColor ?? theme.primary),
                if (widget.icon != null) const SizedBox(width: 8),
                Text(
                  widget.label ?? '',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
                if (widget.required)
                  const Text(
                    ' *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
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
              fillColor: widget.editable ? theme.surfaceVariant : theme.surfaceVariant.withValues(alpha: 0.5),
              textInputType: TextInputType.datetime,
              controller: textEditingController,
              onTap: widget.editable
                  ? () async {
                      FocusScope.of(context).requestFocus(FocusNode());

                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: widget.value != null && widget.value!.isNotEmpty ? DateTime.parse(widget.value!) : DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(data: _buildDatePickerTheme(context, theme), child: child!);
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
                    }
                  : null,
              prefix: const SizedBox(width: 16),
              suffix: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Icon(Icons.calendar_month_rounded, size: 22, color: widget.editable ? theme.primary : theme.textTertiary),
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
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: theme.isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.icon ?? Icons.date_range_rounded, size: 18, color: theme.primary),
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
                      style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.value != null && widget.value!.isNotEmpty ? _formatDateForDisplay(widget.value) ?? '' : translation(context).lbl_not_specified,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: widget.value != null && widget.value!.isNotEmpty ? theme.textPrimary : theme.textTertiary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: widget.value != null && widget.value!.isNotEmpty ? FontStyle.normal : FontStyle.italic,
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

  /// Build One UI 8.5 themed date picker
  ThemeData _buildDatePickerTheme(BuildContext context, OneUITheme theme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: theme.isDark
          ? ColorScheme.dark(primary: theme.primary, onPrimary: Colors.white, surface: theme.cardBackground, onSurface: theme.textPrimary, surfaceContainerHighest: theme.surfaceVariant)
          : ColorScheme.light(primary: theme.primary, onPrimary: Colors.white, surface: theme.cardBackground, onSurface: theme.textPrimary, surfaceContainerHighest: theme.surfaceVariant),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: theme.primary)),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: theme.cardBackground,
        headerBackgroundColor: theme.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        dayStyle: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary),
        weekdayStyle: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary),
        yearStyle: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
