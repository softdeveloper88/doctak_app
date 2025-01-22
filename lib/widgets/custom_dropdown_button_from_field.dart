import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/theme/app_decoration.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CustomDropdownButtonFormField<T> extends StatelessWidget {
  CustomDropdownButtonFormField({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemBuilder,
    this.selectedItemBuilder,
    this.hint,
    this.width,
    this.height,
    this.textSizedBoxwidth,
    this.contentPadding,
    this.borderRadius,
    this.isTimeDropDown = false,
    this.isEnableDropDown = true,
    this.isTextBold = true,

    Key? key,
  }) : super(key: key);

  final List<T> items;
  final T? value;
  final String? hint;
  final double? width;
  final double? height;
  final double? textSizedBoxwidth;
  final double? borderRadius;
  final bool isTextBold;
  final EdgeInsets? contentPadding;

  final Function(T?) onChanged;
  final Widget Function(T) itemBuilder;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  final bool? isTimeDropDown;
  final bool? isEnableDropDown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 90.w,
      height: height ?? 50,
      child: DropdownButtonFormField<T>(
        onChanged: isEnableDropDown! ? (value) => onChanged(value) : null,
        value: value,
        dropdownColor: svGetScaffoldColor(),
        isExpanded: true,
        decoration: _buildDecoration(),
        iconSize: isTextBold ? 20.0 : 0.0,
        style: TextStyle(
          color: isTextBold ? Colors.black : Colors.grey,
          fontSize: 12,
          fontWeight: isTextBold ? FontWeight.bold : FontWeight.normal,
          overflow: TextOverflow.clip,

        ),
        selectedItemBuilder: selectedItemBuilder != null
            ? (context) => selectedItemBuilder!(context)
            : null,
        // selectedItemBuilder:(context){
        //   return items.map((item) {
        //     // You can set any custom value here for the selected item
        //     return Text(style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        //     );
        //   }).toList();
        // },
        icon: isTimeDropDown!
            ? Icon(
          Icons.arrow_drop_down,
          size: 12.sp,
          color: svGetBodyColor(),
        )
            : null,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: itemBuilder(item),
          );
        }).toList(),
      ),
    );
  }
  OutlineInputBorder _outLinedInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
      borderSide: const BorderSide(
        color: Colors.black38,
      ),
    );
  }

  InputDecoration _buildDecoration() {
    return InputDecoration(
      hintText: hint ?? '',
      hintStyle: _setFontStyle(),
      border: _outLinedInputBorder(),
      enabledBorder: _outLinedInputBorder(),
      focusedBorder: _outLinedInputBorder(),
      fillColor: AppDecoration.fillGray.color,
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.only(
        top: 15,
        left: 10,
        bottom: 15,
      ),
    );
  }

  TextStyle _setFontStyle() {
    return const TextStyle(
      color: Colors.grey,
      fontSize: 14,
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
      height: 1.21,
    );
  }
}
