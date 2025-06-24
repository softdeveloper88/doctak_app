import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
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
            return Center(child: Text(translation(context).msg_no_meetings_scheduled));
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  meetingsData.getMeetingModelList[index].date ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
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
                    content: Text('${translation(context).lbl_joining} ${session.title}'),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Meeting info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${translation(context).lbl_meeting_id}: $meetingId",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Join button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onJoin,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          translation(context).lbl_join,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
