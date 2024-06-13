import 'package:doctak_app/presentation/group_screen/group_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../home_screen/utils/SVCommon.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          surfaceTintColor: svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),
          title: Text('My Groups', style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            GroupViewScreen().launch(context);
            // Add functionality to start a new chat
          },
          child: const Icon(Icons.group),
        ),
        body: Container());
  }
}
