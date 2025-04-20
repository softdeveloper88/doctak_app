import 'package:flutter/material.dart';

class MeetingInfoScreen extends StatelessWidget {
  final List<Map<String, String>> meetingOptions = [
    {"title": "Start/Stop Meeting", "description": "Meeting owner can start or stop the meeting"},
    {"title": "Mute All Participants", "description": "Meeting owner can not mute all participants"},
    {"title": "Unmute All Participants", "description": "Meeting owner can not unmute all participants"},
    {"title": "Add/Remove Host", "description": "Meeting owner can add or remove hosts"},
    {"title": "Share Screen", "description": "Meeting owner can share their screen"},
    {"title": "Raise Hand", "description": "Meeting participant can raise their hand"},
    {"title": "Send Reactions", "description": "Meeting participant can send reactions"},
    {"title": "Toggle Microphone", "description": "Meeting participant can toggle their microphone"},
    {"title": "Toggle Video", "description": "Meeting participant can toggle their video"},
    {"title": "Enable Waiting Room", "description": "Meeting owner can enable or disable the waiting room\nAsk to Join Meeting"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () =>Navigator.pop(context),
        ),
        title: const Text(
          "Meeting Information",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600,),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: meetingOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600],fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
