import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              SearchContactScreen().launch(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add more options functionality
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        bloc: chatBloc,
        listener: (BuildContext context, ChatState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(state.errorMessage),
              ),
            );
          }
        },
        builder: (context, state) {
          print("state $state");
          if (state is PaginationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PaginationLoadedState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if(chatBloc.groupList.isNotEmpty) const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Groups',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if(chatBloc.groupList.isNotEmpty) SizedBox(
                  height: 100.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: chatBloc.groupList.length,
                    itemBuilder: (context, index) {
                      final bloc = chatBloc;

                      if (bloc.pageNumber <= bloc.numberOfPage) {
                        if (index == bloc.groupList.length - bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }
                      return bloc.numberOfPage != bloc.pageNumber - 1 &&
                          index >= bloc.groupList.length - 1
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : GestureDetector(
                        onTap: (){
                          ChatRoomScreen(username: '${bloc.groupList[index].groupName}',profilePic: '',id: '',roomId: '${bloc.groupList[index].roomId}',).launch(context);

                        },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Card(
                                elevation: 0,
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(
                                    bloc.groupList[index].groupName ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    bloc.groupList[index].latestMessage ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                    },
                  ),
                ),
              if(chatBloc.contactsList.isNotEmpty) const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Contacts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if(chatBloc.contactsList.isNotEmpty) Expanded(
                  child: ListView.builder(
                    itemCount: chatBloc.contactsList.length,
                    itemBuilder: (context, index) {
                      var bloc = chatBloc;
                      if (bloc.pageNumber <= bloc.numberOfPage) {
                        if (index == bloc.contactsList.length - bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }
                      return bloc.numberOfPage != bloc.pageNumber - 1 &&
                          index >= bloc.contactsList.length - 1
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: (){
                              // SVProfileFragment(userId:bloc.searchContactsList[index].id).launch(context);
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: CachedNetworkImageProvider(
                                  '${AppData.imageUrl}${bloc.contactsList[index].profilePic}'),
                            ),
                          ),
                          title: Text(
                            '${bloc.contactsList[index].firstName} ${bloc.contactsList[index].lastName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            bloc.contactsList[index].latestMessage ?? 'No recent messages',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            ChatRoomScreen(username: '${bloc.contactsList[index].firstName} ${bloc.contactsList[index].lastName}',profilePic: '${bloc.contactsList[index].profilePic}',id: '',roomId: '${bloc.contactsList[index].roomId}',).launch(context);
                            // Add navigation logic or any other action on contact tap
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is DataError) {
            return Expanded(
              child: Center(
                child: Text(state.errorMessage),
              ),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Add functionality to start a new chat
      //   },
      //   child: const Icon(Icons.message),
      // ),
    );
  }
}
