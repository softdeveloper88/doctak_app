import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/component/audio_recorder_widget.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart' as chatItem;
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:record/record.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import '../../calling_module/screens/call_screen.dart';
import '../../calling_module/utils/start_outgoing_call.dart';
import '../../home_screen/home/screens/meeting_screen/video_api.dart';
import 'call_loading_screen.dart';
import 'component/chat_bubble.dart';
import 'component/optimized_message_list.dart';
import 'component/chat_input_field.dart';
import 'component/whatsapp_voice_recorder.dart';
import 'component/enhanced_chat_input_field.dart';
import 'component/animated_voice_recorder.dart';
import 'component/audio_cache_manager.dart';
import 'component/attachment_bottom_sheet.dart';
import 'component/attachment_preview_screen.dart';

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
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  bool isSomeoneTyping = false;
  bool isDataLoaded = true;
  bool isTextTyping = false;
  Timer? _typingTimer;
  final FocusNode focusNode = FocusNode();

  // List<SelectedByte> selectedFiles = [];
  bool isMessageLoaded = false; // Initialize it as per your logic
  bool _isFileUploading = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _timerChat;
  Timer? _ampTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  bool? isBottom = true;

  @override
  void dispose() {
    // Ensure we don't leak global pointer routes.
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _timer?.cancel();
    _ampTimer?.cancel();
    _timerChat?.cancel();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    if (!_isRecorderInitialized) {
      _isRecorderInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Capture finger release globally while recording.
    // This fixes cases where the mic button widget is replaced before it receives onLongPressEnd.
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
    setStatusBarColor(svGetScaffoldColor());
    _scrollController.addListener(_checkScrollPosition);
    _initRecorder();
    // Handle completion
    // seenSenderMessage(1);
    _isRecording = false;
    chatBloc.add(
      LoadRoomMessageEvent(
        page: 1,
        userId: widget.id,
        roomId: widget.roomId,
        isFirstLoading: isDataLoaded,
      ),
    );
    chatBloc.add(ChatReadStatusEvent(userId: widget.id, roomId: widget.roomId));
    ConnectPusher();
    print("my id ${AppData.logInUserId}");
    print("sender id ${widget.id}");
    print("room id ${widget.roomId}");
    _startTimerForChat();

    // Clean old cache files on startup
    _cleanOldAudioCache();

    // fetchMessages();
    // _createClient();
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    // Only act for the WhatsApp-style recorder flow.
    if (!isRecording) return;
    if (_shouldStopRecording) return;

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      // User released finger: request recorder to stop+send.
      debugPrint('👆 Global pointer up/cancel detected - requesting stop+send');
      if (mounted) {
        setState(() {
          _shouldStopRecording = true;
        });
      }
    }
  }

  Future<void> _cleanOldAudioCache() async {
    try {
      final cacheManager = AudioCacheManager();
      await cacheManager.cleanOldCache();
    } catch (e) {
      debugPrint('Error cleaning audio cache: $e');
    }
  }

  void _checkScrollPosition() {
    if (_scrollController.position.pixels == 0) {
      setState(() {
        isBottom = true;
        print('top');
      });
    } else if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        isBottom = false;
        print('bottom');
      });
    } else {
      setState(() {
        print('middle');

        isBottom = false;
      });
    }
  }

  Future<void> _start() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }

      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

      final tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _startTimer();
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    await _audioRecorder.stop();

    debugPrint(_recordingPath);
    setState(() => _isRecording = false);
    chatBloc.add(
      SendMessageEvent(
        userId: AppData.logInUserId,
        roomId: widget.roomId == '' ? chatBloc.roomId : widget.roomId,
        receiverId: widget.id,
        attachmentType: 'voice',
        file: _recordingPath,
        message: '',
      ),
    );
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
    // Note: flutter_sound doesn't have getAmplitude() method
    // If you need amplitude, use setSubscriptionDuration and listen to stream
  }

  void _log(String info) {
    debugPrint(info);
    // setState(() {
    //   _infoStrings.insert(0, info);
    // });
  }

  String? FromId;

  void onEvent(PusherEvent event) {
    print("onEvent data: $event");
    Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
    // var data=json.encode(event);
    print('data click ${jsonMap['from_id']}');
    FromId = jsonMap['from_id'];
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
                  textMessage = parts.first
                      .trim(); // Take the first part (the message)
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
    } catch (e) {
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

  bool _emojiShowing = false;

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
  // Complete implementation of the startOutgoingCall function
  //   Future<void> startOutgoingCall(String userId, String username, String profilePic, bool isVideoCall) async {
  //     // Show calling screen immediately
  //     NavigatorService.navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         builder: (context) => CallLoadingScreen(
  //           contactName: username,
  //           contactAvatar: "${AppData.imageUrl}$profilePic",
  //           isVideoCall: isVideoCall,
  //           onCancel: () {
  //             // Pop the loading screen
  //             Navigator.of(context).pop();
  //             // Cancel any pending call setup
  //             CallKitService().endAllCalls();
  //           },
  //         ),
  //       ),
  //     );
  //
  //     try {
  //       // Initialize call in the background with proper error handling
  //       Map<String, dynamic> callData;
  //
  //       try {
  //         final response = await CallKitService().startOutgoingCall(
  //             userId: userId,
  //             calleeName: username,
  //             avatar: "${AppData.imageUrl}$profilePic",
  //             hasVideo: isVideoCall
  //         );
  //
  //         // Ensure we have proper Map<String, dynamic>
  //         if (response is Map<String, dynamic>) {
  //           callData = response;
  //         } else {
  //           // Convert to Map<String, dynamic> if needed
  //           callData = {};
  //           if (response is Map) {
  //             response.forEach((key, value) {
  //               if (key is String) {
  //                 callData[key] = value;
  //               }
  //             });
  //           } else {
  //             throw Exception('Invalid response format from CallKitService');
  //           }
  //         }
  //       } catch (e) {
  //         print('Error calling CallKitService.startOutgoingCall: $e');
  //         throw e;
  //       }
  //
  //       // Handle success - replace loading screen with call screen
  //       if (callData['success'] == true &&
  //           callData['callId'] != null &&
  //           NavigatorService.navigatorKey.currentState != null) {
  //
  //         final callId = callData['callId'].toString();
  //
  //         // Verify call was created successfully by checking with the API
  //         bool isCallActive = true;
  //         try {
  //           isCallActive = await CallKitService().checkCallIsActive(callId);
  //         } catch (e) {
  //           print('Error verifying call is active: $e');
  //           // Continue anyway since we just created it
  //         }
  //
  //         if (!isCallActive) {
  //           // This is unusual - the call we just created isn't active
  //           print('Call API reports call not active immediately after creation');
  //           NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //           _showCallError("Could not establish call. Please try again.");
  //           return;
  //         }
  //
  //         NavigatorService.navigatorKey.currentState!.pushReplacement(
  //           MaterialPageRoute(
  //             settings: const RouteSettings(name: '/call'),
  //             builder: (context) => CallScreen(
  //               callId: callId,
  //               contactId: userId,
  //               contactName: username,
  //               contactAvatar: "${AppData.imageUrl}$profilePic",
  //               isIncoming: false,
  //               isVideoCall: isVideoCall,
  //               token: callData['token']?.toString() ?? '',
  //             ),
  //           ),
  //         );
  //       } else {
  //         // Handle API error
  //         NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //         _showCallError("Failed to establish call. Please try again.");
  //       }
  //     } catch (error) {
  //       print('Error starting outgoing call: $error');
  //
  //       NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //       _showCallError("Error starting call. Please try again.");
  //
  //       // Make sure any partial call state is cleaned up
  //       try {
  //         await CallKitService().endAllCalls();
  //       } catch (e) {
  //         print('Error cleaning up after failed call: $e');
  //       }
  //     }
  //   }

  // Simple loading screen for calls
  void scrollToBottom() {
    // Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Scroll to the start of the list
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(context, theme),
      body: BlocConsumer<ChatBloc, ChatState>(
        bloc: chatBloc,
        listener: (BuildContext context, ChatState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) =>
                  AlertDialog(content: Text(state.errorMessage)),
            );
          } else if (state is PaginationLoadedState) {
            setState(() {
              _isFileUploading = false;
            });
          } else if (state is FileUploadingState) {
            setState(() {
              _isFileUploading = true;
            });
            // Optional: Show a brief toast for file uploads
            // showToast('Uploading file...');
          } else if (state is FileUploadedState) {
            setState(() {
              _isFileUploading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return ChatShimmerLoader();
          } else if (state is PaginationLoadedState ||
              state is FileUploadingState ||
              state is FileUploadedState ||
              state is DataInitial ||
              state is PaginationInitialState) {
            isDataLoaded = false;
            var bloc = chatBloc;
            return Column(
              children: [
                Expanded(
                  child: OptimizedMessageList(
                    chatBloc: bloc,
                    userId: AppData.logInUserId,
                    roomId: widget.roomId.isEmpty
                        ? (chatBloc.roomId ?? '')
                        : widget.roomId,
                    profilePic: widget.profilePic,
                    scrollController: _scrollController,
                    isSomeoneTyping: isSomeoneTyping,
                    fromId: FromId,
                  ),
                ),
                isRecording
                    ? AnimatedVoiceRecorder(
                        shouldStopAndSend: _shouldStopRecording,
                        initialPointerPosition: _recordingPointerPosition,
                        onStop: (path) {
                          print('📨 onStop called with path: $path');
                          chatBloc.add(
                            SendMessageEvent(
                              userId: AppData.logInUserId,
                              roomId: widget.roomId == ''
                                  ? chatBloc.roomId
                                  : widget.roomId,
                              receiverId: widget.id,
                              attachmentType: 'voice',
                              file: path,
                              message: '',
                            ),
                          );
                          setState(() {
                            print('✅ Message sent, hiding recorder');
                            isRecording = false;
                            _shouldStopRecording = false;
                            _recordingPointerPosition = null;
                          });
                          scrollToBottom();
                        },
                        onCancel: () {
                          print('❌ Recording cancelled');
                          setState(() {
                            isRecording = false;
                            _shouldStopRecording = false;
                            _recordingPointerPosition = null;
                          });
                        },
                      )
                    : EnhancedChatInputField(
                        controller: textController,
                        onSubmitted: (message) {
                          setState(() {
                            isTextTyping = false;
                          });
                          chatBloc.add(
                            SendMessageEvent(
                              userId: AppData.logInUserId,
                              roomId: widget.roomId == ''
                                  ? chatBloc.roomId
                                  : widget.roomId,
                              receiverId: widget.id,
                              attachmentType: 'text',
                              file: '',
                              message: message,
                            ),
                          );
                          textController.clear();
                          scrollToBottom();
                        },
                        onAttachmentPressed: () async {
                          const permission = Permission.storage;
                          const permission1 = Permission.photos;
                          var status = await permission.status;
                          print(status);
                          if (await permission1.isGranted) {
                            _showFileOptions();
                          } else if (await permission1.isDenied) {
                            final result = await permission1.request();
                            if (status.isGranted) {
                              _showFileOptions();
                              print("isGranted");
                            } else if (result.isGranted) {
                              _showFileOptions();
                              print("isGranted");
                            } else if (result.isDenied) {
                              final result = await permission.request();
                              print("isDenied");
                            } else if (result.isPermanentlyDenied) {
                              print("isPermanentlyDenied");
                            }
                          } else if (await permission.isPermanentlyDenied) {
                            print("isPermanentlyDenied");
                          }
                        },
                        onRecordStateChanged: (recording, {Offset? pointerPosition}) {
                          print(
                            '🎤 Record state changed: $recording, pointer: $pointerPosition',
                          );
                          setState(() {
                            if (recording) {
                              // Start recording
                              print('▶️ Starting recording...');
                              isRecording = true;
                              _shouldStopRecording = false;
                              _recordingPointerPosition = pointerPosition;
                            } else {
                              // User released - trigger stop and send
                              print(
                                '⏹️ User released - triggering stop and send',
                              );
                              _shouldStopRecording = true;
                            }
                          });
                        },
                        onVoiceRecorded: (path) {
                          // This is handled by AnimatedVoiceRecorder
                        },
                        isRecording: isRecording,
                        isLoading: _isFileUploading || isLoading,
                        onTyping: (text) {
                          if (text.isNotEmpty) {
                            isTextTyping = true;
                          } else {
                            isTextTyping = false;
                          }
                          onTextFieldFocused(true);

                          // Add typing indicator logic
                          _typingTimer?.cancel();
                          _typingTimer = Timer(const Duration(seconds: 1), () {
                            isTextTyping = false;
                          });
                          // Use existing typing event
                          setState(() {});
                        },
                      ),
                Offstage(
                  offstage: !_emojiShowing,
                  child: EmojiPicker(
                    textEditingController: textController,
                    // scrollController: _scrollController,
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      viewOrderConfig: const ViewOrderConfig(),
                      emojiViewConfig: EmojiViewConfig(
                        // Issue: https://github.com/flutter/flutter/issues/28894
                        emojiSizeMax:
                            28 *
                            (foundation.defaultTargetPlatform ==
                                    TargetPlatform.iOS
                                ? 1.2
                                : 1.0),
                      ),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: const CategoryViewConfig(),
                      bottomActionBarConfig: const BottomActionBarConfig(),
                      searchViewConfig: const SearchViewConfig(),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is DataError) {
            return Center(child: Text(state.errorMessage));
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
    );
  }

  bool isPlayingMsg = false, isRecording = false, isSending = false;
  bool _shouldStopRecording = false; // Flag to trigger stop and send
  Offset?
  _recordingPointerPosition; // Track where user pressed to start recording

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
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Microphone permission not granted");
        return;
      }

      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

      recordFilePath = await getFilePath();

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: recordFilePath ?? '',
      );
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  void stopRecord() async {
    try {
      await _audioRecorder.stop();
      // recordFilePath is already set from startRecord()
      // if (!await FlutterSoundRecord().isPaused()) {
      chatBloc.add(
        SendMessageEvent(
          userId: AppData.logInUserId,
          roomId: widget.roomId == '' ? chatBloc.roomId : widget.roomId,
          receiverId: widget.id,
          attachmentType: 'file',
          file: recordFilePath,
          message: '',
        ),
      );
      scrollToBottom();
      // }
    } catch (e) {
      debugPrint(e.toString());
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

  void _showFileOptions() {
    final BuildContext currentContext = context; // Store context reference
    NavigatorState? bottomSheetNavigator;

    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        // Store the navigator reference
        bottomSheetNavigator = Navigator.of(bottomSheetContext);

        return AttachmentBottomSheet(
          onFileSelected: (File file, String type) {
            // Safely close bottom sheet
            try {
              if (bottomSheetNavigator != null &&
                  bottomSheetNavigator!.mounted) {
                bottomSheetNavigator!.pop();
              } else if (bottomSheetContext.mounted) {
                Navigator.of(bottomSheetContext).pop();
              }
            } catch (e) {
              print('Error closing bottom sheet: $e');
            }

            // Schedule the navigation to happen after the bottom sheet is completely closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && currentContext.mounted) {
                  Navigator.push(
                    currentContext,
                    MaterialPageRoute(
                      builder: (context) => AttachmentPreviewScreen(
                        file: file,
                        type: type,
                        onSend: (File sendFile, String caption) {
                          // Only pop if we can (close preview screen only)
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Close preview screen
                          }
                          print("sendFile $sendFile");
                          if (mounted) {
                            // All file attachments (images, videos, documents) use 'file' type
                            // Only voice recordings use 'voice' type
                            String attachmentType = 'file';

                            chatBloc.add(
                              SendMessageEvent(
                                userId: AppData.logInUserId,
                                roomId: widget.roomId == ''
                                    ? chatBloc.roomId
                                    : widget.roomId,
                                receiverId: widget.id,
                                attachmentType: attachmentType,
                                file: sendFile.path,
                                message: caption,
                              ),
                            );

                            scrollToBottom();
                          }
                        },
                      ),
                    ),
                  );
                }
              });
            });
          },
        );
      },
    );
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
            translation(context).lbl_want_to_join_meeting,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, fontFamily: 'Poppins'),
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
              child: Text(translation(context).lbl_no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(translation(context).lbl_yes),
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

  // Replace your current outgoing call implementation with this
  Future<dynamic> onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
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
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final String data = response.body;

        // Decode JSON and ensure it's a Map
        final decoded = jsonDecode(data);

        // Pusher expects a Map<String, dynamic> with 'auth' and optionally 'channel_data'
        if (decoded is Map) {
          // Convert to Map<String, dynamic> to ensure type safety
          final Map<String, dynamic> authData = Map<String, dynamic>.from(
            decoded,
          );

          debugPrint('Pusher auth successful for channel: $channelName');
          debugPrint('Auth data keys: ${authData.keys}');

          return authData;
        } else {
          debugPrint(
            'Pusher auth response is not a Map: ${decoded.runtimeType}',
          );
          throw Exception(
            'Invalid auth response format - expected Map but got ${decoded.runtimeType}',
          );
        }
      } else {
        debugPrint(
          'Pusher auth failed with status code: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
        throw Exception(
          'Failed to fetch Pusher auth data: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in onAuthorizer: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return a properly typed error response
      return <String, dynamic>{'error': e.toString()};
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
    chatBloc.add(
      LoadRoomMessageEvent(page: 0, userId: widget.id, roomId: widget.roomId),
    );
  }

  void _startTimerForChat() {
    _timerChat = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!isDataLoaded) {
        if (isBottom ?? true) {
          print('bottom');
          chatBloc.add(
            LoadRoomMessageEvent(
              page: 0,
              userId: widget.id,
              roomId: widget.roomId,
            ),
          );
        }
      }
    });
  }

  AppBar _buildAppBar(BuildContext context, OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.cardBackground,
      iconTheme: IconThemeData(color: theme.textPrimary),
      elevation: 0,
      toolbarHeight: 70,
      surfaceTintColor: theme.cardBackground,
      centerTitle: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.primary,
            size: 16,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: InkWell(
        onTap: () {
          SVProfileFragment(userId: widget.id).launch(context);
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withOpacity(0.1),
                border: Border.all(
                  color: theme.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.profilePic == ''
                    ? Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: theme.primary,
                          size: 22,
                        ),
                      )
                    : CustomImageView(
                        imagePath:
                            '${AppData.imageUrl}${widget.profilePic.validate()}',
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                  if (isSomeoneTyping && FromId == widget.id)
                    Text(
                      translation(context).lbl_typing,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Voice Call Button
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_outlined, color: theme.primary, size: 18),
          ),
          onPressed: () async {
            startOutgoingCall(
              widget.id,
              widget.username,
              widget.profilePic,
              false,
            );
          },
        ),
        const SizedBox(width: 4),
        // Video Call Button
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_outlined,
              color: theme.primary,
              size: 18,
            ),
          ),
          onPressed: () async {
            startOutgoingCall(
              widget.id,
              widget.username,
              widget.profilePic,
              true,
            );
          },
        ),
        // More Options Menu
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.more_vert, color: theme.primary, size: 20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.cardBackground,
          elevation: 8,
          offset: const Offset(0, 50),
          onSelected: (value) {
            // Handle menu selection
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    translation(context).lbl_media,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: theme.error),
                  const SizedBox(width: 12),
                  Text(
                    translation(context).lbl_delete_chat,
                    style: TextStyle(color: theme.error, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
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
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: chatItem.ChatBubble(
        alignment: Alignment.centerLeft,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        clipper: ChatBubbleClipper5(type: BubbleType.receiverBubble),
        backGroundColor: theme.surfaceVariant,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                translation(context).lbl_typing,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
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
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(child: Chewie(controller: _chewieController)),
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
    final theme = OneUITheme.of(context);

    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: theme.surfaceVariant,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: theme.primary,
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      FullScreenVideoPage(videoPlayerController: controller),
                ),
              );
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

  VoiceRecordingPainter({required this.animation, required this.color})
    : super(repaint: animation);

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

// Simple loading screen for calls
// Helper function to show error message
void _showCallError(String message) {
  if (NavigatorService.navigatorKey.currentContext != null) {
    ScaffoldMessenger.of(
      NavigatorService.navigatorKey.currentContext!,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
