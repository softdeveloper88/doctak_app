import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class GroupMemberRequestScreen extends StatefulWidget {
  GroupMemberRequestScreen(this.groupBloc, {super.key});
  GroupBloc? groupBloc;

  @override
  State<GroupMemberRequestScreen> createState() =>
      _GroupMemberRequestScreenState();
}

class _GroupMemberRequestScreenState extends State<GroupMemberRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('View Member Request', style: boldTextStyle(size: 20)),
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
            onPressed: () {},
            icon: Image.asset(
              'assets/images/search.png',
              height: 20,
              width: 20,
            ),
          )
        ],
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount:
            widget.groupBloc?.groupMemberRequestModel?.groupMembers?.length ??
                0, // Replace with the actual number of items
        itemBuilder: (context, index) {
          return MemberRequestItem(
              widget.groupBloc?.groupMemberRequestModel?.groupMembers?[index],
              () {
            widget.groupBloc?.add(GroupMemberRequestUpdateEvent(
                '${widget.groupBloc?.groupMemberRequestModel?.groupMembers?[index].id ?? ''}',
                widget.groupBloc?.groupDetailsModel?.group?.id ?? '',
                'rejected'));
            widget.groupBloc?.groupMemberRequestModel?.groupMembers
                ?.removeAt(index);
            setState(() {});
          }, () {
            widget.groupBloc?.add(GroupMemberRequestUpdateEvent(
                '${widget.groupBloc?.groupMemberRequestModel?.groupMembers?[index].id ?? ''}',
                widget.groupBloc?.groupDetailsModel?.group?.id ?? '',
                'joined'));
            widget.groupBloc?.groupMemberRequestModel?.groupMembers
                ?.removeAt(index);
            setState(() {});
          });
        },
      ),
    );
  }
}

class MemberRequestItem extends StatelessWidget {
  MemberRequestItem(this.groupMember, this.onPressReject, this.onPressAccept,
      {super.key});
  GroupMembers? groupMember;
  Function? onPressReject;
  Function? onPressAccept;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(children: [
            // Profile picture
            CircleAvatar(
              radius: 30,
              backgroundImage: CachedNetworkImageProvider(
                  groupMember?.profilePic ??
                      ''), // Replace with actual image URL
            ),
            const SizedBox(width: 16),
            // Request details
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    groupMember?.name ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    timeAgo.format(DateTime.parse(groupMember?.joinedAt ?? "")),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MaterialButton(
                minWidth: 40.w,
                color: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onPressed: () => onPressReject!(),
                child: const Text(
                  'REJECT',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MaterialButton(
                minWidth: 40.w,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onPressed: () => onPressAccept!(),
                child: const Text(
                  'ACCEPT',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
