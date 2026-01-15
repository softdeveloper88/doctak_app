import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'meeting_detail_screen.dart';

class UpcomingMeetingScreen extends StatefulWidget {
  const UpcomingMeetingScreen({super.key});

  @override
  State<UpcomingMeetingScreen> createState() => _UpcomingMeetingScreenState();
}

class _UpcomingMeetingScreenState extends State<UpcomingMeetingScreen> {
  MeetingBloc meetingBloc = MeetingBloc();
  @override
  void initState() {
    meetingBloc.add(FetchMeetings());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocBuilder<MeetingBloc, MeetingState>(
      bloc: meetingBloc,
      builder: (context, state) {
        if (state is MeetingsLoading) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        } else if (state is MeetingsError) {
          return Center(
            child: Text(state.message, style: TextStyle(color: theme.textSecondary)),
          );
        } else if (state is MeetingsLoaded) {
          return _buildMeetingList(context, theme, meetingBloc.meetings!);
        }
        return Center(
          child: Text(translation(context).msg_no_meetings_scheduled, style: TextStyle(color: theme.textSecondary)),
        );
      },
    );
  }
}

Widget _buildMeetingList(BuildContext context, OneUITheme theme, GetMeetingModel meetingsData) {
  return ListView.builder(
    padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
    itemCount: meetingsData.getMeetingModelList.length ?? 0,
    itemBuilder: (context, index) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: theme.primary),
                const SizedBox(width: 8),
                Text(
                  meetingsData.getMeetingModelList[index].date ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primary),
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
                MeetingDetailScreen(sessions: session, date: meetingsData.getMeetingModelList[index].date).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${translation(context).lbl_joining} ${session.title}'), backgroundColor: theme.primary));
              },
            );
          }),
          Divider(thickness: 1, height: 32, color: theme.surfaceVariant),
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

  const MeetingItem({super.key, required this.time, required this.title, required this.meetingId, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent, width: 1),
        boxShadow: theme.isDark ? [] : [BoxShadow(color: theme.primary.withValues(alpha: 0.05), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                time,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primary),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.videocam_rounded, size: 14, color: theme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text("${translation(context).lbl_meeting_id}: $meetingId", style: TextStyle(fontSize: 12, color: theme.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Join button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
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
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          translation(context).lbl_join,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
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
