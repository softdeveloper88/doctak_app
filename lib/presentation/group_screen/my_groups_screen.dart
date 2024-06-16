import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/group_screen/group_create_screen.dart';
import 'package:doctak_app/presentation/group_screen/group_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../data/models/group_model/group_list_model.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/group_state.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  GroupBloc groupBloc=GroupBloc();
  @override
  void initState() {
    groupBloc.add(ListGroupsEvent());
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
            const GroupCreateScreen().launch(context);
            // Add functionality to start a new chat
          },
          child: const Icon(Icons.group),
        ),
        body: BlocConsumer<GroupBloc, GroupState>(
        listener: (BuildContext context, GroupState state) {},
    bloc: groupBloc,
    builder: (context, state) {
    if (state is PaginationLoadingState) {
    return Center(
    child: CircularProgressIndicator(
    color: svGetBodyColor(),
    ));
    } else if (state is PaginationLoadedState) {
      return ListView.builder(
    shrinkWrap: true,
    itemCount: groupBloc.groupListModel?.groups?.length??0, // Replace with the actual number of items
          itemBuilder: (context, index) {
            return GroupListItem(group:groupBloc.groupListModel!.groups![index]);
          },
        );
    }else{
      return Container();
    }
    }
        )
    );
  }
}
class GroupListItem extends StatelessWidget {
  final Groups group;

  GroupListItem( {required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
         GroupViewScreen(group.id).launch(context);
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: "${AppData.imageUrl}${group.logo}",
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ).cornerRadiusWithClipRRect(20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name??'',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group?.description??'',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // SizedBox(height: 4),
                    // Text(
                    //   'Specialty Focus: ${group!.specialtyFocus?.map((e) => e.value).join(', ')}',
                    //   style: TextStyle(fontSize: 14, color: Colors.grey),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      'Privacy: ${group.privacySetting}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member Limit: ${group.memberLimit}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
