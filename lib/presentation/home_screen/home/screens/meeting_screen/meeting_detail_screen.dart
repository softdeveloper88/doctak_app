import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class MeetingDetailScreen extends StatelessWidget {
  final String date = "Today, Jun 1, 2024";
  final String hours = "2:00 - 3:00 AM";
  final String topic = "Design Workshop";
  final String meetingId = "0123 4567 890";
  final String duration = "60 minutes";
  final String timeZone = "Time zone in Islamabad (GMT+5)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Expanded(
            child: Text('Meeting Detail',
                textAlign: TextAlign.left,
                style: boldTextStyle(size: 18))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow("Date", date),
            buildDivider(),
            buildDetailRow("Hours", hours),
            buildDivider(),
            buildDetailRow("Topic", topic),
            buildDivider(),
            buildDetailRow("Meeting ID", meetingId),
            buildDivider(),
            buildDetailRow("Duration", duration),
            buildDivider(),
            buildDetailRow("Time Zone", timeZone),
            const Spacer(),
            // Join Button
            SizedBox(
              width: double.infinity,
              child: svAppButton(
                onTap: () {
                  const HomeScreen1().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                  // Action for Join button

                },
                text: 'Join', context: context
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(color: Colors.grey, height: 16);
  }
}
