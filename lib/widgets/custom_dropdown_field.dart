import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CustomDropdownField extends StatelessWidget {
  CustomDropdownField({
    required this.items,
    required this.value,
    this.hint,
    required this.onChanged,
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
  List<Countries> items;
  String? value;
  String? hint;
  double? width;
  double? height;
  double? textSizedBoxwidth;
  double? borderRadius;
  bool isTextBold;
  EdgeInsets? contentPadding;

  Function onChanged;

  bool? isTimeDropDown;
  bool? isEnableDropDown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width??100.w,
      height: height??60,
      // width: getProportionateScreenWidth(0.5),
      child: DropdownButtonFormField<String>(
        onChanged: isEnableDropDown! ? (value) => onChanged(value) : null,
        value: value,
        decoration: _buildDecoration(),
        iconSize: isTextBold ? 20.0 : 0.0,
        style: TextStyle(
          color: isTextBold ? Colors.black : Colors.grey,
          fontSize: 12,
          fontWeight: isTextBold ? FontWeight.bold : FontWeight.normal,
          overflow: TextOverflow.clip,
        ),
        icon: isTimeDropDown!
            ? Icon(
          Icons.arrow_drop_down,
          size: 12.sp,
        )
            : null,
        isExpanded: true,
        items: [
          ...List.generate(
            items.length,
                (index) => DropdownMenuItem<String>(
              value: items[index].countryName,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    items[index].countryName ?? '',
                    overflow: TextOverflow.visible,
                    style:  TextStyle(
                      fontWeight: FontWeight.bold,
                      color: svGetBodyColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        selectedItemBuilder: (BuildContext context) {
          return items.map((item) {
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                item.countryName ?? '',
                style: TextStyle(
                  color: isTextBold ? svGetBodyColor() : Colors.grey,
                  fontSize: 12,
                  fontWeight: isTextBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList();
        },
      )
    );
  }

  OutlineInputBorder _outLinedInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
      borderSide: const BorderSide(
        color: Colors.transparent,
      ),
    );
  }

  _buildDecoration() {
    return InputDecoration(

      hintText: hint ?? '',
      hintStyle: _setFontStyle(),
      border: _outLinedInputBorder(),
      enabledBorder: _outLinedInputBorder(),
      focusedBorder: _outLinedInputBorder(),
      // prefixIcon: prefix,
      // prefixIconConstraints: prefixConstraints,
      fillColor: Colors.white30,
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.only(
        top: 15,
        left: 10,
        bottom: 15,
      ),
    );
  }

  _setFontStyle() {
    return const TextStyle(
      color: Colors.grey,
      fontSize:
      14,
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
      height: 1.21,

    );
  }
}
