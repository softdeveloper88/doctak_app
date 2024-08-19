import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import '../user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'bloc/notification_event.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationBloc notificationBloc = NotificationBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    notificationBloc.add(
      NotificationLoadPageEvent(
        page: 1,
      ),
    );
    super.initState();
  }

  // var selectedValue;
  // bool isShownSuggestion = false;
  // bool isSearchShow = true;
  int selectedIndex = 0;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Notifications', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon:
            Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () {
              Navigator.pop(context);
            }),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: Column(
        children: [
          BlocConsumer<NotificationBloc, NotificationState>(
            bloc: notificationBloc,
            // listenWhen: (previous, current) => current is PaginationLoadedState,
            // buildWhen: (previous, current) => current is! PaginationLoadedState,
            listener: (BuildContext context, NotificationState state) {
              if (state is DataError) {
                // showDialog(
                //   context: context,
                //   builder: (context) => AlertDialog(
                //     content: Text(state.errorMessage),
                //   ),
                // );
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                  color: svGetBodyColor(),
                )));
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                return _buildPostList(context);
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Text(state.errorMessage),
                  ),
                );
              } else {
                return const Expanded(
                    child: Center(child: Text('Something went wrong')));
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = notificationBloc;
    return Expanded(
      child: bloc.notificationsList.isEmpty
          ? const Center(
              child: Text("No Notification Found"),
            )
          : ListView.builder(
              itemCount: bloc.notificationsList.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index ==
                      bloc.notificationsList.length - bloc.nextPageTrigger) {
                    bloc.add(NotificationCheckIfNeedMoreDataEvent(index: index));
                  }
                }
                if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                    index >= bloc.notificationsList.length - 1) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: svGetBodyColor(),
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () {
                      print('object');
                      var typeNotification=bloc.notificationsList[index].type;
                      if(typeNotification=='simple'){

                      }else if(typeNotification=='post_liked'){

                      }else if(typeNotification=='follow'){

                      }else if(typeNotification=='message'){
                        print('object');
                        ChatRoomScreen(
                          username:
                          '${bloc.notificationsList[index].user?.name}',
                          profilePic:
                          '${bloc.notificationsList[index].user?.profilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                          id: '${bloc.notificationsList[index].user?.id}',
                          roomId: '',
                        ).launch(context);
                      }else if(typeNotification=='post_liked'){

                      }else if(typeNotification=='post_liked'){

                      }else if(typeNotification=='post_liked'){

                      }
                      // JobsDetailsScreen(
                      //         jobId: '${bloc.notificationsList[index].id ?? ''}')
                      //     .launch(context);
                    },
                    child: Column(
                      children: [
                        Material(
                          color: bloc.notificationsList[index].isRead== 1 ? Colors.white : Colors.blue[50],
                          // color: Theme.of(context).cardColor,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                            title: Text(
                              bloc.notificationsList[index].text??"",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.0,
                              ),
                            ),
                            subtitle: Text(
                              timeAgo.format(DateTime.parse(bloc.notificationsList[index].createdAt??"")),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.0,
                              ),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Colors.grey[600],
                              size: 16.0,
                            ),
                            onTap: () {
                              print('object');
                              var typeNotification=bloc.notificationsList[index].type;
                              if(typeNotification=='simple'){

                              } else if(typeNotification=='follow'){
                                SVProfileFragment(
                                    userId: bloc.notificationsList[index].user?.id)
                                    .launch(context);
                              }else if(typeNotification=='message'){
                                print('object');
                                ChatRoomScreen(
                                  username:
                                  '${bloc.notificationsList[index].user?.name}',
                                  profilePic:
                                  '${bloc.notificationsList[index].user?.profilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                                  id: '${bloc.notificationsList[index].user?.id}',
                                  roomId: '',
                                ).launch(context);
                              }else if(typeNotification=='post_liked'){
                                LikesListScreen(
                                    id: bloc.notificationsList[index]
                                        .postId ??
                                        '0')
                                    .launch(context);
                              }else if(typeNotification=='post_liked'){

                              }
                              // JobsDetailsScreen(
                              //         jobId: '${bloc.notificationsList[index].id ?? ''}')
                              //     .launch(context);

                              // Add your onTap functionality here
                            },
                          ),
                        ),
                        const Divider(thickness: 0.2,endIndent: 16,indent: 16,color: Colors.grey,)
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}
