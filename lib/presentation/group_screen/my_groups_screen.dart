import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/group_screen/group_create_screen.dart';
import 'package:doctak_app/presentation/group_screen/group_view_screen.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
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
  GroupBloc groupBloc = GroupBloc();
  @override
  void initState() {
    groupBloc.add(ListGroupsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(
        title: 'My Groups',
        centerTitle: true,
        toolbarHeight: 56,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
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
            return Center(child: CircularProgressIndicator(color: svGetBodyColor()));
          } else if (state is PaginationLoadedState) {
            return ListView.builder(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
              itemCount: groupBloc.groupListModel?.groups?.length ?? 0, // Replace with the actual number of items
              itemBuilder: (context, index) {
                return GroupListItem(group: groupBloc.groupListModel!.groups![index]);
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class GroupListItem extends StatelessWidget {
  final Groups group;

  const GroupListItem({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GroupViewScreen(group.id).launch(context);
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(imageUrl: AppData.fullImageUrl(group.logo), height: 50, width: 50, fit: BoxFit.cover).cornerRadiusWithClipRRect(20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(group.description ?? '', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    // SizedBox(height: 4),
                    // Text(
                    //   'Specialty Focus: ${group!.specialtyFocus?.map((e) => e.value).join(', ')}',
                    //   style: TextStyle(fontSize: 14, color: Colors.grey),
                    // ),
                    const SizedBox(height: 4),
                    Text('Privacy: ${group.privacySetting}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Member Limit: ${group.memberLimit}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
