import 'package:flutter/cupertino.dart';
import 'package:sizer/sizer.dart';

class TextIconWidget extends StatelessWidget {
  final String text;
  final Widget suffix;
  final TextStyle textStyle;

  TextIconWidget({
    required this.text,
    required this.suffix,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 50.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              text,
              style: textStyle,
              overflow: TextOverflow.visible,
            ),
          ),
          suffix,
        ],
      ),
    );
  }
}
