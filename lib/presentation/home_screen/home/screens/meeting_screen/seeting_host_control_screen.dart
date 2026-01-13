import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class SettingsHostControlsScreen extends StatefulWidget {
  const SettingsHostControlsScreen(this.settings, this.meetingId, {super.key});

  final Settings? settings;
  final String? meetingId;

  @override
  State<SettingsHostControlsScreen> createState() =>
      _SettingsHostControlsScreenState();
}

class _SettingsHostControlsScreenState
    extends State<SettingsHostControlsScreen> {
  bool startStopMeeting = true;
  bool muteAll = true;
  bool unMuteAll = true;
  bool addRemoveHost = true;
  bool shareScreen = true;
  bool raiseHand = true;
  bool sendReactions = true;
  bool turnOnOffMicrophone = true;
  bool turnOnOffVideo = true;
  bool enableWaitingRoom = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    setState(() {
      startStopMeeting = widget.settings?.startStopMeeting == '1';
      muteAll = widget.settings?.muteAll == '1';
      unMuteAll = widget.settings?.unmuteAll == '1';
      addRemoveHost = widget.settings?.addRemoveHost == '1';
      shareScreen = widget.settings?.shareScreen == '1';
      raiseHand = widget.settings?.raisedHand == '1';
      sendReactions = widget.settings?.sendReactions == 1;
      turnOnOffMicrophone = widget.settings?.toggleMicrophone == 1;
      turnOnOffVideo = widget.settings?.toggleVideo == 1;
      enableWaitingRoom = widget.settings?.enableWaitingRoom == 1;
    });
  }

  Future<void> _updateSettings() async {
    await updateMeetingSetting(
      meetingId: widget.meetingId,
      startStopMeeting: startStopMeeting ? '1' : '0',
      addRemoveHost: addRemoveHost ? '1' : '0',
      shareScreen: shareScreen ? '1' : '0',
      raisedHand: raiseHand ? '1' : '0',
      sendReactions: sendReactions ? '1' : '0',
      toggleMicrophone: turnOnOffMicrophone ? '1' : '0',
      toggleVideo: turnOnOffVideo ? '1' : '0',
      enableWaitingRoom: enableWaitingRoom ? '1' : '0',
      requirePassword: '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          translation(context).lbl_settings_host_controls,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Host Management Section
              _buildSectionCard(
                theme: theme,
                icon: Icons.admin_panel_settings_rounded,
                title: translation(context).lbl_host_management,
                description: translation(context).desc_host_management,
                children: [
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.play_circle_outline_rounded,
                    title: translation(context).lbl_start_stop_meeting,
                    value: startStopMeeting,
                    onChanged: (val) async {
                      setState(() => startStopMeeting = val);
                      await _updateSettings();
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.person_add_alt_1_rounded,
                    title: translation(context).lbl_add_remove_host,
                    value: addRemoveHost,
                    onChanged: (val) async {
                      setState(() => addRemoveHost = val);
                      await _updateSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Participant Controls Section
              _buildSectionCard(
                theme: theme,
                icon: Icons.people_alt_rounded,
                title: translation(context).lbl_participant_controls,
                description: translation(context).desc_participant_controls,
                children: [
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.screen_share_rounded,
                    title: translation(context).lbl_share_screen,
                    value: shareScreen,
                    onChanged: (val) async {
                      setState(() => shareScreen = val);
                      await _updateSettings();
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.back_hand_rounded,
                    title: translation(context).lbl_raise_hand,
                    value: raiseHand,
                    onChanged: (val) async {
                      setState(() => raiseHand = val);
                      await _updateSettings();
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.emoji_emotions_rounded,
                    title: translation(context).lbl_send_reactions,
                    value: sendReactions,
                    onChanged: (val) async {
                      setState(() => sendReactions = val);
                      await _updateSettings();
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.mic_rounded,
                    title: translation(context).lbl_toggle_microphone,
                    value: turnOnOffMicrophone,
                    onChanged: (val) async {
                      setState(() => turnOnOffMicrophone = val);
                      await _updateSettings();
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.videocam_rounded,
                    title: translation(context).lbl_toggle_video,
                    value: turnOnOffVideo,
                    onChanged: (val) async {
                      setState(() => turnOnOffVideo = val);
                      await _updateSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meeting Privacy Settings Section
              _buildSectionCard(
                theme: theme,
                icon: Icons.security_rounded,
                title: translation(context).lbl_meeting_privacy_settings,
                description: translation(context).desc_meeting_privacy_settings,
                children: [
                  _buildSwitchTile(
                    theme: theme,
                    icon: Icons.meeting_room_rounded,
                    title: translation(context).lbl_enable_waiting_room,
                    value: enableWaitingRoom,
                    onChanged: (val) async {
                      setState(() => enableWaitingRoom = val);
                      await _updateSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
        ),
        boxShadow: theme.isDark ? [] : theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.divider),
          // Controls List
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? theme.primary.withOpacity(0.1)
                  : theme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? theme.primary : theme.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
            activeTrackColor: theme.primary.withOpacity(0.3),
            inactiveThumbColor: theme.isDark ? Colors.white70 : Colors.white,
            inactiveTrackColor: theme.isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
