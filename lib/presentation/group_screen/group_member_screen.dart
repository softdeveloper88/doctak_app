import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class GroupMemberScreen extends StatefulWidget {
  GroupMemberScreen(this.groupBloc, {super.key});

  final GroupBloc groupBloc;

  @override
  State<GroupMemberScreen> createState() => _GroupMemberScreenState();
}

class _GroupMemberScreenState extends State<GroupMemberScreen> {
  List<GroupMembers> admins = [];
  List<GroupMembers> user = [];

  @override
  void initState() {
    super.initState();
    _syncMembers();
    final groupId = widget.groupBloc.groupDetailsModel?.group?.id?.trim() ?? '';
    if (groupId.isNotEmpty) {
      widget.groupBloc.add(GroupMembersEvent(groupId, ''));
    }
  }

  void _syncMembers() {
    final members = widget.groupBloc.groupMemberModel?.groupMembers ?? [];
    admins = members.where((member) => member.adminType == 'admin').toList();
    user = members.where((member) => member.adminType != 'admin').toList();
  }

  String _joinedLabel(String? joinedAt) {
    final raw = joinedAt?.trim() ?? '';
    if (raw.isEmpty) return 'Recently joined';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Recently joined';
    return timeAgo.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocListener<GroupBloc, GroupState>(
      bloc: widget.groupBloc,
      listener: (context, state) {
        if (state is PaginationLoadedState) {
          setState(_syncMembers);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: 'Members',
          actions: [
            IconButton(
              icon: Icon(CupertinoIcons.search, size: 22, color: theme.iconColor),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: context.cardColor,
                child: Column(
                  children: [
                    SectionTitle(title: 'Admins and Moderators', count: admins.length),
                    ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: admins.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final member = admins[index];
                        return MemberItem(
                          name: member.name ?? '',
                          role: member.adminType ?? 'admin',
                          joined: _joinedLabel(member.joinedAt),
                          avatarUrl: member.profilePic ?? '',
                          isAdmin: member.adminType == 'admin',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: context.cardColor,
                child: Column(
                  children: [
                    SectionTitle(title: 'Members', count: user.length),
                    if (admins.isEmpty && user.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No members loaded yet.'),
                      ),
                    ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: user.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final member = user[index];
                        return MemberItem(
                          name: member.name ?? '',
                          role: 'member',
                          joined: 'Joined ${_joinedLabel(member.joinedAt)}',
                          avatarUrl: member.profilePic ?? '',
                          isAdmin: member.adminType == 'admin',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  const MemberItem({
    super.key,
    required this.name,
    required this.role,
    required this.joined,
    required this.avatarUrl,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = AppData.fullImageUrl(avatarUrl);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
        child: resolvedAvatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(name),
      subtitle: Row(
        children: [
          isAdmin ? Image.asset('assets/images/admin.png', height: 16, width: 16) : const Icon(Icons.person, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text('$role  •  $joined', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      trailing: const Icon(Icons.more_vert),
      onTap: () {},
    );
  }
}
