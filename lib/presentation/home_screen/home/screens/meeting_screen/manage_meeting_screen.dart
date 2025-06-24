import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'bloc/meeting_bloc.dart';
import 'upcoming_meeting_screen.dart';
import 'video_call_screen.dart';

// Custom color palette for professional look
class AppColors {
  static const Color primary = Color(0xFF1E88E5); // Professional blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF26A69A); // Teal accent
  static const Color success = Color(0xFF43A047); // Green
  static const Color danger = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFFA000); // Amber
  static const Color background = Color(0xFFF5F7FA); // Light grey background
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF263238); // Dark text
  static const Color textSecondary = Color(0xFF607D8B); // Grey text
  static const Color divider = Color(0xFFE0E0E0);
  static const Color formFieldBackground = Color(0xFFF5F7FA);
  static const Color formFieldBorder = Color(0xFFE0E0E0);
}

class ManageMeetingScreen extends StatefulWidget {
  const ManageMeetingScreen({Key? key}) : super(key: key);

  @override
  State<ManageMeetingScreen> createState() => _ManageMeetingScreenState();
}

class _ManageMeetingScreenState extends State<ManageMeetingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _meetingCodeController = TextEditingController();
  final TextEditingController _meetingTitleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  late TabController _tabController;
  bool _showNewMeeting = false;
  bool _isScheduling = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  int _durationMinutes = 60;

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
    });
    meetingBloc.add(FetchMeetings());
    // Initialize date field with tomorrow's date
    _dateController.text =
        "${DateTime.now().add(const Duration(days: 1)).toLocal()}"
            .split(' ')[0];
  }

  @override
  void dispose() {
    _meetingCodeController.dispose();
    _meetingTitleController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
        _scheduledDate = pickedDate;
      });
    }
  }

  void _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.cardBackground,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              dayPeriodColor: AppColors.primary.withOpacity(0.1),
              dayPeriodTextColor: AppColors.primary,
              hourMinuteColor: AppColors.primary.withOpacity(0.1),
              hourMinuteTextColor: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        controller.text = pickedTime.format(context);
        _scheduledTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
        body: Column(
          children: [
            // Modern App Bar
            AppBar(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: context.iconColor),
              elevation: 0,
              toolbarHeight: 70,
              surfaceTintColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_call_outlined,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    translation(context).lbl_meeting_management,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Compact Tab Container matching drugs_list_screen style
            Container(
              color: Colors.white,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _tabController.animateTo(0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabController.index == 0 
                              ? Colors.blue
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_tabController.index == 0)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.videocam_outlined,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                Text(
                                  translation(context).lbl_join_create,
                                  style: TextStyle(
                                    color: _tabController.index == 0 
                                      ? Colors.white
                                      : Colors.black87,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _tabController.animateTo(1);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabController.index == 1 
                              ? Colors.blue
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_tabController.index == 1)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                Text(
                                  translation(context).lbl_scheduled,
                                  style: TextStyle(
                                    color: _tabController.index == 1 
                                      ? Colors.white
                                      : Colors.black87,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _tabController.animateTo(2);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabController.index == 2 
                              ? Colors.blue
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_tabController.index == 2)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.history_outlined,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                Text(
                                  translation(context).lbl_history,
                                  style: TextStyle(
                                    color: _tabController.index == 2 
                                      ? Colors.white
                                      : Colors.black87,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
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
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJoinCreateTab(),
                  const UpcomingMeetingScreen(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildJoinCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Join/Create card
          Card(
            elevation: 3,
            shadowColor: AppColors.primary.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showNewMeeting
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildJoinMeetingView(),
                secondChild: _buildCreateMeetingView(),
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
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.accent.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                ProgressDialogUtils.showProgressDialog();
                try {
                  await startMeetings().then((createMeeting) async {
                    await joinMeetings(
                            createMeeting.data?.meeting?.meetingChannel ?? '')
                        .then((joinMeetingData) {
                      ProgressDialogUtils.hideProgressDialog();
                      VideoCallScreen(
                        meetingDetailsModel: joinMeetingData,
                        isHost: true,
                      ).launch(context,
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    });
                  });
                } catch (error) {
                  ProgressDialogUtils.hideProgressDialog();
                  showToast(error.toString());
                }
              },
              icon: const Icon(Icons.videocam, size: 20,color: Colors.white,),
              label: Text(
                translation(context).lbl_create_instant_meeting,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
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
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                translation(context).lbl_key_features,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
              _buildFeatureCard(
                icon: Icons.hd,
                title: translation(context).lbl_hd_video,
                description:
                    translation(context).desc_hd_video,
                color: AppColors.primary,
              ),
              _buildFeatureCard(
                icon: Icons.people_alt_outlined,
                title: translation(context).lbl_unlimited_participants,
                description: translation(context).desc_unlimited_participants,
                color: AppColors.accent,
              ),
              _buildFeatureCard(
                icon: Icons.screen_share_outlined,
                title: translation(context).lbl_screen_sharing,
                description: translation(context).desc_screen_sharing,
                color: AppColors.warning,
              ),
              _buildFeatureCard(
                icon: Icons.chat_outlined,
                title: translation(context).lbl_group_chat,
                description: translation(context).desc_group_chat,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinMeetingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.login_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translation(context).lbl_join_meeting,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
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
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    translation(context).lbl_create_instead,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
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
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Text(
            translation(context).msg_enter_meeting_code_description,
            style: const TextStyle(
              color: AppColors.textSecondary, 
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        _buildCustomTextField(
          controller: _meetingCodeController,
          labelText: translation(context).lbl_meeting_code,
          hintText: translation(context).hint_enter_meeting_code,
          icon: Icons.meeting_room_outlined,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final code = _meetingCodeController.text.trim();
            if (code.isNotEmpty) {
              _checkJoinStatus(context, code);
            } else {
              toast(translation(context).msg_please_enter_meeting_code);
            }
          },
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text(
            translation(context).lbl_join_meeting,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        // const SizedBox(height: 12),
        //  Row(
        //   children: [
        //     const Expanded(child: Divider()),
        //     Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: 12),
        //       child: Text(
        //         translation(context).lbl_or,
        //         style: const TextStyle(
        //           color: AppColors.textSecondary,
        //           fontSize: 12,
        //           fontFamily: 'Poppins',
        //         ),
        //       ),
        //     ),
        //     const Expanded(child: Divider()),
        //   ],
        // ),
        const SizedBox(height: 12),
        // OutlinedButton.icon(
        //   onPressed: () {
        //     // Open camera to scan QR code
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text(translation(context).msg_qr_code_scan_implementation),
        //         backgroundColor: AppColors.primary,
        //       ),
        //     );
        //   },
        //   icon: const Icon(Icons.qr_code_scanner, size: 18),
        //   label: Text(
        //     translation(context).lbl_scan_qr_code,
        //     style: const TextStyle(
        //       fontFamily: 'Poppins',
        //       fontSize: 14,
        //     ),
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        //   style: OutlinedButton.styleFrom(
        //     minimumSize: const Size(double.infinity, 44),
        //     foregroundColor: AppColors.primary,
        //     side: BorderSide(color: AppColors.primary),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildCreateMeetingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.add_circle_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translation(context).lbl_create_meeting,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
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
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.login_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    translation(context).lbl_join_instead,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
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
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Text(
            translation(context).msg_create_new_meeting_description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isScheduling
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomTextField(
                controller: _meetingTitleController,
                labelText: translation(context).lbl_meeting_title,
                hintText: translation(context).hint_enter_meeting_title,
                icon: Icons.title,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final title = _meetingTitleController.text.trim();
                        // Create instant meeting
                      },
                      icon: const Icon(Icons.videocam),
                      label: Text(translation(context).lbl_start_meeting),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isScheduling = true;
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(translation(context).lbl_schedule),
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
                controller: _meetingTitleController,
                labelText: translation(context).lbl_meeting_title,
                hintText: translation(context).hint_enter_meeting_title,
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildCustomTextField(
                controller: _dateController,
                labelText: translation(context).lbl_date,
                hintText: translation(context).hint_select_date,
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              _buildCustomTextField(
                controller: _startTimeController,
                labelText: translation(context).lbl_time,
                hintText: translation(context).hint_select_time,
                icon: Icons.access_time_outlined,
                readOnly: true,
                onTap: () => _selectTime(_startTimeController),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.formFieldBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.formFieldBorder),
                ),
                child: DropdownButtonFormField<int>(
                  value: _durationMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timelapse_outlined),
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
                  dropdownColor: AppColors.cardBackground,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isScheduling = false;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: Text(translation(context).lbl_cancel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Schedule meeting using setScheduleMeeting from VideoAPI
                        if (_meetingTitleController.text.isEmpty ||
                            _dateController.text.isEmpty ||
                            _startTimeController.text.isEmpty) {
                          toast(translation(context).msg_all_fields_required);
                          return;
                        }

                        try {
                          ProgressDialogUtils.showProgressDialog();
                          final response = await setScheduleMeeting(
                            title: _meetingTitleController.text,
                            date: _dateController.text,
                            time: _startTimeController.text,
                          );

                          Map<String, dynamic> responseData =
                              json.decode(jsonEncode(response.data));
                          ProgressDialogUtils.hideProgressDialog();

                          toast(responseData['message']);
                          setState(() {
                            _isScheduling = false;
                          });

                          // Clear fields after successful submission
                          _meetingTitleController.clear();
                          _dateController.text =
                              "${DateTime.now().add(const Duration(days: 1)).toLocal()}"
                                  .split(' ')[0];
                          _startTimeController.clear();

                          // Show success dialog
                          _showScheduleSuccessDialog();

                          // Update meetings list
                          meetingBloc.add(FetchMeetings());
                        } catch (e) {
                          ProgressDialogUtils.hideProgressDialog();
                          toast('${translation(context).msg_error_scheduling_meeting}: ${e.toString()}');
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(translation(context).lbl_schedule_meeting),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
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
                Positioned(
                  key: bottomChildKey,
                  child: bottomChild,
                ),
                Positioned(
                  key: topChildKey,
                  child: topChild,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.formFieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.formFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.2,
                  fontFamily: 'Poppins',
                ),
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

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meeting History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.formFieldBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.primary),
                  onPressed: () {
                    // Open search
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter options
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', true),
              _buildFilterChip('This Week', false),
              _buildFilterChip('This Month', false),
              _buildFilterChip('Custom Range', false),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Past meetings
        _buildHistoryCard(
          title: 'Medical Review Meeting',
          date: DateTime.now().subtract(const Duration(days: 15)),
          duration: const Duration(hours: 1, minutes: 30),
          participants: 8,
          hasRecording: true,
        ),
        _buildHistoryCard(
          title: 'Patient Consultation Workshop',
          date: DateTime.now().subtract(const Duration(days: 30)),
          duration: const Duration(hours: 2, minutes: 15),
          participants: 12,
          hasRecording: false,
        ),
        _buildHistoryCard(
          title: 'Team Weekly Standup',
          date: DateTime.now().subtract(const Duration(days: 7)),
          duration: const Duration(hours: 1, minutes: 0),
          participants: 6,
          hasRecording: true,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Update filter
        },
        backgroundColor: AppColors.formFieldBackground,
        selectedColor: AppColors.primary.withOpacity(0.1),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required DateTime date,
    required Duration duration,
    required int participants,
    required bool hasRecording,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Show meeting details
        },
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
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_file_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$participants participants',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(translation(context).lbl_details),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: AppColors.textSecondary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                  if (hasRecording)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: Text(translation(context).lbl_see_more),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(100, 36),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  // Functionality from SetScheduleScreen
  void _checkJoinStatus(BuildContext context, String channel) {
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, channel).then((resp) async {
      print("join response ${jsonEncode(resp.data)}");
      Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
      if (responseData['success'] == '1') {
        await joinMeetings(channel).then((joinMeetingData) {
          ProgressDialogUtils.hideProgressDialog();
          VideoCallScreen(
            meetingDetailsModel: joinMeetingData,
            isHost: false,
          ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
        });
      } else {
        _connectPusher(responseData['meeting_id'], channel);
      }
    }).catchError((error) {
      ProgressDialogUtils.hideProgressDialog();
      toast("Something went wrong: ${error.toString()}");
    });
  }

  Future<void> _navigateToCallScreen(
      BuildContext context, String getChannelName) async {
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
          onAuthorizer: null);

      pusher.connect();

      if (pusher != null) {
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
                  VideoCallScreen(
                    meetingDetailsModel: joinMeetingData,
                    isHost: false,
                  ).launch(context,
                      pageRouteAnimation: PageRouteAnimation.Slide);
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
      } else {
        ProgressDialogUtils.hideProgressDialog();
        toast("Failed to connect to meeting");
      }
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

  void _showScheduleSuccessDialog() {
    final meetingTitle = _meetingTitleController.text.trim().isEmpty
        ? 'Untitled Meeting'
        : _meetingTitleController.text.trim();
    final meetingDate = _dateController.text;
    final meetingTime = _startTimeController.text;
    final meetingCode =
        'MT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 16),
            const Text(
              'Meeting Scheduled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                ),
              ),
              child: Text(
                translation(context).msg_no_internet,
                style: const TextStyle(color: AppColors.success),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Meeting Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Title', meetingTitle),
            _buildDetailRow('Date', meetingDate),
            _buildDetailRow('Time', meetingTime),
            _buildDetailRow('Duration', '$_durationMinutes minutes'),
            const SizedBox(height: 16),
            const Text(
              'Meeting Code:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meetingCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: meetingCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meeting code copied to clipboard'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
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
            child: Text(translation(context).lbl_close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Show share options
              _shareDialog(meetingTitle, meetingDate, meetingTime, meetingCode);
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(String meetingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 28),
            ),
            const SizedBox(width: 16),
            const Text(
              'Cancel Meeting',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.danger.withOpacity(0.2),
            ),
          ),
          child: Text(
            translation(context).msg_confirm_delete,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translation(context).lbl_cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Cancel meeting API call would go here
              toast('Meeting cancelled successfully');
              // Refresh meetings
              meetingBloc.add(FetchMeetings());
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Yes, Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _shareDialog(String title, String date, String time, String code) {
    final meetingInfo =
        'Meeting: $title\nDate: $date\nTime: $time\nMeeting Code: $code';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Share Meeting Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to share the meeting information',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    toast('Sharing via email...');
                    // Email sharing implementation
                  },
                ),
                _buildShareOption(
                  icon: Icons.message_outlined,
                  label: 'SMS',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    toast('Sharing via SMS...');
                    // SMS sharing implementation
                  },
                ),
                _buildShareOption(
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  color: AppColors.warning,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: meetingInfo));
                    Navigator.pop(context);
                    toast('Meeting details copied to clipboard');
                  },
                ),
                _buildShareOption(
                  icon: Icons.share_outlined,
                  label: 'More',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.pop(context);
                    toast('Opening share options...');
                    // General share implementation
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

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
