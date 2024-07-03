import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
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

  // List<SelectedByte> selectedFiles = [];
  bool isMessageLoaded = false; // Initialize it as per your logic
  File? _selectedFile;
  bool _isFileUploading = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _ampTimer;
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  Amplitude? _amplitude;

  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setStatusBarColor(svGetScaffoldColor());

    // Handle completion
    print("id${widget.id}roomid${widget.roomId}");
    _isRecording = false;

    chatBloc.add(LoadRoomMessageEvent(
        page: 1, userId: widget.id, roomId: widget.roomId));
    ConnectPusher();
    // fetchMessages();
    // _createClient();
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
        channelName: "private-chatify." + AppData.logInUserId,
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
                chatBloc.add(LoadRoomMessageEvent(
                    page: 0, userId: widget.id, roomId: widget.roomId));
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
              }

              setState(() {
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
            // Add more cases for other event types as needed
            default:
              // Handle unknown event types or ignore them
              break;
          }
        },
      );

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
  }

  void ontextFieldFocused(bool typingStatus) async {
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

  // void _selectFiles(BuildContext context) async {
  //   ImagePickerPlus picker = ImagePickerPlus(context);
  //   SelectedImagesDetails? details = await picker.pickBoth(
  //     source: ImageSource.both,
  //     multiSelection: true,
  //     galleryDisplaySettings:
  //     GalleryDisplaySettings(cropImage: false, showImagePreview: true),
  //   );
  //   if (details != null) {
  //     setState(() {
  //       selectedFiles = details.selectedFiles;
  //     });
  //   }
  // }

  // Future<void> fetchMessages() async {
  //   try {
  //     String? token = AppData.userToken; // Replace with your token
  //
  //     String id = widget.id; // Replace with the user's ID
  //     final RemoteService service = RemoteService();
  //     userMessagesList = await service.fetchChatMessages(token!, id);
  //
  //     setState(() {
  //       messagesList = userMessagesList.messages!;
  //       isMessageLoaded = true;
  //     });
  //   } catch (e) {
  //     print('Error fetching messages: $e');
  //   }
  // }

  // Function to handle file attachment and sending
  // You will need to implement this logic

  // void _showIncomingCallDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Incoming Call'),
  //         content: Text('You have an incoming call from ${widget.username}'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               // Reject the call
  //
  //               _client
  //                   ?.getRtmCallManager()
  //                   .refuseRemoteInvitation(_remoteInvitation!);
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Reject'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               // Accept the call
  //               _client
  //                   ?.getRtmCallManager()
  //                   .acceptRemoteInvitation(_remoteInvitation!);
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Accept'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // Future<void> sendMessage(String message, String messageType) async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     String? token = AppData.userToken; // Replace with your token
  //     String id = widget.id; // Replace with the user's ID
  //     String temporaryMsgId = '123'; // Replace with your temporary message ID
  //
  //     final Uri uri = Uri.parse('${AppData.chatifyUrl}sendMessage');
  //
  //     if (selectedFiles.isNotEmpty) {
  //       // If files are selected, prepare a MultipartRequest
  //       var request = http.MultipartRequest('POST', uri)
  //         ..fields['type'] = messageType
  //         ..fields['message'] = message
  //         ..fields['temporaryMsgId'] = temporaryMsgId
  //         ..fields['id'] = id
  //         ..headers['Authorization'] = 'Bearer $token';
  //
  //       for (var file in selectedFiles) {
  //         String mimeType = lookupMimeType(file.selectedFile.path) ??
  //             'application/octet-stream';
  //         request.files.add(
  //           http.MultipartFile.fromBytes(
  //             'file', // Field name for the file
  //             file.selectedFile.readAsBytesSync(),
  //             filename: basename(file.selectedFile.path),
  //             contentType: MediaType.parse(mimeType),
  //           ),
  //         );
  //       }
  //
  //       var streamedResponse = await request.send();
  //       final response = await http.Response.fromStream(streamedResponse);
  //       handleResponse(response, message, "123");
  //       setState(() {
  //         selectedFiles.clear(); // Clear all selected files
  //       });
  //     } else {
  //       // If no files are selected, send a standard POST request
  //       final response = await http.post(
  //         uri,
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //         },
  //         body: {
  //           'type': messageType,
  //           'message': message,
  //           'temporaryMsgId': temporaryMsgId,
  //           'id': id,
  //         },
  //       );
  //
  //       handleResponse(response, message, id);
  //     }
  //   } catch (e) {
  //     print('Error sending message: $e');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // void handleResponse(http.Response response, String message, String id) {
  //   if (response.statusCode == 200) {
  //     final responseJson = json.decode(response.body);
  //     final fromId = responseJson['message']['from_id'];
  //     setState(() {
  //       messagesList.insert(
  //         0,
  //         Message(
  //           body: message,
  //           toId: id,
  //           fromId: fromId,
  //         ),
  //       );
  //       isLoading = false;
  //     });
  //   } else {
  //     final responseJson = json.decode(response.body);
  //     final errorMessage = responseJson['error'] as String? ?? 'Unknown error';
  //     print('Failed to send message. Error: $errorMessage');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
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
          toolbarHeight: 100,
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Column(
            children: [
              Text(
                widget.username,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                '',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: widget.profilePic == ''
                      ? Image.asset('images/socialv/faces/face_5.png',
                              height: 56, width: 56, fit: BoxFit.cover)
                          .cornerRadiusWithClipRRect(8)
                          .cornerRadiusWithClipRRect(8)
                      : CachedNetworkImage(
                              imageUrl:
                                  '${AppData.imageUrl}${widget.profilePic.validate()}',
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover)
                          .cornerRadiusWithClipRRect(30),
                ),
              ],
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
            } else if (state is PaginationLoadedState) {
              _isFileUploading = false;
            }
          },
          builder: (context, state) {
            print("state $state");

            if (state is PaginationLoadingState) {
              return Center(
                child: CircularProgressIndicator(
                  color: svGetBodyColor(),
                ),
              );
            } else if (state is PaginationLoadedState) {
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
                        return bloc.messageNumberOfPage !=
                                    bloc.messagePageNumber - 1 &&
                                index >= bloc.messagesList.length - 1
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: svGetBodyColor(),
                                ),
                              )
                            : ChatBubble(
                                profile: bloc.messagesList[index].userId !=
                                        widget.id
                                    ? widget.profilePic
                                    : "${AppData.imageUrl}${widget.profilePic}",
                                message: bloc.messagesList[index].body ?? '',
                                isMe:
                                    bloc.messagesList[index].userId == widget.id
                                        ? false
                                        : true,
                                attachmentJson:
                                    bloc.messagesList[index].attachment,
                                createAt: bloc.messagesList[index].createdAt,
                              );
                      },
                      itemCount: bloc.messagesList.length,
                    ),
                  ),
                  isSomeoneTyping
                      ? TypingIndicator(profilePic: widget.profilePic)
                      : Container(),
                  if (_selectedFile != null)
                    if (_isImageFile(_selectedFile!))
                      _buildImagePreview(_selectedFile!),
                  if (_isVideoFile(_selectedFile))
                    _buildVideoPreview(_selectedFile),
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
                        Container(
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
                                        const permission = Permission.photos;
                                        if (await permission.isGranted) {
                                          _showFileOptions();
                                        } else if (await permission.isDenied) {
                                          final result =
                                              await permission.request();
                                          if (result.isGranted) {
                                            _showFileOptions();
                                          } else if (result.isDenied) {
                                            print("isDenied");
                                          } else if (result
                                              .isPermanentlyDenied) {
                                            print("isPermanentlyDenied");
                                            _permissionDialog(context);
                                          }
                                        } else if (await permission
                                            .isPermanentlyDenied) {
                                          print("isPermanentlyDenied");
                                          _permissionDialog(context);
                                        }
                                        _showFileOptions();
                                      },
                                    ),
                              const SizedBox(width: 8.0),
                              isRecording
                                  ? const Text('Recording Start..')
                                  : Container(
                                      width: 50.w,
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
                                          decoration:
                                              const InputDecoration.collapsed(
                                            hintText: 'Type your message...',
                                          ),
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          textInputAction:
                                              TextInputAction.newline,
                                          onChanged: (Text) {
                                            ontextFieldFocused(true);
                                          },
                                          onTapOutside: (text) {
                                            ontextFieldFocused(false);
                                          },
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
                                        String message = textController.text;
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
                                      },
                                      icon: const Icon(Icons.send),
                                    ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onLongPress: () {
                            _start();
                            setState(() {
                              isRecording = true;
                            });
                          },
                          onLongPressEnd: (details) {
                            _stop();
                            setState(() {
                              isRecording = false;
                            });
                          },
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.fromLTRB(16, 5, 5, 5),
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                      color: isRecording
                                          ? Colors.white
                                          : svGetBodyColor(),
                                      spreadRadius: 4)
                                ],
                                color: isRecording ? Colors.red : Colors.grey,
                                shape: BoxShape.circle),
                            child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 20,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: FileImage(file),
        ),
        title: Text(file.path.split('/').last),
        trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _selectedFile = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildVideoPreview(File? file) {
    // Implement video preview widget
    return Container();
  }

  Widget _buildDocumentPreview(File file) {
    // Implement document preview widget
    return Container();
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
                  File? file = await _pickFile(ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _selectedFile = file;
                    });
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
          title: const Text('Warning!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure want to enable permission?'),
              ],
            ),
          ),
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
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(profilePic),
            // Use a placeholder image
            radius: 16.0,
          ),
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

class _DisplayVideo extends StatefulWidget {
  final selectedByte;

  const _DisplayVideo({Key? key, required this.selectedByte}) : super(key: key);

  @override
  State<_DisplayVideo> createState() => _DisplayVideoState();
}

class _DisplayVideoState extends State<_DisplayVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.selectedByte.selectedFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                ClosedCaption(text: _controller.value.caption.text),
                _ControlsOverlay(controller: _controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
              ],
            ),
          )
        : SizedBox(
            height: 200,
            child: Center(
                child: CircularProgressIndicator(
              color: svGetBodyColor(),
            )),
          );
  }

  @override
  Future<void> dispose() async {
    _controller.dispose();
    await FlutterSoundRecord().dispose();

    super.dispose();
  }
}

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
