import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'meeting_detail_screen.dart';

class UpcomingMeetingScreen extends StatefulWidget {
  const UpcomingMeetingScreen({super.key});

  @override
  State<UpcomingMeetingScreen> createState() => _UpcomingMeetingScreenState();
}

class _UpcomingMeetingScreenState extends State<UpcomingMeetingScreen> {
  MeetingBloc meetingBloc=MeetingBloc();
  @override
  void initState() {
  meetingBloc.add(FetchMeetings());
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return  BlocBuilder<MeetingBloc, MeetingState>(
      bloc: meetingBloc,
          builder: (context, state) {
            if (state is MeetingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MeetingsError) {
              return Center(child: Text(state.message));
            } else if (state is MeetingsLoaded) {
              return _buildMeetingList(meetingBloc.meetings!);
            }
            return const Center(child: Text('No meetings scheduled'));
          },

      );
  }
}

Widget _buildMeetingList(GetMeetingModel meetingsData) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: meetingsData.getMeetingModelList.length ?? 0,
    itemBuilder: (context, index) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meetingsData.getMeetingModelList[index].date ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...meetingsData.getMeetingModelList[index].sessions.map((session) {
            return MeetingItem(
              time: session.time,
              title: session.title,
              meetingId: session.channel.toString(),
              onJoin: () {
                MeetingDetailScreen(sessions: session,date:meetingsData.getMeetingModelList[index].date).launch(context,
                    pageRouteAnimation: PageRouteAnimation.Slide);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joining ${session.title}'),
                  ),
                );
              },
            );
          }).toList(),
          Divider(
            thickness: 1,
            height: 32,
            color: Colors.grey.shade200,
          ),
        ],
      );
    },
  );
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
                fontSize: 12,
                color: Colors.black,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Meeting ID: $meetingId",
                    style: const TextStyle(
                      fontSize: 12,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onPressed: onJoin,
              child: const Text(
                'Join',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
