import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import 'component/chat_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String username;
  final String profilePic;
  final String id;
  final String roomId;

  ChatRoomScreen({
    super.key,
    required this.username,
    required this.profilePic,
    required this.id,
    required this.roomId,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with TickerProviderStateMixin {
  // late UserMessagesModel userMessagesList;
  // late List<Message> messagesList = []; // Initialize it here with an empty list
  final ScrollController _scrollController = ScrollController();

  // late Message message;
  TextEditingController textController = TextEditingController();
  bool isLoading = false;
  Timer? typingTimer;
  ChatBloc chatBloc = ChatBloc();
  String? _audioFilePath;

  // late AgoraRtmClient _client; // Remove the nullable type
  // AgoraRtmChannel? _channel;
  // LocalInvitation? _localInvitation;
  // RemoteInvitation? _remoteInvitation;
  bool _isLogin = false;
  bool _isInChannel = false;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  bool isSomeoneTyping = false;
  bool isDataLoaded=true;
  // List<SelectedByte> selectedFiles = [];
  bool isMessageLoaded = false; // Initialize it as per your logic
  File? _selectedFile;
  bool _isFileUploading = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _timerChat;
  Timer? _ampTimer;
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  Amplitude? _amplitude;
  bool? isBottom=true;
  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _timerChat?.cancel();
    _audioRecorder.dispose();
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setStatusBarColor(svGetScaffoldColor());
    _scrollController.addListener(_checkScrollPosition);
    // Handle completion
    // seenSenderMessage(1);
    _isRecording = false;
    chatBloc.add(LoadRoomMessageEvent(
        page: 1,
        userId: widget.id,
        roomId: widget.roomId,
        isFirstLoading: isDataLoaded));
    chatBloc.add(ChatReadStatusEvent(
      userId: widget.id,
      roomId: widget.roomId,));
    ConnectPusher();
    print("my id ${AppData.logInUserId}");
    print("sender id ${widget.id}");
    print("room id ${widget.roomId}");
    _startTimerForChat();

    // fetchMessages();
    // _createClient();
  }


  void _checkScrollPosition() {
    if (_scrollController.position.pixels == 0) {
      setState(() {
        isBottom=true;
        print('top');
      });
    } else if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        isBottom=false;
        print('bottom');


      });
    } else {
      setState(() {
        print('middle');

        isBottom=false;

      });
    }
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();

        bool isRecording = await _audioRecorder.isRecording();
        setState(() {
          _isRecording = isRecording;
          _recordDuration = 0;
        });
        _startTimer();
      }
    } catch (e) {
      // if (kDebugMode) {
      //   print(e);
      // }
    }
  }
  Future<void> _stop() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    final String? path = await _audioRecorder.stop();
    print(path);
    setState(() => _isRecording = false);
    chatBloc.add(SendMessageEvent(
        userId: AppData.logInUserId,
        roomId: widget.roomId == '' ? chatBloc.roomId : widget.roomId,
        receiverId: widget.id,
        attachmentType: 'voice',
        file: path,
        message: ''));
    scrollToBottom();
  }
  Future<void> _pause() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    await _audioRecorder.pause();

    setState(() => _isPaused = true);
  }
  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();

    setState(() => _isPaused = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
    _ampTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      _amplitude = await _audioRecorder.getAmplitude();
      setState(() {});
    });
  }
//   void _createClient() async {
//     _client =
//         await AgoraRtmClient.createInstance('f2cf99f1193a40e69546157883b2159f');
//     _client.login(null, AppData.logInUserId);
//
//     _client.onConnectionStateChanged2 =
//         (RtmConnectionState state, RtmConnectionChangeReason reason) {
//       _log('Connection state changed: $state, reason: $reason');
//       if (state == RtmConnectionState.aborted) {
//         _client.logout();
//         _log('Logout');
//       }
//     };
//     _client.onMessageReceived = (RtmMessage message, String peerId) {
//       _log("Peer msg: $peerId, msg: ${message.messageType} ${message.text}");
//     };
//     _client.onTokenExpired = () {
//       _log("Token expired");
//     };
//     _client.onTokenPrivilegeWillExpire = () {
//       _log("Token privilege will expire");
//     };
//     _client.onPeersOnlineStatusChanged =
//         (Map<String, RtmPeerOnlineState> peersStatus) {
//       _log("Peers online status changed ${peersStatus.toString()}");
//     };
//
//     var callManager = _client.getRtmCallManager();
//     callManager.onError = (error) {
//       _log('Call manager error: $error');
//     };
//     callManager.onLocalInvitationReceivedByPeer =
//         (LocalInvitation localInvitation) {
//       _log(
//           'Local invitation received by peer: ${localInvitation.calleeId}, content: ${localInvitation.content}');
//     };
//     callManager.onRemoteInvitationAccepted =
//         (RemoteInvitation remoteInvitation) async {
//       dynamic content = remoteInvitation.content;
//       String? channelId;
//       if (remoteInvitation.content is String) {
//         // Attempt to parse the content from a JSON string.
//         try {
//           final Map<String, dynamic> content =
//               json.decode(remoteInvitation.content!);
//           if (content.containsKey('channelId')) {
//             channelId = content['channelId'];
//           }
//         } catch (e) {
//           // Handle the parsing error.
//         }
//       }
// // Create channel
//       var channel = await _client.createChannel(channelId!);
//       String name, id, profilePic;
//       name = AppData.name;
//       id = AppData.logInUserId;
//       profilePic = AppData.profile_pic;
// // User attributes map
//       // User attributes map
//       var attributes = {'name': name, 'userId': id, 'userAvatar': profilePic};
//
//       List<RtmAttribute> rtmAttributes =
//           await convertToRtmAttributes(attributes);
//       await _client.addOrUpdateLocalUserAttributes2(rtmAttributes);
//       channel?.join();
//       print(channel);
//
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => AgoraScreen(channelName: channelId!),
//         ),
//       );
//     };
//     callManager.onRemoteInvitationReceived =
//         (RemoteInvitation remoteInvitation) {
//       _log(
//           'Remote invitation received by peer: ${remoteInvitation.callerId}, content: ${remoteInvitation.content}');
//       setState(() {
//         _showIncomingCallDialog();
//         _remoteInvitation = remoteInvitation;
//       });
//     };
//   }

  // void _toggleLogin() async {
  //   if (_isLogin) {
  //     try {
  //       await _client.logout();
  //       _log('Logout success');
  //
  //       setState(() {
  //         _isLogin = false;
  //         _isInChannel = false;
  //       });
  //     } catch (errorCode) {
  //       _log('Logout error: $errorCode');
  //     }
  //   } else {
  //     try {
  //       await _client.login(null, AppData.logInUserId);
  //       _log('Login success: $AppData.logInUserId');
  //       setState(() {
  //         _isLogin = true;
  //       });
  //     } catch (errorCode) {
  //       _log('Login error: $errorCode');
  //     }
  //   }
  // }
  void _log(String info) {
    debugPrint(info);
    // setState(() {
    //   _infoStrings.insert(0, info);
    // });
  }

  void ConnectPusher() async {
    // Create the Pusher client
    try {
      await pusher.init(
          apiKey: PusherConfig.key,
          cluster: PusherConfig.cluster,
          useTLS: false,
          onSubscriptionCount: onSubscriptionCount,
          onAuthorizer: onAuthorizer);
      pusher.connect();

      if (pusher != null) {
        // Successfully created and connected to Pusher
        clientListenChannel = await pusher.subscribe(
          channelName: 'private-chatify.${AppData.logInUserId}',
          onMemberAdded: (member) {
            // print("Member added: $member");
          },
          onMemberRemoved: (member) {
            // print("Member removed: $member");
          },
          onEvent: (event) {
            String eventName = event.eventName;

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
              case 'messaging':
                var textMessage = "";
                var messageData = event.data;
                messageData = json.decode(messageData);
                var status = messageData['status'];
                if (status == "web") {
                  final htmlMessage = event.data;
                  var message = json.decode(htmlMessage);

                  // Use the html package to parse the HTML and extract text content
                  final document = htmlParser.parse(message['message']);

                  final messageDiv = document.querySelector('.message');
                  final textMessageWithTime = messageDiv?.text.trim() ?? "";

// Split the textMessageWithTime by the "time ago" portion
                  final parts = textMessageWithTime.split('1 second ago');
                  textMessage =
                      parts.first.trim(); // Take the first part (the message)

                }
                if (status == "api") {
                  var message = messageData['message'];

                  textMessage = message['message'];
                  print(textMessage);
                }
                print(textMessage);
                // setState(() {
                typingTimer = Timer(const Duration(seconds: 2), () {
                  onTypingStopped();
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
        print(widget.id);
        clientSendChannel = await pusher.subscribe(
          channelName: "private-chatify.${widget.id}",
          onMemberAdded: (member) {
            // print("Member added: $member");
          },
          onMemberRemoved: (member) {
            // print("Member removed: $member");
          },
          onEvent: (event) {
            // print("Received Event (Listen Channel): $event");
          },
        );

        // Attach an event listener to the channel
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    }catch(e){
      print(e);
    }
  }

  // void ConnectPusher() async {
  //   // Create the Pusher client
  //   await pusher.init(
  //     apiKey: PusherConfig.key,
  //     cluster: PusherConfig.cluster,
  //     useTLS: false,
  //     onSubscriptionCount: onSubscriptionCount,
  //     onAuthorizer: onAuthorizer,
  //   );
  //
  //   pusher.connect();
  //
  //   if (pusher != null) {
  //     // Successfully created and connected to Pusher
  //
  //     clientListenChannel = await pusher.subscribe(
  //       channelName: "private-chattily.${AppData.logInUserId}",
  //       onSubscriptionSucceeded: (event) {
  //         // Channel is ready, now you can trigger events
  //         print("Subscription to listen channel succeeded.");
  //       },
  //       onMemberAdded: (member) {
  //         // print("Member added: $member");
  //       },
  //       onMemberRemoved: (member) {
  //         // print("Member removed: $member");
  //       },
  //       onEvent: (event) {
  //         String eventName = event.eventName;
  //         switch (eventName) {
  //           case 'client-typing':
  //             onTypingStarted();
  //             // If the timer is already running, cancel it
  //             if (typingTimer != null && typingTimer!.isActive) {
  //               typingTimer!.cancel();
  //             }
  //             // Set a timer to stop typing indicator after 2 seconds
  //             typingTimer = Timer(const Duration(seconds: 2), () {
  //               onTypingStopped();
  //               chatBloc.add(LoadRoomMessageEvent(
  //                   page: 0, userId: widget.id, roomId: widget.roomId));
  //             });
  //             break;
  //           case 'messaging':
  //             var textMessage = "";
  //             var messageData = event.data;
  //             messageData = json.decode(messageData);
  //             var status = messageData['status'];
  //
  //             if (status == "web") {
  //               final htmlMessage = event.data;
  //               var message = json.decode(htmlMessage);
  //
  //               // Use the html package to parse the HTML and extract text content
  //               final document = htmlParser.parse(message['message']);
  //
  //               final messageDiv = document.querySelector('.message');
  //               final textMessageWithTime = messageDiv?.text.trim() ?? "";
  //
  //               // Split the textMessageWithTime by the "time ago" portion
  //               final parts = textMessageWithTime.split('1 second ago');
  //               textMessage = parts.first.trim(); // Take the first part (the message)
  //             }
  //             if (status == "api") {
  //               var message = messageData['message'];
  //               textMessage = message['message'];
  //             }
  //
  //             // setState(() {
  //               typingTimer = Timer(const Duration(seconds: 2), () {
  //                 onTypingStopped();
  //                 chatBloc.add(LoadRoomMessageEvent(
  //                     page: 0, userId: widget.id, roomId: widget.roomId));
  //               });
  //             // });
  //
  //             break;
  //         // Add more cases for other event types as needed
  //           default:
  //           // Handle unknown event types or ignore them
  //             break;
  //         }
  //       },
  //     );
  //
  //     clientSendChannel = await pusher.subscribe(
  //       channelName: "private-chatify.${widget.id}",
  //       onSubscriptionSucceeded: (event) {
  //         // Channel is ready, now you can trigger events
  //         print("Subscription to send channel succeeded.");
  //       },
  //       onMemberAdded: (member) {
  //         // print("Member added: $member");
  //       },
  //       onMemberRemoved: (member) {
  //         // print("Member removed: $member");
  //       },
  //       onEvent: (event) {
  //         // print("Received Event (Listen Channel): $event");
  //       },
  //     );
  //     // Attach an event listener to the channel
  //   } else {
  //     // Handle the case where Pusher connection failed
  //     // print("Failed to connect to Pusher");
  //   }
  // }

  void onTextFieldFocused(bool typingStatus) async {
    String eventName = "client-typing"; // Replace with your event name
// String data = "{ \"from_id\": \"ae25c6e9-10bd-4201-a4c7-f6de15b0211a\",\"to_id\": \"2cc3375a-7681-435b-9d12-3a85a10ed355\",\"typing\": true}";
    Map<String, dynamic> eventData = {
      "from_id": AppData.logInUserId,
      "to_id": widget.id,
      "typing": typingStatus,
    };

    // Convert the Map to a JSON string
    String data = jsonEncode(eventData);
    // Create a PusherEvent and pass the eventData
    PusherEvent event = PusherEvent(
      channelName: "private-chatify.${widget.id}",
      eventName: eventName,
      data: data, // Pass the eventData map
    );

    try {
      await clientSendChannel.trigger(event);
    } catch (e) {
      print(e);
    }
  }
  void seenSenderMessage(int seenStatus) async {
    String eventName = "client-seen"; // Replace with your event name
// String data = "{ \"from_id\": \"ae25c6e9-10bd-4201-a4c7-f6de15b0211a\",\"to_id\": \"2cc3375a-7681-435b-9d12-3a85a10ed355\",\"typing\": true}";
    Map<String, dynamic> eventData = {
      "from_id": AppData.logInUserId,
      "to_id": widget.id,
      "seen": seenStatus,
    };
    // Convert the Map to a JSON string
    String data = jsonEncode(eventData);
    // Create a PusherEvent and pass the eventData
    PusherEvent event = PusherEvent(
      channelName: "private-chatify.${widget.id}",
      eventName: eventName,
      data: data, // Pass the eventData map
    );
   print("e");
    try {
      await clientSendChannel.trigger(event);
    } catch (e) {
      print(e);
    }
  }
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Scroll to the start of the list
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
        backgroundColor: svGetBgColor(),
        appBar: AppBar(
          surfaceTintColor: context.cardColor,
          backgroundColor: context.cardColor,
          // toolbarHeight: 80,
          leadingWidth: 30,
          leading: IconButton(
            iconSize: 20,
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: false,
          title: Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(1, 3),
                        ),
                      ],
                    ),
                    child: widget.profilePic == ''
                        ? InkWell(
                      onTap: () {
                        SVProfileFragment(userId: widget.id)
                            .launch(context);
                      },
                          child: CircleAvatar(
                              child: Image.asset(
                                      'images/socialv/faces/face_5.png',
                                      height: 56,
                                      width: 56,
                                      fit: BoxFit.cover)
                                  .cornerRadiusWithClipRRect(8)
                                  .cornerRadiusWithClipRRect(8),
                            ),
                        )
                        : InkWell(
                            onTap: () {
                              SVProfileFragment(userId: widget.id)
                                  .launch(context);
                            },
                            child: CircleAvatar(
                              child: CustomImageView(
                                      imagePath:
                                          '${AppData.imageUrl}${widget.profilePic.validate()}',
                                      height: 56,
                                      width: 56,
                                      fit: BoxFit.cover)
                                  .cornerRadiusWithClipRRect(30),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    SVProfileFragment(userId: widget.id)
                        .launch(context);
                  },
                  child: Text(
                    widget.username,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: Builder(builder: (context) {
                      return Column(
                        children: ["Media", 'Delete Chat'].map((String item) {
                          return PopupMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                      );
                    }),
                  ),
                ];
              },
              onSelected: (value) {},
            )
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
            } else if (state is PaginationLoadedState) {
              _isFileUploading = false;
            }
          },
          builder: (context, state) {
            if (state is PaginationLoadingState) {
              return Center(
                child: CircularProgressIndicator(
                  color: svGetBodyColor(),
                ),
              );
            } else if (state is PaginationLoadedState) {
              isDataLoaded=false;
              var bloc = chatBloc;
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      reverse: true,
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        if (bloc.messagePageNumber <=
                            bloc.messageNumberOfPage) {
                          if (index ==
                              bloc.messagesList.length -
                                  bloc.messageNextPageTrigger) {
                            bloc.add(CheckIfNeedMoreMessageDataEvent(
                              index: index,
                              userId: AppData.logInUserId,
                              roomId: widget.roomId == ''
                                  ? chatBloc.roomId!
                                  : widget.roomId,
                            ));
                          }
                        }
                         if(bloc.messageNumberOfPage !=
                                    bloc.messagePageNumber - 1 &&
                                index >= bloc.messagesList.length - 1
                        ) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: svGetBodyColor(),
                            ),
                          );
                        }else{
                           final isLastOfOwnMessage = index == bloc.messagesList.length - 1 ||
                               bloc.messagesList[index].userId != bloc.messagesList[index + 1].userId;

                           return InkWell(
                                onLongPress: () {
                                  if (bloc.messagesList[index].userId !=
                                      widget.id) {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomAlertDialog(
                                              title:
                                                  'Are you sure want to delete message ?',
                                              callback: () {
                                                bloc.add(DeleteMessageEvent(
                                                    id: bloc
                                                        .messagesList[index].id
                                                        .toString()));
                                                Navigator.of(context).pop();
                                              });
                                        });
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: isLastOfOwnMessage ? 20 : 0, // Extra space after own last message
                                  ),
                                  child: ChatBubble(
                                    profile: bloc.messagesList[index].userId !=
                                            widget.id
                                        ? widget.profilePic
                                        : "${AppData.imageUrl}${widget.profilePic}",
                                    message: bloc.messagesList[index].body ?? '',
                                    isMe: bloc.messagesList[index].userId ==
                                            widget.id
                                        ? false
                                        : true,
                                    attachmentJson:
                                        bloc.messagesList[index].attachment,
                                    createAt: bloc.messagesList[index].createdAt,
                                    seen: bloc.messagesList[index].seen,
                                  ),
                                ),
                              );
                           }
                      },
                      itemCount: bloc.messagesList.length,
                    ),
                  ),
                  isSomeoneTyping
                      ? TypingIndicator(profilePic: widget.profilePic)
                      : Container(),
                  if (_selectedFile != null)
                    if (_isImageFile(_selectedFile!))
                      _buildImagePreview(_selectedFile ?? File('')),
                  if (_isVideoFile(_selectedFile))
                    _buildVideoPreview(_selectedFile?? File('')),
                  if (_isDocumentFile(_selectedFile))
                    _buildDocumentPreview(_selectedFile!),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              color: appStore.isDarkMode
                                  ? svGetScaffoldColor()
                                  : cardLightColor,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              children: [
                                isLoading
                                    ? Container(
                                        width: 25,
                                        height: 25,
                                        margin: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color: svGetBodyColor(),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.attach_file),
                                        onPressed: () async {
                                          const permission = Permission.storage;
                                          const permission1 = Permission.photos;
                                          var status = await permission.status;
                                          print(status);
                                          if (await permission1.isGranted) {
                                            _showFileOptions();
                                            // _selectFiles(context);
                                          } else if (await permission1.isDenied) {
                                            final result =
                                                await permission1.request();
                                            if (status.isGranted) {
                                              _showFileOptions();
                                              // _selectFiles(context);
                                              print("isGranted");
                                            } else if (result.isGranted) {
                                              _showFileOptions();
                                              // _selectFiles(context);
                                              print("isGranted");
                                            } else if (result.isDenied) {
                                              final result =
                                                  await permission.request();
                                              print("isDenied");
                                            } else if (result
                                                .isPermanentlyDenied) {
                                              print("isPermanentlyDenied");
                                              // _permissionDialog(context);
                                            }
                                          } else if (await permission
                                              .isPermanentlyDenied) {
                                            print("isPermanentlyDenied");
                                            // _permissionDialog(context);
                                          }
                                        },
                                      ),
                                const SizedBox(width: 8.0),
                                isRecording
                                    ? const Text('Recording Start..')
                                    : Flexible(
                                        child: Container(
                                          height: 40,
                                          padding: const EdgeInsets.only(
                                              left: 8, right: 8),
                                          decoration: BoxDecoration(
                                            color: appStore.isDarkMode
                                                ? svGetScaffoldColor()
                                                : cardLightColor,
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Center(
                                            child: TextField(
                                              controller: textController,
                                              decoration: const InputDecoration
                                                  .collapsed(
                                                hintText:
                                                    'Type your message...',
                                              ),
                                              maxLines: null,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              textInputAction:
                                                  TextInputAction.newline,
                                              onChanged: (Text) {
                                                onTextFieldFocused(true);

                                              },
                                              onTapOutside: (text) {
                                                onTextFieldFocused(false);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                const SizedBox(width: 8.0),
                                _isFileUploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 3),
                                      )
                                    : IconButton(
                                        onPressed: () async {
                                          if (textController.text.isNotEmpty) {
                                            String message =
                                                textController.text;
                                            _isFileUploading = true;
                                            chatBloc.add(SendMessageEvent(
                                                userId: AppData.logInUserId,
                                                roomId: widget.roomId == ''
                                                    ? chatBloc.roomId
                                                    : widget.roomId,
                                                receiverId: widget.id,
                                                attachmentType: 'file',
                                                file: _selectedFile?.path ?? '',
                                                message: message));
                                            textController.clear();
                                            setState(() {});
                                            _selectedFile = null;
                                            scrollToBottom();
                                          } else if(textController.text.isEmpty &&  _selectedFile != null ){
                                            String message =
                                                textController.text;
                                            _isFileUploading = true;
                                            chatBloc.add(SendMessageEvent(
                                                userId: AppData.logInUserId,
                                                roomId: widget.roomId == ''
                                                    ? chatBloc.roomId
                                                    : widget.roomId,
                                                receiverId: widget.id,
                                                attachmentType: 'file',
                                                file: _selectedFile?.path ?? '',
                                                message: message == ''
                                                    ? ' '
                                                    : message));
                                            textController.clear();
                                            setState(() {});
                                            _selectedFile = null;
                                            scrollToBottom();
                                          }
                                        },
                                        icon: const Icon(Icons.send),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        // GestureDetector(
                        //   onLongPress: () {
                        //     _start();
                        //     setState(() {
                        //       isRecording = true;
                        //     });
                        //   },
                        //   onLongPressEnd: (details) {
                        //     _stop();
                        //     setState(() {
                        //       _isFileUploading = true;
                        //       isRecording = false;
                        //     });
                        //   },
                        //   child: Container(
                        //     height: 40,
                        //     margin: const EdgeInsets.fromLTRB(16, 5, 5, 5),
                        //     decoration: BoxDecoration(
                        //         boxShadow: [
                        //           BoxShadow(
                        //               color: isRecording ? Colors.white : svGetBodyColor(),
                        //               spreadRadius: 4)
                        //         ],
                        //         color: isRecording ? Colors.red : Colors.grey,
                        //         shape: BoxShape.circle),
                        //     child: Container(
                        //       padding: const EdgeInsets.all(10),
                        //       child: const Icon(
                        //         Icons.mic,
                        //         color: Colors.white,
                        //         size: 20,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  )
                ],
              );
            } else if (state is DataError) {
              return Center(
                child: Text(state.errorMessage),
              );
            } else {
              return const Center(child: Text('Something went wrong'));
            }
          },
        ));
  }

  bool isPlayingMsg = false, isRecording = false, isSending = false;

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  // final record = AudioRecorder();
  void startRecord() async {
    // if (await record.hasPermission()) {
    //   // Start recording to file
    //     recordFilePath = await getFilePath();
    //   await record.start(const RecordConfig(), path: recordFilePath!);
    //   final stream = await record.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
    //
    // }
    bool result = await FlutterSoundRecord().hasPermission();
    recordFilePath = await getFilePath();
// Start recording
    if (result) {
      await FlutterSoundRecord().start(
        path: recordFilePath, // required
        encoder: AudioEncoder.AAC, // by default
        bitRate: 128000, // by default
        // sampleRate: 44100, // by default
      );
    }
    // bool hasPermission = await checkPermission();
    // if (hasPermission) {
    //   recordFilePath = await getFilePath();
    //   RecordMp3.instance.start(recordFilePath!, (type) {
    //     setState(() {});
    //   });
    // } else {}
    // setState(() {});
  }

  void stopRecord() async {
    try {
      await FlutterSoundRecord().pause();
      String? path = await FlutterSoundRecord().stop();
      // await FlutterSoundRecord().isRecording();
      // bool s = RecordMp3.instance.stop();
      // final path = await record.stop();
// ... or cancel it (and implicitly remove file/blob).
//       await record.cancel();

      // record.dispose();
      // if (!await FlutterSoundRecord().isPaused()) {
      chatBloc.add(SendMessageEvent(
          userId: AppData.logInUserId,
          roomId: widget.roomId == '' ? chatBloc.roomId : widget.roomId,
          receiverId: widget.id,
          attachmentType: 'file',
          file: path!,
          message: ''));
      scrollToBottom();
      // }
    } catch (e) {
      print(e);
    }
  }

  String? recordFilePath;

  // Future<void> play() async {
  //   if (recordFilePath != null && File(recordFilePath).existsSync()) {
  //     AudioPlayer audioPlayer = AudioPlayer();
  //     await audioPlayer.play(
  //       recordFilePath,
  //       isLocal: false,
  //     );
  //   }
  // }
  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = "${storageDirectory.path}/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }

  void _startCall() {}

  bool _isImageFile(File? file) {
    // Check if the file is an image
    return true; // Implement your logic here
  }

  bool _isVideoFile(File? file) {
    // Check if the file is a video
    return false; // Implement your logic here
  }

  bool _isDocumentFile(File? file) {
    // Check if the file is a document
    return false; // Implement your logic here
  }

  Widget _buildImagePreview(File file) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10)
              ),
              padding: const EdgeInsets.all(8.0),
              child: Image.file(
                file,
                width: 150,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(File? file) {
    // Implement video preview widget
    return Card(
      margin: const EdgeInsets.all(8.0),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10)
            ),
            padding: const EdgeInsets.all(8.0),
            child: Image.file(
              file??File(''),
              width: 150,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(File file) {
    // Implement document preview widget
    return Card(
      margin: const EdgeInsets.all(8.0),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10)
            ),
            padding: const EdgeInsets.all(8.0),
            child: Image.file(
              file,
              width: 150,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }
  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    File? file = await _pickFile(ImageSource.gallery);
                    if (file != null) {
                      setState(() {
                        _selectedFile = file;
                      });
                    }
                  } catch (e) {
                    _permissionDialog(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickFile(ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      _selectedFile = file;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Video'),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickVideoFile(ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      _selectedFile = file;
                    });
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.insert_drive_file),
              //   title: const Text('Select a document'),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     File? file = await _pickFile(ImageSource.gallery);
              //     if (file != null) {
              //       setState(() {
              //         _selectedFile = file;
              //       });
              //     }
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  Future<File?> _pickVideoFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}

  Future<void> _permissionDialog(context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text(
            'You want to enable permission?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14.sp),
          ),
          // content: const SingleChildScrollView(
          //   child: ListBody(
          // //     children: <Widget>[
          // //       Text('Are you sure want to enable permission?'),
          // //     ],
          //   ),
          // ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
      throw Exception('Failed to fetch Pusher auth data');
    }
  }

// Handle typing events
  void handleTypingEvent(Map<String, dynamic> eventData) {
    final fromId = eventData['from_id'];
    final typingStatus = eventData['typing'];
    // Handle typing event here
  }

// Handle message events
  void handleMessageEvent(Map<String, dynamic> eventData) {
    final fromId = eventData['from_id'];
    final message = eventData['message'];
    // Handle message event here
  }

  void onTypingStarted() {
    setState(() {
      isSomeoneTyping = true;
    });
  }

  void onTypingStopped() {
    setState(() {
      isSomeoneTyping = false;
    });
    chatBloc.add(LoadRoomMessageEvent(
        page: 0, userId: widget.id, roomId: widget.roomId));
  }

  void _startTimerForChat() {
    _timerChat = Timer.periodic(const Duration(seconds: 10), (timer) {
      if(!isDataLoaded) {
        if (isBottom??true) {
          print('bottom');
          chatBloc.add(LoadRoomMessageEvent(
              page: 0, userId: widget.id, roomId: widget.roomId));
        }
      }
    });


  }

// List<RtmAttribute> convertToRtmAttributes(Map<String, dynamic> attributes) {
//   List<RtmAttribute> rtmAttributes = [];
//
//   attributes.forEach((key, value) {
//     if (value is String) {
//       rtmAttributes.add(RtmAttribute(key, value));
//     }
//   });
//
//   return rtmAttributes;
// }
}

class PusherConnectionState {
  static String connected = "CONNECTED";
}

class TypingIndicator extends StatelessWidget {
  final String profilePic;

  const TypingIndicator({super.key, required this.profilePic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CircleAvatar(
          //   backgroundImage: CachedNetworkImageProvider(profilePic),
          //   // Use a placeholder image
          //   radius: 16.0,
          // ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              // Adjust alignment for typing indicator
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0.0),
                    bottomRight: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: svGetBodyColor().withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "typing...",
                  style: TextStyle(color: svGetBodyColor()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Include your _DisplayVideo class here...

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController videoPlayerController;

  const FullScreenVideoPage({Key? key, required this.videoPlayerController})
      : super(key: key);

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      aspectRatio: widget.videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: true,
      // Configure additional settings as needed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBodyColor(),
      appBar: AppBar(
        backgroundColor: svGetBodyColor(),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Chewie(
          controller: _chewieController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();

    super.dispose();
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: svGetBodyColor(),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 35.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              // controller.play();
              // Navigate to full screen video page
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    FullScreenVideoPage(videoPlayerController: controller),
              ));
            }
          },
        ),
      ],
    );
  }
}

class VoiceRecordingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  VoiceRecordingPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;

    final radius = size.width / 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    final double angle = animation.value * 2.0 * math.pi;

    final double lineLength = size.width / 3;
    final double startX = centerX + math.cos(angle) * (radius - lineLength / 2);
    final double startY = centerY + math.sin(angle) * (radius - lineLength / 2);
    final double endX = centerX + math.cos(angle) * (radius + lineLength / 2);
    final double endY = centerY + math.sin(angle) * (radius + lineLength / 2);

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
