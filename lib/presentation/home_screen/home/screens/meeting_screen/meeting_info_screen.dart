import 'package:flutter/material.dart';
import 'package:doctak_app/localization/app_localization.dart';

class MeetingInfoScreen extends StatelessWidget {
  List<Map<String, String>> getMeetingOptions(BuildContext context) {
    return [
      {"title": translation(context).lbl_start_stop_meeting, "description": translation(context).desc_start_stop_meeting},
      {"title": translation(context).lbl_mute_all_participants, "description": translation(context).desc_mute_all_participants},
      {"title": translation(context).lbl_unmute_all_participants, "description": translation(context).desc_unmute_all_participants},
      {"title": translation(context).lbl_add_remove_host, "description": translation(context).desc_add_remove_host},
      {"title": translation(context).lbl_share_screen, "description": translation(context).desc_share_screen},
      {"title": translation(context).lbl_raise_hand, "description": translation(context).desc_raise_hand},
      {"title": translation(context).lbl_send_reactions, "description": translation(context).desc_send_reactions},
      {"title": translation(context).lbl_toggle_microphone, "description": translation(context).desc_toggle_microphone},
      {"title": translation(context).lbl_toggle_video, "description": translation(context).desc_toggle_video},
      {"title": translation(context).lbl_enable_waiting_room, "description": translation(context).desc_enable_waiting_room},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () =>Navigator.pop(context),
        ),
        title: Text(
          translation(context).lbl_meeting_information,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600,),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getMeetingOptions(context).map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600],fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
