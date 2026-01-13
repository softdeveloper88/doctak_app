// // import 'dart:async';
// // import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// // import 'package:flutter/material.dart';
// // import 'package:permission_handler/permission_handler.dart';
// //
// // const appId = "f2cf99f1193a40e69546157883b2159f";
// // const token = "007eJxTYJj24FzjNbk6Ub3mZ48q5T9cq521xeer8n8uS3Pxjtw45qkKDGlGyWmWlmmGhpbGiSYGqWaWpiZmhqbmFhbGSUaGppZp3r/npjcEMjI8E5JkYIRCEJ+NISU/uSQxm4EBAJ1iH6U=";
// // const channel = "doctak";
// //
// // class VideoCallScreen extends StatefulWidget {
// //   const VideoCallScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   State<VideoCallScreen> createState() => _VideoCallScreenState();
// // }
// //
// // class _VideoCallScreenState extends State<VideoCallScreen> {
// //   int? _remoteUid;
// //   bool _localUserJoined = false;
// //   bool _isMuted = false;
// //   bool _isVideoDisabled = false;
// //   bool _isFrontCamera = true;
// //   late RtcEngine _engine;
// //   Timer? _callTimer;
// //   int _callDuration = 0;
// //   List<Widget> _remoteUsers = [];
// //   bool _isSpeakerEnabled = true;
// //   int? _networkQuality;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initAgora();
// //   }
// //
// //   Future<void> _initAgora() async {
// //     try {
// //       await _requestPermissions();
// //       await _setupEngine();
// //       await _joinChannel();
// //     } catch (e) {
// //       _showErrorDialog("Initialization Error", e.toString());
// //     }
// //   }
// //
// //   Future<void> _requestPermissions() async {
// //     final status = await [Permission.microphone, Permission.camera].request();
// //     if (status[Permission.camera] != PermissionStatus.granted ||
// //         status[Permission.microphone] != PermissionStatus.granted) {
// //       throw Exception('Permissions not granted');
// //     }
// //   }
// //
// //   Future<void> _setupEngine() async {
// //     _engine = createAgoraRtcEngine();
// //     await _engine.initialize(RtcEngineContext(
// //       appId: appId,
// //       channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
// //     ));
// //
// //     await _engine.enableVideo();
// //     await _engine.startPreview();
// //     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
// //
// //     _registerEventHandlers();
// //   }
// //
// //   void _registerEventHandlers() {
// //     _engine.registerEventHandler(
// //       RtcEngineEventHandler(
// //         onJoinChannelSuccess: (connection, elapsed) {
// //           setState(() => _localUserJoined = true);
// //           _startCallTimer();
// //         },
// //         onUserJoined: (connection, remoteUid, elapsed) {
// //           setState(() => _remoteUid = remoteUid);
// //         },
// //         onUserOffline: (connection, remoteUid, reason) {
// //           setState(() => _remoteUid = null);
// //           _showUserLeftMessage(remoteUid);
// //         },
// //         onError: (error, msg) => _showErrorDialog("Engine Error", "$msg ($error)"),
// //         onTokenPrivilegeWillExpire: (connection, token) => _renewToken(),
// //         onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
// //           // setState(() => _networkQuality = rxQuality);
// //         },
// //         onConnectionLost: (connection) => _showErrorDialog("Connection Lost", "Attempting to reconnect..."),
// //       ),
// //     );
// //   }
// //
// //   Future<void> _joinChannel() async {
// //     try {
// //       await _engine.joinChannel(
// //         token: token,
// //         channelId: channel,
// //         uid: 0,
// //         options: const ChannelMediaOptions(),
// //       );
// //     } catch (e) {
// //       _showErrorDialog("Join Channel Failed", e.toString());
// //     }
// //   }
// //
// //   void _startCallTimer() {
// //     _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       setState(() => _callDuration++);
// //     });
// //   }
// //
// //   void _toggleMute() {
// //     setState(() => _isMuted = !_isMuted);
// //     _engine.muteLocalAudioStream(_isMuted);
// //   }
// //
// //   void _toggleVideo() {
// //     setState(() => _isVideoDisabled = !_isVideoDisabled);
// //     _engine.muteLocalVideoStream(_isVideoDisabled);
// //   }
// //
// //   void _switchCamera() {
// //     _engine.switchCamera().then((_) {
// //       setState(() => _isFrontCamera = !_isFrontCamera);
// //     });
// //   }
// //
// //   void _toggleSpeaker() {
// //     setState(() => _isSpeakerEnabled = !_isSpeakerEnabled);
// //     _engine.setEnableSpeakerphone(_isSpeakerEnabled);
// //   }
// //
// //   Future<void> _renewToken() async {
// //     // Implement token renewal logic here
// //     const newToken = token; // Replace with actual token renewal
// //     await _engine.renewToken(newToken);
// //   }
// //
// //   String _formatDuration(int seconds) {
// //     return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
// //   }
// //
// //   void _showUserLeftMessage(int uid) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('User $uid left the call')),
// //     );
// //   }
// //
// //   void _showErrorDialog(String title, String message) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text(title),
// //         content: Text(message),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text('OK'),
// //           )
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   void dispose() {
// //     _callTimer?.cancel();
// //     _engine.leaveChannel();
// //     _engine.release();
// //     super.dispose();
// //   }
// //
// //   Widget _buildControlPanel() {
// //     return Positioned(
// //       bottom: 20,
// //       left: 0,
// //       right: 0,
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //         children: [
// //           _controlButton(
// //             icon: _isMuted ? Icons.mic_off : Icons.mic,
// //             onPressed: _toggleMute,
// //             color: _isMuted ? Colors.red : Colors.white,
// //           ),
// //           _controlButton(
// //             icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
// //             onPressed: _toggleVideo,
// //             color: _isVideoDisabled ? Colors.red : Colors.white,
// //           ),
// //           _controlButton(
// //             icon: Icons.switch_camera,
// //             onPressed: _switchCamera,
// //           ),
// //           _controlButton(
// //             icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
// //             onPressed: _toggleSpeaker,
// //           ),
// //           _controlButton(
// //             icon: Icons.call_end,
// //             onPressed: () => Navigator.pop(context),
// //             color: Colors.red,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _controlButton({required IconData icon, required VoidCallback onPressed, Color color = Colors.white}) {
// //     return CircleAvatar(
// //       backgroundColor: Colors.black54,
// //       child: IconButton(
// //         icon: Icon(icon, color: color),
// //         onPressed: onPressed,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildNetworkIndicator() {
// //     if (_networkQuality == null) return const SizedBox.shrink();
// //
// //     final quality = _networkQuality!;
// //     Color indicatorColor;
// //     if (quality > 5) {
// //       indicatorColor = Colors.red;
// //     } else if (quality > 3) {
// //       indicatorColor = Colors.orange;
// //     } else {
// //       indicatorColor = Colors.green;
// //     }
// //
// //     return Positioned(
// //       top: 50,
// //       right: 20,
// //       child: Row(
// //         children: [
// //           Icon(Icons.network_check, color: indicatorColor),
// //           Text(' ${_formatDuration(_callDuration)}',
// //               style: TextStyle(color: Colors.white)),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Video Call'),
// //         backgroundColor: Colors.black87,
// //       ),
// //       backgroundColor: Colors.black,
// //       body: Stack(
// //         children: [
// //           _remoteVideoView(),
// //           _localPreview(),
// //           _buildControlPanel(),
// //           _buildNetworkIndicator(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _remoteVideoView() {
// //     return _remoteUid != null
// //         ? AgoraVideoView(
// //       controller: VideoViewController.remote(
// //         rtcEngine: _engine,
// //         canvas: VideoCanvas(uid: _remoteUid),
// //         connection: RtcConnection(channelId: channel),
// //       ),
// //     )
// //         : Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           const CircularProgressIndicator(),
// //           const SizedBox(height: 20),
// //           Text(
// //             'Waiting for participant...',
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _localPreview() {
// //     return Positioned(
// //       right: 20,
// //       top: 20,
// //       child: SizedBox(
// //         width: 120,
// //         height: 180,
// //         child: ClipRRect(
// //           borderRadius: BorderRadius.circular(12),
// //           child: _localUserJoined
// //               ? AgoraVideoView(
// //             controller: VideoViewController(
// //               rtcEngine: _engine,
// //               canvas: const VideoCanvas(uid: 0),
// //             ),
// //           )
// //               : Container(color: Colors.black),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'dart:convert';
//
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:doctak_app/core/app_export.dart';
// import 'package:doctak_app/core/utils/app/AppData.dart';
// import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
// import 'package:doctak_app/core/utils/pusher_service.dart';
// import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
// import 'package:doctak_app/localization/app_localization.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/search_user_screen.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/seeting_host_control_screen.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
// import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
// import 'package:doctak_app/widgets/meeting_join_reject_dialog.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
// import 'package:sizer/sizer.dart';
//
// import 'meeting_chat_screen.dart';
// import 'meeting_info_screen.dart';
//
// // class HomeScreen1 extends StatefulWidget {
// //   const HomeScreen1({super.key});
// //
// //   @override
// //   State<HomeScreen1> createState() => _HomeScreen1State();
// // }
// //
// // class _HomeScreen1State extends State<HomeScreen1> {
// //   @override
// //   void dispose() {
// //     super.dispose();
// //   }
// //
// //
// //   late PusherChannel clientListenChannel;
// //   late PusherChannel clientSendChannel;
// //   PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Meeting Call')),
// //       body: Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             ElevatedButton(
// //               onPressed: () => _navigateToCallScreen(context, ''),
// //               child: const Text('Create Instant Meeting'),
// //             ),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: () => _showJoinDialog(context),
// //               child: const Text('Join Meeting'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void checkJoinStatus(BuildContext context, String channel) {
// //        ProgressDialogUtils.showProgressDialog();
// //       askToJoin(context, channel).then((resp) async {
// //         print("join response ${jsonEncode(resp.data)}");
// //         Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
// //         if(responseData['success']=='1'){
// //           await joinMeetings(channel).then((joinMeetingData) {
// //             ProgressDialogUtils.hideProgressDialog();
// //             VideoCallScreen(
// //               meetingDetailsModel: joinMeetingData,
// //               isHost: false,
// //             ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
// //           });
// //         }else {
// //           ConnectPusher(responseData['meeting_id'], channel);
// //         }
// //       }).catchError((error) {
// //         // Stop the timer when condition is met
// //         ProgressDialogUtils.hideProgressDialog();
// //         toast("Something went wrong");
// //       });
// //   }
// //
// //   void onSubscriptionSucceeded(String channelName, dynamic data) {
// //     print("onSubscriptionSucceeded: $channelName data: $data");
// //   }
// //
// //   void onSubscriptionError(String message, dynamic e) {
// //     print("onSubscriptionError: $message Exception: $e");
// //   }
// //
// //   void onDecryptionFailure(String event, String reason) {
// //     print("onDecryptionFailure: $event reason: $reason");
// //   }
// //
// //   void onMemberAdded(String channelName, PusherMember member) {
// //     print("onMemberAdded: $channelName member: $member");
// //   }
// //
// //   void onMemberRemoved(String channelName, PusherMember member) {
// //     print("onMemberRemoved: $channelName member: $member");
// //   }
// //
// //   void onError(String message, int? code, dynamic e) {
// //     print("onError: $message code: $code exception: $e");
// //   }
// //
// //   void onSubscriptionCount(String channelName, int subscriptionCount) {}
// //
// //   void ConnectPusher(meetingId,channel) async {
// //     // Create the Pusher client
// //     try {
// //       await pusher.init(
// //           apiKey: PusherConfig.key,
// //           cluster: PusherConfig.cluster,
// //           useTLS: false,
// //           onSubscriptionSucceeded: onSubscriptionSucceeded,
// //           onSubscriptionError: onSubscriptionError,
// //           onMemberAdded: onMemberAdded,
// //           onMemberRemoved: onMemberRemoved,
// //           // onEvent: onEvent,
// //           onDecryptionFailure: onDecryptionFailure,
// //           onError: onError,
// //           onSubscriptionCount: onSubscriptionCount,
// //           onAuthorizer: null);
// //
// //       pusher.connect();
// //
// //       if (pusher != null) {
// //         // Successfully created and connected to Pusher
// //         clientListenChannel = await pusher.subscribe(
// //           channelName: "meeting-channel$meetingId",
// //           onMemberAdded: (member) {
// //             // print("Member added: $member");
// //           },
// //           onMemberRemoved: (member) {
// //             print("Member removed: $member");
// //           },
// //           onEvent: (event) async {
// //             String eventName = event.eventName;
// //             print(eventName);
// //             switch (eventName) {
// //               case 'new-user-allowed':
// //                 await joinMeetings(channel).then((joinMeetingData) {
// //                   ProgressDialogUtils.hideProgressDialog();
// //                   VideoCallScreen(
// //                     meetingDetailsModel: joinMeetingData,
// //                     isHost: false,
// //                   ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
// //                 });
// //                 print("eventName $eventName");
// //                 toast(eventName);
// //                 break;
// //               case 'new-user-rejected':
// //                 ProgressDialogUtils.hideProgressDialog();
// //
// //                 print("eventName $eventName");
// //                 toast(eventName);
// //                 break;
// //               default:
// //               // Handle unknown event types or ignore them
// //                 break;
// //             }
// //           },
// //         );
// //
// //         // Attach an event listener to the channel
// //       } else {
// //         // Handle the case where Pusher connection failed
// //         // print("Failed to connect to Pusher");
// //       }
// //     } catch (e) {
// //       print('eee $e');
// //     }
// //   }
// //
// //   Future<void> _navigateToCallScreen(
// //       BuildContext context, String getChannelName) async {
// //     if (getChannelName.isNotEmpty) {
// //       checkJoinStatus(context, getChannelName);
// //     } else {
// //       ProgressDialogUtils.showProgressDialog();
// //       await startMeetings().then((createMeeting) async {
// //         await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '')
// //             .then((joinMeetingData) {
// //           ProgressDialogUtils.hideProgressDialog();
// //           VideoCallScreen(
// //             meetingDetailsModel: joinMeetingData,
// //             isHost: true,
// //           ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
// //         });
// //       });
// //     }
// //   }
// //
// //   void _showJoinDialog(BuildContext context) {
// //     TextEditingController channelController = TextEditingController();
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Join Meeting'),
// //         content: TextField(
// //           controller: channelController,
// //           decoration: const InputDecoration(labelText: 'Channel Name'),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text(translation(context).lbl_cancel),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               if (channelController.text.isNotEmpty) {
// //                 setState(() {
// //                   String channelNames = channelController.text;
// //                   _navigateToCallScreen(context, channelNames);
// //                 });
// //               }
// //             },
// //             child: const Text('Join'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// const defaultChannel = 'doctak';
// const appId = "f2cf99f1193a40e69546157883b2159f";
// String token = '';
//
// class VideoCallScreen extends StatefulWidget {
//   MeetingDetailsModel? meetingDetailsModel;
//   bool? isHost;
//   String? channel;
//   VideoCallScreen({
//     super.key,
//     this.meetingDetailsModel,
//     this.channel,
//     this.isHost,
//   });
//
//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   late RtcEngine _agoraEngine;
//   final List<RemoteVideoData> _remoteVideos = [];
//   final ValueNotifier<int> _participantCount = ValueNotifier(0);
//   final List<Offset> _defaultPositions = [];
//
//   bool _isJoined = false;
//   bool _isMuted = false;
//   bool _isScreenSharing = false;
//   bool _isFrontCamera = true;
//   bool _showControls = true;
//   bool _isLocalVideoEnabled = true;
//   double _localVideoScale = 1.0;
//   Offset _localVideoPosition = const Offset(20, 20);
//   int _callDuration = 0;
//   Timer? _callTimer;
//   int? _networkQuality;
//   String channelName = '';
//   bool _isLogin = false;
//   PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
//   late PusherChannel clientListenChannel;
//   late PusherChannel clientSendChannel;
//   @override
//   void initState() {
//     super.initState();
//
//     if (widget.isHost ?? true) {
//       channelName =
//           widget.meetingDetailsModel?.data?.meeting?.meetingChannel ?? 'doctak';
//       // token=widget.meetingDetailsModel?.data?.meeting?.meetingToken??'';
//     } else {
//       channelName =
//           widget.meetingDetailsModel?.data?.meeting?.meetingChannel ?? 'doctak';
//
//       // channelName = widget.channel ?? '';
//     }
//     ConnectPusher();
//     // _initializePusher();
//     _initializeAgora();
//     _generateDefaultPositions();
//     _startCallTimer();
//   }
//
//   // void onEvent(PusherEvent event) {
//   //   log("onEvent data: $event");
//   //   Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
//   //   print(jsonMap['id']);
//   //   switch (event.channelName) {
//   //     case 'new-user-join':
//   //       showDialog(
//   //           context: NavigatorService.navigatorKey.currentContext??context,
//   //           builder: (BuildContext context) {
//   //             return CustomAlertDialog(
//   //               mainTitle: 'Request Join Meeting',
//   //               title: 'New user want to join meeting',
//   //               yesButtonText: 'Accept',
//   //               callback: () async {
//   //                 await allowJoinMeet(
//   //                     context,
//   //                     widget.meetingDetailsModel?.data?.meeting?.id,
//   //                     jsonMap['id'])
//   //                     .then((resp) async {
//   //                   print("join response ${resp.data}");
//   //                   widget.meetingDetailsModel = await joinMeetings(
//   //                       widget.meetingDetailsModel?.data?.meeting
//   //                           ?.meetingChannel ?? '');
//   //                   setState(() {});
//   //                 });
//   //                 Navigator.of(context).pop();
//   //               },
//   //               noButtonText: 'Reject',
//   //               callbackNegative: () async {
//   //                 await rejectJoinMeet(
//   //                     context,
//   //                     jsonMap['id'],
//   //                     widget
//   //                         .meetingDetailsModel?.data?.meeting?.id)
//   //                     .then((resp) {
//   //                   print("join response ${resp.data}");
//   //                 });
//   //                 Navigator.of(context).pop();
//   //               },
//   //             );
//   //           });
//   //       break;
//   //     case 'allow-join-request':
//   //
//   //       break;
//   //     case 'messaging':
//   //       var textMessage = "";
//   //       var messageData = event.data;
//   //       messageData = json.decode(messageData);
//   //       var status = messageData['status'];
//   //       if (status == "web") {}
//   //       if (status == "api") {}
//   //       break;
//   //     default:
//   //     // Handle unknown event types or ignore them
//   //       break;
//   //   }
//   //
//   //
//   // }
//
//   void onSubscriptionSucceeded(String channelName, dynamic data) {
//     print("onSubscriptionSucceeded: $channelName data: $data");
//   }
//
//   void onSubscriptionError(String message, dynamic e) {
//     print("onSubscriptionError: $message Exception: $e");
//   }
//
//   void onDecryptionFailure(String event, String reason) {
//     print("onDecryptionFailure: $event reason: $reason");
//   }
//
//   void onMemberAdded(String channelName, PusherMember member) {
//     print("onMemberAdded: $channelName member: $member");
//   }
//
//   void onMemberRemoved(String channelName, PusherMember member) {
//     print("onMemberRemoved: $channelName member: $member");
//   }
//
//   void onError(String message, int? code, dynamic e) {
//     print("onError: $message code: $code exception: $e");
//   }
//
//   final PusherService _pusherService = PusherService();
//   final String _meetingChannelName = 'meeting-channel';
//
//   void _initializePusher() async {
//     // Initialize if not already initialized
//     if (!_pusherService.isConnected) {
//       await _pusherService.initialize();
//       await _pusherService.connect();
//     }
//
//     final channelName =
//         '$_meetingChannelName${widget.meetingDetailsModel?.data?.meeting?.id}';
//
//     // Subscribe to channel
//     _pusherService.subscribeToChannel(channelName);
//
//     // Register event listeners
//     _pusherService.registerEventListener('new-user-join', (data) {
//       Map<String, dynamic> jsonMap = jsonDecode(data.toString());
//       print("join response ${jsonMap}");
//       //   showDialog(
//       //       context: context,
//       //       builder: (BuildContext context) {
//       //         return CustomAlertDialog(
//       //           mainTitle: 'Request Join Meeting',
//       //           title: 'New user want to join meeting',
//       //           yesButtonText: 'Accept',
//       //           callback: () async {
//       //             await allowJoinMeet(
//       //                 context,
//       //                 widget.meetingDetailsModel?.data?.meeting?.id,
//       //                 jsonMap['id'])
//       //                 .then((resp) async {
//       //               print("join response ${resp.data}");
//       //               widget.meetingDetailsModel = await joinMeetings(
//       //                   widget.meetingDetailsModel?.data?.meeting
//       //                       ?.meetingChannel ?? '');
//       //               setState(() {});
//       //             });
//       //
//       //             Navigator.of(context).pop();
//       //           },
//       //           noButtonText: 'Reject',
//       //           callbackNegative: () async {
//       //             await rejectJoinMeet(
//       //                 context,
//       //                 jsonMap['id'],
//       //                 widget
//       //                     .meetingDetailsModel?.data?.meeting?.id)
//       //                 .then((resp) {
//       //               print("join response ${resp.data}");
//       //             });
//       //             Navigator.of(context).pop();
//       //           },
//       //         );
//       //       });
//       //
//     });
//     _pusherService.registerEventListener('allow-join-request', (data) {});
//     _pusherService.registerEventListener('messaging', (data) {});
//   }
//
//   void ConnectPusher() async {
//     // Create the Pusher client
//     try {
//       await pusher.init(
//           apiKey: PusherConfig.key,
//           cluster: PusherConfig.cluster,
//           useTLS: false,
//           onSubscriptionSucceeded: onSubscriptionSucceeded,
//           onSubscriptionError: onSubscriptionError,
//           onMemberAdded: onMemberAdded,
//           onMemberRemoved: onMemberRemoved,
//           // onEvent: onEvent,
//           onDecryptionFailure: onDecryptionFailure,
//           onError: onError,
//           onSubscriptionCount: onSubscriptionCount,
//           onAuthorizer: null);
//
//       pusher.connect();
//
//       if (pusher != null) {
//         // Successfully created and connected to Pusher
//         clientListenChannel = await pusher.subscribe(
//           channelName:
//               "meeting-channel${widget.meetingDetailsModel?.data?.meeting?.id}",
//           onMemberAdded: (member) {
//             // print("Member added: $member");
//           },
//           onMemberRemoved: (member) {
//             print("Member removed: $member");
//           },
//           onEvent: (event) {
//             String eventName = event.eventName;
//             Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
//             print('eventdata ${jsonMap}');
//             print('eventdata1 $eventName');
//
//             switch (eventName) {
//               case 'new-user-join':
//                 if (widget.isHost ?? false) {
//                   showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return MeetingJoinRejectDialog(
//                           joinName:
//                               '${jsonMap['first_name']} ${jsonMap['last_name']}',
//                           title: translation(context).lbl_want_to_join_meeting,
//                           yesButtonText: translation(context).lbl_accept,
//                           profilePic:
//                               '${AppData.imageUrl}${jsonMap['profile_pic']}',
//                           callback: () async {
//                             await allowJoinMeet(
//                                     context,
//                                     widget
//                                         .meetingDetailsModel?.data?.meeting?.id,
//                                     jsonMap['id'])
//                                 .then((resp) async {
//                               print("join response ${resp.data}");
//                               widget.meetingDetailsModel = await joinMeetings(
//                                   widget.meetingDetailsModel?.data?.meeting
//                                           ?.meetingChannel ??
//                                       '');
//                               setState(() {});
//                             });
//                             Navigator.of(context).pop();
//                           },
//                           noButtonText: translation(context).lbl_decline,
//                           callbackNegative: () async {
//                             await rejectJoinMeet(
//                                     context,
//                                     jsonMap['id'],
//                                     widget
//                                         .meetingDetailsModel?.data?.meeting?.id)
//                                 .then((resp) {
//                               print("join response ${resp.data}");
//                             });
//                             Navigator.of(context).pop();
//                           },
//                         );
//                       });
//                 }
//                 break;
//               case 'allow-join-request':
//                 print("eventName $eventName");
//                 toast(eventName);
//                 break;
//               default:
//                 // Handle unknown event types or ignore them
//                 break;
//             }
//           },
//         );
//
//         // Attach an event listener to the channel
//       } else {
//         // Handle the case where Pusher connection failed
//         // print("Failed to connect to Pusher");
//       }
//     } catch (e) {
//       print('eee $e');
//     }
//   }
//
//   onSubscriptionCount(String channelName, int subscriptionCount) {}
//   Future<void> _permissionDialog(context) async {
//     return showDialog(
//       context: context, barrierDismissible: false, // user must tap button!
//       builder: (BuildContext context) {
//         return AlertDialog(
//           // <-- SEE HERE
//           title: Text(
//             translation(context).lbl_you_want_enable_permission,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14.sp,
//               fontFamily: 'Poppins',
//             ),
//           ),
//           // content: const SingleChildScrollView(
//           //   child: ListBody(
//           // //     children: <Widget>[
//           // //       Text('Are you sure want to enable permission?'),
//           // //     ],
//           //   ),
//           // ),
//           actions: <Widget>[
//             TextButton(
//               child: Text(translation(context).lbl_cancel),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(translation(context).lbl_yes),
//               onPressed: () {
//                 openAppSettings();
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // Future<dynamic> onAuthorizer(
//   //     String channelName, String socketId, dynamic options) async {
//   //   final Uri uri = Uri.parse("${AppData.chatifyUrl}chat/auth");
//   //
//   //   // Build query parameters
//   //   final Map<String, String> queryParams = {
//   //     'socket_id': socketId,
//   //     'channel_name': channelName,
//   //   };
//   //
//   //   final response = await http.post(
//   //     uri.replace(queryParameters: queryParams),
//   //     headers: {
//   //       'Authorization': 'Bearer ${AppData.userToken!}',
//   //     },
//   //   );
//   //
//   //   if (response.statusCode == 200) {
//   //     final String data = response.body;
//   //
//   //     return jsonDecode(data);
//   //   } else {
//   //     throw Exception('Failed to fetch Pusher auth data');
//   //   }
//   // }
//   Future<void> _renewToken() async {
//     // Implement token renewal logic here
//     var newToken = token; // Replace with actual token renewal
//     await _agoraEngine.renewToken(newToken);
//   }
//
//   void _startCallTimer() {
//     _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() => _callDuration++);
//     });
//   }
//
//   void _generateDefaultPositions() {
//     _defaultPositions.addAll([
//       const Offset(20, 20),
//       const Offset(20, 200),
//       const Offset(200, 20),
//       const Offset(200, 200),
//     ]);
//   }
//
//   Future<void> _initializeAgora() async {
//     try {
//       await [Permission.microphone, Permission.camera].request();
//
//       _agoraEngine = createAgoraRtcEngine();
//       await _agoraEngine.initialize(const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//       ));
//       _setupEventHandlers();
//       await _configureVideoSettings();
//       await _joinChannel();
//     } catch (e) {
//       _showErrorDialog('Initialization Error', e.toString());
//     }
//   }
//
//   Future<String?> _getUserAccount(int uid) async {
//     final userInfo = await _agoraEngine.getUserInfoByUid(uid);
//     return userInfo.userAccount ?? "";
//   }
//
//   void _setupEventHandlers() {
//     _agoraEngine.registerEventHandler(
//       RtcEngineEventHandler(
//         onVideoPublishStateChanged: (VideoSourceTypevideoSourceType,
//             v1,
//             StreamPublishState streamPublishState1,
//             StreamPublishState streamPublishState2,
//             v2) {
//
//         },
//         onUserJoined:
//             (RtcConnection connection, int remoteUid, int elapsed) async {
//           // Handle both camera and screen sharing UIDs
//           // final userAccount = await _agoraEngine.getUserInfoByUid(remoteUid).then((info) => info.userAccount);
//           //
//           // // Find matching user in API data
//           // final apiUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
//           //       (u) => u.id == userAccount,
//           // );
//           //
//           // if (apiUser != null) {
//           //   // Skip local user
//           //    setState(() {
//           //      _remoteVideos.add(RemoteVideoData(
//           //        uid: remoteUid,
//           //        joinUser: apiUser,
//           //        isScreenShare: false,
//           //        position: _getNextPosition(),
//           //        scale: 1.0,
//           //      ));
//           //    });
//           try {
//             // Add slight delay for Agora to sync user info
//             widget.meetingDetailsModel = await joinMeetings(channelName);
//             setState(() {});
//             await Future.delayed(const Duration(milliseconds: 200));
//             final userInfo = await _agoraEngine.getUserInfoByUid(remoteUid);
//             final userAccount = userInfo.userAccount;
//
//             if (userAccount?.isEmpty ?? true) {
//               print('Failed to get userAccount for UID: $remoteUid');
//               return;
//             }
//
//             final apiUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
//               (u) => u.id == userAccount,
//             );
//
//             if (apiUser != null) {
//               String? id = await _getUserAccount(remoteUid);
//               setState(() {
//                 _remoteVideos.add(RemoteVideoData(
//                   uid: remoteUid,
//                   joinUser: apiUser,
//                   isScreenShare: false,
//                   position: _getNextPosition(),
//                   scale: 1.0,
//                 ));
//               });
//             }
//           } catch (e) {
//             print('Error in onUserJoined: $e');
//           }
//         },
//         onTokenPrivilegeWillExpire: (connection, token) {
//           _renewToken();
//         },
//         onUserEnableVideo:
//             (RtcConnection s, int remoteUid, bool isVideoMuted) async {
//                  String? id = await _getUserAccount(remoteUid);
//                 widget.meetingDetailsModel?.data?.users
//                     ?.singleWhere((user) => user.id == id)
//                     .meetingDetails
//                     ?.single
//                     .isVideoOn = isVideoMuted ? 1 : 0;
//                 setState(() {});
//
//         },
//         onUserMuteAudio: (RtcConnection s, int remoteUid, bool isMuted) async {
//
//           String? id = await _getUserAccount(remoteUid);
//           widget.meetingDetailsModel?.data?.users
//               ?.singleWhere((user) => user.id == id)
//               .meetingDetails
//               ?.single
//               .isMicOn = isMuted ? 0 : 1;
//           setState(() {});
//         },
//         onUserMuteVideo:
//             (RtcConnection s, int remoteUid, bool isVideoMuted) async {
//           String? id = await _getUserAccount(remoteUid);
//           widget.meetingDetailsModel?.data?.users
//               ?.singleWhere((user) => user.id == id)
//               .meetingDetails
//               ?.single
//               .isVideoOn = isVideoMuted ? 1 : 0;
//
//           setState(() {});
//         },
//         onRemoteVideoStateChanged: (RtcConnection connection,
//             int remoteUid,
//             RemoteVideoState state,
//             RemoteVideoStateReason reason,
//             int elapsed) async {
//           if (state == RemoteVideoState.remoteVideoStateStarting) {
//             print('state ${state.name}');
//
//             if (!_remoteVideos.any((v) => v.uid == remoteUid)) {
//               print('state ${state.name}');
//               widget.meetingDetailsModel = await joinMeetings(channelName);
//
//               setState(() {
//                 _remoteVideos.add(RemoteVideoData(
//                   uid: remoteUid,
//
//                   isScreenShare: false,
//                   position: _getNextPosition(),
//                   scale: 1.0,
//                 ));
//               });
//             }
//           }
//         },
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           setState(() => _isJoined = true);
//           _updateParticipantCount();
//         },
//         onUserInfoUpdated: (value, UserInfo userInfo) {},
//         onUserOffline: (RtcConnection connection, int remoteUid,
//             UserOfflineReasonType reason) async {
//           String? userId=await _getUserAccount(remoteUid);
//           Users? usersRemoveData=widget.meetingDetailsModel?.data?.users?.singleWhere((user) => user.id == userId);
//
//           setState(() => _remoteVideos.removeWhere((v) => v.uid == remoteUid));
//
//           _showSystemMessage('${usersRemoveData?.firstName??""} ${usersRemoveData?.lastName??""} left Meeting');
//
//           _updateParticipantCount();
//         },
//         onError: (ErrorCodeType err, String msg) {
//           print(msg);
//           _showErrorDialog('Agora Error', err.name);
//         },
//         onRtcStats: (RtcConnection connection, RtcStats stats) => {},
//         onNetworkQuality: (RtcConnection connection, int rxQuality,
//             QualityType qualityType, QualityType qualityType2) {
//           setState(() => _networkQuality = rxQuality);
//         },
//       ),
//     );
//   }
//
//   Future<void> _configureVideoSettings() async {
//     await _agoraEngine.enableVideo();
//     await _agoraEngine
//         .setVideoEncoderConfiguration(const VideoEncoderConfiguration(
//       dimensions: VideoDimensions(width: 640, height: 480),
//       frameRate: 15,
//       bitrate: 2000,
//     ));
// // Highlight: Keep preview running initially
//     await _agoraEngine.startPreview();
//     await _agoraEngine.setClientRole(
//         role: ClientRoleType.clientRoleBroadcaster);
//     await _agoraEngine.enableVideo();
//   }
//
//   Future<void> _joinChannel() async {
//     print('token $token');
//     print('channelName $channelName');
//     try {
//       await _agoraEngine.joinChannelWithUserAccount(
//         token: token,
//         channelId: channelName,
//         userAccount: AppData.logInUserId,
//         options: const ChannelMediaOptions(
//           channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//           clientRoleType: ClientRoleType.clientRoleBroadcaster,
//           publishCameraTrack: true,
//           publishScreenTrack: true,
//           publishScreenCaptureVideo: true,
//           autoSubscribeAudio: true,
//           autoSubscribeVideo: true,
//         ),
//       );
//     } catch (e) {
//       print(e);
//       _showErrorDialog('Connection Error', e.toString());
//     }
//   }
//
//   Offset _getNextPosition() {
//     if (_remoteVideos.length < _defaultPositions.length) {
//       return _defaultPositions[_remoteVideos.length];
//     }
//     return Offset(
//       20 + (_remoteVideos.length % 4) * 180,
//       20 + (_remoteVideos.length % 3) * 160,
//     );
//   }
//
//   void _updateParticipantCount() {}
//
//   Future<void> _toggleScreenSharing() async {
//     try {
//
//       if (widget.meetingDetailsModel?.data?.settings?.shareScreen == '1' || widget.isHost==true) {
//
//         if (_isScreenSharing) {
// // Stop screen sharing
//           await _agoraEngine.stopScreenCapture();
// // await _agoraEngine.leaveChannel();
// // await _joinChannel();
// // Restart camera stream
//           await _agoraEngine.updateChannelMediaOptions(
//               const ChannelMediaOptions(
//                 publishScreenTrack: false,
//                 publishSecondaryScreenTrack: false,
//                 publishCameraTrack: true,
//                 publishMicrophoneTrack: false,
//                 publishScreenCaptureAudio: false,
//                 publishScreenCaptureVideo: false,
//                 autoSubscribeAudio: false,
//                 publishMediaPlayerAudioTrack: false,
//                 clientRoleType: ClientRoleType.clientRoleBroadcaster,
//               ));
//           await changeMeetingStatus(
//               context,
//               widget.meetingDetailsModel?.data?.meeting?.id,
//               AppData.logInUserId,
//               'cam',
//               true)
//               .then((resp) {
//             print("join response ${resp.data}");
//           });
//           await _agoraEngine.startPreview();
//         } else {
// // Stop camera stream
//           await _agoraEngine.stopPreview();
// // Start screen sharing
//           await _agoraEngine.startScreenCapture(const ScreenCaptureParameters2(
//             captureVideo: true,
//             captureAudio: true,
//             videoParams: ScreenVideoParameters(
//               dimensions: VideoDimensions(width: 1280, height: 720),
//               frameRate: 15,
//               contentHint: VideoContentHint.contentHintMotion,
//               bitrate: 2000,
//             ),
//           ));
// // Update channel to publish screen track
// // await _agoraEngine.updateChannelMediaOptions(const ChannelMediaOptions(
// //   publishCameraTrack: false,
// //   publishScreenTrack: true,
// //   clientRoleType: ClientRoleType.clientRoleBroadcaster,
// // ));
//           await _agoraEngine.updateChannelMediaOptions(
//             const ChannelMediaOptions(
//               publishScreenTrack: true,
//               publishSecondaryScreenTrack: true,
//               publishCameraTrack: false,
//               publishMicrophoneTrack: true,
//               publishScreenCaptureAudio: true,
//               publishScreenCaptureVideo: true,
//               autoSubscribeAudio: true,
//               publishMediaPlayerAudioTrack: true,
//               clientRoleType: ClientRoleType
//                   .clientRoleBroadcaster, // or ClientRoleType.clientRoleAudience
//             ),
//           );
//           await changeMeetingStatus(
//               context,
//               widget.meetingDetailsModel?.data?.meeting?.id,
//               AppData.logInUserId,
//               'screen',
//               true)
//               .then((resp) {
//             print("join response ${resp.data}");
//           });
//         }
//         setState(() => _isScreenSharing = !_isScreenSharing);
//       }else{
//         _showSystemMessage('Screen share permission not allowed from host');
//
//       }
//       } catch (e) {
//       _showErrorDialog('Screen Share Error', e.toString());
//     }
//
//   }
//
//
//   String _formatDuration(int seconds) {
//     return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
//   }
//
//   void _showSystemMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
//
//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.loose,
//         children: [
//           Positioned.fill(
//             top: 30,
//             child: GridView.builder(
//                 padding: EdgeInsets.zero,
//                 gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 20,
//                   maxCrossAxisExtent:
//                       (MediaQuery.of(context).size.width - 20) / 2,
//                   childAspectRatio: _calculateAspectRatio(context),
//                 ),
//                 itemCount: _remoteVideos.length ?? 0,
//                 itemBuilder: (context, index) {
//                   return _buildVideoWindow(
//                       _remoteVideos[index], getColorByIndex(index));
//                 }),
//           ),
//           if (_isJoined) _buildLocalPreview(),
//           Positioned(
//             bottom: 30,
//             right: 20,
//             child: Column(
//               spacing: 10,
//               children: [
//                 FloatingActionButton(
//                   heroTag: "more_fab_tag_${UniqueKey()}", // Ensure a unique tag
//
//                   elevation: 0,
//                   backgroundColor: Colors.blueGrey.withOpacity(0.4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _showFloatingOptions = !_showFloatingOptions;
//                     });
//                   },
//                   child: Icon(_showFloatingOptions
//                       ? CupertinoIcons.chevron_down
//                       : CupertinoIcons.chevron_up),
//                 ),
//                 if (_showFloatingOptions) ...[
//                   FloatingActionButton(
//                     heroTag: "hand_fab_tag_${UniqueKey()}", // Ensure a unique tag
//
//                     elevation: 0,
//
//                     backgroundColor: const Color(0xFF3D4D55).withOpacity(0.9),
// // Background color
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30), // Radius
//                     ),
//                     onPressed: () {},
//                     child: Icon(_isMuted
//                         ? CupertinoIcons.hand_raised
//                         : CupertinoIcons.hand_raised),
//                   ),
//                   FloatingActionButton(
//                     heroTag: "audio_fab_tag_${UniqueKey()}", // Ensure a unique tag
//
//                     elevation: 0,
//
//                     backgroundColor: const Color(0xFF3D4D55).withOpacity(0.9),
// // Background color
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30), // Radius
//                     ),
//                     onPressed: _toggleAudio,
//                     child: Icon(
//                         _isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic),
//                   ),
//                   FloatingActionButton(
//                     heroTag: "camera_fab_tag_${UniqueKey()}", // Ensure a unique tag
//
//                     elevation: 0,
//
//                     backgroundColor: const Color(0xFF3D4D55).withOpacity(0.9),
// // Background color
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30), // Radius
//                     ),
//
//                     onPressed: _toggleVideo,
//                     child: Icon(_isLocalVideoEnabled
//                         ? Icons.videocam
//                         : Icons.videocam_off),
//                   ),
//                   FloatingActionButton(
//                     heroTag: "camera_fab_tag_${UniqueKey()}", // Ensure a unique tag
//                     elevation: 0,
//                     backgroundColor: const Color(0xFF3D4D55).withOpacity(0.9),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30), // Radius
//                     ),
//                     onPressed: _switchCamera,
//                     child: Icon(_isFrontCamera
//                         ? CupertinoIcons.camera_rotate
//                         : CupertinoIcons.camera_rotate_fill),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           Positioned(
//             top: 50,
//             right: 20,
//             child: PopupMenuButton<int>(
//               offset: const Offset(0, 50),
//               icon: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                       color: Colors.blueGrey.withOpacity(0.4),
//                       borderRadius: BorderRadius.circular(50)),
//                   child: const Icon(Icons.more_vert, color: Colors.white)),
//               color: const Color(0xFF263238),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               itemBuilder: (context) => [
//                 PopupMenuItem(
//                   onTap: (){
//                     MeetingInfoScreen().launch(context,pageRouteAnimation:PageRouteAnimation.Slide);
//                   },
//                   value: 1,
//                   child: const ListTile(
//                     trailing: Icon(Icons.info, color: Colors.white),
//                     title: Text("Information",
//                         style: TextStyle(color: Colors.white)),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   onTap: () async {
//                   var  update=await SettingsHostControlsScreen(widget.meetingDetailsModel?.data?.settings,widget.meetingDetailsModel?.data?.meeting?.id??"").launch(context,pageRouteAnimation:PageRouteAnimation.Slide);
//                   if(update){
//                     widget.meetingDetailsModel = await joinMeetings(channelName);
//                     setState(() {});
//
//                   }
//                   },
//                   value: 2,
//                   child: const ListTile(
//                     trailing: Icon(Icons.settings, color: Colors.white),
//                     title:
//                         Text("Setting", style: TextStyle(color: Colors.white)),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 3,
//                   child: ListTile(
//                     trailing: IconButton(
//                         onPressed: (){
//                           Clipboard.setData(
//                               ClipboardData(text: channelName));
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text(translation(context).msg_meeting_code_copied)),
//                           );
//                         },
//                         icon: const Icon(Icons.copy, color: Colors.white)),
//                     title: Text("Meeting ID : $channelName",
//                         style: const TextStyle(color: Colors.white)),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   onTap: (){
//                     SearchUserScreen(channel: channelName,).launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
//                   },
//                   value: 4,
//                   child: ListTile(
//                     trailing: const Icon(Icons.link, color: Colors.white),
//                     title: Text(
//                         "Send Invitation link : ${AppData.base2}/$channelName",
//                         style: const TextStyle(color: Colors.white)),
//                   ),
//                 ),
//               ],
//               onSelected: (value) {
// // Handle selection
//               },
//             ),
//           ),
//           Positioned(
//             top: 50,
//             left: 16,
//             child: Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: BoxDecoration(
//                     color: Colors.blueGrey.withOpacity(0.4),
//                     borderRadius: BorderRadius.circular(50)),
//                 child: const Icon(
//                   CupertinoIcons.back,
//                   color: Colors.white,
//                 ),
//               ).onTap(() {
//                 Navigator.pop(context);
//               }),
//             ),
//           ),
//           if (_networkQuality != null)
//             Positioned(
//               bottom: 16,
//               left: 16,
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 12),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.network_check,
//                       color: _getNetworkQualityColor(),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       _getNetworkQualityText(),
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//       bottomNavigationBar: _buildControlBar(),
//     );
//   }
//
//   bool _showFloatingOptions = true;
//   double _calculateAspectRatio(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return screenWidth /
//         (screenHeight * 0.6); // Adjust the factor (0.55) as needed
//   }
//
//   Color _getNetworkQualityColor() {
//     switch (_networkQuality) {
//       case 1:
//         return Colors.green;
//       case 2:
//         return Colors.yellow;
//       case 3:
//         return Colors.orange;
//       case 4:
//       case 5:
//       case 6:
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   String _getNetworkQualityText() {
//     switch (_networkQuality) {
//       case 1:
//         return 'Excellent';
//       case 2:
//         return 'Good';
//       case 3:
//         return 'Poor';
//       case 4:
//         return 'Bad';
//       case 5:
//         return 'Very Bad';
//       case 6:
//         return 'Disconnected';
//       default:
//         return 'Unknown';
//     }
//   }
//
//   Color getColorByIndex(int index) {
//     List<Color> colors = [
//       Colors.red,
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.teal,
//       Colors.brown,
//       Colors.pink,
//       Colors.indigo,
//       Colors.cyan,
//     ];
//
//     return colors[index % colors.length]; // Ensures the index wraps around
//   }
//
//   Widget _buildVideoWindow(RemoteVideoData videoData, color) {
//     return GestureDetector(
//       child: Container(
//         width: 120,
//         height: 180,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(
//             color:
//                 videoData.joinUser?.meetingDetails?.single.isScreenShared == 1
//                     ? Colors.green
//                     : Colors.grey,
//             width: 4,
//           ),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(6),
//           child: Stack(
//             children: [
//               videoData.joinUser?.meetingDetails?.single.isVideoOn != 1 ||
//                       videoData.joinUser?.meetingDetails?.single
//                               .isScreenShared ==
//                           1
//                   ? AgoraVideoView(
//                       controller: VideoViewController.remote(
//                           rtcEngine: _agoraEngine,
//                           canvas: VideoCanvas(
//                             uid: videoData.uid,
//                             sourceType: VideoSourceType.videoSourceRemote,
//                           ),
//                           connection: RtcConnection(channelId: channelName),
//                           useFlutterTexture: true,
//                           useAndroidSurfaceView: true),
//                     )
//                   : Container(
//                       color: color,
//                       child: Column(
//                         children: [
//                           CircleAvatar(
//                             radius: 100,
//                             backgroundImage: NetworkImage(
//                                 '${AppData.imageUrl}${videoData.joinUser?.profilePic}'),
//                           ),
//                         ],
//                       ),
//                     ),
//               Positioned(
//                   bottom: 8,
//                   child: Row(
//                     children: [
//                       Icon(
//                         videoData.joinUser?.meetingDetails?.single.isMicOn == 1
//                             ? CupertinoIcons.mic
//                             : CupertinoIcons.mic_off,
//                         color: Colors.white,
//                       ),
//                       Text(
//                         '${videoData.joinUser?.firstName ?? ""} ${videoData.joinUser?.lastName}',
//                         style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                             color: Colors.white),
//                       )
//                     ],
//                   ))
//             ],
//           ),
//         ),
//       ),
// // ),
//     );
//   }
//
//   Widget _buildLocalPreview() {
//     return Positioned(
//       left: _localVideoPosition.dx,
//       top: _localVideoPosition.dy,
//       child: GestureDetector(
//         onPanUpdate: (details) =>
//             setState(() => _localVideoPosition += details.delta),
//         onDoubleTap: () => setState(
//             () => _localVideoScale = _localVideoScale == 1.0 ? 1.5 : 1.0),
//         child: Transform.scale(
//           scale: _localVideoScale,
//           child: Container(
//             width: 120,
//             height: 180,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               border: Border.all(color: Colors.blue, width: 2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: _isScreenSharing
//                   ? AgoraVideoView(
//                       controller: VideoViewController(
//                         useAndroidSurfaceView: true,
//                         useFlutterTexture: true,
//                         rtcEngine: _agoraEngine,
//                         canvas: const VideoCanvas(
//                             uid: 0,
//                             sourceType: VideoSourceType.videoSourceScreen),
//                       ),
//                     )
//                   : !_isLocalVideoEnabled
//                       ? Column(
//                           children: [
//                             Expanded(
//                               child: CircleAvatar(
//                                 radius: 100,
//                                 backgroundImage: NetworkImage(
//                                     '${AppData.imageUrl}${AppData.profile_pic}'),
//                               ),
//                             ),
//                           ],
//                         )
//                       : AgoraVideoView(
//                           controller: VideoViewController(
//                             rtcEngine: _agoraEngine,
//                             canvas: const VideoCanvas(uid: 0),
//                           ),
//                         ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildControlBar() {
//     return Container(
//       width: 100.w,
//       height: 90,
// // margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       decoration: const BoxDecoration(
//         color: Color(0xFF263238),
// // borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         spacing: 4,
//         children: [
//           Column(
//             children: [
//               MaterialButton(
//                 color: const Color(0xFF3D4D55), // Background color
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20), // Radius
//                 ),
//                 onPressed: () {
//                   MeetingChatScreen(
//                           channelId:
//                               widget.meetingDetailsModel?.data?.meeting?.id ??
//                                   "")
//                       .launch(context,
//                           pageRouteAnimation: PageRouteAnimation.Slide);
//                 },
//                 child: SvgPicture.asset(
//                   icChat,
//                   color: Colors.white,
//                 ),
//               ),
//               const Text(
//                 'chat',
//                 style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500),
//               )
//             ],
//           ),
// // MaterialButton(
// //   minWidth: 50,
// //   color: Color(0xFF3D4D55), // Background color
// //   shape: RoundedRectangleBorder(
// //     borderRadius: BorderRadius.circular(20), // Radius
// //   ),
// //
// //   onPressed: _toggleVideo,
// //   child: Icon(_isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off),
// // ),
//           Column(
//             children: [
//               MaterialButton(
//                 color: const Color(0xFF3D4D55),
// // Background color
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20), // Radius
//                 ),
//
//                 onPressed: _toggleScreenSharing,
//                 child: Icon(
//                   _isScreenSharing
//                       ? Icons.stop_screen_share
//                       : Icons.screen_share,
//                   color: Colors.white,
//                 ),
//               ),
//               const Text(
//                 'Share',
//                 style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500),
//               )
//             ],
//           ),
//
//           Column(
//             children: [
//               MaterialButton(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20), // Radius
//                 ),
//                 color: Colors.red,
//                 onPressed: _confirmEndCall,
//                 child: const Icon(
//                   Icons.call_end,
//                   color: Colors.white,
//                 ),
//               ),
//               const Text(
//                 'End Meeting',
//                 style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500),
//               )
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _toggleAudio() async {
//     if (widget.meetingDetailsModel?.data?.settings?.toggleMicrophone == 1 || widget.isHost==true) {
//       setState(() => _isMuted = !_isMuted);
//       await changeMeetingStatus(
//           context,
//           widget.meetingDetailsModel?.data?.meeting?.id,
//           AppData.logInUserId,
//           'mic',
//           _isMuted)
//           .then((resp) {
//         print("join response ${resp.data}");
//       });
//       _agoraEngine.muteLocalAudioStream(_isMuted);
//     }else{
//       _showSystemMessage("You don't have permission to enable audio");
//     }
//   }
//
//   Future<void> _toggleVideo() async {
//     if (widget.meetingDetailsModel?.data?.settings?.toggleVideo == 1 || widget.isHost==true) {
//       setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
//       _agoraEngine.muteLocalVideoStream(!_isLocalVideoEnabled);
//       _agoraEngine.enableLocalVideo(_isLocalVideoEnabled);
//       await changeMeetingStatus(
//           context,
//           widget.meetingDetailsModel?.data?.meeting?.id,
//           AppData.logInUserId,
//           'cam',
//           _isLocalVideoEnabled)
//           .then((resp) {
//         print("join response ${resp.data}");
//       });
//     }else{
//       _showSystemMessage("You don't have permission to enable video");
//     }
//   }
//
//   Future<void> _switchCamera() async {
//     await _agoraEngine.switchCamera();
//     setState(() => _isFrontCamera = !_isFrontCamera);
//   }
//
//   void _confirmEndCall() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('End Call'),
//         content: const Text('Are you sure you want to end this meeting?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(translation(context).lbl_cancel),
//           ),
//           TextButton(
//             onPressed: () async {
//               if (widget.isHost ?? false) {
//                 await endMeeting(
//                         context, widget.meetingDetailsModel?.data?.meeting?.id)
//                     .then((resp) {
//                   print("join response ${resp.data}");
//                 });
//               }
//               AppData.chatMessages.clear();
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: Text(translation(context).lbl_end_call, style: const TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _callTimer?.cancel();
//     _agoraEngine.leaveChannel();
//     _agoraEngine.release();
//     super.dispose();
//   }
// }
//
// class RemoteVideoData {
//   final int uid;
//   final Users? joinUser;
//   final Offset position;
//   final bool isScreenShare;
//   final double scale;
//
//   RemoteVideoData({
//     required this.uid,
//     required this.position,
//     this.joinUser,
//     required this.isScreenShare,
//     this.scale = 1.0,
//   });
//
//   RemoteVideoData copyWith({
//     Offset? position,
//     bool? isScreenShare,
//     double? scale,
//   }) {
//     return RemoteVideoData(
//       uid: uid,
//       position: position ?? this.position,
//       joinUser: joinUser ?? Users(),
//       isScreenShare: isScreenShare ?? this.isScreenShare,
//       scale: scale ?? this.scale,
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/presentation/calling_module/services/pip_service.dart';
import 'package:doctak_app/presentation/calling_module/services/screen_share_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/search_user_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/seeting_host_control_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/meeting_join_reject_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:http/http.dart' as http;

import 'meeting_chat_screen.dart';
import 'meeting_chat_bottom_sheet.dart';
import 'meeting_info_screen.dart';

const defaultChannel = 'doctak';
const appId = "f2cf99f1193a40e69546157883b2159f";
// The Agora token will be taken from the meetingDetailsModel when available.
String token = '';

// Constants for audio level detection
const int SPEAKING_THRESHOLD =
    30; // Audio volume threshold to consider as speaking
const int SPEAKING_INTERVAL_MS = 1000; // Interval to check audio levels

class VideoCallScreen extends StatefulWidget {
  MeetingDetailsModel? meetingDetailsModel;
  final bool? isHost;
  final String? channel;
  VideoCallScreen({
    Key? key,
    this.meetingDetailsModel,
    this.channel,
    this.isHost,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late RtcEngine _agoraEngine;
  final List<RemoteVideoData> _remoteVideos = [];
  final ValueNotifier<int> _participantCount = ValueNotifier(0);
  final List<Offset> _defaultPositions = [];
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isScreenSharing = false;
  bool _isFrontCamera = false;
  bool _showControls = true;
  bool _isLocalVideoEnabled = false;
  bool _isHandRaised = false; // Track hand raise status
  double _localVideoScale = 1.0;
  Offset _localVideoPosition = const Offset(20, 120); // Below top controls
  final ValueNotifier<int> _callDurationNotifier = ValueNotifier<int>(0);
  Timer? _callTimer;
  int? _networkQuality;
  String channelName = '';
  bool _isLogin = false;
  bool _showFloatingOptions = true;
  int? _selectedUserId;

  // PiP service for Picture-in-Picture support
  final PiPService _pipService = PiPService();
  bool _isPiPEnabled = false;
  StreamSubscription<PiPServiceStatus>? _pipStatusSubscription;

  // Screen share service for iOS ReplayKit integration
  final ScreenShareService _screenShareService = ScreenShareService();

  // Audio indication variables
  Map<int, int> _userSpeakingLevels = {}; // Maps user ID to audio level
  Map<int, bool> _userSpeakingStatus = {}; // Maps user ID to speaking status
  bool _isLocalUserSpeaking = false;
  int _localUserSpeakingLevel = 0;

  // Connection state tracking
  bool _isReconnecting = false;
  int _reconnectionAttempts = 0;
  final int _maxReconnectionAttempts = 5;

  // Remote users map to track user state more efficiently
  Map<int, RemoteUserState> _remoteUserStates = {};

  // Animation controller for speaking indicator
  late AnimationController _speakingAnimationController;
  late Animation<double> _speakingAnimation;

  Timer? _localUserSpeakingTimer;
  Map<int, Timer> _speakingTimers = {};
  // Pusher client instance
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;

  // Flag to track if meeting details are being refreshed
  bool _isRefreshingMeetingDetails = false;
  // Debouncer for meeting refresh to avoid too frequent API calls
  Timer? _meetingRefreshDebouncer;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // NOTE: PiP is NOT allowed here - only when actually joined the meeting
    // _pipService.allowPiP() will be called in onJoinChannelSuccess callback

    // Keep screen awake during video call
    _enableWakelock();

    // Initialize animation controller for speaking indication
    _speakingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
    _speakingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(_speakingAnimationController);

    // Set channel name based on host/participant role
    if (widget.isHost ?? true) {
      channelName =
          widget.meetingDetailsModel?.data?.meeting?.meetingChannel ??
          defaultChannel;
      // Extract Agora token from meeting details.
      token = widget.meetingDetailsModel?.data?.meeting?.meetingToken ?? '';
    } else {
      channelName =
          widget.meetingDetailsModel?.data?.meeting?.meetingChannel ??
          defaultChannel;
      // In participant case token may be provided similarly.
      token = widget.meetingDetailsModel?.data?.meeting?.meetingToken ?? '';
    }

    // Connect to the Pusher channels
    _initializePusher();
    // Initialize Agora engine and join channel
    _initializeAgora();
    _generateDefaultPositions();
    _startCallTimer();

    // Initialize PiP for background support
    _initializePiP();

    // Pre-populate remote user states from meeting details if available
    _initializeRemoteUserStates();
  }

  // Initialize remote user states from meeting details
  void _initializeRemoteUserStates() {
    final users = widget.meetingDetailsModel?.data?.users;
    if (users != null) {
      for (var user in users) {
        if (user.id != AppData.logInUserId) {
          _remoteUserStates[int.tryParse(user.id ?? '0') ??
              0] = RemoteUserState(
            userId: user.id ?? '',
            isVideoOn: user.meetingDetails?.single.isVideoOn == 1,
            isMicOn: user.meetingDetails?.single.isMicOn == 1,
            isScreenShared: user.meetingDetails?.single.isScreenShared == 1,
            isHandUp: user.meetingDetails?.single.isHandUp == 1,
            userData: user,
          );
        }
      }
    }
  }

  // Enable wakelock with error handling
  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('VideoCallScreen: Wakelock enabled successfully');
    } catch (e) {
      debugPrint('VideoCallScreen: Error enabling wakelock: $e');
    }
  }

  // Disable wakelock with error handling
  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('VideoCallScreen: Wakelock disabled successfully');
    } catch (e) {
      debugPrint('VideoCallScreen: Error disabling wakelock: $e');
    }
  }

  // Initialize Picture-in-Picture subscription for meetings (don't enable yet)
  Future<void> _initializePiP() async {
    try {
      // Cancel any existing subscription first
      await _pipStatusSubscription?.cancel();
      _pipStatusSubscription = null;

      final available = await _pipService.isAvailable();
      debugPrint(
        '📺 VideoCallScreen: PiP available = $available on ${Platform.operatingSystem}',
      );
      if (available && mounted) {
        // Subscribe to PiP status changes using our stream
        _pipStatusSubscription = _pipService.statusStream.listen((status) {
          if (mounted) {
            final isInPiP = status == PiPServiceStatus.enabled;
            if (_isPiPEnabled != isInPiP) {
              setState(() {
                _isPiPEnabled = isInPiP;
              });
              debugPrint('📺 VideoCallScreen: PiP status changed to $status');
            }
          }
        });

        debugPrint(
          '📺 VideoCallScreen: PiP subscription ready (waiting for join)',
        );
      }
    } catch (e) {
      debugPrint('📺 VideoCallScreen: Error initializing PiP: $e');
    }
  }

  // Track if we're pending PiP start (to handle brief inactive states)
  Timer? _pipDelayTimer;
  
  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Cancel any pending PiP start FIRST
        _pipDelayTimer?.cancel();
        _pipDelayTimer = null;
        
        // IMMEDIATELY tell PiP service app resumed - don't delay!
        // This must happen before any pending PiP start can execute
        _pipService.setResumeGracePeriod(true);
        
        // Re-enable wakelock when app returns to foreground
        _enableWakelock();
        // Call full onAppResumed handler (which also sets grace period)
        unawaited(_pipService.onAppResumed());
        // Reset PiP flag when returning to foreground
        if (_isPiPEnabled && mounted) {
          setState(() {
            _isPiPEnabled = false;
          });
        }
        debugPrint('📺 VideoCallScreen: App resumed');
        break;

      case AppLifecycleState.inactive:
        // On iOS, delay PiP start to handle brief inactive states (control center, etc.)
        // PiP will only start if app stays inactive/hidden for 300ms
        if (Platform.isIOS) {
          debugPrint('📺 VideoCallScreen: App inactive - scheduling iOS PiP (300ms delay)');
          _pipDelayTimer?.cancel();
          _pipDelayTimer = Timer(const Duration(milliseconds: 300), () {
            // Double-check: only start PiP if timer wasn't cancelled and not in grace period
            if (mounted && !_pipService.isInResumeGracePeriod) {
              debugPrint('📺 VideoCallScreen: PiP delay elapsed - starting PiP');
              _pipService.onAppPaused();
            } else {
              debugPrint('📺 VideoCallScreen: PiP delay elapsed but blocked (grace period or unmounted)');
            }
          });
        }
        debugPrint('📺 VideoCallScreen: App inactive');
        break;

      case AppLifecycleState.paused:
        // For Android, trigger PiP when fully paused (Android handles this better)
        if (Platform.isAndroid) {
          _pipService.onAppPaused();
        }
        debugPrint('📺 VideoCallScreen: App paused');
        break;

      case AppLifecycleState.detached:
        debugPrint('📺 VideoCallScreen: App detached');
        break;

      case AppLifecycleState.hidden:
        debugPrint('📺 VideoCallScreen: App hidden');
        break;
    }
  }

  // Enable PiP mode for meetings
  Future<void> _enablePiPMode() async {
    // Use the PiP service API
    try {
      final result = await _pipService.enablePiP(
        isVideoCall: true,
        context: mounted ? context : null,
      );
      debugPrint('📺 VideoCallScreen: PiP enable = $result');
    } catch (e) {
      debugPrint('📺 VideoCallScreen: Error enabling PiP: $e');
    }
  }

  // Disable PiP mode
  Future<void> _disablePiPMode() async {
    try {
      _pipService.resetPiPFlag();
      debugPrint('📺 VideoCallScreen: PiP stopped');
    } catch (e) {
      debugPrint('📺 VideoCallScreen: Error disabling PiP: $e');
    }
  }

  // --------------------
  // Pusher Integration
  // --------------------
  void onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("onSubscriptionSucceeded: $channelName data: $data");
  }

  void onSubscriptionError(String message, dynamic e) {
    debugPrint("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    debugPrint("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    debugPrint("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    debugPrint("onMemberRemoved: $channelName member: $member");
  }

  void onError(String message, int? code, dynamic e) {
    debugPrint("onError: $message code: $code exception: $e");
  }

  void onSubscriptionCount(String channelName, int subscriptionCount) {}

  // Authorizer method for Pusher - required to prevent iOS crash
  Future<dynamic>? onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    debugPrint(
      "onAuthorizer called for channel: $channelName, socketId: $socketId",
    );

    // For public channels (not starting with 'private-' or 'presence-'),
    // return null
    if (!channelName.startsWith('private-') &&
        !channelName.startsWith('presence-')) {
      return null;
    }

    return null;
  }

  void onConnectionStateChange(String currentState, String previousState) {
    debugPrint(
      "Pusher Connection State Changed: $previousState -> $currentState",
    );
    // If connection is established, ensure we're subscribed to the channel
    if (currentState == 'CONNECTED' && previousState != 'CONNECTED') {
      debugPrint('Pusher connected successfully, ready to receive events');
    } else if (currentState == 'DISCONNECTED') {
      debugPrint('Pusher disconnected, attempting to reconnect...');
    }
  }

  void _initializePusher() async {
    try {
      await pusher.init(
        apiKey: PusherConfig.key,
        cluster: PusherConfig.cluster,
        useTLS: true,
        onConnectionStateChange: onConnectionStateChange,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onSubscriptionError: onSubscriptionError,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        onDecryptionFailure: onDecryptionFailure,
        onError: onError,
        onSubscriptionCount: onSubscriptionCount,
        onAuthorizer: onAuthorizer,
      );

      await pusher.connect();

      final meetingId = widget.meetingDetailsModel?.data?.meeting?.id;
      final pusherChannelName = "meeting-channel$meetingId";
      debugPrint('Subscribing to Pusher channel: $pusherChannelName');

      clientListenChannel = await pusher.subscribe(
        channelName: pusherChannelName,
        onMemberAdded: (member) {
          // Handle when a new member is added if needed.
          debugPrint("Pusher member added to channel: $member");
        },
        onMemberRemoved: (member) {
          debugPrint("Member removed: $member");
        },
        onEvent: (event) {
          String eventName = event.eventName;
          debugPrint(
            'Pusher raw event received - name: $eventName, data: ${event.data}',
          );

          // Handle pusher subscription events
          if (eventName == 'pusher:subscription_succeeded' ||
              eventName == 'pusher_internal:subscription_succeeded') {
            debugPrint(
              'Successfully subscribed to Pusher channel: $pusherChannelName',
            );
            return;
          }

          Map<String, dynamic> jsonMap = {};
          try {
            jsonMap = jsonDecode(event.data.toString());
          } catch (e) {
            debugPrint('Error parsing Pusher event data: $e');
            return;
          }

          debugPrint('Received event: $eventName with data: $jsonMap');

          // Handling meeting join events
          switch (eventName) {
            case 'new-user-join':
              if (widget.isHost ?? false) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return MeetingJoinRejectDialog(
                      joinName:
                          '${jsonMap['first_name']} ${jsonMap['last_name']}',
                      title: ' wants to join the meeting?',
                      yesButtonText: "Accept",
                      profilePic:
                          '${AppData.imageUrl}${jsonMap['profile_pic']}',
                      callback: () async {
                        // Allow join request via API call.
                        ProgressDialogUtils.showProgressDialog(
                          context: context,
                        );
                        await allowJoinMeet(
                          context,
                          widget.meetingDetailsModel?.data?.meeting?.id,
                          jsonMap['id'],
                        ).then((resp) async {
                          debugPrint("Allow join response: ${resp}");
                          // Refresh meeting details after successful join.
                          _refreshMeetingDetailsDebounced();
                          ProgressDialogUtils.hideProgressDialog();
                        });

                        Navigator.of(context).pop();
                      },
                      noButtonText: 'Reject',
                      callbackNegative: () async {
                        ProgressDialogUtils.showProgressDialog(
                          context: context,
                        );

                        // Reject join request via API call.
                        await rejectJoinMeet(
                          context,
                          jsonMap['id'],
                          widget.meetingDetailsModel?.data?.meeting?.id,
                        ).then((resp) {
                          debugPrint("Reject join response: ${resp}");
                        });
                        ProgressDialogUtils.hideProgressDialog();

                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              }
              break;
            case 'allow-join-request':
              debugPrint("Event name: $eventName");
              toast("Join request allowed");
              break;
            case 'new-message':
              if (AppData.logInUserId != jsonMap['user_id']) {
                AppData.chatMessages.add(
                  Message(
                    text: jsonMap['message'],
                    senderId: jsonMap['user_id'],
                    profilePic: jsonMap['profile_pic'],
                    name: '',
                    timestamp: DateTime.timestamp(),
                    isSentByMe: false,
                  ),
                );
              }
              setState(() {});
              break;
            case 'meeting-status':
              // IMPROVED: Handling meeting status updates more efficiently
              // Handle both 'userId' and 'user_id' field names from Pusher
              final String oderId =
                  (jsonMap['userId'] ?? jsonMap['user_id'] ?? '').toString();
              final String action = jsonMap['action'].toString();

              // Parse status correctly - handle bool, string, int formats
              final dynamic rawStatus = jsonMap['status'];
              final bool status;
              if (rawStatus is bool) {
                status = rawStatus;
              } else if (rawStatus is String) {
                status = rawStatus.toLowerCase() == 'true' || rawStatus == '1';
              } else if (rawStatus is int) {
                status = rawStatus == 1;
              } else {
                status = rawStatus == true;
              }

              debugPrint(
                '📢 Meeting status update: user=$oderId, action=$action, rawStatus=$rawStatus (${rawStatus.runtimeType}), parsedStatus=$status',
              );

              // Update meeting details model
              if (_updateMeetingDetailsForStatus(oderId, action, status)) {
                // Find all remote videos that might need UI updates
                _updateRemoteVideosForUser(oderId);

                // Force UI refresh
                if (mounted) setState(() {});

                // Show user-friendly notification for hand raise (like Zoom/Meet)
                debugPrint(
                  '🖐️ Hand check: action="$action", oderId="$oderId", myId="${AppData.logInUserId}", isNotMe=${oderId != AppData.logInUserId}, status=$status',
                );
                if (action == 'hand') {
                  debugPrint('🖐️ Action is hand! Checking if not me...');
                  if (oderId != AppData.logInUserId) {
                    debugPrint('🖐️ Not me! Checking status: $status');
                    // Find the user's name
                    final user = widget.meetingDetailsModel?.data?.users
                        ?.firstWhere(
                          (u) => u.id == oderId,
                          orElse: () => Users(),
                        );
                    final userName =
                        '${user?.firstName ?? ''} ${user?.lastName ?? ''}'
                            .trim();
                    if (status) {
                      debugPrint(
                        '🖐️ Status is TRUE - showing raised hand message',
                      );
                      _showSystemMessage(
                        '✋ ${userName.isNotEmpty ? userName : 'A participant'} raised their hand',
                      );
                    } else {
                      debugPrint(
                        '🖐️ Status is FALSE - showing lowered hand message',
                      );
                      _showSystemMessage(
                        '${userName.isNotEmpty ? userName : 'A participant'} lowered their hand',
                      );
                    }
                  } else {
                    debugPrint('🖐️ Skipping - this is my own hand event');
                  }
                }
              }
              break;
            default:
              break;
          }
        },
      );
    } catch (e) {
      debugPrint('Pusher initialization error: $e');
      _showErrorDialog(
        'Pusher Connection Error',
        'Failed to connect to messaging service. Please try again.',
      );
    }
  }

  // Helper method to update meeting details model based on status change
  bool _updateMeetingDetailsForStatus(
    String userId,
    String action,
    bool status,
  ) {
    try {
      final userToUpdate = widget.meetingDetailsModel?.data?.users?.firstWhere(
        (user) => user.id == userId,
        orElse: () => Users(),
      );

      if (userToUpdate == null || userToUpdate.id == null) {
        debugPrint("User not found in meeting details: $userId");
        return false;
      }

      final meetingDetail = userToUpdate.meetingDetails?.single;
      if (meetingDetail == null) {
        debugPrint("Meeting details not found for user: $userId");
        return false;
      }

      // Update the appropriate field based on action
      switch (action) {
        case 'cam':
          meetingDetail.isVideoOn = status ? 1 : 0;
          break;
        case 'screen':
          meetingDetail.isScreenShared = status ? 1 : 0;
          break;
        case 'mic':
          meetingDetail.isMicOn = status ? 1 : 0;
          break;
        case 'hand':
          meetingDetail.isHandUp = status ? 1 : 0;
          break;
        default:
          return false;
      }

      // Also update the remote user state map
      _updateRemoteUserState(userId, action, status);

      return true;
    } catch (e) {
      debugPrint("Error updating meeting details: $e");
      return false;
    }
  }

  // Update remote user state in our tracking map
  void _updateRemoteUserState(String oderId, String action, bool status) {
    // Use the userIdToUidMap to find the Agora UID for this user ID
    final int? uidValue = _userIdToUidMap[oderId];

    debugPrint(
      '📝 Updating remote user state: userId=$oderId, action=$action, status=$status, agoraUid=$uidValue',
    );

    // Check if this is the local user (UID 0 is valid for local user)
    if (oderId == AppData.logInUserId) {
      debugPrint('📝 This is the local user, updating local state');
      // For local user, update local state flags directly
      if (action == 'screen') {
        setState(() {
          _isScreenSharing = status;
        });
      } else if (action == 'cam') {
        setState(() {
          _isLocalVideoEnabled = status;
        });
      }
      // Also update the state map for consistency
      _updateRemoteUserStateByUid(0, action, status);
      return;
    }

    if (uidValue == null) {
      // Try to find by iterating through remote videos
      for (var video in _remoteVideos) {
        if (video.joinUser?.id == oderId) {
          final uid = video.uid;
          _updateRemoteUserStateByUid(uid, action, status);
          return;
        }
      }
      debugPrint('Could not find Agora UID for user: $oderId');
      return;
    }

    _updateRemoteUserStateByUid(uidValue, action, status);
  }

  // Update remote user state by Agora UID
  void _updateRemoteUserStateByUid(int uid, String action, bool status) {
    // Create or update user state
    final userState =
        _remoteUserStates[uid] ??
        RemoteUserState(
          userId: _uidToUserIdMap[uid] ?? '',
          userData: Users(id: _uidToUserIdMap[uid]),
        );

    // Update the state based on action
    switch (action) {
      case 'cam':
        userState.isVideoOn = status;
        break;
      case 'screen':
        userState.isScreenShared = status;
        break;
      case 'mic':
        userState.isMicOn = status;
        break;
      case 'hand':
        userState.isHandUp = status;
        debugPrint('✋ Hand status updated for UID $uid: $status');
        break;
    }

    // Update the state map
    _remoteUserStates[uid] = userState;
  }

  // Update UI components for a specific user
  void _updateRemoteVideosForUser(String userId) {
    // Find this user's UID in the remote videos list
    for (int i = 0; i < _remoteVideos.length; i++) {
      final video = _remoteVideos[i];
      final videoUserId = video.joinUser?.id;

      if (videoUserId == userId) {
        // Force rebuild of this video element
        // We don't need to modify the video element itself since it reads from meetingDetailsModel
        setState(() {});
        break;
      }
    }
  }

  // Refresh meeting details with debouncing to prevent too many API calls
  void _refreshMeetingDetailsDebounced() {
    if (_meetingRefreshDebouncer?.isActive ?? false) {
      _meetingRefreshDebouncer!.cancel();
    }

    _meetingRefreshDebouncer = Timer(const Duration(milliseconds: 500), () {
      _refreshMeetingDetails();
    });
  }

  // Actually refresh meeting details
  Future<void> _refreshMeetingDetails() async {
    if (_isRefreshingMeetingDetails) return;

    _isRefreshingMeetingDetails = true;
    try {
      final updatedDetails = await joinMeetings(channelName);
      if (updatedDetails != null && mounted) {
        setState(() {
          widget.meetingDetailsModel = updatedDetails;
          _isRefreshingMeetingDetails = false;

          // Update remote user states from the new details
          _initializeRemoteUserStates();
        });
      }
    } catch (e) {
      debugPrint("Error refreshing meeting details: $e");
      _isRefreshingMeetingDetails = false;
    }
  }

  // --------------------
  // Agora Integration
  // --------------------
  Future<void> _initializeAgora() async {
    try {
      // Request required permissions
      await _requestPermissions();

      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      _setupEventHandlers();
      await _configureVideoSettings();
      await _joinChannel();
    } catch (e) {
      debugPrint('Agora initialization error: $e');
      _showErrorDialog(
        'Initialization Error',
        'Failed to initialize video call. Please check your connection and try again.',
      );
    }
  }

  // Request permissions with professional UI handling
  Future<void> _requestPermissions() async {
    if (!mounted) return;

    // Use the professional CallPermissionHandler
    final result = await callPermissionHandler.showInCallPermissionDialog(
      context,
      isVideoCall: true,
    );

    // Handle the result
    if (result != CallPermissionResult.granted) {
      // Show appropriate feedback based on result
      if (result == CallPermissionResult.permanentlyDenied && mounted) {
        // User was shown settings dialog, permissions might be granted after returning
        // Re-check permissions after a delay (user may have enabled them in settings)
        await Future.delayed(const Duration(seconds: 1));
        final hasPermissions = await callPermissionHandler.hasCallPermissions(
          isVideoCall: true,
        );
        if (!hasPermissions && mounted) {
          _showPermissionRequiredSnackbar();
        }
      } else if (result == CallPermissionResult.denied && mounted) {
        _showPermissionRequiredSnackbar();
      }
    }
  }

  void _showPermissionRequiredSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Camera and microphone access is required for video calls',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  Future<String?> _getUserAccount(int uid) async {
    try {
      final userInfo = await _agoraEngine.getUserInfoByUid(uid);
      return userInfo.userAccount ?? "";
    } catch (e) {
      debugPrint('Error getting user account for UID $uid: $e');
      return null;
    }
  }

  // IMPROVED: Better user-Agora ID mapping and caching
  final Map<int, String> _uidToUserIdMap = {};
  final Map<String, int> _userIdToUidMap = {};

  // Get or cache user ID from Agora UID
  Future<String?> _getCachedUserAccount(int uid) async {
    if (_uidToUserIdMap.containsKey(uid)) {
      return _uidToUserIdMap[uid];
    }

    try {
      final userAccount = await _getUserAccount(uid);
      if (userAccount != null && userAccount.isNotEmpty) {
        _uidToUserIdMap[uid] = userAccount;
        _userIdToUidMap[userAccount] = uid;
      }
      return userAccount;
    } catch (e) {
      debugPrint('Error getting cached user account: $e');
      return null;
    }
  }

  // Set up Agora event handlers
  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onLocalVideoStateChanged: (source, state, reason) {
          // Track local video state changes including screen share
          debugPrint(
            '📹 Local video state changed: source=$source, state=$state, reason=$reason',
          );

          // Check if screen capture started or failed (check both source types)
          if (source == VideoSourceType.videoSourceScreen ||
              source == VideoSourceType.videoSourceScreenPrimary ||
              source == VideoSourceType.videoSourceScreenSecondary) {
            if (state == LocalVideoStreamState.localVideoStreamStateCapturing ||
                state == LocalVideoStreamState.localVideoStreamStateEncoding) {
              debugPrint('📹 Screen capture is now active');
              if (!_isScreenSharing && mounted) {
                setState(() => _isScreenSharing = true);
              }
            } else if (state ==
                LocalVideoStreamState.localVideoStreamStateFailed) {
              debugPrint('📹 Screen capture FAILED: reason=$reason');
              if (mounted) {
                setState(() => _isScreenSharing = false);
                _showSystemMessage('Screen sharing failed. Please try again.');
              }
            } else if (state ==
                LocalVideoStreamState.localVideoStreamStateStopped) {
              debugPrint('📹 Screen capture stopped');
            }
          }
        },
        onVideoPublishStateChanged: (source, oldState, newState, newState2, extra) {
          // Handle video publish state changes - for debugging only
          debugPrint(
            'Video publish state changed from $oldState to $newState for $source',
          );
          // NOTE: Don't auto-enable UI flag here - video should be OFF by default
          // The UI flag (_isLocalVideoEnabled) is only changed when user explicitly toggles
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) async {
          debugPrint('User joined: $remoteUid');
          try {
            // Get user account for this UID
            final userAccount = await _getCachedUserAccount(remoteUid);
            if (userAccount == null || userAccount.isEmpty) {
              debugPrint('Failed to get userAccount for UID: $remoteUid');
              // Add a placeholder user to show something while we wait for user info
              setState(() {
                _remoteVideos.add(
                  RemoteVideoData(
                    uid: remoteUid,
                    joinUser: Users(firstName: "User", lastName: "$remoteUid"),
                    isScreenShare: false,
                    isSpeaking: false,
                    position: _getNextPosition(),
                    scale: 1.0,
                  ),
                );

                // Initialize speaking level
                _userSpeakingLevels[remoteUid] = 0;
                _userSpeakingStatus[remoteUid] = false;
              });

              // Request meeting details update in background
              _refreshMeetingDetailsDebounced();
              return;
            }

            // First find if we already have user information in the meeting details
            Users? apiUser = widget.meetingDetailsModel?.data?.users
                ?.firstWhere((u) => u.id == userAccount, orElse: () => Users());

            if (apiUser?.id == null) {
              // User not found in current meeting details, refresh to get updated info
              await _refreshMeetingDetails();
              // Try again to find the user
              apiUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
                (u) => u.id == userAccount,
                orElse: () => Users(),
              );
            }

            if (apiUser?.id != null) {
              // Add remote video with real user information
              setState(() {
                _remoteVideos.add(
                  RemoteVideoData(
                    uid: remoteUid,
                    joinUser: apiUser,
                    isScreenShare: false,
                    isSpeaking: false,
                    position: _getNextPosition(),
                    scale: 1.0,
                  ),
                );

                // Initialize speaking level
                _userSpeakingLevels[remoteUid] = 0;
                _userSpeakingStatus[remoteUid] = false;

                // Update user state map
                _remoteUserStates[remoteUid] = RemoteUserState(
                  userId: apiUser!.id ?? '',
                  isVideoOn: apiUser.meetingDetails?.single.isVideoOn == 1,
                  isMicOn: apiUser.meetingDetails?.single.isMicOn == 1,
                  isScreenShared:
                      apiUser.meetingDetails?.single.isScreenShared == 1,
                  isHandUp: apiUser.meetingDetails?.single.isHandUp == 1,
                  userData: apiUser,
                );
              });

              // Show welcome message
              _showSystemMessage(
                '${apiUser?.firstName ?? ""} ${apiUser?.lastName ?? ""} joined the meeting',
              );

              // Update participant count
              _updateParticipantCount();
            }
          } catch (e) {
            debugPrint('Error in onUserJoined: $e');
          }
        },
        // onTokenPrivilegeWillExpire: (connection, token) {
        //   _renewToken();
        // },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              debugPrint('Connection state changed: $state, reason: $reason');

              // Handle reconnection scenarios
              if (state == ConnectionStateType.connectionStateReconnecting) {
                setState(() {
                  _isReconnecting = true;
                  _reconnectionAttempts++;
                });

                _showSystemMessage('Attempting to reconnect...');

                if (_reconnectionAttempts >= _maxReconnectionAttempts) {
                  _showErrorDialog(
                    'Connection Lost',
                    'Failed to reconnect after multiple attempts. Please check your network connection and try rejoining the meeting.',
                  );
                }
              } else if (state ==
                  ConnectionStateType.connectionStateConnected) {
                if (_isReconnecting) {
                  _showSystemMessage('Successfully reconnected to the meeting');
                  // Refresh meeting details after reconnection
                  _refreshMeetingDetailsDebounced();
                }

                setState(() {
                  _isReconnecting = false;
                  _reconnectionAttempts = 0;
                });
              } else if (state == ConnectionStateType.connectionStateFailed ||
                  state == ConnectionStateType.connectionStateDisconnected) {
                if (reason !=
                    ConnectionChangedReasonType.connectionChangedLeaveChannel) {
                  _showSystemMessage(
                    'Connection lost. Please check your network.',
                  );
                }
              }
            },
        onUserEnableVideo:
            (
              RtcConnection connection,
              int remoteUid,
              bool isVideoEnabled,
            ) async {
              debugPrint('User ${remoteUid} video enabled: ${isVideoEnabled}');

              String? id = await _getCachedUserAccount(remoteUid);
              if (id != null) {
                try {
                  // Update meeting details model
                  widget.meetingDetailsModel?.data?.users
                      ?.singleWhere(
                        (user) => user.id == id,
                        orElse: () => Users(),
                      )
                      .meetingDetails
                      ?.single
                      .isVideoOn = isVideoEnabled
                      ? 1
                      : 0;

                  // Update remote user state
                  if (_remoteUserStates.containsKey(remoteUid)) {
                    _remoteUserStates[remoteUid]!.isVideoOn = isVideoEnabled;
                  }

                  setState(() {});
                } catch (e) {
                  debugPrint('Error updating video state: $e');
                }
              }
            },
        onUserMuteAudio:
            (RtcConnection connection, int remoteUid, bool isMuted) async {
              debugPrint('User ${remoteUid} audio muted: ${isMuted}');

              String? id = await _getCachedUserAccount(remoteUid);
              if (id != null) {
                try {
                  // Update meeting details model
                  widget.meetingDetailsModel?.data?.users
                      ?.singleWhere(
                        (user) => user.id == id,
                        orElse: () => Users(),
                      )
                      .meetingDetails
                      ?.single
                      .isMicOn = isMuted
                      ? 0
                      : 1;

                  // Update remote user state
                  if (_remoteUserStates.containsKey(remoteUid)) {
                    _remoteUserStates[remoteUid]!.isMicOn = !isMuted;
                  }

                  setState(() {});
                } catch (e) {
                  debugPrint('Error updating mic state: $e');
                }
              }
            },
        onUserMuteVideo:
            (RtcConnection connection, int remoteUid, bool isVideoMuted) async {
              debugPrint('User ${remoteUid} video muted: ${isVideoMuted}');

              String? id = await _getCachedUserAccount(remoteUid);
              if (id != null) {
                try {
                  // Update meeting details model
                  widget.meetingDetailsModel?.data?.users
                      ?.singleWhere(
                        (user) => user.id == id,
                        orElse: () => Users(),
                      )
                      .meetingDetails
                      ?.single
                      .isVideoOn = isVideoMuted
                      ? 0
                      : 1;

                  // Update remote user state
                  if (_remoteUserStates.containsKey(remoteUid)) {
                    _remoteUserStates[remoteUid]!.isVideoOn = !isVideoMuted;
                  }

                  setState(() {});
                } catch (e) {
                  debugPrint('Error updating video mute state: $e');
                }
              }
            },
        onAudioVolumeIndication: (connection, speakers, totalVolume, s) {
          if (speakers.isEmpty) return;

          // First, mark all users as not speaking by default
          setState(() {
            // Set local user as not speaking by default
            bool foundLocalUser = false;

            // Process all active speakers
            for (var speaker in speakers) {
              // Consider someone as speaking if their volume is above threshold
              if ((speaker.volume ?? 0) > 50) {
                if (speaker.uid == 0) {
                  // Local user is speaking
                  foundLocalUser = true;
                  _isLocalUserSpeaking = true;

                  // Reset speaking state after a delay if no more audio
                  _localUserSpeakingTimer?.cancel();
                  _localUserSpeakingTimer = Timer(
                    const Duration(milliseconds: 800),
                    () {
                      if (mounted) setState(() => _isLocalUserSpeaking = false);
                    },
                  );
                } else {
                  // Remote user is speaking - find and update their status
                  for (var i = 0; i < _remoteVideos.length; i++) {
                    if (_remoteVideos[i].uid == speaker.uid) {
                      _remoteVideos[i] = _remoteVideos[i].copyWith(
                        isSpeaking: true,
                      );

                      // Cancel any existing timer for this user
                      _speakingTimers[speaker.uid]?.cancel();

                      // Create a timer to reset speaking state after delay
                      _speakingTimers[speaker.uid!] = Timer(
                        const Duration(milliseconds: 800),
                        () {
                          if (mounted) {
                            setState(() {
                              for (var j = 0; j < _remoteVideos.length; j++) {
                                if (_remoteVideos[j].uid == speaker.uid) {
                                  _remoteVideos[j] = _remoteVideos[j].copyWith(
                                    isSpeaking: false,
                                  );
                                  break;
                                }
                              }
                            });
                          }
                        },
                      );
                      break;
                    }
                  }
                }
              }
            }

            // If local user wasn't in the speakers list with sufficient volume
            if (!foundLocalUser) {
              _isLocalUserSpeaking = false;
            }
          });
        },
        onRemoteVideoStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed,
            ) async {
              debugPrint(
                'Remote video state changed for UID: $remoteUid to state: $state, reason: $reason',
              );

              if (state == RemoteVideoState.remoteVideoStateStarting) {
                debugPrint('Remote video state starting for UID: $remoteUid');
                // Check if we already have this remote user
                final existingIndex = _remoteVideos.indexWhere(
                  (v) => v.uid == remoteUid,
                );

                if (existingIndex == -1) {
                  // New user with video - add them
                  final userAccount = await _getCachedUserAccount(remoteUid);
                  var apiUser = Users();

                  if (userAccount != null) {
                    apiUser =
                        widget.meetingDetailsModel?.data?.users?.firstWhere(
                          (u) => u.id == userAccount,
                          orElse: () => Users(),
                        ) ??
                        Users();
                  }

                  if (apiUser.id == null) {
                    // Try refreshing meeting details
                    await _refreshMeetingDetails();
                    if (userAccount != null) {
                      apiUser =
                          widget.meetingDetailsModel?.data?.users?.firstWhere(
                            (u) => u.id == userAccount,
                            orElse: () => Users(),
                          ) ??
                          Users();
                    }
                  }

                  // If we still don't have user info, use a placeholder
                  if (apiUser.id == null) {
                    apiUser = Users(
                      id: userAccount,
                      firstName: "User",
                      lastName: "$remoteUid",
                      meetingDetails: [
                        MeetingDetails(isVideoOn: 1, isMicOn: 1),
                      ],
                    );
                  }

                  setState(() {
                    _remoteVideos.add(
                      RemoteVideoData(
                        uid: remoteUid,
                        joinUser: apiUser,
                        isScreenShare: false,
                        isSpeaking: false,
                        position: _getNextPosition(),
                        scale: 1.0,
                      ),
                    );

                    // Initialize speaking level
                    _userSpeakingLevels[remoteUid] = 0;
                    _userSpeakingStatus[remoteUid] = false;
                  });
                } else {
                  // Update existing user
                  final existingVideo = _remoteVideos[existingIndex];
                  if (existingVideo
                          .joinUser
                          ?.meetingDetails
                          ?.single
                          .isVideoOn ==
                      0) {
                    // Update video state if needed
                    final userAccount = await _getCachedUserAccount(remoteUid);
                    if (userAccount != null) {
                      try {
                        widget.meetingDetailsModel?.data?.users
                                ?.singleWhere(
                                  (user) => user.id == userAccount,
                                  orElse: () => Users(),
                                )
                                .meetingDetails
                                ?.single
                                .isVideoOn =
                            1;

                        if (_remoteUserStates.containsKey(remoteUid)) {
                          _remoteUserStates[remoteUid]!.isVideoOn = true;
                        }

                        setState(() {});
                      } catch (e) {
                        debugPrint('Error updating remote video state: $e');
                      }
                    }
                  }
                }
              } else if (state == RemoteVideoState.remoteVideoStateStopped) {
                // Video stopped - update state
                final userAccount = await _getCachedUserAccount(remoteUid);
                if (userAccount != null) {
                  try {
                    widget.meetingDetailsModel?.data?.users
                            ?.singleWhere(
                              (user) => user.id == userAccount,
                              orElse: () => Users(),
                            )
                            .meetingDetails
                            ?.single
                            .isVideoOn =
                        0;

                    if (_remoteUserStates.containsKey(remoteUid)) {
                      _remoteUserStates[remoteUid]!.isVideoOn = false;
                    }

                    setState(() {});
                  } catch (e) {
                    debugPrint('Error updating remote video state: $e');
                  }
                }
              } else if (state == RemoteVideoState.remoteVideoStateFailed) {
                // Handle video failure if needed
                debugPrint(
                  'Remote video failed for UID: $remoteUid, reason: $reason',
                );
              }
            },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Successfully joined channel: ${connection.channelId}');
          setState(() => _isJoined = true);
          _updateParticipantCount();

          // NOW enable PiP since user has actually joined the meeting
          // Allow PiP and enable auto-enter when app goes to background
          _pipService.allowPiP();
          _pipService.enableAutoPiP(
            isVideoCall: true,
            context: mounted ? context : null,
          );

          // IMPORTANT: Pre-setup PiP so it's ready before backgrounding (especially for iOS)
          // This ensures the PiP controller is fully initialized before we need it
          if (Platform.isIOS) {
            _pipService.setup().then((_) {
              debugPrint('📺 VideoCallScreen: iOS PiP pre-setup complete');
            });
          }

          debugPrint(
            '📺 VideoCallScreen: Joined meeting - PiP service notified',
          );

          // Start audio volume detection
          _agoraEngine.enableAudioVolumeIndication(
            interval: 500, // Check every 500ms
            smooth: 3, // Smoothing factor
            reportVad: true, // Voice activity detection
          );

          // Subscribe to all remote users immediately after joining
          _subscribeToAllRemoteUsers();

          // Notify server that camera is OFF by default when joining
          changeMeetingStatus(
                context,
                widget.meetingDetailsModel?.data?.meeting?.id,
                AppData.logInUserId,
                'cam',
                false, // Camera OFF by default
              )
              .then((resp) {
                debugPrint("Initial camera status set to OFF: ${resp}");
              })
              .catchError((error) {
                debugPrint("Error setting initial camera status: $error");
              });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) async {
              debugPrint('User offline: $remoteUid, reason: $reason');

              String? userId = await _getCachedUserAccount(remoteUid);
              var removedUser = widget.meetingDetailsModel?.data?.users
                  ?.firstWhere(
                    (user) => user.id == userId,
                    orElse: () => Users(),
                  );

              // Clean up our maps
              _userSpeakingLevels.remove(remoteUid);
              _userSpeakingStatus.remove(remoteUid);
              _remoteUserStates.remove(remoteUid);
              _speakingTimers[remoteUid]?.cancel();
              _speakingTimers.remove(remoteUid);

              setState(() {
                _remoteVideos.removeWhere((v) => v.uid == remoteUid);
              });

              if (removedUser?.id != null) {
                _showSystemMessage(
                  '${removedUser?.firstName ?? ""} ${removedUser?.lastName ?? ""} left the meeting',
                );
              } else {
                _showSystemMessage('A participant left the meeting');
              }

              _updateParticipantCount();

              // Check if user is now alone in the meeting and auto-end if host
              _checkAndHandleAloneInMeeting();
            },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora error: $msg");

          // Only show UI error for significant issues
          if (err != ErrorCodeType.errOk) {
            _showErrorDialog(
              'Video Call Error',
              'Error code: ${err.name}. Please try reconnecting if issues persist.',
            );
          }
        },
        onRtcStats: (RtcConnection connection, RtcStats stats) {
          // Can be used to show call quality metrics if needed
        },
        onNetworkQuality:
            (
              RtcConnection connection,
              int uid,
              QualityType txQuality,
              QualityType rxQuality,
            ) {
              setState(() => _networkQuality = rxQuality.index);
            },
      ),
    );
  }

  // Proactively subscribe to all remote users
  void _subscribeToAllRemoteUsers() {
    try {
      _agoraEngine.setDefaultAudioRouteToSpeakerphone(true);

      // Subscribe to both audio and video by default
      _agoraEngine.muteAllRemoteAudioStreams(false);
      _agoraEngine.muteAllRemoteVideoStreams(false);

      debugPrint('Subscribed to all remote users');
    } catch (e) {
      debugPrint('Error subscribing to remote users: $e');
    }
  }

  Future<void> _renewToken() async {
    try {
      // In a production app, you would call your backend to get a new token
      // For now, show a message that token is expiring
      _showSystemMessage(
        'Session token expiring soon. You may need to rejoin.',
      );

      // Call your token renewal API and update the engine token.
      // var newToken = await fetchNewAgoraToken(); // Implement this function as needed.
      // await _agoraEngine.renewToken(newToken);
    } catch (e) {
      debugPrint('Token renewal error: $e');
    }
  }

  Future<void> _configureVideoSettings() async {
    try {
      await _agoraEngine.enableVideo();
      await _agoraEngine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 2000,
        ),
      );

      // Set more aggressive parameters for better performance
      await _agoraEngine.setParameters(
        '{"che.video.lowBitRateStreamParameter":{"width":320,"height":180,"frameRate":15,"bitRate":140}}',
      );

      // Optimize for network conditions
      await _agoraEngine.setParameters('{"rtc.using_ui_smaller_size":true}');
      await _agoraEngine.setParameters('{"che.video.mobile_1080p":true}');

      // Start camera preview initially
      await _agoraEngine.startPreview();
      await _agoraEngine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
      await _agoraEngine.enableVideo();

      // Enable dual-stream mode for better bandwidth adaptation
      await _agoraEngine.enableDualStreamMode(enabled: true);

      // Set audio profile for better quality
      await _agoraEngine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Enable automatic fallback options for poor network
      await _agoraEngine.setLocalPublishFallbackOption(
        StreamFallbackOptions.streamFallbackOptionAudioOnly,
      );
      await _agoraEngine.setRemoteSubscribeFallbackOption(
        StreamFallbackOptions.streamFallbackOptionAudioOnly,
      );

      // Set default speaker mode
      await _agoraEngine.setDefaultAudioRouteToSpeakerphone(true);

      // IMPORTANT: By default, disable local video so camera is OFF when user joins
      // User must explicitly turn on their camera
      await _agoraEngine.stopPreview();
      await _agoraEngine.muteLocalVideoStream(true);
      await _agoraEngine.enableLocalVideo(false);
      debugPrint('Camera set to OFF by default - user must enable manually');
    } catch (e) {
      debugPrint('Error configuring video settings: $e');
      _showErrorDialog(
        'Setup Error',
        'Failed to configure video settings. Please try again.',
      );
    }
  }

  Future<void> _joinChannel() async {
    debugPrint(
      'Joining channel: $channelName with user ID: ${AppData.logInUserId}',
    );
    try {
      // Pre-populate our user ID to UID mapping
      _userIdToUidMap[AppData.logInUserId] = 0; // Local user has UID 0
      _uidToUserIdMap[0] = AppData.logInUserId;

      // Save channel config for iOS screen share extension
      if (Platform.isIOS) {
        await _screenShareService.saveChannelConfig(
          appId: appId,
          channelName: channelName,
          token: token.isNotEmpty ? token : null,
          uid: 0,
        );
      }

      // Join with optimized options - camera OFF by default
      await _agoraEngine.joinChannelWithUserAccount(
        token: '',
        channelId: channelName,
        userAccount: AppData.logInUserId,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack:
              false, // Camera OFF by default - user must enable manually
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      debugPrint('Join channel error: $e');
      _showErrorDialog(
        'Connection Error',
        'Failed to join the meeting. Please check your connection and try again.',
      );
    }
  }

  Offset _getNextPosition() {
    if (_remoteVideos.length < _defaultPositions.length) {
      return _defaultPositions[_remoteVideos.length];
    }
    return Offset(
      20 + (_remoteVideos.length % 4) * 180,
      20 + (_remoteVideos.length % 3) * 160,
    );
  }

  void _updateParticipantCount() {
    // Update the participant count if needed.
    _participantCount.value = _remoteVideos.length + 1; // including local user.
  }

  // Check if user is alone in meeting and handle accordingly
  void _checkAndHandleAloneInMeeting() {
    if (_remoteVideos.isEmpty && (widget.isHost ?? false)) {
      // User is alone and is host - offer to end meeting
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _remoteVideos.isEmpty) {
          _showAloneInMeetingDialog();
        }
      });
    }
  }

  // Show dialog when user is alone in meeting
  void _showAloneInMeetingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translation(context).lbl_meeting),
          content: const Text(
            'You are the only participant left in the meeting. Would you like to end it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context).lbl_cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _endMeetingProperly();
              },
              child: Text(
                translation(context).lbl_end_meeting,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Properly end meeting with error handling
  Future<void> _endMeetingProperly() async {
    try {
      // Disable wakelock when ending the call
      await _disableWakelock();

      // Clear chat messages
      AppData.chatMessages.clear();

      if (widget.isHost ?? false) {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Ending meeting...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Call the API to end meeting
        final resp = await endMeeting(
          context,
          widget.meetingDetailsModel?.data?.meeting?.id,
        );

        // Dismiss loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        debugPrint("End meeting response: ${resp}");

        if (resp.success) {
          // Success - navigate back
          if (mounted) {
            Navigator.pop(context); // Exit meeting screen
          }
        } else {
          // API call failed but still allow user to leave
          debugPrint("End meeting API failed but allowing user to exit");
          if (mounted) {
            // Show error but still navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to end meeting on server, but you have left the meeting.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context); // Exit meeting screen anyway
          }
        }
      } else {
        // Non-host user - just leave the meeting
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Error ending meeting: $e");

      // Dismiss loading dialog if still showing
      if (mounted) {
        Navigator.pop(context);

        // Show error but still allow user to leave
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error ending meeting, but you have left the meeting.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        // Navigate back anyway
        Navigator.pop(context);
      }
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationNotifier.value++;
    });
  }

  void _generateDefaultPositions() {
    _defaultPositions.addAll([
      const Offset(20, 20),
      const Offset(20, 200),
      const Offset(200, 20),
      const Offset(200, 200),
    ]);
  }

  // --------------------
  // Screen Sharing Toggle
  // --------------------
  Future<void> _toggleScreenSharing() async {
    try {
      // Check if screen sharing is allowed by settings or host privilege.
      if (widget.meetingDetailsModel?.data?.settings?.shareScreen == '1' ||
          widget.isHost == true) {
        // When currently screen sharing, revert to normal camera video.
        if (_isScreenSharing) {
          if (Platform.isIOS) {
            // iOS: Stop in-app screen capture
            await _agoraEngine.stopScreenCapture();
            debugPrint('iOS: Screen capture stopped');

            // Update channel media options to disable screen sharing tracks
            await _agoraEngine.updateChannelMediaOptions(
              ChannelMediaOptions(
                publishScreenTrack: false,
                publishScreenCaptureVideo: false,
                publishCameraTrack: _isLocalVideoEnabled,
                publishMicrophoneTrack: true,
                autoSubscribeAudio: true,
                clientRoleType: ClientRoleType.clientRoleBroadcaster,
              ),
            );
          } else {
            // Android: Stop screen capture in main app
            await _agoraEngine.stopScreenCapture();
            debugPrint('Android: Screen capture stopped');

            // Update channel media options to disable screen sharing tracks
            await _agoraEngine.updateChannelMediaOptions(
              ChannelMediaOptions(
                publishScreenTrack: false,
                publishScreenCaptureAudio: false,
                publishScreenCaptureVideo: false,
                publishCameraTrack: _isLocalVideoEnabled,
                publishMicrophoneTrack: true,
                publishMediaPlayerAudioTrack: true,
                autoSubscribeAudio: true,
                clientRoleType: ClientRoleType.clientRoleBroadcaster,
              ),
            );
          }
          // Update meeting status for camera (based on whether video was enabled)
          await changeMeetingStatus(
                context,
                widget.meetingDetailsModel?.data?.meeting?.id,
                AppData.logInUserId,
                'cam',
                _isLocalVideoEnabled,
              )
              .then((resp) {
                debugPrint("Change status (camera) response: $resp");
              })
              .catchError((error) {
                debugPrint("Error changing meeting status: $error");
              });

          // Update meeting status for screen share being off
          await changeMeetingStatus(
                context,
                widget.meetingDetailsModel?.data?.meeting?.id,
                AppData.logInUserId,
                'screen',
                false,
              )
              .then((resp) {
                debugPrint("Change status (screen) response: $resp");
              })
              .catchError((error) {
                debugPrint("Error changing meeting status: $error");
              });

          // Set the state to reflect that we are no longer screen sharing.
          setState(() => _isScreenSharing = false);
          // Start the camera preview if video was enabled
          if (_isLocalVideoEnabled) {
            await _agoraEngine.startPreview();
          }
        }
        // Otherwise, switch to screen sharing mode.
        else {
          debugPrint('🖥️ Starting screen share...');

          // Stop the camera preview.
          await _agoraEngine.stopPreview();

          // Platform-specific screen capture configuration
          if (Platform.isIOS) {
            // iOS: Use Broadcast Extension for screen sharing
            // First prepare Agora, then show the system broadcast picker
            debugPrint('🖥️ iOS: Starting screen share setup');

            try {
              await _agoraEngine.startScreenCapture(
                const ScreenCaptureParameters2(
                  captureVideo: true,
                  captureAudio:
                      false, // iOS doesn't support audio capture in-app
                  videoParams: ScreenVideoParameters(
                    dimensions: VideoDimensions(width: 1280, height: 720),
                    frameRate: 15,
                    contentHint: VideoContentHint.contentHintDetails,
                    bitrate: 2000,
                  ),
                ),
              );
              debugPrint('🖥️ iOS: startScreenCapture completed');
            } catch (e) {
              debugPrint('🖥️ iOS: startScreenCapture FAILED: $e');
              _showSystemMessage('Failed to start screen capture');
              return;
            }

            // Start preview with screen capture source to initialize video pipeline
            try {
              await _agoraEngine.startPreview(
                sourceType: VideoSourceType.videoSourceScreen,
              );
              debugPrint('🖥️ iOS: startPreview for screen source completed');
            } catch (e) {
              debugPrint('🖥️ iOS: startPreview for screen FAILED: $e');
            }

            // Small delay to allow preview to initialize
            await Future.delayed(const Duration(milliseconds: 200));

            // Update channel media options for iOS screen sharing
            try {
              await _agoraEngine.updateChannelMediaOptions(
                const ChannelMediaOptions(
                  publishScreenTrack: true,
                  publishScreenCaptureVideo: true,
                  publishSecondaryScreenTrack: true, // Also try secondary track
                  // Disable camera track while screen sharing
                  publishCameraTrack: false,
                  publishMicrophoneTrack: true,
                  autoSubscribeAudio: true,
                  autoSubscribeVideo: true,
                  clientRoleType: ClientRoleType.clientRoleBroadcaster,
                ),
              );
              debugPrint('🖥️ iOS: updateChannelMediaOptions completed');
            } catch (e) {
              debugPrint('🖥️ iOS: updateChannelMediaOptions FAILED: $e');
            }

            // Now show the system broadcast picker to let user start the extension
            try {
              const screenShareChannel = MethodChannel('com.doctak.app/screen_share');
              await screenShareChannel.invokeMethod('startBroadcast');
              debugPrint('🖥️ iOS: Broadcast picker shown');
            } catch (e) {
              debugPrint('🖥️ iOS: Failed to show broadcast picker: $e');
            }

            debugPrint('🖥️ iOS: Screen share setup completed');
          } else {
            // Android: Standard screen capture
            debugPrint('🖥️ Android: Starting screen capture');
            try {
              await _agoraEngine.startScreenCapture(
                const ScreenCaptureParameters2(
                  captureVideo: true,
                  captureAudio: true,
                  videoParams: ScreenVideoParameters(
                    dimensions: VideoDimensions(width: 1280, height: 720),
                    frameRate: 15,
                    contentHint: VideoContentHint.contentHintMotion,
                    bitrate: 2000,
                  ),
                ),
              );
              debugPrint('🖥️ Android: startScreenCapture completed');
            } catch (e) {
              debugPrint('🖥️ Android: startScreenCapture FAILED: $e');
              _showSystemMessage('Failed to start screen capture');
              return;
            }

            // Update channel media options to disable camera track and enable screen sharing.
            try {
              await _agoraEngine.updateChannelMediaOptions(
                const ChannelMediaOptions(
                  publishScreenTrack: true,
                  publishScreenCaptureAudio: true,
                  publishScreenCaptureVideo: true,
                  // Disable camera track while screen sharing.
                  publishCameraTrack: false,
                  publishMicrophoneTrack: true,
                  publishMediaPlayerAudioTrack: true,
                  autoSubscribeAudio: true,
                  clientRoleType: ClientRoleType.clientRoleBroadcaster,
                ),
              );
              debugPrint('🖥️ Android: updateChannelMediaOptions completed');
            } catch (e) {
              debugPrint('🖥️ Android: updateChannelMediaOptions FAILED: $e');
            }
          }

          debugPrint('🖥️ Screen share started');

          // Update the meeting status accordingly:
          // Indicate that the camera is off.
          await changeMeetingStatus(
                context,
                widget.meetingDetailsModel?.data?.meeting?.id,
                AppData.logInUserId,
                'cam',
                false,
              )
              .then((resp) {
                debugPrint("Change status (camera) response: $resp");
              })
              .catchError((error) {
                debugPrint("Error changing meeting status: $error");
              });
          // Indicate that the screen share is on.
          await changeMeetingStatus(
                context,
                widget.meetingDetailsModel?.data?.meeting?.id,
                AppData.logInUserId,
                'screen',
                true,
              )
              .then((resp) {
                debugPrint("Change status (screen) response: $resp");
              })
              .catchError((error) {
                debugPrint("Error changing meeting status: $error");
              });
          // Set the state to reflect that screen sharing is now active.
          setState(() => _isScreenSharing = true);

          _showSystemMessage('Screen sharing started');
        }
      } else {
        _showSystemMessage('Screen share permission not allowed from host');
      }
    } catch (e, stackTrace) {
      debugPrint('Screen share error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorDialog(
        'Screen Share Error',
        'Failed to ${_isScreenSharing ? 'stop' : 'start'} screen sharing: $e',
      );
    }
  }

  // Format call duration
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSystemMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translation(context).lbl_ok),
          ),
        ],
      ),
    );
  }

  // --------------------
  // UI Build Methods
  // --------------------
  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to detect actual window size
    // PiP windows are typically very small (< 400 pixels in either dimension)
    return LayoutBuilder(
      builder: (context, constraints) {
        // ONLY use _isPiPEnabled flag - remove isSmallWindow check
        // The isSmallWindow check was causing false positives on some devices
        if (_isPiPEnabled) {
          return _buildPipModeView();
        } else {
          return _buildNormalModeView();
        }
      },
    );
  }

  /// OLD design for normal/expanded mode
  // One UI 8.5 Color Palette
  static const Color _oneUIBackground = Color(
    0xFF0D1B2A,
  ); // Deep navy background
  static const Color _oneUISurface = Color(0xFF1B2838); // Card surface
  static const Color _oneUIFloatingBg = Color(
    0xFF2D3E50,
  ); // Floating button background
  static const Color _oneUIAccent = Color(0xFF4DA3FF); // Accent blue
  static const Color _oneUINavBar = Color(0xFF152232); // Bottom nav bar

  Widget _buildNormalModeView() {
    // Calculate bottom nav bar height for positioning
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 85 + (bottomPadding > 0 ? bottomPadding : 12);

    return WillPopScope(
      onWillPop: () async {
        _confirmEndCall();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: _oneUIBackground,
        extendBody: true,
        body: Stack(
          fit: StackFit.loose,
          children: [
            // Main video area that adapts based on number of participants
            // Add bottom margin to not cover the bottom navigation bar
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              bottom:
                  0, // Let it extend to bottom, bottomNavigationBar handles spacing
              child: _buildMainVideoArea(),
            ),

            // Local video preview
            if (_isJoined) _buildLocalPreview(),

            // Floating control options - positioned above bottom nav bar
            Positioned(
              bottom: navBarHeight + 16,
              right: 16,
              child: _buildFloatingControls(),
            ),

            // Top right Popup Menu
            Positioned(top: 50, right: 20, child: _buildPopupMenu()),

            // Top left back button
            Positioned(top: 50, left: 16, child: _buildBackButton()),

            // Call timer display
            Positioned(
              top: 50,
              left: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _oneUISurface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: _callDurationNotifier,
                      builder: (context, duration, child) => Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Show reconnecting indicator if needed
            if (_isReconnecting)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: _oneUIAccent),
                      const SizedBox(height: 20),
                      Text(
                        'Reconnecting... (Attempt $_reconnectionAttempts)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildControlBar(),
      ),
    );
  }

  /// NEW responsive design for PiP/floating widget mode
  Widget _buildPipModeView() {
    return WillPopScope(
      onWillPop: () async {
        _confirmEndCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            final totalWidth = constraints.maxWidth;

            // For very small PiP windows, use minimal controls
            final isVerySmall = totalHeight < 150 || totalWidth < 200;

            // Control bar height - smaller for tiny windows
            final controlBarHeight = isVerySmall
                ? (totalHeight * 0.30).clamp(24.0, 40.0)
                : (totalHeight * 0.25).clamp(32.0, 50.0);

            return ClipRect(
              child: Column(
                children: [
                  // Main video area - takes remaining space
                  Expanded(
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Video content - clipped
                          ClipRect(child: _buildPipVideoArea()),

                          // Compact call timer in PiP mode
                          if (!isVerySmall)
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                    const SizedBox(width: 2),
                                    ValueListenableBuilder<int>(
                                      valueListenable: _callDurationNotifier,
                                      builder: (context, duration, child) =>
                                          Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 7,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Show reconnecting indicator if needed
                          if (_isReconnecting)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Control bar at the bottom - constrained height
                  SizedBox(
                    height: controlBarHeight,
                    child: ClipRect(child: _buildControlBar()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Simplified video area for PiP mode - no center/column that can overflow
  Widget _buildPipVideoArea() {
    if (_remoteVideos.isEmpty) {
      // No remote videos - show local video (user's own camera) in PiP
      return Container(
        color: const Color(0xFF1a1a2e),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show local video or avatar
            if (_isLocalVideoEnabled)
              AgoraVideoView(
                controller: VideoViewController(
                  useAndroidSurfaceView: true,
                  useFlutterTexture: true,
                  rtcEngine: _agoraEngine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            else
              Center(
                child: AppData.profile_pic.isNotEmpty
                    ? CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade700,
                        backgroundImage: NetworkImage(
                          '${AppData.imageUrl}${AppData.profile_pic}',
                        ),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blueGrey.shade600,
                        child: Text(
                          AppData.name.isNotEmpty
                              ? AppData.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            // Label showing "You"
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_remoteVideos.length == 1) {
      // Single participant - fill the screen
      return _buildVideoWindow(_remoteVideos[0], getColorByIndex(0));
    } else {
      // Multiple participants - show first one in PiP
      return _buildVideoWindow(_remoteVideos[0], getColorByIndex(0));
    }
  }

  Widget _buildMainVideoArea() {
    // Only use PiP design when actually in PiP mode
    final isPipMode = _isPiPEnabled;

    if (_remoteVideos.isEmpty) {
      // No remote videos, show waiting message or local preview fullscreen
      if (isPipMode) {
        // NEW design for PiP mode - compact with FittedBox
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 24, color: Colors.grey),
                  const SizedBox(height: 4),
                  const Text(
                    'Waiting...',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // OLD design for normal mode
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_no_user_found,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
    } else if (_remoteVideos.length == 1 && _selectedUserId == null) {
      // Single participant - fill the screen
      return _buildSingleUserView(_remoteVideos[0]);
    } else if (_remoteVideos.length == 2 && _selectedUserId == null) {
      // Two participants - split screen
      return _buildTwoUserView();
    } else if (_selectedUserId != null) {
      // Focused view on selected user with bottom carousel
      return _buildFocusedView();
    } else {
      // Multiple participants - grid view
      return _buildGridView();
    }
  }

  Widget _buildSingleUserView(RemoteVideoData videoData) {
    return _buildVideoWindow(videoData, getColorByIndex(0));
  }

  Widget _buildTwoUserView() {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedUserId = _remoteVideos[0].uid;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              child: _buildVideoWindow(_remoteVideos[0], getColorByIndex(0)),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedUserId = _remoteVideos[1].uid;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              child: _buildVideoWindow(_remoteVideos[1], getColorByIndex(1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCrossAxisCount(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 3 / 4,
      ),
      itemCount: _remoteVideos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedUserId = _remoteVideos[index].uid;
            });
          },
          child: _buildVideoWindow(
            _remoteVideos[index],
            getColorByIndex(index),
          ),
        );
      },
    );
  }

  Widget _buildFocusedView() {
    // Find the selected user
    final selectedVideoData = _remoteVideos.firstWhere(
      (video) => video.uid == _selectedUserId,
      orElse: () => _remoteVideos.first,
    );

    // All other videos for the carousel
    final otherVideos = _remoteVideos
        .where((video) => video.uid != _selectedUserId)
        .toList();

    return Column(
      children: [
        // Main focused video (takes most of the screen)
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.fromLTRB(4, 4, 4, 2),
            child: _buildVideoWindow(
              selectedVideoData,
              getColorByIndex(0),
              isFocused: true,
            ),
          ),
        ),

        // Horizontal list of other participants at the bottom
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.fromLTRB(4, 2, 4, 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: otherVideos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserId = otherVideos[index].uid;
                    });
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildVideoWindow(
                      otherVideos[index],
                      getColorByIndex(index + 1),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  int _getGridCrossAxisCount() {
    if (_remoteVideos.length <= 4) {
      return 2; // 2x2 grid for 3-4 participants
    } else if (_remoteVideos.length <= 9) {
      return 3; // 3x3 grid for 5-9 participants
    } else {
      return 4; // 4x4 grid for 10+ participants
    }
  }

  // IMPROVED: More robust video window with better status checking
  Widget _buildVideoWindow(
    RemoteVideoData videoData,
    Color color, {
    bool isFocused = false,
  }) {
    // Get the latest state from our map if possible
    final remoteState = _remoteUserStates[videoData.uid];

    // Determine display states prioritizing real-time data from our state map
    final bool isVideoEnabled =
        remoteState?.isVideoOn ??
        (videoData.joinUser?.meetingDetails?.single.isVideoOn == 1);
    final bool isScreenShared =
        remoteState?.isScreenShared ??
        (videoData.joinUser?.meetingDetails?.single.isScreenShared == 1);
    final bool isMicOn =
        remoteState?.isMicOn ??
        (videoData.joinUser?.meetingDetails?.single.isMicOn == 1);
    final bool isHandUp =
        remoteState?.isHandUp ??
        (videoData.joinUser?.meetingDetails?.single.isHandUp == 1);

    // Debug log hand status
    if (isHandUp) {
      debugPrint(
        '✋ Building video window with hand raised for ${videoData.joinUser?.firstName} (uid: ${videoData.uid})',
      );
    }

    // Get user name for display
    final String firstName = videoData.joinUser?.firstName ?? "";
    final String lastName = videoData.joinUser?.lastName ?? "";
    final String displayName = "$firstName $lastName".trim();

    // Determine border properties based on speaking status and mode
    Color borderColor;
    double borderWidth;

    if (videoData.isSpeaking) {
      borderColor = Colors.green;
      borderWidth = 3.0;
    } else if (isScreenShared) {
      borderColor = Colors.blue;
      borderWidth = 2.0;
    } else {
      borderColor = Colors.grey.shade800;
      borderWidth = isFocused ? 0 : 2.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(8),
        boxShadow: videoData.isSpeaking
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Main video content - show video, screen share, or avatar
            Positioned.fill(
              child: isScreenShared
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraEngine,
                        canvas: VideoCanvas(
                          uid: videoData.uid,
                          sourceType: VideoSourceType.videoSourceRemote,
                        ),
                        connection: RtcConnection(channelId: channelName),
                        useFlutterTexture: true,
                        useAndroidSurfaceView: true,
                      ),
                    )
                  : isVideoEnabled
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraEngine,
                        canvas: VideoCanvas(
                          uid: videoData.uid,
                          sourceType: VideoSourceType.videoSourceRemote,
                        ),
                        connection: RtcConnection(channelId: channelName),
                        useFlutterTexture: true,
                        useAndroidSurfaceView: true,
                      ),
                    )
                  : Container(
                      color: color,
                      child: Center(
                        child: CircleAvatar(
                          radius: isFocused ? 80 : 40,
                          backgroundImage: NetworkImage(
                            '${AppData.imageUrl}${videoData.joinUser?.profilePic}',
                          ),
                        ),
                      ),
                    ),
            ),

            // User info overlay at bottom
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  // Mic status icon
                  Icon(
                    isMicOn ? CupertinoIcons.mic : CupertinoIcons.mic_off,
                    color: isMicOn ? Colors.white : Colors.red,
                    size: isFocused ? 20 : 16,
                  ),
                  const SizedBox(width: 4),
                  // Username and mode status
                  Text(
                    displayName.isEmpty
                        ? "Unknown User"
                        : isScreenShared
                        ? "$displayName (Screen)"
                        : displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isFocused ? 16 : 12,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Exit focused view button (only for focused video)
            if (_selectedUserId != null && isFocused)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserId = null; // Exit focused view
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Show screen share indicator if applicable
            if (isScreenShared)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.screen_share,
                        color: Colors.white,
                        size: 14,
                      ),
                      if (isFocused) ...[
                        const SizedBox(width: 4),
                        Text(
                          translation(context).lbl_screen_sharing,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Show hand raised indicator - prominent like Zoom/Google Meet
            if (isHandUp)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.hand_raised_fill,
                        color: Colors.white,
                        size: 16,
                      ),
                      if (isFocused) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Hand Raised',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Container(
      decoration: BoxDecoration(
        color: _oneUISurface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOneUIFloatingButton(
            icon: _showFloatingOptions
                ? CupertinoIcons.chevron_down
                : CupertinoIcons.chevron_up,
            onPressed: () {
              setState(() {
                _showFloatingOptions = !_showFloatingOptions;
              });
            },
            isToggle: true,
          ),
          if (_showFloatingOptions) ...[
            const SizedBox(height: 8),
            _buildOneUIFloatingButton(
              icon: CupertinoIcons.hand_raised,
              onPressed: _toggleHandRaise,
              isActive: _isHandRaised,
              activeColor: const Color(0xFFFF9500),
            ),
            const SizedBox(height: 8),
            _buildOneUIFloatingButton(
              icon: _isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
              onPressed: _toggleAudio,
              isActive: !_isMuted,
            ),
            const SizedBox(height: 8),
            _buildOneUIFloatingButton(
              icon: _isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
              onPressed: _toggleVideo,
              isActive: _isLocalVideoEnabled,
            ),
            const SizedBox(height: 8),
            _buildOneUIFloatingButton(
              icon: CupertinoIcons.camera_rotate,
              onPressed: _switchCamera,
            ),
            const SizedBox(height: 8),
            _buildOneUIFloatingButton(
              icon: Icons.network_check,
              onPressed: () {},
              iconColor: _getNetworkQualityColor(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOneUIFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isToggle = false,
    Color? activeColor,
    Color? iconColor,
  }) {
    final bgColor = isActive ? (activeColor ?? _oneUIAccent) : _oneUIFloatingBg;
    final fgColor =
        iconColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.9));

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: fgColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _oneUISurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
      ),
      color: _oneUISurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: ListTile(
            trailing: const Icon(Icons.info, color: Colors.white),
            title: Text(
              translation(context).lbl_information,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: ListTile(
            trailing: const Icon(Icons.settings, color: Colors.white),
            title: Text(
              translation(context).lbl_setting,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: ListTile(
            trailing: const Icon(Icons.copy, color: Colors.white),
            title: Text(
              "${translation(context).lbl_meeting_id} : $channelName",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: ListTile(
            trailing: const Icon(Icons.link, color: Colors.white),
            title: Text(
              "${translation(context).lbl_send_invitation_link} : ${AppData.base2}/$channelName",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
      onSelected: (value) async {
        // Use addPostFrameCallback to ensure navigation happens after popup is closed
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          switch (value) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MeetingInfoScreen()),
              );
              break;
            case 2:
              final update = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsHostControlsScreen(
                    widget.meetingDetailsModel?.data?.settings,
                    widget.meetingDetailsModel?.data?.meeting?.id ?? "",
                  ),
                ),
              );
              if (update == true) {
                _refreshMeetingDetails();
              }
              break;
            case 3:
              Clipboard.setData(ClipboardData(text: channelName));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(translation(context).msg_meeting_code_copied),
                ),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchUserScreen(channel: channelName),
                ),
              );
              break;
          }
        });
      },
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: _oneUISurface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _confirmEndCall(),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.back, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Color _getNetworkQualityColor() {
    switch (_networkQuality) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
      case 6:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNetworkQualityText() {
    switch (_networkQuality) {
      case 1:
        return translation(context).lbl_network_quality_excellent;
      case 2:
        return translation(context).lbl_network_quality_good;
      case 3:
        return translation(context).lbl_network_quality_fair;
      case 4:
        return translation(context).lbl_network_quality_poor;
      case 5:
        return translation(context).lbl_network_quality_very_poor;
      case 6:
        return translation(context).lbl_network_quality_unknown;
      default:
        return translation(context).lbl_network_quality_unknown;
    }
  }

  Color getColorByIndex(int index) {
    List<Color> colors = [
      Colors.blueGrey.shade800,
      Colors.indigo.shade700,
      Colors.teal.shade700,
      Colors.purple.shade700,
      Colors.deepOrange.shade700,
      Colors.brown.shade700,
      Colors.cyan.shade700,
      Colors.pink.shade700,
      Colors.green.shade700,
      Colors.amber.shade800,
    ];
    return colors[index % colors.length];
  }

  Widget _buildLocalPreview() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) =>
            setState(() => _localVideoPosition += details.delta),
        onDoubleTap: () => setState(
          () => _localVideoScale = _localVideoScale == 1.0 ? 1.5 : 1.0,
        ),
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: _isLocalUserSpeaking
                  ? Colors.green.withOpacity(0.8)
                  : Colors.white.withOpacity(0.6),
              width: _isLocalUserSpeaking ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _isLocalUserSpeaking
                    ? Colors.green.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                blurRadius: _isLocalUserSpeaking ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Video content - Screen share, video, or avatar
                Positioned.fill(
                  child: _isScreenSharing
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            useAndroidSurfaceView: true,
                            useFlutterTexture: true,
                            rtcEngine: _agoraEngine,
                            canvas: const VideoCanvas(
                              uid: 0,
                              sourceType: VideoSourceType.videoSourceScreen,
                            ),
                          ),
                        )
                      : !_isLocalVideoEnabled
                      ? Container(
                          color: Colors.blueGrey.shade800,
                          child: Center(
                            child: AppData.profile_pic.isNotEmpty
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey.shade700,
                                    backgroundImage: NetworkImage(
                                      '${AppData.imageUrl}${AppData.profile_pic}',
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                  )
                                : CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.blueGrey.shade600,
                                    child: Text(
                                      AppData.name.isNotEmpty
                                          ? AppData.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _agoraEngine,
                            canvas: const VideoCanvas(uid: 0),
                            useAndroidSurfaceView: true,
                            useFlutterTexture: true,
                          ),
                        ),
                ),

                // Name label with gradient background
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "You",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Camera status indicator
                            Icon(
                              _isLocalVideoEnabled
                                  ? CupertinoIcons.video_camera
                                  : CupertinoIcons.video_camera_solid,
                              color: _isLocalVideoEnabled
                                  ? Colors.white
                                  : Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            // Mic status indicator
                            Icon(
                              _isMuted
                                  ? CupertinoIcons.mic_slash
                                  : CupertinoIcons.mic,
                              color: _isMuted ? Colors.red : Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Screen sharing indicator
                if (_isScreenSharing)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.screen_share,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    // Only use PiP control bar when actually in PiP mode
    // Don't use LayoutBuilder here as bottomNavigationBar constraints can be unreliable
    if (_isPiPEnabled) {
      return _buildPipControlBar();
    } else {
      return _buildNormalControlBar();
    }
  }

  /// One UI 8.5 style bottom control bar
  Widget _buildNormalControlBar() {
    // Get the bottom safe area padding for proper spacing
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: 100.w,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
      ),
      decoration: BoxDecoration(
        color: _oneUINavBar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Chat button
          _buildOneUIControlButton(
            icon: icChat,
            label: translation(context).lbl_chat,
            onPressed: () {
              showMeetingChatBottomSheet(
                context: context,
                channelId: widget.meetingDetailsModel?.data?.meeting?.id ?? "",
              );
            },
            useSvg: true,
          ),
          // Screen share button
          _buildOneUIControlButton(
            icon: _isScreenSharing
                ? Icons.stop_screen_share
                : Icons.screen_share,
            label: translation(context).lbl_share,
            isActive: _isScreenSharing,
            onPressed: _toggleScreenSharing,
          ),
          // End meeting button
          _buildOneUIControlButton(
            icon: Icons.call_end,
            label: translation(context).lbl_end_meeting,
            isEndCall: true,
            onPressed: _confirmEndCall,
          ),
        ],
      ),
    );
  }

  /// One UI 8.5 style control button
  Widget _buildOneUIControlButton({
    required dynamic icon,
    required String label,
    required VoidCallback onPressed,
    bool useSvg = false,
    bool isEndCall = false,
    bool isActive = false,
  }) {
    final bgColor = isEndCall
        ? const Color(0xFFFF3B30)
        : isActive
        ? _oneUIAccent
        : _oneUIFloatingBg;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isEndCall ? 28 : 22,
                vertical: 14,
              ),
              child: useSvg
                  ? SvgPicture.asset(
                      icon as String,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    )
                  : Icon(icon as IconData, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// NEW ultra-compact design for PiP/floating widget mode - icons only, no labels
  Widget _buildPipControlBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate sizes based on available width
        final availableWidth = constraints.maxWidth;
        // Use very small button size that scales with PiP window
        final buttonSize = (availableWidth / 6).clamp(20.0, 36.0);
        final iconSize = (buttonSize * 0.5).clamp(10.0, 18.0);
        final padding = (availableWidth / 30).clamp(2.0, 6.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: padding / 2,
          ),
          decoration: const BoxDecoration(color: Color(0xFF263238)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Chat button - icon only
              _buildPipIconButton(
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF3D4D55),
                onPressed: () {
                  showMeetingChatBottomSheet(
                    context: context,
                    channelId:
                        widget.meetingDetailsModel?.data?.meeting?.id ?? "",
                  );
                },
                buttonSize: buttonSize,
                iconSize: iconSize,
              ),
              // Screen share button - icon only
              _buildPipIconButton(
                icon: _isScreenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                color: _isScreenSharing ? Colors.blue : const Color(0xFF3D4D55),
                onPressed: _toggleScreenSharing,
                buttonSize: buttonSize,
                iconSize: iconSize,
              ),
              // End meeting button - icon only
              _buildPipIconButton(
                icon: Icons.call_end,
                color: Colors.red,
                onPressed: _confirmEndCall,
                buttonSize: buttonSize,
                iconSize: iconSize,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ultra-compact icon-only button for PiP mode
  Widget _buildPipIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double buttonSize,
    required double iconSize,
  }) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        minWidth: buttonSize,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonSize / 3),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  // --------------------
  // Audio & Video Toggle Functions
  // --------------------

  /// Toggle hand raise status and notify other users via API
  Future<void> _toggleHandRaise() async {
    try {
      final newHandState = !_isHandRaised;
      setState(() => _isHandRaised = newHandState);

      // Call API with action="hand" to notify other users
      await changeMeetingStatus(
        context,
        widget.meetingDetailsModel?.data?.meeting?.id,
        AppData.logInUserId,
        'hand', // action for hand raise
        newHandState,
      ).then((resp) {
        debugPrint("Change hand status response: ${resp}");

        if (newHandState) {
          _showSystemMessage('Hand raised');
        } else {
          _showSystemMessage('Hand lowered');
        }
      });
    } catch (e) {
      debugPrint('Error toggling hand raise: $e');
      // Revert the state if there was an error
      if (mounted) {
        setState(() => _isHandRaised = !_isHandRaised);
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (widget.meetingDetailsModel?.data?.settings?.toggleMicrophone == 1 ||
        widget.isHost == true) {
      setState(() => _isMuted = !_isMuted);
      await _agoraEngine.muteLocalAudioStream(_isMuted);

      // Update meeting status
      await changeMeetingStatus(
        context,
        widget.meetingDetailsModel?.data?.meeting?.id,
        AppData.logInUserId,
        'mic',
        !_isMuted, // true = mic on, false = mic off
      ).then((resp) {
        debugPrint("Change mic status response: ${resp}");

        // Update local model to stay in sync
        final currentUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
          (user) => user.id == AppData.logInUserId,
          orElse: () => Users(),
        );
        if (currentUser?.meetingDetails?.isNotEmpty ?? false) {
          currentUser!.meetingDetails!.single.isMicOn = _isMuted ? 0 : 1;
        }
      });
    } else {
      _showSystemMessage("You don't have permission to enable audio");
    }
  }

  Future<void> _toggleVideo() async {
    if (widget.meetingDetailsModel?.data?.settings?.toggleVideo == 1 ||
        widget.isHost == true) {
      // Safety check - make sure we're joined before manipulating video
      if (!_isJoined) {
        debugPrint('Cannot toggle video - not joined to channel yet');
        return;
      }

      // Don't toggle camera while screen sharing - need to stop screen share first
      if (_isScreenSharing) {
        _showSystemMessage('Stop screen sharing first to enable camera');
        return;
      }

      try {
        final newVideoState = !_isLocalVideoEnabled;
        setState(() => _isLocalVideoEnabled = newVideoState);

        // CRITICAL: Update channel media options to publish/unpublish camera track
        // This is what makes the video visible to remote users!
        await _agoraEngine.updateChannelMediaOptions(
          ChannelMediaOptions(
            publishCameraTrack: newVideoState,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );

        // Enable/disable local video
        await _agoraEngine.enableLocalVideo(newVideoState);
        await _agoraEngine.muteLocalVideoStream(!newVideoState);

        // Start or stop preview based on video state
        if (newVideoState) {
          await _agoraEngine.startPreview();
          debugPrint('📹 Camera enabled - track published to remote users');
        } else {
          await _agoraEngine.stopPreview();
          debugPrint(
            '📹 Camera disabled - track unpublished from remote users',
          );
        }

        // Update meeting status to sync with remote users via API
        await changeMeetingStatus(
          context,
          widget.meetingDetailsModel?.data?.meeting?.id,
          AppData.logInUserId,
          'cam',
          newVideoState,
        ).then((resp) {
          debugPrint("Change cam status response: ${resp}");

          // Update local model to stay in sync
          final currentUser = widget.meetingDetailsModel?.data?.users
              ?.firstWhere(
                (user) => user.id == AppData.logInUserId,
                orElse: () => Users(),
              );
          if (currentUser?.meetingDetails?.isNotEmpty ?? false) {
            currentUser!.meetingDetails!.single.isVideoOn = newVideoState
                ? 1
                : 0;
          }
        });
      } catch (e) {
        debugPrint('Error toggling video: $e');
        // Revert the state if there was an error
        if (mounted) {
          setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
        }
      }
    } else {
      _showSystemMessage("You don't have permission to enable video");
    }
  }

  Future<void> _switchCamera() async {
    await _agoraEngine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  // End call confirmation dialog
  void _confirmEndCall() {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.call_end_rounded, color: theme.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              translation(context).lbl_meeting,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          translation(context).msg_confirm_end_call,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: theme.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.border),
                    ),
                  ),
                  child: Text(
                    translation(context).lbl_cancel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Close dialog first
                    await _endMeetingProperly();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    translation(context).lbl_end_meeting,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel PiP delay timer
    _pipDelayTimer?.cancel();
    _pipDelayTimer = null;

    // Cancel PiP status subscription safely
    try {
      _pipStatusSubscription?.cancel();
      _pipStatusSubscription = null;
    } catch (e) {
      debugPrint('VideoCallScreen: Error cancelling PiP subscription: $e');
    }

    // Notify PiP service that meeting has ended
    try {
      _pipService.disablePiP();
    } catch (e) {
      debugPrint('VideoCallScreen: Error disabling PiP: $e');
    }

    // Clear screen share config for iOS
    if (Platform.isIOS) {
      _screenShareService.clearChannelConfig();
    }

    // Clean up all timers
    _callTimer?.cancel();
    _callDurationNotifier.dispose();
    _meetingRefreshDebouncer?.cancel();
    _localUserSpeakingTimer?.cancel();
    _speakingTimers.forEach((_, timer) => timer.cancel());
    _speakingTimers.clear();

    // Animation controller
    _speakingAnimationController.dispose();

    // Agora cleanup
    _agoraEngine.leaveChannel();
    _agoraEngine.release();

    // Disable wakelock when leaving the call
    _disableWakelock();

    super.dispose();
  }
}

// --------------------
// Remote Video Data Model
// --------------------
class RemoteVideoData {
  final int uid;
  final Users? joinUser;
  final Offset position;
  final bool isScreenShare;
  final bool isSpeaking;
  final double scale;

  RemoteVideoData({
    required this.uid,
    required this.position,
    this.joinUser,
    required this.isScreenShare,
    required this.isSpeaking,
    this.scale = 1.0,
  });

  RemoteVideoData copyWith({
    Offset? position,
    bool? isScreenShare,
    bool? isSpeaking,
    double? scale,
  }) {
    return RemoteVideoData(
      uid: uid,
      position: position ?? this.position,
      joinUser: joinUser ?? Users(),
      isScreenShare: isScreenShare ?? this.isScreenShare,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      scale: scale ?? this.scale,
    );
  }
}

// New class to track remote user states separately from meeting details
class RemoteUserState {
  final String userId;
  bool isVideoOn;
  bool isMicOn;
  bool isScreenShared;
  bool isHandUp;
  Users? userData;

  RemoteUserState({
    required this.userId,
    this.isVideoOn = false,
    this.isMicOn = false,
    this.isScreenShared = false,
    this.isHandUp = false,
    this.userData,
  });
}
