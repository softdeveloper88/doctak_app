import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_history_model.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';

import 'bloc/meeting_bloc.dart';
import 'upcoming_meeting_screen.dart';
import 'video_call_screen.dart';

class ManageMeetingScreen extends StatefulWidget {
  const ManageMeetingScreen({super.key, this.meetingCode, this.autoJoin = false});

  /// Optional meeting code to pre-fill (from deep link)
  final String? meetingCode;

  /// Whether to automatically join the meeting
  final bool autoJoin;

  @override
  State<ManageMeetingScreen> createState() => _ManageMeetingScreenState();
}

class _ManageMeetingScreenState extends State<ManageMeetingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _meetingCodeController = TextEditingController();
  final TextEditingController _meetingTitleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool _showNewMeeting = false;
  bool _isScheduling = false;
  int _durationMinutes = 60;
  String _selectedHistoryFilter = 'all';
  bool _isSearchVisible = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Pusher related properties
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  // Meeting BLoC
  late MeetingBloc meetingBloc = MeetingBloc();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      // Load history when switching to History tab
      if (_tabController.index == 2 && meetingBloc.historyList.isEmpty) {
        meetingBloc.add(FetchMeetingHistory(filter: _selectedHistoryFilter, search: _searchQuery));
      }
    });
    meetingBloc.add(FetchMeetings());
    // Initialize date field with tomorrow's date
    _dateController.text = "${DateTime.now().add(const Duration(days: 1)).toLocal()}".split(' ')[0];

    // Handle deep link auto-join
    if (widget.meetingCode != null && widget.meetingCode!.isNotEmpty) {
      _meetingCodeController.text = widget.meetingCode!;
      // Auto-join after widget is built
      if (widget.autoJoin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoJoinMeeting();
        });
      }
    }
  }

  /// Automatically join meeting from deep link
  void _autoJoinMeeting() {
    final code = _meetingCodeController.text.trim();
    if (code.isNotEmpty) {
      _checkJoinStatus(context, code);
    }
  }

  @override
  void dispose() {
    _meetingCodeController.dispose();
    _meetingTitleController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final theme = OneUITheme.of(context);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: theme.primary, onPrimary: Colors.white, onSurface: theme.textPrimary),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: theme.primary)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _selectTime(TextEditingController controller) async {
    final theme = OneUITheme.of(context);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: theme.primary, onPrimary: Colors.white, onSurface: theme.textPrimary),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.cardBackground,
              hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              dayPeriodColor: theme.primary.withValues(alpha: 0.1),
              dayPeriodTextColor: theme.primary,
              hourMinuteColor: theme.primary.withValues(alpha: 0.1),
              hourMinuteTextColor: theme.primary,
            ),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: theme.primary)),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        controller.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.isDark
          ? theme.scaffoldBackground
          : const Color(0xFFF6F6F8),
      body: Column(
        children: [
          // Unified header card: AppBar + underline tabs (same as Drugs List)
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: theme.isDark ? theme.border : Colors.grey.shade200,
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoctakAppBar(
                  title: translation(context).lbl_meeting_management,
                  titleIcon: Icons.video_call_rounded,
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
                        color: theme.iconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                            _searchQuery = '';
                            if (_tabController.index == 2) {
                              meetingBloc.add(FetchMeetingHistory(filter: _selectedHistoryFilter));
                            }
                          }
                        });
                      },
                    ),
                  ],
                  searchField: _isSearchVisible
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.surfaceVariant),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(color: theme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: translation(context).lbl_search,
                                hintStyle: TextStyle(color: theme.textTertiary),
                                prefixIcon: Icon(Icons.search_rounded, color: theme.textSecondary, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (value) {
                                _searchDebounce?.cancel();
                                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  if (_tabController.index == 2) {
                                    meetingBloc.add(FetchMeetingHistory(
                                      filter: _selectedHistoryFilter,
                                      search: value,
                                    ));
                                  }
                                });
                              },
                            ),
                          ),
                        )
                      : null,
                ),
                OneUITabBar(
                  controller: _tabController,
                  tabs: [
                    translation(context).lbl_join_create,
                    translation(context).lbl_scheduled,
                    translation(context).lbl_history,
                  ],
                  icons: const [
                    Icons.videocam_rounded,
                    Icons.calendar_today_rounded,
                    Icons.history_rounded,
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJoinCreateTab(theme),
                UpcomingMeetingScreen(searchQuery: _searchQuery),
                _buildHistoryTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCreateTab(OneUITheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Join/Create card
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent, width: 1),
              boxShadow: theme.isDark ? [] : [BoxShadow(color: theme.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showNewMeeting ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: _buildJoinMeetingView(theme),
                secondChild: _buildCreateMeetingView(theme),
                sizeCurve: Curves.easeInOut,
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick action buttons
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  ProgressDialogUtils.showProgressDialog();
                  try {
                    await startMeetings().then((createMeeting) async {
                      await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '').then((joinMeetingData) {
                        print('Meeting data${joinMeetingData.toJson()}');
                        ProgressDialogUtils.hideProgressDialog();
                        VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: true).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                      });
                    });
                  } catch (error) {
                    ProgressDialogUtils.hideProgressDialog();
                    showToast(error.toString());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        translation(context).lbl_create_instant_meeting,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, fontFamily: 'Poppins'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Features heading
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                translation(context).lbl_key_features,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Feature cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _buildFeatureCard(theme: theme, icon: Icons.hd_rounded, title: translation(context).lbl_hd_video, description: translation(context).desc_hd_video, color: theme.primary),
              _buildFeatureCard(
                theme: theme,
                icon: Icons.people_alt_rounded,
                title: translation(context).lbl_unlimited_participants,
                description: translation(context).desc_unlimited_participants,
                color: theme.success,
              ),
              _buildFeatureCard(
                theme: theme,
                icon: Icons.screen_share_rounded,
                title: translation(context).lbl_screen_sharing,
                description: translation(context).desc_screen_sharing,
                color: theme.warning,
              ),
              _buildFeatureCard(theme: theme, icon: Icons.chat_rounded, title: translation(context).lbl_group_chat, description: translation(context).desc_group_chat, color: theme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinMeetingView(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.login_rounded, color: theme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translation(context).lbl_join_meeting,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary, fontFamily: 'Poppins'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _showNewMeeting = true;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 14, color: theme.primary),
                  const SizedBox(width: 4),
                  Text(
                    translation(context).lbl_create_instead,
                    style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: theme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            translation(context).msg_enter_meeting_code_description,
            style: TextStyle(color: theme.textSecondary, fontSize: 12, fontFamily: 'Poppins', height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        _buildCustomTextField(
          theme: theme,
          controller: _meetingCodeController,
          labelText: translation(context).lbl_meeting_code,
          hintText: translation(context).hint_enter_meeting_code,
          icon: Icons.meeting_room_rounded,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final code = _meetingCodeController.text.trim();
                if (code.isNotEmpty) {
                  _checkJoinStatus(context, code);
                } else {
                  toast(translation(context).msg_please_enter_meeting_code);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      translation(context).lbl_join_meeting,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCreateMeetingView(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_rounded, color: theme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translation(context).lbl_create_meeting,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary, fontFamily: 'Poppins'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _showNewMeeting = false;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, size: 14, color: theme.primary),
                  const SizedBox(width: 4),
                  Text(
                    translation(context).lbl_join_instead,
                    style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: theme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(translation(context).msg_create_new_meeting_description, style: TextStyle(color: theme.textSecondary, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isScheduling ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomTextField(
                theme: theme,
                controller: _meetingTitleController,
                labelText: translation(context).lbl_meeting_title,
                hintText: translation(context).hint_enter_meeting_title,
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildThemedButton(
                      theme: theme,
                      label: translation(context).lbl_start_meeting,
                      icon: Icons.videocam_rounded,
                      isPrimary: true,
                      color: theme.success,
                      onTap: () {
                        final title = _meetingTitleController.text.trim();
                        // Create instant meeting
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildThemedButton(
                      theme: theme,
                      label: translation(context).lbl_schedule,
                      icon: Icons.calendar_today_rounded,
                      isPrimary: false,
                      onTap: () {
                        setState(() {
                          _isScheduling = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomTextField(
                theme: theme,
                controller: _meetingTitleController,
                labelText: translation(context).lbl_meeting_title,
                hintText: translation(context).hint_enter_meeting_title,
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              _buildCustomTextField(
                theme: theme,
                controller: _dateController,
                labelText: translation(context).lbl_date,
                hintText: translation(context).hint_select_date,
                icon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              _buildCustomTextField(
                theme: theme,
                controller: _startTimeController,
                labelText: translation(context).lbl_time,
                hintText: translation(context).hint_select_time,
                icon: Icons.access_time_rounded,
                readOnly: true,
                onTap: () => _selectTime(_startTimeController),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.surfaceVariant),
                ),
                child: DropdownButtonFormField<int>(
                  initialValue: _durationMinutes,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    labelStyle: TextStyle(color: theme.textSecondary),
                    prefixIcon: Icon(Icons.timelapse_rounded, color: theme.primary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  items: [
                    DropdownMenuItem(value: 30, child: Text(translation(context).lbl_30_minutes)),
                    DropdownMenuItem(value: 60, child: Text(translation(context).lbl_1_hour)),
                    DropdownMenuItem(value: 90, child: Text(translation(context).lbl_1_5_hours)),
                    DropdownMenuItem(value: 120, child: Text(translation(context).lbl_2_hours)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _durationMinutes = value!;
                    });
                  },
                  dropdownColor: theme.cardBackground,
                  icon: Icon(Icons.arrow_drop_down, color: theme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildThemedButton(
                      theme: theme,
                      label: translation(context).lbl_cancel,
                      icon: Icons.close_rounded,
                      isPrimary: false,
                      onTap: () {
                        setState(() {
                          _isScheduling = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildThemedButton(
                      theme: theme,
                      label: translation(context).lbl_schedule_meeting,
                      icon: Icons.schedule_rounded,
                      isPrimary: true,
                      onTap: () async {
                        if (_meetingTitleController.text.isEmpty || _dateController.text.isEmpty || _startTimeController.text.isEmpty) {
                          toast(translation(context).msg_all_fields_required);
                          return;
                        }

                        try {
                          ProgressDialogUtils.showProgressDialog();
                          final response = await setScheduleMeeting(title: _meetingTitleController.text, date: _dateController.text, time: _startTimeController.text, duration: _durationMinutes);

                          Map<String, dynamic> responseData = json.decode(jsonEncode(response.data));
                          ProgressDialogUtils.hideProgressDialog();

                          toast(responseData['message']);
                          setState(() {
                            _isScheduling = false;
                          });

                          _meetingTitleController.clear();
                          _dateController.text = "${DateTime.now().add(const Duration(days: 1)).toLocal()}".split(' ')[0];
                          _startTimeController.clear();

                          _showScheduleSuccessDialog();
                          meetingBloc.add(FetchMeetings());
                        } catch (e) {
                          ProgressDialogUtils.hideProgressDialog();
                          toast('${translation(context).msg_error_scheduling_meeting}: ${e.toString()}');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(key: bottomChildKey, child: bottomChild),
                Positioned(key: topChildKey, child: topChild),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildThemedButton({required OneUITheme theme, required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap, Color? color}) {
    final buttonColor = color ?? theme.primary;

    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textSecondary),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: theme.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCustomTextField({
    required OneUITheme theme,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(color: theme.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(color: theme.textSecondary),
              hintText: hintText,
              hintStyle: TextStyle(color: theme.textTertiary),
              prefixIcon: Icon(icon, color: theme.primary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required OneUITheme theme, required IconData icon, required String title, required String description, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent, width: 1),
        boxShadow: theme.isDark ? [] : [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimary, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: TextStyle(fontSize: 11, color: theme.textSecondary, height: 1.2, fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(OneUITheme theme) {
    return BlocBuilder<MeetingBloc, MeetingState>(
      bloc: meetingBloc,
      builder: (context, state) {
        return Column(
          children: [
            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(theme, translation(context).lbl_all, 'all'),
                  _buildFilterChip(theme, translation(context).lbl_this_week, 'this_week'),
                  _buildFilterChip(theme, translation(context).lbl_this_month, 'this_month'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // History list
            Expanded(
              child: _buildHistoryContent(theme, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryContent(OneUITheme theme, MeetingState state) {
    if (state is MeetingHistoryLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }

    if (state is MeetingHistoryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => meetingBloc.add(FetchMeetingHistory(filter: _selectedHistoryFilter, search: _searchQuery)),
              child: Text(translation(context).lbl_retry),
            ),
          ],
        ),
      );
    }

    if (meetingBloc.historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: theme.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              translation(context).msg_no_meeting_history,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              translation(context).msg_meetings_will_appear_here,
              style: TextStyle(fontSize: 13, color: theme.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          if (!meetingBloc.isHistoryLoading && meetingBloc.historyPage < meetingBloc.historyLastPage) {
            meetingBloc.add(LoadMoreMeetingHistory());
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: meetingBloc.historyList.length + (state is MeetingHistoryLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == meetingBloc.historyList.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: theme.primary)),
            );
          }
          return _buildHistoryCard(theme: theme, item: meetingBloc.historyList[index]);
        },
      ),
    );
  }

  Widget _buildFilterChip(OneUITheme theme, String label, String filterValue) {
    final isSelected = _selectedHistoryFilter == filterValue;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedHistoryFilter = filterValue;
          });
          meetingBloc.add(FetchMeetingHistory(filter: filterValue, search: _searchQuery));
        },
        backgroundColor: theme.surfaceVariant.withValues(alpha: 0.5),
        selectedColor: theme.primary.withValues(alpha: 0.15),
        checkmarkColor: theme.primary,
        labelStyle: TextStyle(color: isSelected ? theme.primary : theme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? theme.primary : Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({required OneUITheme theme, required MeetingHistoryItem item}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent, width: 1),
        boxShadow: theme.isDark ? [] : [BoxShadow(color: theme.primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.video_file_rounded, color: theme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: theme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(item.date, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: theme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(item.formattedDuration, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_rounded, size: 14, color: theme.textSecondary),
                              const SizedBox(width: 4),
                              Text('${item.participantsCount} ${translation(context).lbl_participants}', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                            ],
                          ),
                          if (item.host != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(item.isHost ? Icons.star_rounded : Icons.person_rounded, size: 14, color: item.isHost ? theme.warning : theme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  item.isHost ? translation(context).lbl_you_hosted : '${translation(context).lbl_hosted_by} ${item.host!.name}',
                                  style: TextStyle(color: item.isHost ? theme.warning : theme.textSecondary, fontSize: 12, fontWeight: item.isHost ? FontWeight.w600 : FontWeight.normal),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: theme.surfaceVariant),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildThemedButton(
                      theme: theme,
                      label: translation(context).lbl_details,
                      icon: Icons.info_outline_rounded,
                      isPrimary: false,
                      onTap: () {
                        _showHistoryDetailDialog(theme, item);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistoryDetailDialog(OneUITheme theme, MeetingHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, color: theme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogDetailRow(theme, translation(context).lbl_date, item.date),
            _buildDialogDetailRow(theme, translation(context).lbl_time, item.time),
            _buildDialogDetailRow(theme, translation(context).lbl_duration, item.formattedDuration),
            _buildDialogDetailRow(theme, translation(context).lbl_participants, '${item.participantsCount}'),
            _buildDialogDetailRow(theme, translation(context).lbl_meeting_code, item.meetingChannel),
            if (item.host != null) _buildDialogDetailRow(theme, translation(context).lbl_host, item.host!.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translation(context).lbl_close, style: TextStyle(color: theme.textSecondary)),
          ),
        ],
      ),
    );
  }

  // Functionality from SetScheduleScreen
  void _checkJoinStatus(BuildContext context, String channel) {
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, channel)
        .then((resp) async {
          print("join response ${jsonEncode(resp.data)}");
          Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
          if (responseData['success'] == '1') {
            await joinMeetings(channel).then((joinMeetingData) {
              ProgressDialogUtils.hideProgressDialog();
              VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: false).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            });
          } else {
            _connectPusher(responseData['meeting_id'], channel);
          }
        })
        .catchError((error) {
          ProgressDialogUtils.hideProgressDialog();
          toast("Something went wrong: ${error.toString()}");
        });
  }

  Future<void> _navigateToCallScreen(BuildContext context, String getChannelName) async {
    if (getChannelName.isNotEmpty) {
      _checkJoinStatus(context, getChannelName);
    } else {
      toast('Invalid meeting channel');
    }
  }

  // Pusher related methods
  void _connectPusher(meetingId, channel) async {
    try {
      await pusher.init(
        apiKey: PusherConfig.key,
        cluster: PusherConfig.cluster,
        useTLS: false,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onDecryptionFailure: _onDecryptionFailure,
        onError: _onError,
        onSubscriptionCount: _onSubscriptionCount,
        onAuthorizer: _onAuthorizer,
      );

      pusher.connect();

      // Successfully created and connected to Pusher
      clientListenChannel = await pusher.subscribe(
        channelName: "meeting-channel$meetingId",
        onMemberAdded: (member) {
          // print("Member added: $member");
        },
        onMemberRemoved: (member) {
          print("Member removed: $member");
        },
        onEvent: (event) async {
          String eventName = event.eventName;
          print(eventName);
          switch (eventName) {
            case 'new-user-allowed':
              await joinMeetings(channel).then((joinMeetingData) {
                ProgressDialogUtils.hideProgressDialog();
                VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: false).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
              });
              print("eventName $eventName");
              toast(eventName);
              break;
            case 'new-user-rejected':
              ProgressDialogUtils.hideProgressDialog();
              print("eventName $eventName");
              toast("Meeting join request was rejected");
              break;
            default:
              // Handle unknown event types or ignore them
              break;
          }
        },
      );
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print('Pusher error: $e');
      toast("Connection error: ${e.toString()}");
    }
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
  }

  void _onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
    ProgressDialogUtils.hideProgressDialog();
    toast("Subscription error: $message");
  }

  void _onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  void _onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
    ProgressDialogUtils.hideProgressDialog();
    toast("Error: $message");
  }

  void _onSubscriptionCount(String channelName, int subscriptionCount) {}

  // Authorizer method for Pusher - required to prevent iOS crash
  Future<dynamic>? _onAuthorizer(String channelName, String socketId, dynamic options) async {
    print("_onAuthorizer called for channel: $channelName, socketId: $socketId");

    // For public channels (not starting with 'private-' or 'presence-'),
    // return null
    if (!channelName.startsWith('private-') && !channelName.startsWith('presence-')) {
      return null;
    }

    return null;
  }

  void _showScheduleSuccessDialog() {
    final theme = OneUITheme.of(context);
    final meetingTitle = _meetingTitleController.text.trim().isEmpty ? 'Untitled Meeting' : _meetingTitleController.text.trim();
    final meetingDate = _dateController.text;
    final meetingTime = _startTimeController.text;
    final meetingCode = 'MT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: theme.success, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              'Meeting Scheduled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.success.withValues(alpha: 0.2)),
              ),
              child: Text('Your meeting has been scheduled successfully!', style: TextStyle(color: theme.success)),
            ),
            const SizedBox(height: 20),
            Text(
              translation(context).lbl_meeting_detail,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDialogDetailRow(theme, translation(context).lbl_meeting_title, meetingTitle),
            _buildDialogDetailRow(theme, translation(context).lbl_date, meetingDate),
            _buildDialogDetailRow(theme, translation(context).lbl_time, meetingTime),
            _buildDialogDetailRow(theme, 'Duration', '$_durationMinutes minutes'),
            const SizedBox(height: 16),
            Text(
              translation(context).lbl_meeting_code,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meetingCode,
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.primary, fontSize: 16, letterSpacing: 1.2),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: theme.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: meetingCode));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).msg_meeting_code_copied), backgroundColor: theme.primary));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(translation(context).lbl_close, style: TextStyle(color: theme.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(8)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                  _shareDialog(theme, meetingTitle, meetingDate, meetingTime, meetingCode);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        translation(context).lbl_share,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(OneUITheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: theme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(String meetingId) {
    final theme = OneUITheme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: theme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: theme.error, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              'Cancel Meeting',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.error.withValues(alpha: 0.2)),
          ),
          child: Text('Are you sure you want to cancel this meeting? This action cannot be undone.', style: TextStyle(color: theme.textPrimary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translation(context).lbl_cancel, style: TextStyle(color: theme.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(color: theme.error, borderRadius: BorderRadius.circular(8)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                  toast('Meeting cancelled successfully');
                  meetingBloc.add(FetchMeetings());
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Yes, Cancel',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareDialog(OneUITheme theme, String title, String date, String time, String code) {
    final meetingLink = DeepLinkService.generateMeetingLink(code, title: title);
    final meetingInfo =
        '${translation(context).lbl_meeting}: $title\n${translation(context).lbl_date}: $date\n${translation(context).lbl_time}: $time\n${translation(context).lbl_meeting_code}: $code\n\nJoin: $meetingLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              'Share Meeting Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to share the meeting information',
              style: TextStyle(fontSize: 14, color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  theme: theme,
                  icon: Icons.email_rounded,
                  label: translation(context).lbl_email,
                  color: theme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    DeepLinkService.shareMeeting(meetingId: code, title: title, date: date, time: time);
                  },
                ),
                _buildShareOption(
                  theme: theme,
                  icon: Icons.message_rounded,
                  label: 'SMS',
                  color: theme.success,
                  onTap: () {
                    Navigator.pop(context);
                    DeepLinkService.shareMeeting(meetingId: code, title: title, date: date, time: time);
                  },
                ),
                _buildShareOption(
                  theme: theme,
                  icon: Icons.copy_rounded,
                  label: translation(context).lbl_copy,
                  color: theme.warning,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: meetingInfo));
                    Navigator.pop(context);
                    toast('Meeting details copied to clipboard');
                  },
                ),
                _buildShareOption(
                  theme: theme,
                  icon: Icons.share_rounded,
                  label: 'More',
                  color: theme.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    DeepLinkService.shareMeeting(meetingId: code, title: title, date: date, time: time);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({required OneUITheme theme, required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}
