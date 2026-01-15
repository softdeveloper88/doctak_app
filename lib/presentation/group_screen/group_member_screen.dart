import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../home_screen/utils/SVCommon.dart';

class GroupMemberScreen extends StatefulWidget {
  GroupMemberScreen(this.groupBloc, {super.key});

  GroupBloc groupBloc;

  @override
  State<GroupMemberScreen> createState() => _GroupMemberScreenState();
}

class _GroupMemberScreenState extends State<GroupMemberScreen> {
  List<GroupMembers> admins = [];
  List<GroupMembers> user = [];

  @override
  void initState() {
    admins = widget.groupBloc.groupMemberModel!.groupMembers!.where((member) => member.adminType == 'admin').toList();
    user = widget.groupBloc.groupMemberModel!.groupMembers!.where((member) => member.adminType == 'user').toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Member', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/add_member.png', height: 20, width: 20),
            onPressed: () {
              // Handle add member button press
            },
          ),
          IconButton(
            icon: Image.asset('assets/images/search.png', height: 20, width: 20),
            onPressed: () {
              // Handle search button press
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: context.cardColor,
              child: Column(
                children: [
                  SectionTitle(title: 'Admins and Moderators', count: admins.length ?? 0),
                  ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: admins.length ?? 0,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return MemberItem(
                        name: admins[index].name ?? "",
                        role: admins[index].adminType ?? "user",
                        joined: timeAgo.format(DateTime.parse(admins[index].joinedAt ?? "")),
                        avatarUrl: admins[index].profilePic ?? "",
                        isAdmin: admins[index].adminType == 'admin' ? true : false,
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              color: context.cardColor,
              child: Column(
                children: [
                  SectionTitle(title: 'Members', count: user.length),
                  ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: user.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return MemberItem(
                        name: user[index].name ?? "",
                        role: 'member',
                        joined: "Joined ${timeAgo.format(DateTime.parse(user[index].joinedAt ?? ""))}",
                        avatarUrl: user[index].profilePic ?? "",
                        isAdmin: user[index].adminType == 'admin' ? true : false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const SectionTitle({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MemberItem extends StatelessWidget {
  final String name;
  final String role;
  final String joined;
  final String avatarUrl;
  final bool isAdmin;

  const MemberItem({super.key, required this.name, required this.role, required this.joined, required this.avatarUrl, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
      title: Text(name),
      subtitle: Row(
        children: [
          isAdmin ? Image.asset('assets/images/admin.png', height: 16, width: 16) : const Icon(Icons.person, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text('$role  •  $joined', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      trailing: const Icon(Icons.more_vert),
      onTap: () {
        // Handle member item tap
      },
    );
  }
}
