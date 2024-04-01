import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CustomDropdownButtonFormField extends StatelessWidget {
  CustomDropdownButtonFormField({
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
  List<String> items;
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
      width: width??90.w,
      height: height??50,
      // width: getProportionateScreenWidth(0.5),
      child:
      DropdownButtonFormField<String>(
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
          // color: Colors.black,
        )
            : null,
        // decoration: InputDecoration(
        //   filled: true,
        //   hintText: hint,
        //   fillColor: Colors.white,
        //   border: _outLinedInputBorder(),
        //   enabledBorder: _outLinedInputBorder(),
        //   focusedBorder: _outLinedInputBorder(),
        //   contentPadding: contentPadding ??
        //       const EdgeInsets.symmetric(
        //         horizontal: 6,
        //         // vertical: 13,
        //       ),
        // ),
        items: [
          ...List.generate(
            items.length,
                (index) =>
                DropdownMenuItem<String>(
                  value: items[index],
                  child: Text(
                    items[index],
                    overflow: TextOverflow.visible,
                    style:
                    const TextStyle(
                      fontWeight:  FontWeight.bold ,
                      color:  Colors.black ,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _outLinedInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
      borderSide: const BorderSide(
        color: Colors.black26,
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
