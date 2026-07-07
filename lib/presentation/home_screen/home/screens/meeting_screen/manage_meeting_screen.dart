import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_history_model.dart';
import 'package:doctak_app/data/services/meeting_websocket_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'bloc/meeting_bloc.dart';
import 'upcoming_meeting_screen.dart';
import 'video_call_screen.dart';

class ManageMeetingScreen extends StatefulWidget {
  const ManageMeetingScreen({
    super.key,
    this.meetingCode,
    this.autoJoin = false,
    this.cmeEventId,
  });

  /// Optional meeting code to pre-fill (from deep link)
  final String? meetingCode;

  /// Whether to automatically join the meeting
  final bool autoJoin;

  /// When set, CME attendance is tracked while in the call (learner live sessions).
  final String? cmeEventId;

  @override
  State<ManageMeetingScreen> createState() => _ManageMeetingScreenState();
}

class _ManageMeetingScreenState extends State<ManageMeetingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _meetingCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _selectedHistoryFilter = 'all';
  bool _isSearchVisible = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Meeting realtime WebSocket (replaces Pusher)
  final MeetingWebSocketService _meetingWs = MeetingWebSocketService();
  StreamSubscription<MeetingWsEvent>? _meetingWsSub;

  // Polling fallback so a missed realtime event doesn't strand the user on the
  // strand the user on the "waiting for host" dialog. Cancelled once the
  // transition into VideoCallScreen has happened.
  Timer? _waitingPollTimer;
  bool _meetingTransitionStarted = false;

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
    _searchController.dispose();
    _searchDebounce?.cancel();
    _waitingPollTimer?.cancel();
    _meetingWsSub?.cancel();
    unawaited(_meetingWs.disconnect());
    _tabController.dispose();
    super.dispose();
  }

  void _openScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleMeetingSheet(
        onSuccess: ({required String title, required String date, required String time, required int duration}) {
          _showScheduleSuccessDialog(title: title, date: date, time: time, duration: duration);
          meetingBloc.add(FetchMeetings());
        },
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Instant Meeting card ──────────────────────────
          _buildActionCard(
            theme: theme,
            color: theme.success,
            icon: Icons.videocam_rounded,
            title: translation(context).lbl_create_instant_meeting,
            subtitle: 'Launch a private HD video room instantly — no setup needed.',
            buttonLabel: 'Start Now',
            buttonIcon: Icons.play_arrow_rounded,
            onTap: () async {
              ProgressDialogUtils.showProgressDialog();
              try {
                final createMeeting = await startMeetings();
                final joinMeetingData = await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '');
                ProgressDialogUtils.hideProgressDialog();
                VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: true)
                    .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
              } catch (error) {
                ProgressDialogUtils.hideProgressDialog();
                showToast(error.toString());
              }
            },
          ),

          const SizedBox(height: 12),

          // ── Schedule Meeting card ─────────────────────────
          _buildActionCard(
            theme: theme,
            color: theme.primary,
            icon: Icons.calendar_today_rounded,
            title: translation(context).lbl_schedule_meeting,
            subtitle: 'Plan ahead — set date, time, duration and options.',
            buttonLabel: translation(context).lbl_schedule,
            buttonIcon: Icons.add_rounded,
            onTap: _openScheduleSheet,
          ),

          const SizedBox(height: 12),

          // ── Join Meeting card ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.isDark ? theme.surfaceVariant : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: theme.isDark
                  ? []
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.login_rounded, color: theme.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      translation(context).lbl_join_meeting,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.surfaceVariant),
                        ),
                        child: TextField(
                          controller: _meetingCodeController,
                          style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: 'XXX-XXXX-XX',
                            hintStyle: TextStyle(color: theme.textTertiary, fontSize: 14),
                            prefixIcon: Icon(Icons.meeting_room_rounded, color: theme.textSecondary, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          final code = _meetingCodeController.text.trim();
                          if (code.isNotEmpty) {
                            _checkJoinStatus(context, code);
                          } else {
                            toast(translation(context).msg_please_enter_meeting_code);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'Join',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Features grid ─────────────────────────────────
          const SizedBox(height: 20),
          Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(translation(context).lbl_key_features, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(theme: theme, icon: Icons.hd_rounded, title: translation(context).lbl_hd_video, description: translation(context).desc_hd_video, color: theme.primary),
              _buildFeatureCard(theme: theme, icon: Icons.people_alt_rounded, title: translation(context).lbl_unlimited_participants, description: translation(context).desc_unlimited_participants, color: theme.success),
              _buildFeatureCard(theme: theme, icon: Icons.screen_share_rounded, title: translation(context).lbl_screen_sharing, description: translation(context).desc_screen_sharing, color: theme.warning),
              _buildFeatureCard(theme: theme, icon: Icons.chat_rounded, title: translation(context).lbl_group_chat, description: translation(context).desc_group_chat, color: theme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required OneUITheme theme,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDark ? theme.surfaceVariant : color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: theme.isDark
            ? []
            : [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: theme.textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: color,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(buttonIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    return AppSurfaceCard.listItem(
      margin: const EdgeInsets.only(bottom: AppCardLayout.listGap),
      onTap: () {},
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
    // Reset guards so this works on the second/third join in the same session.
    _meetingTransitionStarted = false;
    _cancelWaitingRoomPolling();
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, channel)
        .then((resp) async {
          print("join response ${jsonEncode(resp.data)}");
          Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));

          // Support both old backend (success='1') and node backend (success=true)
          final success = responseData['success'] == true || responseData['success'] == '1';
          if (!success) {
            ProgressDialogUtils.hideProgressDialog();
            toast(responseData['message']?.toString() ?? "Failed to join meeting");
            return;
          }

          // Node backend: waiting room returns waiting=true or status='waiting_room'
          final isWaiting = responseData['waiting'] == true ||
              responseData['status']?.toString() == 'waiting_room';

          if (isWaiting) {
            // Extract meeting ID — node uses meeting.id, old backend uses meeting_id
            final meetingId =
                (responseData['meeting'] as Map?)?['id']?.toString() ??
                responseData['meeting_id']?.toString();
            _connectMeetingSocket(meetingId, channel);
          } else {
            await joinMeetings(channel).then((joinMeetingData) {
              ProgressDialogUtils.hideProgressDialog();
              VideoCallScreen(
                meetingDetailsModel: joinMeetingData,
                isHost: false,
                cmeEventId: widget.cmeEventId,
              ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            });
          }
        })
        .catchError((error) {
          ProgressDialogUtils.hideProgressDialog();
          toast("Something went wrong: ${error.toString()}");
        });
  }

  void _connectMeetingSocket(dynamic meetingId, String channel) async {
    _startWaitingRoomPolling(channel);
    try {
      final id = meetingId?.toString() ?? '';
      if (id.isEmpty) return;

      _meetingWsSub?.cancel();
      _meetingWsSub = _meetingWs.events.listen((event) async {
        if (event is! MeetingRealtimeEvent) return;
        switch (event.event) {
          case 'allow-join-request':
          case 'new-user-allowed':
            final targetId = event.payload['id']?.toString() ?? '';
            if (targetId.isEmpty || targetId == AppData.logInUserId) {
              await _enterMeetingOnce(channel);
            }
            break;
          case 'reject-join-request':
          case 'new-user-rejected':
            final targetId = event.payload['id']?.toString() ?? '';
            if (targetId.isEmpty || targetId == AppData.logInUserId) {
              _cancelWaitingRoomPolling();
              ProgressDialogUtils.hideProgressDialog();
              toast('Meeting join request was rejected');
            }
            break;
        }
      });
      await _meetingWs.connect(id);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      toast('Connection error: ${e.toString()}');
    }
  }

  /// Idempotent transition into the call screen. Multiple sources can race
  /// to call this (Pusher event + polling fallback); only the first wins.
  Future<void> _enterMeetingOnce(String channel) async {
    if (_meetingTransitionStarted) return;
    _meetingTransitionStarted = true;
    _cancelWaitingRoomPolling();
    try {
      final joinMeetingData = await joinMeetings(channel);
      if (!mounted) return;
      ProgressDialogUtils.hideProgressDialog();
      VideoCallScreen(
        meetingDetailsModel: joinMeetingData,
        isHost: false,
        cmeEventId: widget.cmeEventId,
      ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
    } catch (e) {
      _meetingTransitionStarted = false; // allow retry
      ProgressDialogUtils.hideProgressDialog();
      toast("Failed to enter meeting: $e");
    }
  }

  /// Polls the ask-to-join endpoint as a fallback in case the Pusher
  /// `allow-join-request` event never arrives (websocket drop / DNS failure).
  /// The endpoint returns the participant payload including `isAllowed`,
  /// which flips to `true` once the host approves. We also accept a
  /// non-`waiting_room` status as proof of approval (legacy backends).
  void _startWaitingRoomPolling(String channel) {
    _waitingPollTimer?.cancel();
    _waitingPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_meetingTransitionStarted || !mounted) {
        timer.cancel();
        return;
      }
      try {
        final resp = await askToJoin(context, channel);
        if (resp.success != true) return;
        final data = resp.data is Map<String, dynamic>
            ? resp.data as Map<String, dynamic>
            : Map<String, dynamic>.from(jsonDecode(jsonEncode(resp.data)) as Map);
        final status = data['status']?.toString() ?? '';
        final participant = data['participant'];
        final isAllowed = participant is Map ? participant['isAllowed'] == true : false;
        final approved = isAllowed || (status.isNotEmpty && status != 'waiting_room');
        if (approved) {
          timer.cancel();
          await _enterMeetingOnce(channel);
        }
      } catch (_) {
        // Swallow transient errors — keep polling.
      }
    });
  }

  void _cancelWaitingRoomPolling() {
    _waitingPollTimer?.cancel();
    _waitingPollTimer = null;
  }

  void _showScheduleSuccessDialog({required String title, required String date, required String time, required int duration}) {
    final theme = OneUITheme.of(context);
    final meetingTitle = title.isEmpty ? 'Untitled Meeting' : title;
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
            _buildDialogDetailRow(theme, translation(context).lbl_date, date),
            _buildDialogDetailRow(theme, translation(context).lbl_time, time),
            _buildDialogDetailRow(theme, 'Duration', '$duration minutes'),
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
            onPressed: () => Navigator.of(context).pop(),
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
                  _shareDialog(theme, meetingTitle, date, time, meetingCode);
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

  // ignore: unused_element
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

// ═══════════════════════════════════════════════════════
//  SCHEDULE MEETING BOTTOM SHEET
// ═══════════════════════════════════════════════════════
class _ScheduleMeetingSheet extends StatefulWidget {
  final void Function({required String title, required String date, required String time, required int duration}) onSuccess;

  const _ScheduleMeetingSheet({required this.onSuccess});

  @override
  State<_ScheduleMeetingSheet> createState() => _ScheduleMeetingSheetState();
}

class _ScheduleMeetingSheetState extends State<_ScheduleMeetingSheet> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _descController = TextEditingController();
  int _duration = 60;
  String _type = 'meeting';
  bool _waitingRoom = false;
  bool _registration = false;
  bool _autoRecord = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = "${DateTime.now().add(const Duration(days: 1)).toLocal()}".split(' ')[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final theme = OneUITheme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: theme.primary, onPrimary: Colors.white, onSurface: theme.textPrimary),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: theme.primary)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dateController.text = "${picked.toLocal()}".split(' ')[0]);
    }
  }

  Future<void> _pickTime() async {
    final theme = OneUITheme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
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
      ),
    );
    if (picked != null && mounted) {
      setState(() => _timeController.text = picked.format(context));
    }
  }

  Widget _sectionLabel(OneUITheme theme, String label) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _dropdown<T>({
    required OneUITheme theme,
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.surfaceVariant),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: theme.primary, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.only(right: 8),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: theme.cardBackground,
        icon: Icon(Icons.arrow_drop_down_rounded, color: theme.primary),
        style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins'),
        isExpanded: true,
      ),
    );
  }

  Widget _toggleTile({
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? theme.primary.withValues(alpha: 0.3) : theme.surfaceVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value ? theme.primary.withValues(alpha: 0.1) : theme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: value ? theme.primary : theme.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: theme.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ],
      ),
    );
  }

  Widget _prefixIcon(OneUITheme theme, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(left: 8, right: 8),
          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: theme.primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          // Title bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.calendar_today_rounded, color: theme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule a Meeting', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textPrimary, fontFamily: 'Poppins')),
                      Text('Fill in the details and confirm', style: TextStyle(fontSize: 12, color: theme.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: theme.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: theme.border, height: 1),
          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 100),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel(theme, 'Meeting Details'),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _titleController,
                    hintText: 'Enter meeting title',
                    autofocus: false,
                    textInputAction: TextInputAction.next,
                    prefix: _prefixIcon(theme, Icons.title_rounded),
                    prefixConstraints: const BoxConstraints(minWidth: 60, maxHeight: 56),
                    filled: true,
                    fillColor: theme.inputBackground,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _dateController,
                              hintText: 'Select date',
                              isReadOnly: true,
                              autofocus: false,
                              prefix: _prefixIcon(theme, Icons.calendar_today_rounded),
                              prefixConstraints: const BoxConstraints(minWidth: 60, maxHeight: 56),
                              filled: true,
                              fillColor: theme.inputBackground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _timeController,
                              hintText: 'Select time',
                              isReadOnly: true,
                              autofocus: false,
                              prefix: _prefixIcon(theme, Icons.access_time_rounded),
                              prefixConstraints: const BoxConstraints(minWidth: 60, maxHeight: 56),
                              filled: true,
                              fillColor: theme.inputBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dropdown<int>(
                          theme: theme,
                          label: 'Duration',
                          icon: Icons.timelapse_rounded,
                          value: _duration,
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 60, child: Text('1 hour')),
                            DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                            DropdownMenuItem(value: 120, child: Text('2 hours')),
                            DropdownMenuItem(value: 180, child: Text('3 hours')),
                          ],
                          onChanged: (v) => setState(() => _duration = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dropdown<String>(
                          theme: theme,
                          label: 'Type',
                          icon: Icons.category_rounded,
                          value: _type,
                          items: const [
                            DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                            DropdownMenuItem(value: 'webinar', child: Text('Webinar')),
                            DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                          ],
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _descController,
                    hintText: 'Add a note or agenda for participants...',
                    autofocus: false,
                    maxLines: 4,
                    minLines: 3,
                    textInputType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    prefix: _prefixIcon(theme, Icons.notes_rounded),
                    prefixConstraints: const BoxConstraints(minWidth: 60, maxHeight: 56),
                    filled: true,
                    fillColor: theme.inputBackground,
                    onChanged: (v) {},
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel(theme, 'Options'),
                  const SizedBox(height: 10),
                  _toggleTile(
                    theme: theme,
                    icon: Icons.lock_clock_rounded,
                    title: 'Enable Waiting Room',
                    subtitle: 'Approve participants before they join',
                    value: _waitingRoom,
                    onChanged: (v) => setState(() => _waitingRoom = v),
                  ),
                  const SizedBox(height: 8),
                  _toggleTile(
                    theme: theme,
                    icon: Icons.how_to_reg_rounded,
                    title: 'Require Registration',
                    subtitle: 'Participants must register to join',
                    value: _registration,
                    onChanged: (v) => setState(() => _registration = v),
                  ),
                  const SizedBox(height: 8),
                  _toggleTile(
                    theme: theme,
                    icon: Icons.fiber_manual_record_rounded,
                    title: 'Auto Record',
                    subtitle: 'Start recording automatically when meeting begins',
                    value: _autoRecord,
                    onChanged: (v) => setState(() => _autoRecord = v),
                  ),
                ],
              ),
            ),
          ),
          // Sticky submit bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(top: BorderSide(color: theme.border, width: 0.8)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Material(
              color: theme.primary,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  if (_titleController.text.trim().isEmpty || _dateController.text.isEmpty || _timeController.text.isEmpty) {
                    toast('Please fill in all required fields');
                    return;
                  }
                  try {
                    ProgressDialogUtils.showProgressDialog();
                    final response = await setScheduleMeeting(
                      title: _titleController.text.trim(),
                      date: _dateController.text,
                      time: _timeController.text,
                      duration: _duration,
                      type: _type,
                      description: _descController.text.trim(),
                      enableWaitingRoom: _waitingRoom,
                      requireRegistration: _registration,
                      autoRecord: _autoRecord,
                    );
                    ProgressDialogUtils.hideProgressDialog();
                    if (!mounted) return;
                    final responseData = json.decode(jsonEncode(response.data)) as Map<String, dynamic>;
                    if (responseData['message'] != null) toast(responseData['message'].toString());
                    Navigator.of(context).pop();
                    widget.onSuccess(
                      title: _titleController.text.trim(),
                      date: _dateController.text,
                      time: _timeController.text,
                      duration: _duration,
                    );
                  } catch (e) {
                    ProgressDialogUtils.hideProgressDialog();
                    toast('Error scheduling meeting: ${e.toString()}');
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Schedule Meeting', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
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
}
