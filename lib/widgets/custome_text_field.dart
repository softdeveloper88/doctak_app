import 'package:flutter/material.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';

import '../presentation/home_screen/utils/SVColors.dart';

class CustomTextField extends StatelessWidget {
   CustomTextField({
    Key? key,
    this.alignment,
    this.width,
    this.scrollPadding,
    this.controller,
    this.focusNode,
    this.autofocus = true,
    this.textStyle,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textInputType = TextInputType.text,
    this.maxLines,
    this.minLines,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled = false,
    this.isReadOnly = false,
    this.initialValue,
    this.onSaved,
    this.onFieldSubmitted,
    this.onChanged,
    this.validator,
  }) : super(
          key: key,
        );

  final Alignment? alignment;

  final double? width;

  final TextEditingController? scrollPadding;

  final TextEditingController? controller;

  final FocusNode? focusNode;

  final bool? autofocus;

  final TextStyle? textStyle;

  final bool? obscureText;

  final TextInputAction? textInputAction;

  final TextInputType? textInputType;

  final int? maxLines;
  final int? minLines;

  final String? hintText;

  final TextStyle? hintStyle;

  final Widget? prefix;

  final BoxConstraints? prefixConstraints;

  final Widget? suffix;

  final BoxConstraints? suffixConstraints;

  final EdgeInsets? contentPadding;

  final InputBorder? borderDecoration;

  final Color? fillColor;

  final bool? filled;

  final bool? isReadOnly;
  final Function(String)? onSaved;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;
  final String? initialValue;

  final FormFieldValidator<String>? validator;

  BuildContext? currentContext;

  @override
  Widget build(BuildContext context) {
    currentContext = context;
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: textFormFieldWidget(context),
          )
        : textFormFieldWidget(context);
  }

  Widget textFormFieldWidget(BuildContext context) => SizedBox(
        width: width ?? double.maxFinite,
        child: TextFormField(
          readOnly: isReadOnly ?? false,
          scrollPadding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          onFieldSubmitted: (v) {
            if (onFieldSubmitted != null) {
              onFieldSubmitted!(v);
            }
          },
          onChanged: (v) {
            if (onChanged != null) {
              onChanged!(v);
            }
          },
          controller: controller,
          focusNode: focusNode ?? FocusNode(),
          autofocus: autofocus!,
          minLines: minLines ?? 1,
          onSaved: (v) {
            if (onSaved != null) {
              onSaved!(v ?? '');
            }
          },
          initialValue: initialValue,
          style: secondaryTextStyle(color: SVAppColorPrimary),
          // style: textStyle ?? CustomTextStyles.titleMediumMedium,
          obscureText: obscureText!,
          textInputAction: textInputAction,
          keyboardType: textInputType,
          maxLines: maxLines ?? 4,
          decoration: decoration,
          validator: validator,
        ),
      );

  InputDecoration get decoration => InputDecoration(
        hintText: hintText ?? translation(currentContext!).lbl_empty,
        hintStyle: hintStyle ?? theme.textTheme.bodyLarge,
        prefixIcon: prefix,
        prefixIconConstraints: prefixConstraints,
        suffixIcon: suffix,
        suffixIconConstraints: suffixConstraints,
        isDense: true,
        contentPadding:
            contentPadding ?? const EdgeInsets.symmetric(vertical: 18),
        fillColor: fillColor,
        filled: filled,
        border: borderDecoration ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: appTheme.gray300,
                width: 1,
              ),
            ),
        enabledBorder: borderDecoration ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: appTheme.gray300,
                width: 1,
              ),
            ),
        focusedBorder: borderDecoration ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1,
              ),
            ),
      );
}

/// Extension on [CustomTextField] to facilitate inclusion of all types of border style etc
extension TextFormFieldStyleHelper on CustomTextField {
  static OutlineInputBorder get outlineGrayTL8 => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: appTheme.gray300,
          width: 1,
        ),
      );
}
