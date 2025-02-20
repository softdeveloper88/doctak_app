import 'dart:async';

import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/set_schedule_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/upcoming_meeting_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({Key? key}) : super(key: key);

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  ProfileBloc profileBloc = ProfileBloc();
  JobsBloc jobsBloc = JobsBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];

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
    return GestureDetector(
      onTap: () {
        setState(() {
          isShownSuggestion = false;
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        body: Column(
          children: [
            AppBar(
              surfaceTintColor: svGetScaffoldColor(),
              backgroundColor: svGetScaffoldColor(),
              iconTheme: IconThemeData(color: context.iconColor),
              title: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('Meeting',
                          textAlign: TextAlign.left,
                          style: boldTextStyle(size: 18))),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: svGetBodyColor()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
              centerTitle: false,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Expanded(
                child: Container(
                  color: svGetScaffoldColor(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {});
                                    selectedIndex = 0;
                                  },
                                  child: Text(
                                    'Set Schedule',
                                    style: TextStyle(
                                      color: selectedIndex == 0 ? Colors.black:Colors.black38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: context.width() / 2 - 10,
                                  color: selectedIndex == 0
                                      ? SVAppColorPrimary
                                      : SVAppColorPrimary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            Center(
                                child: Container(
                              color: Colors.grey.shade300,
                              height: 30,
                              width: 1,
                            )),
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() { });
                                    selectedIndex = 1;
                                  },
                                  child: Text(
                                    'Upcoming',
                                    style: TextStyle(
                                      color: selectedIndex == 1 ? Colors.black:Colors.black38,
                                      fontSize: 14,
                                      fontWeight:FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: context.width() / 2 - 10,
                                  color: selectedIndex == 1
                                      ? SVAppColorPrimary
                                      : SVAppColorPrimary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            16.height,
                          ],
                        ),
                      ),
                      const SizedBox(height: 10,),
                      if(selectedIndex==0) SetScheduleScreen()
                        else UpcomingMeetingScreen()

                    ],
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
