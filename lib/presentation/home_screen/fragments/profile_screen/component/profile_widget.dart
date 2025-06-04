import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class TextFieldEditWidget extends StatefulWidget {
  TextFieldEditWidget({
    this.index,
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
    this.required = false,
    this.errorText,
    this.iconColor,
    this.editable = true,
    this.obscureText = false,
    super.key
  });

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
  bool required;
  String? errorText;
  Color? iconColor;
  bool editable;
  bool obscureText;

  @override
  State<TextFieldEditWidget> createState() => _TextFieldEditWidgetState();
}

class _TextFieldEditWidgetState extends State<TextFieldEditWidget> {
  late TextEditingController _controller;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TextFieldEditWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value ?? '';
    }
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edit mode with form field
    if (widget.isEditModeMap ?? false) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with required indicator if necessary
          Row(
            children: [
              Text(
                widget.label ?? '',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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

          // Form field
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            child: CustomTextField(
              isReadOnly: !widget.editable, // Fix: readOnly should be opposite of editable
              textInputAction: widget.textInputAction,
              hintText: widget.hints ?? widget.label, // Add fallback hint
              filled: true,
              minLines: 1,
              focusNode: widget.focusNode,
              fillColor: widget.editable ? AppDecoration.fillGray.color : Colors.grey.shade100,
              textInputType: widget.textInputType ?? TextInputType.text,
              autofocus: false, // Fix: don't auto-focus to avoid unwanted behavior
              prefix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(left: 8, right: 8),
                      decoration: BoxDecoration(
                        color: (widget.iconColor ?? Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 16,
                        color: widget.iconColor ?? Colors.blue,
                      ),
                    ),
                ],
              ),
              obscureText: _obscureText,
              suffix: widget.obscureText
                  ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
                  : null,
              prefixConstraints: BoxConstraints(
                minWidth: widget.icon != null ? 60 : 40,
                maxHeight: 56,
              ),
              controller: _controller,
              maxLines: widget.maxLines,
              onChanged: (value) {
                // Fix: Real-time updates as user types
                if (widget.onSave != null) {
                  widget.onSave!(value);
                }
              },
              onSaved: (value) {
                // Fix: Ensure onSave is called and value is updated
                if (widget.onSave != null) {
                  widget.onSave!(value ?? '');
                }
              },
              onFieldSubmitted: (value) {
                // Fix: Ensure onFieldSubmitted works properly
                if (widget.onFieldSubmitted != null) {
                  widget.onFieldSubmitted!(value ?? '');
                }
                if (widget.onSave != null) {
                  widget.onSave!(value ?? '');
                }
              },
              validator: widget.required
                  ? (v) {
                if (v == null || v.isEmpty) {
                  return widget.errorText ?? translation(context).msg_required_field;
                }
                return null;
              }
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
        ],
      );
    }
    // View mode with formatted display
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
            // Icon container (if icon provided)
            if (widget.icon != null)
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: (widget.iconColor ?? Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.iconColor ?? Colors.blue[600],
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
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.value != null && widget.value!.isNotEmpty
                          ? widget.obscureText
                          ? '••••••••'
                          : capitalizeWords(widget.value ?? '')
                          : translation(context).lbl_not_specified,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: widget.value != null && widget.value!.isNotEmpty
                            ? Colors.grey[900]
                            : Colors.grey[500],
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
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