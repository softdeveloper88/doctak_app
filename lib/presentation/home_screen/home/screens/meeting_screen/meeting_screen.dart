import 'dart:async';

import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/set_schedule_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/upcoming_meeting_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  ProfileBloc profileBloc = ProfileBloc();
  JobsBloc jobsBloc = JobsBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  final List<String> _filteredSuggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  var selectedValue;
  bool isShownSuggestion = false;
  bool isSearchShow = true;
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          isShownSuggestion = false;
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(title: translation(context).lbl_meeting),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 0 ? theme.cardBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedIndex == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_outlined, size: 18, color: selectedIndex == 0 ? theme.primary : theme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              translation(context).lbl_set_schedule,
                              style: TextStyle(color: selectedIndex == 0 ? theme.primary : theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 1 ? theme.cardBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedIndex == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upcoming_outlined, size: 18, color: selectedIndex == 1 ? theme.primary : theme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              translation(context).lbl_upcoming,
                              style: TextStyle(color: selectedIndex == 1 ? theme.primary : theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            if (selectedIndex == 0) Expanded(child: SetScheduleScreen()) else const Expanded(child: UpcomingMeetingScreen()),
          ],
        ),
      ),
    );
  }
}
