import 'package:flutter/material.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

class MeetingInfoScreen extends StatelessWidget {
  const MeetingInfoScreen({super.key});

  List<Map<String, dynamic>> getMeetingOptions(BuildContext context) {
    return [
      {"title": translation(context).lbl_start_stop_meeting, "description": translation(context).desc_start_stop_meeting, "icon": Icons.play_circle_outline_rounded},
      {"title": translation(context).lbl_mute_all_participants, "description": translation(context).desc_mute_all_participants, "icon": Icons.mic_off_rounded},
      {"title": translation(context).lbl_unmute_all_participants, "description": translation(context).desc_unmute_all_participants, "icon": Icons.mic_rounded},
      {"title": translation(context).lbl_add_remove_host, "description": translation(context).desc_add_remove_host, "icon": Icons.person_add_alt_1_rounded},
      {"title": translation(context).lbl_share_screen, "description": translation(context).desc_share_screen, "icon": Icons.screen_share_rounded},
      {"title": translation(context).lbl_raise_hand, "description": translation(context).desc_raise_hand, "icon": Icons.back_hand_rounded},
      {"title": translation(context).lbl_send_reactions, "description": translation(context).desc_send_reactions, "icon": Icons.emoji_emotions_rounded},
      {"title": translation(context).lbl_toggle_microphone, "description": translation(context).desc_toggle_microphone, "icon": Icons.settings_voice_rounded},
      {"title": translation(context).lbl_toggle_video, "description": translation(context).desc_toggle_video, "icon": Icons.videocam_rounded},
      {"title": translation(context).lbl_enable_waiting_room, "description": translation(context).desc_enable_waiting_room, "icon": Icons.meeting_room_rounded},
    ];
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          translation(context).lbl_meeting_information,
          style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
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
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.1), theme.secondary.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.info_outline_rounded, color: theme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meeting Features',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Learn about available controls and permissions',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Meeting Options List
              Container(
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent),
                  boxShadow: theme.isDark ? [] : theme.cardShadow,
                ),
                child: Column(
                  children: List.generate(getMeetingOptions(context).length, (index) {
                    final option = getMeetingOptions(context)[index];
                    final isLast = index == getMeetingOptions(context).length - 1;

                    return Column(
                      children: [
                        _buildOptionTile(theme: theme, icon: option['icon'] as IconData, title: option['title'] as String, description: option['description'] as String),
                        if (!isLast) Divider(height: 1, indent: 68, endIndent: 16, color: theme.divider),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({required OneUITheme theme, required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: theme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
