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
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

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
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final Uri uri = Uri.parse("${AppData.chatifyUrl}chat/auth");

    // Build query parameters
    final Map<String, String> queryParams = {
      'socket_id': socketId,
      'channel_name': channelName,
    };

    final response = await http.post(
      uri.replace(queryParameters: queryParams),
      headers: {'Authorization': 'Bearer ${AppData.userToken!}'},
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
        onAuthorizer: onAuthorizer,
      );

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
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_chats,
        titleIcon: Icons.chat_rounded,
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_rounded, color: theme.primary, size: 18),
            ),
            onPressed: () {
              SearchContactScreen().launch(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        color: theme.primary,
        onRefresh: _refresh,
        child: BlocConsumer<ChatBloc, ChatState>(
          bloc: chatBloc,
          listener: (BuildContext context, ChatState state) {
            if (state is DataError) {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(content: Text(state.errorMessage)),
              );
            }
          },
          builder: (context, state) {
            if (state is PaginationLoadingState) {
              return const UserShimmer();
            } else if (state is PaginationLoadedState) {
              return _buildChatContent(theme);
            } else if (state is DataError) {
              return RetryWidget(
                errorMessage: translation(context).msg_chat_error,
                onRetry: () {
                  try {
                    chatBloc.add(LoadPageEvent(page: 1));
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
              );
            } else {
              return Center(
                child: Text(translation(context).msg_notification_error),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildChatContent(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No Internet Banner
        if (isCurrentlyOnNoInternet)
          Container(
            padding: const EdgeInsets.all(10),
            color: theme.error,
            child: Text(
              translation(context).msg_no_internet,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Groups Section
        if (chatBloc.groupList.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            translation(context).lbl_groups,
            chatBloc.groupList.length,
          ),
          _buildGroupsList(theme),
        ],

        // Messages Section
        if (chatBloc.contactsList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              translation(context).lbl_message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
              ),
            ),
          ),
          _buildContactsList(theme),
        ] else
          Expanded(
            child: Center(
              child: Text(
                translation(context).msg_no_chats,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textSecondary,
                ),
              ),
            ),
          ),

        if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
      ],
    );
  }

  Widget _buildSectionHeader(OneUITheme theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(OneUITheme theme) {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(left: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chatBloc.groupList.length,
        itemBuilder: (context, index) {
          final bloc = chatBloc;

          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.groupList.length - bloc.nextPageTrigger) {
              bloc.add(CheckIfNeedMoreDataEvent(index: index));
            }
          }
          if (bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= bloc.groupList.length - 1) {
            return const UserShimmer();
          } else {
            return _buildGroupCard(theme, bloc, index);
          }
        },
      ),
    );
  }

  Widget _buildGroupCard(OneUITheme theme, ChatBloc bloc, int index) {
    return GestureDetector(
      onTap: () {
        ChatRoomScreen(
          username: bloc.groupList[index].groupName ?? '',
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
            colors: [theme.primary.withOpacity(0.85), theme.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.3),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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

  Widget _buildContactsList(OneUITheme theme) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        itemCount: chatBloc.contactsList.length,
        itemBuilder: (context, index) {
          var bloc = chatBloc;
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.contactsList.length - bloc.nextPageTrigger) {
              bloc.add(CheckIfNeedMoreDataEvent(index: index));
            }
          }
          if (bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= bloc.contactsList.length - 1) {
            return const UserShimmer();
          } else {
            return _buildContactCard(theme, bloc, index);
          }
        },
      ),
    );
  }

  Widget _buildContactCard(OneUITheme theme, ChatBloc bloc, int index) {
    final contact = bloc.contactsList[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            contact.unreadCount = 0;
            setState(() {});
            ChatRoomScreen(
              username: '${contact.firstName ?? ''} ${contact.lastName ?? ''}',
              profilePic: '${contact.profilePic}',
              id: '${contact.id}',
              roomId: '${contact.roomId}',
            ).launch(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.divider, width: 1),
              boxShadow: theme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Profile Picture
                _buildContactAvatar(theme, contact),
                const SizedBox(width: 12),
                // Message Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sanitizeString(
                          "${contact.firstName ?? ""} ${contact.lastName ?? ''}",
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildMessagePreview(theme, contact),
                    ],
                  ),
                ),
                // Time and Unread Count
                _buildTimeAndBadge(theme, contact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(OneUITheme theme, dynamic contact) {
    return InkWell(
      onTap: () {
        SVProfileFragment(userId: contact.id).launch(context);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.primary.withOpacity(0.1),
              theme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CustomImageView(
            placeHolder: 'images/socialv/faces/face_5.png',
            imagePath: '${AppData.imageUrl}${contact.profilePic ?? ''}',
            height: 52,
            width: 52,
            fit: BoxFit.cover,
          ).cornerRadiusWithClipRRect(50),
        ),
      ),
    );
  }

  Widget _buildMessagePreview(OneUITheme theme, dynamic contact) {
    if (isSomeoneTyping && FromId == contact.id) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            translation(context).lbl_typing,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: theme.primary,
            ),
          ),
        ],
      );
    }

    return Text(
      (contact.latestMessage?.length ?? 0) > 30
          ? '${contact.latestMessage?.substring(0, 30)}...'
          : contact.latestMessage ?? "Start a conversation",
      style: TextStyle(
        fontFamily: 'Poppins',
        color: theme.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTimeAndBadge(OneUITheme theme, dynamic contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeAgo.format(
            DateTime.parse(contact.latestMessageTime ?? '2024-01-01 00:00:00'),
          ),
          style: TextStyle(
            fontFamily: 'Poppins',
            color: theme.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        if ((contact.unreadCount ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.error.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${contact.unreadCount ?? 0}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
