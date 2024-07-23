import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../home_screen/utils/SVCommon.dart';

class ManageNotificationScreen extends StatefulWidget {
  ManageNotificationScreen(this.groupBloc, {super.key});
  GroupBloc? groupBloc;
  @override
  _ManageNotificationScreenState createState() =>
      _ManageNotificationScreenState();
}

class _ManageNotificationScreenState extends State<ManageNotificationScreen> {
  bool pushNotification = true;
  bool emailNotification = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Manage Notification', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16),
        child: Column(
          children: [
            Divider(
              color: Colors.grey[200],
            ),
            SwitchListTile(
              title: const Text('Push'),
              value: pushNotification,
              onChanged: (bool value) {
                setState(() {
                  pushNotification = value;
                  widget.groupBloc!.add(GroupNotificationEvent(
                      'post',
                      pushNotification ? '1' : '0',
                      emailNotification ? "1" : '0'));
                });
              },
            ),
            SwitchListTile(
              title: const Text('Email'),
              value: emailNotification,
              onChanged: (bool value) {
                setState(() {
                  emailNotification = value;
                  widget.groupBloc!.add(GroupNotificationEvent(
                      'post',
                      pushNotification ? '1' : '0',
                      emailNotification ? "1" : '0'));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
