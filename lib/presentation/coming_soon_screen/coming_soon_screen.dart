import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ComingSoonScreen extends StatelessWidget {
 const  ComingSoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: ComingSoonWidget(
          imagePath: 'assets/logo/update-bg.png',
          aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
        ),
      ),
    );
  }
}

class ComingSoonWidget extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;

  const ComingSoonWidget({
    Key? key,
    required this.imagePath,
    this.aspectRatio = 16 / 9, // Default aspect ratio is 16:9
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(
            color: context.iconColor),
        title: Text(translation(context).lbl_coming_soon, style: boldTextStyle(size: 20)),
        elevation: 0,
        leading: IconButton(
            icon:
            Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () {
              Navigator.pop(context);
            }),
        centerTitle: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio, // Adjust the aspect ratio as needed
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
