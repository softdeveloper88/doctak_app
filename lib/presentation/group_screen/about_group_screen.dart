import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';

class AboutGroupScreen extends StatelessWidget {
  AboutGroupScreen(this.groupBloc, {super.key});
  GroupBloc? groupBloc;
  String decodeDataFromJson(data) {
    List<dynamic> decodedJson = jsonDecode(data);

    var values = decodedJson.map((item) => item['value'] as String).toList();
    return values.join(',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        title: const Text('About Group'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(groupBloc?.groupDetailsModel?.group?.logo ?? ''), // Add your image asset
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupBloc?.groupAboutModel?.group?.name ?? '',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${groupBloc?.groupDetailsModel?.group?.privacySetting ?? ''} Group · ${groupBloc?.groupDetailsModel?.totalMembers ?? ''} members', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(groupBloc?.groupAboutModel?.group?.description ?? ""),
            const SizedBox(height: 16),
            buildListTile("assets/images/img_speciality.png", 'Specialty Focus', decodeDataFromJson(groupBloc?.groupAboutModel?.group?.specialtyFocus)),
            buildListTile('assets/images/img_privacy.png', 'Privacy Setting', '${groupBloc?.groupAboutModel?.group?.privacySetting}'),
            buildListTile('assets/images/img_tags.png', 'Tags', decodeDataFromJson(groupBloc?.groupAboutModel?.group?.tags)),
            buildListTile('assets/images/img_location.png', 'Location', '${groupBloc?.groupAboutModel?.group?.location}'),
            buildListTile('assets/images/img_interest.png', 'Interest', decodeDataFromJson(groupBloc?.groupAboutModel?.group?.interest)),
            ListTile(
              leading: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: svGetBgColor(), borderRadius: BorderRadius.circular(100)),
                child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset('assets/images/img_rules.png', height: 15, width: 15)),
              ),
              title: const Text('Rules'),
              subtitle: Text(groupBloc?.groupAboutModel?.group?.rules ?? ''),
            ),
            buildListTile('assets/images/img_group.png', 'Join Request', groupBloc?.groupAboutModel?.group?.joinRequest ?? ''),
            buildListTile('assets/images/img_status.png', 'Status', groupBloc?.groupAboutModel?.group?.status ?? ''),
            buildListTile('assets/images/img_language.png', 'Language', decodeDataFromJson(groupBloc?.groupAboutModel?.group?.language)),
            buildListTile('assets/images/img_visability.png', 'Visibility', groupBloc?.groupAboutModel?.group?.visibility ?? ''),
          ],
        ),
      ),
    );
  }

  Widget buildListTile(String icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(color: svGetBgColor(), borderRadius: BorderRadius.circular(100)),
        child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset(icon, height: 15, width: 15)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
