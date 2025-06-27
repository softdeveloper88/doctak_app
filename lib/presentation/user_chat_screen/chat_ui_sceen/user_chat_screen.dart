import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../home_screen/utils/SVColors.dart';
import '../Pusher/PusherConfig.dart';
import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatusBarColor(svGetScaffoldColor());
    ConnectPusher();
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  String sanitizeString(String input) {
    try {
      return String.fromCharCodes(input.codeUnits);
    } catch (e) {
      return translation(context).msg_invalid_string;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('state life');
    if (state == AppLifecycleState.resumed) {
      print("state life $state");
      ConnectPusher();
    }
  }

  void onEvent(PusherEvent event) {
    print("onEvent data: $event");
    Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
    // var data=json.encode(event);
    // print(jsonDecode(event.eventName));
    // print('onEventName ${jsonDecode(event.eventName)}');
    // if(event.eventName=='client-typing'){
    //   onTypingStarted();
    // }
    print('data click ${jsonMap['from_id']}');
    FromId = jsonMap['from_id'];
    setState(() {});
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
  }

  void onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  void onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
  }

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  bool isSomeoneTyping = false;
  String? FromId;

  Future<dynamic> onAuthorizer(
      String channelName, String socketId, dynamic options) async {
    final Uri uri = Uri.parse("${AppData.chatifyUrl}chat/auth");

    // Build query parameters
    final Map<String, String> queryParams = {
      'socket_id': socketId,
      'channel_name': channelName,
    };

    final response = await http.post(
      uri.replace(queryParameters: queryParams),
      headers: {
        'Authorization': 'Bearer ${AppData.userToken!}',
      },
    );

    if (response.statusCode == 200) {
      final String data = response.body;

      return jsonDecode(data);
    } else {
      throw Exception(translation(context).msg_pusher_auth_failed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _ampTimer?.cancel();
    _timerChat?.cancel();
    super.dispose();
  }

  void onTypingStarted() {
    setState(() {
      print('FromId $FromId');
      isSomeoneTyping = true;
    });
  }

  Future<void> _refresh() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      chatBloc.add(LoadPageEvent(page: 1));
    });
  }

  void onTypingStopped() {
    print('FromId $FromId');
    setState(() {
      isSomeoneTyping = false;
    });
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}
  Timer? _timer;
  Timer? _timerChat;
  Timer? _ampTimer;
  Timer? typingTimer;

  void ConnectPusher() async {
    // Create the Pusher client
    try {
      await pusher.init(
          apiKey: PusherConfig.key,
          cluster: PusherConfig.cluster,
          useTLS: false,
          onSubscriptionSucceeded: onSubscriptionSucceeded,
          onSubscriptionError: onSubscriptionError,
          onMemberAdded: onMemberAdded,
          onMemberRemoved: onMemberRemoved,
          onEvent: onEvent,
          onDecryptionFailure: onDecryptionFailure,
          onError: onError,
          onSubscriptionCount: onSubscriptionCount,
          onAuthorizer: onAuthorizer);

      pusher.connect();

      if (pusher != null) {
        // Successfully created and connected to Pusher
        clientListenChannel = await pusher.subscribe(
          channelName: 'private-chatify.${AppData.logInUserId}',
          onMemberAdded: (member) {
            print("Member added: $member");
          },
          onMemberRemoved: (member) {
            // print("Member removed: $member");
          },
          onEvent: (event) {
            String eventName = event.eventName;
            print(eventName);

            switch (eventName) {
              case 'client-typing':
                onTypingStarted();
                // If the timer is already running, cancel it
                if (typingTimer != null && typingTimer!.isActive) {
                  typingTimer!.cancel();
                }
                // Set a timer to stop typing indicator after 2 seconds
                typingTimer = Timer(const Duration(seconds: 2), () {
                  onTypingStopped();
                  // chatBloc.add(LoadRoomMessageEvent(
                  //     page: 0, userId: widget.id, roomId: widget.roomId));
                });
                break;
              // case 'client-seen':
              // var textMessage = "";
              // var messageData = event.data;
//                 messageData = json.decode(messageData);
//                 var status = messageData['status'];
//                 if (status == "web") {
//                   final htmlMessage = event.data;
//                   var message = json.decode(htmlMessage);
//
//                   // Use the html package to parse the HTML and extract text content
//                   final document = htmlParser.parse(message['message']);
//
//                   final messageDiv = document.querySelector('.message');
//                   final textMessageWithTime = messageDiv?.text.trim() ?? "";
//
// // Split the textMessageWithTime by the "time ago" portion
//                   final parts = textMessageWithTime.split('1 second ago');
//                   textMessage =
//                       parts.first.trim(); // Take the first part (the message)
//
//                 }
//                 if (status == "api") {
//                   var message = messageData['message'];
//
//                   textMessage = message['message'];
//                   print(textMessage);
//
//                 }
//                 print(textMessage);
//                 // setState(() {
//                 typingTimer = Timer(const Duration(seconds: 2), () {
//                   chatBloc.add(ChatReadStatusEvent(
//                       userId: widget.id,
//                       roomId: widget.roomId,));
              // chatBloc.add(LoadRoomMessageEvent(
              //     page: 0, userId: widget.id, roomId: widget.roomId));
              // });
              // messagesList.insert(
              //   0,
              //   Message(
              //     body: textMessage, // Use the extracted text content
              //     toId: AppData.logInUserId,
              //     fromId: widget.id,
              //   ),
              // );
              // isLoading = false;
              // });
              // break;
              // Add more cases for other event types as needed
              default:
                // Handle unknown event types or ignore them
                break;
            }
          },
        );
        // clientSendChannel = await pusher.subscribe(
        //   channelName: "private-chatify.${widget.id}",
        //   onMemberAdded: (member) {
        //     // print("Member added: $member");
        //   },
        //   onMemberRemoved: (member) {
        //     // print("Member removed: $member");
        //   },
        //   onEvent: (event) {
        //     // print("Received Event (Listen Channel): $event");
        //   },
        // );

        // Attach an event listener to the channel
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: DoctakAppBar(
        title: translation(context).lbl_chats,
        titleIcon: Icons.chat_rounded,
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.blue[600],
                size: 18,
              ),
            ),
            onPressed: () {
              SearchContactScreen().launch(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: _refresh,
          child: BlocConsumer<ChatBloc, ChatState>(
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
              if (state is PaginationLoadingState) {
                return const UserShimmer();
              } else if (state is PaginationLoadedState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isCurrentlyOnNoInternet ? Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red,
                      child: Text(
                        translation(context).msg_no_internet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ) : const SizedBox(),
                    if (chatBloc.groupList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              translation(context).lbl_groups,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: appStore.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: SVAppColorPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${chatBloc.groupList.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SVAppColorPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (chatBloc.groupList.isNotEmpty)
                      Container(
                        height: 120,
                        padding: const EdgeInsets.only(left: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: chatBloc.groupList.length,
                          itemBuilder: (context, index) {
                            final bloc = chatBloc;

                            if (bloc.pageNumber <= bloc.numberOfPage) {
                              if (index ==
                                  bloc.groupList.length -
                                      bloc.nextPageTrigger) {
                                bloc.add(
                                    CheckIfNeedMoreDataEvent(index: index));
                              }
                            }
                            if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.groupList.length - 1) {
                              return const UserShimmer();
                            } else {
                              return GestureDetector(
                                onTap: () {
                                  ChatRoomScreen(
                                    username:
                                        bloc.groupList[index].groupName ?? '',
                                    profilePic: '',
                                    id: '',
                                    roomId: '${bloc.groupList[index].roomId}',
                                  ).launch(context);
                                },
                                child: Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        SVAppColorPrimary.withOpacity(0.8),
                                        SVAppColorPrimary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SVAppColorPrimary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.group_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Group',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bloc.groupList[index].groupName ??
                                                  translation(context).lbl_unknown,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              bloc.groupList[index].latestMessage ?? 'No messages yet',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    // if (chatBloc.contactsList.isNotEmpty)
                    //   const Padding(
                    //     padding: EdgeInsets.all(16.0),
                    //     child: Text(
                    //       'Contacts',
                    //       style:
                    //           TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    //     ),
                    //   ),
                    if (chatBloc.contactsList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          translation(context).lbl_message,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: appStore.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    if (chatBloc.contactsList.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: chatBloc.contactsList.length,
                          itemBuilder: (context, index) {
                            var bloc = chatBloc;
                            if (bloc.pageNumber <= bloc.numberOfPage) {
                              if (index ==
                                  bloc.contactsList.length -
                                      bloc.nextPageTrigger) {
                                bloc.add(
                                    CheckIfNeedMoreDataEvent(index: index));
                              }
                            }
                            if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.contactsList.length - 1) {
                              return const UserShimmer();
                            } else {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      bloc.contactsList[index].unreadCount = 0;
                                      setState(() {});
                                      ChatRoomScreen(
                                        username:
                                            '${bloc.contactsList[index].firstName ?? ''} ${bloc.contactsList[index].lastName ?? ''}',
                                        profilePic:
                                            '${bloc.contactsList[index].profilePic}',
                                        id: '${bloc.contactsList[index].id}',
                                        roomId:
                                            '${bloc.contactsList[index].roomId}',
                                      ).launch(context);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: appStore.isDarkMode
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: appStore.isDarkMode
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: appStore.isDarkMode
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Profile Picture
                                          InkWell(
                                            onTap: () {
                                              SVProfileFragment(
                                                      userId: bloc
                                                          .contactsList[
                                                              index]
                                                          .id)
                                                  .launch(context);
                                            },
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        SVAppColorPrimary.withOpacity(0.1),
                                                        SVAppColorPrimary.withOpacity(0.05),
                                                      ],
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2),
                                                    child: CustomImageView(
                                                      placeHolder:
                                                          'images/socialv/faces/face_5.png',
                                                      imagePath:
                                                          '${AppData.imageUrl}${bloc.contactsList[index].profilePic ?? ''}',
                                                      height: 52,
                                                      width: 52,
                                                      fit: BoxFit.cover,
                                                    ).cornerRadiusWithClipRRect(50),
                                                  ),
                                                ),
                                                // Online indicator placeholder - can be added when backend supports it
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Message Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Name Row
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        sanitizeString(
                                                            "${bloc.contactsList[index].firstName ?? ""} ${bloc.contactsList[index].lastName ?? ''}"),
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color: appStore.isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    // Verification badge placeholder
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Message or Typing Indicator
                                                (isSomeoneTyping &&
                                                        FromId ==
                                                            bloc
                                                                .contactsList[
                                                                    index]
                                                                .id)
                                                    ? Row(
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            margin: const EdgeInsets.only(right: 4),
                                                            decoration: const BoxDecoration(
                                                              color: SVAppColorPrimary,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          Text(
                                                            translation(context).lbl_typing,
                                                            style: const TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 14,
                                                              color: SVAppColorPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        (bloc.contactsList[index]
                                                                        .latestMessage
                                                                        ?.length ??
                                                                    0) >
                                                                30
                                                            ? '${bloc.contactsList[index].latestMessage?.substring(0, 30)}...'
                                                            : bloc.contactsList[index]
                                                                    .latestMessage ??
                                                                "Start a conversation",
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color: appStore.isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black54,
                                                          fontSize: 14,
                                                          height: 1.5,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                              ],
                                            ),
                                          ),
                                          // Time and Unread Count
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              // Time
                                              Text(
                                                timeAgo.format(DateTime.parse(
                                                    bloc.contactsList[index]
                                                            .latestMessageTime ??
                                                        '2024-01-01 00:00:00')),
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: appStore.isDarkMode
                                                      ? Colors.white54
                                                      : Colors.black45,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Unread Count Badge
                                              if ((bloc.contactsList[index]
                                                          .unreadCount ??
                                                      0) >
                                                  0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.red.shade400,
                                                        Colors.red.shade600,
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red.withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    '${bloc.contactsList[index].unreadCount ?? 0}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                                // Read indicator placeholder
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      )
                    else
                      Expanded(
                          child: Center(
                        child: Text(translation(context).msg_no_chats,
                            style: boldTextStyle(
                              size: 16,
                              fontFamily: 'Poppins',
                            )),
                      )),
                    if (AppData.isShowGoogleBannerAds ?? false)
                      BannerAdWidget(),
                  ],
                );
              } else if (state is DataError) {
                return RetryWidget(
                    errorMessage: translation(context).msg_chat_error,
                    onRetry: () {
                      try {
                        chatBloc.add(LoadPageEvent(page: 1));
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    });
              } else {
                return Center(child: Text(translation(context).msg_notification_error));
              }
            },
          )),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     GroupViewScreen().launch(context);
      //     // Add functionality to start a new chat
      //   },
      //   child: const Icon(Icons.group),
      // ),
    );
  }
}
