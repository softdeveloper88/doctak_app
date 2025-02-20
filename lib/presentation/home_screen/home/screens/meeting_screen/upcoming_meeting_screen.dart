import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/screen_utils.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'meeting_detail_screen.dart';

class UpcomingMeetingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> meetings = [
    {
      'date': 'Today',
      'sessions': [
        {
          'time': '03:00 PM',
          'title': 'Design Workshop',
          'id': '0123 4567 7890',
          'image': 'https://via.placeholder.com/150',
        },
        {
          'time': '05:00 PM',
          'title': 'Project Briefing',
          'id': '0123 4567 7891',
          'image': 'https://via.placeholder.com/150',
        },
      ]
    },
    {
      'date': 'Tomorrow',
      'sessions': [
        {
          'time': '10:00 AM',
          'title': 'Team Stand-up',
          'id': '0123 4567 7892',
          'image': 'https://via.placeholder.com/150',
        },
        {
          'time': '02:00 PM',
          'title': 'Client Meeting',
          'id': '0123 4567 7893',
          'image': 'https://via.placeholder.com/150',
        },
      ]
    },
    {
      'date': 'Jun 3, 2024',
      'sessions': [
        {
          'time': '11:00 AM',
          'title': 'Code Review',
          'id': '0123 4567 7894',
          'image': 'https://via.placeholder.com/150',
        },
        {
          'time': '03:00 PM',
          'title': 'UI/UX Presentation',
          'id': '0123 4567 7895',
          'image': 'https://via.placeholder.com/150',
        },
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
      shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final section = meetings[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header (Date)
              Text(
                section['date'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Meeting Items
              ...section['sessions'].map<Widget>((session) {
                return MeetingItem(
                  time: session['time'],
                  title: session['title'],
                  meetingId: session['id'],
                  onJoin: () {
                    MeetingDetailScreen().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joining ${session['title']}'),
                      ),
                    );
                  },
                );
              }).toList(),
               Divider(thickness: 1, height: 32,color: Colors.grey.shade200,),
            ],
          );
        },

    );
  }
}

class MeetingItem extends StatelessWidget {
  final String time;
  final String title;
  final String meetingId;
  final VoidCallback onJoin;

  const MeetingItem({
    Key? key,
    required this.time,
    required this.title,
    required this.meetingId,
    required this.onJoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Meeting ID: $meetingId",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),

                ],
              ),
            ),
            MaterialButton(
              minWidth: 80,
              color: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)),
              onPressed: onJoin,
              child:const Text('Join',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
