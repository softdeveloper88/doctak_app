// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:voice_message_package/src/helpers/play_status.dart';
// import 'package:voice_message_package/src/helpers/utils.dart';
// import 'package:voice_message_package/src/voice_controller.dart';
// import 'package:voice_message_package/src/widgets/noises.dart';
// import 'package:voice_message_package/src/widgets/play_pause_button.dart';
//
// class VoiceMessageView1 extends StatelessWidget {
//   const VoiceMessageView1({
//     Key? key,
//     required this.controller,
//     this.backgroundColor = Colors.white,
//     this.activeSliderColor = Colors.red,
//     this.notActiveSliderColor,
//     this.circlesColor = Colors.red,
//     this.innerPadding = 12,
//     this.cornerRadius = 20,
//     this.size = 38,
//     this.circlesTextStyle = const TextStyle(
//       color: Colors.white,
//       fontSize: 10,
//       fontWeight: FontWeight.bold,
//     ),
//     this.counterTextStyle = const TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.w500,
//     ),
//   }) : super(key: key);
//
//   final VoiceController controller;
//   final Color backgroundColor;
//   final Color circlesColor;
//   final Color activeSliderColor;
//   final Color? notActiveSliderColor;
//   final TextStyle circlesTextStyle;
//   final TextStyle counterTextStyle;
//   final double innerPadding;
//   final double cornerRadius;
//   final double size;
//
//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final color = circlesColor;
//     final newTheme = theme.copyWith(
//       sliderTheme: SliderThemeData(
//         trackShape: CustomTrackShape(),
//         thumbShape: SliderComponentShape.noThumb,
//         minThumbSeparation: 0,
//       ),
//       splashColor: Colors.transparent,
//     );
//
//     return Container(
//       padding: EdgeInsets.all(innerPadding),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(cornerRadius),
//       ),
//       child: ValueListenableBuilder(
//         valueListenable: controller.updater,
//         builder: (context, value, child) {
//           return Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               PlayPauseButton(controller: controller, color: color, size: size, playIcon: Icon(Icons.play_arrow), pauseIcon: Icon(Icons.pause_circle), refreshIcon: Icon(Icons.refresh), stopDownloadingIcon: Icon(Icons.stop), loadingColor: Colors.white,),
//               SizedBox(width: 8), // Add space between buttons
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(
//                       height: 40, // Adjusted height for noises
//                       child: _noises(newTheme),
//                     ),
//                     SizedBox(height: 4),
//                     Text(controller.remindingTime, style: counterTextStyle),
//                   ],
//                 ),
//               ),
//
//               SizedBox(width: 8), // Add space between buttons
//
//               _changeSpeedButton(color),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   SizedBox _noises(ThemeData newTheme) => SizedBox(
//     height: 30,
//     child: Stack(
//       alignment: Alignment.center,
//       children: [
//         Noises(
//           rList: controller.randoms!,
//           activeSliderColor: activeSliderColor,
//         ),
//         AnimatedBuilder(
//           animation: CurvedAnimation(
//             parent: controller.animController,
//             curve: Curves.ease,
//           ),
//           builder: (BuildContext context, Widget? child) {
//             return Positioned(
//               left: controller.animController.value,
//               child: Container(
//                 width: controller.noiseWidth,
//                 height: 6,
//                 color: notActiveSliderColor ?? backgroundColor.withValues(alpha: .4),
//               ),
//             );
//           },
//         ),
//       ],
//     ),
//   );
//
//   Transform _changeSpeedButton(Color color) => Transform.translate(
//     offset: const Offset(0, -7),
//     child: InkWell(
//       onTap: controller.changeSpeed,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Text(
//           controller.speed.playSpeedStr,
//           style: circlesTextStyle,
//         ),
//       ),
//     ),
//   );
// }
//
// class CustomTrackShape extends RoundedRectSliderTrackShape {
//   @override
//   Rect getPreferredRect({
//     required RenderBox parentBox,
//     Offset offset = Offset.zero,
//     required SliderThemeData sliderTheme,
//     bool isEnabled = false,
//     bool isDiscrete = false,
//   }) {
//     const double trackHeight = 10;
//     final double trackLeft = offset.dx,
//         trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
//     final double trackWidth = parentBox.size.width;
//     return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
//   }
// }
