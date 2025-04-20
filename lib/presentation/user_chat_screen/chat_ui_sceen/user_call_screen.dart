import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/search_user_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/seeting_host_control_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/widgets/meeting_join_reject_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sizer/sizer.dart';

const defaultChannel = 'doctak';
const appId = "f2cf99f1193a40e69546157883b2159f";
String token = '';

class UserCallScreen extends StatefulWidget {
  MeetingDetailsModel? meetingDetailsModel;
  bool? isHost;
  String? channel;
  UserCallScreen({
    super.key,
    this.meetingDetailsModel,
    this.channel,
    this.isHost,
  });

  @override
  State<UserCallScreen> createState() => _UserCallScreenState();
}

class _UserCallScreenState extends State<UserCallScreen> {
  late RtcEngine _agoraEngine;
  final List<RemoteVideoData> _remoteVideos = [];
  final ValueNotifier<int> _participantCount = ValueNotifier(0);
  final List<Offset> _defaultPositions = [];

  bool _isJoined = false;
  bool _isMuted = false;
  bool _isScreenSharing = false;
  bool _isFrontCamera = true;
  bool _showControls = true;
  bool _isLocalVideoEnabled = true;
  double _localVideoScale = 1.0;
  Offset _localVideoPosition = const Offset(20, 20);
  int _callDuration = 0;
  Timer? _callTimer;
  int? _networkQuality;
  String channelName = '';
  bool _isLogin = false;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  @override
  void initState() {
    super.initState();

    if (widget.isHost ?? true) {
      channelName =
          widget.meetingDetailsModel?.data?.meeting?.meetingChannel ?? 'doctak';
      // token=widget.meetingDetailsModel?.data?.meeting?.meetingToken??'';
    } else {
      channelName =
          widget.meetingDetailsModel?.data?.meeting?.meetingChannel ?? 'doctak';

      // channelName = widget.channel ?? '';
    }
    ConnectPusher();
    // _initializePusher();
    _initializeAgora();
    _generateDefaultPositions();
    _startCallTimer();
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

  final PusherService _pusherService = PusherService();
  final String _meetingChannelName = 'meeting-channel';

  void _initializePusher() async {
    // Initialize if not already initialized
    if (!_pusherService.isConnected) {
      await _pusherService.initialize();
      await _pusherService.connect();
    }

    final channelName =
        '$_meetingChannelName${widget.meetingDetailsModel?.data?.meeting?.id}';

    // Subscribe to channel
    _pusherService.subscribeToChannel(channelName);

    // Register event listeners
    _pusherService.registerEventListener('new-user-join', (data) {
      Map<String, dynamic> jsonMap = jsonDecode(data.toString());
      print("join response ${jsonMap}");

    });
    _pusherService.registerEventListener('allow-join-request', (data) {});
    _pusherService.registerEventListener('messaging', (data) {});
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
          // onEvent: onEvent,
          onDecryptionFailure: onDecryptionFailure,
          onError: onError,
          onSubscriptionCount: onSubscriptionCount,
          onAuthorizer: null);

      pusher.connect();

      if (pusher != null) {
        // Successfully created and connected to Pusher
        clientListenChannel = await pusher.subscribe(
          channelName:
          "meeting-channel${widget.meetingDetailsModel?.data?.meeting?.id}",
          onMemberAdded: (member) {
            // print("Member added: $member");
          },
          onMemberRemoved: (member) {
            print("Member removed: $member");
          },
          onEvent: (event) {
            String eventName = event.eventName;
            Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
            print('eventdata ${jsonMap}');
            print('eventdata1 $eventName');

            switch (eventName) {
              case 'new-user-join':
                if (widget.isHost ?? false) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MeetingJoinRejectDialog(
                          joinName:
                          '${jsonMap['first_name']} ${jsonMap['last_name']}',
                          title: ' want to join the meeting ?',
                          yesButtonText: 'Accept',
                          profilePic:
                          '${AppData.imageUrl}${jsonMap['profile_pic']}',
                          callback: () async {
                            await allowJoinMeet(
                                context,
                                widget
                                    .meetingDetailsModel?.data?.meeting?.id,
                                jsonMap['id'])
                                .then((resp) async {
                              print("join response ${resp.data}");
                              widget.meetingDetailsModel = await joinMeetings(
                                  widget.meetingDetailsModel?.data?.meeting
                                      ?.meetingChannel ??
                                      '');
                              setState(() {});
                            });
                            Navigator.of(context).pop();
                          },
                          noButtonText: 'Reject',
                          callbackNegative: () async {
                            await rejectJoinMeet(
                                context,
                                jsonMap['id'],
                                widget
                                    .meetingDetailsModel?.data?.meeting?.id)
                                .then((resp) {
                              print("join response ${resp.data}");
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      });
                }
                break;
              case 'allow-join-request':
                print("eventName $eventName");
                toast(eventName);
                break;
              default:
              // Handle unknown event types or ignore them
                break;
            }
          },
        );

        // Attach an event listener to the channel
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    } catch (e) {
      print('eee $e');
    }
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}
  Future<void> _permissionDialog(context) async {
    return showDialog(
      context: context, barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text(
            'You want to enable permission?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
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

  // Future<dynamic> onAuthorizer(
  //     String channelName, String socketId, dynamic options) async {
  //   final Uri uri = Uri.parse("${AppData.chatifyUrl}chat/auth");
  //
  //   // Build query parameters
  //   final Map<String, String> queryParams = {
  //     'socket_id': socketId,
  //     'channel_name': channelName,
  //   };
  //
  //   final response = await http.post(
  //     uri.replace(queryParameters: queryParams),
  //     headers: {
  //       'Authorization': 'Bearer ${AppData.userToken!}',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final String data = response.body;
  //
  //     return jsonDecode(data);
  //   } else {
  //     throw Exception('Failed to fetch Pusher auth data');
  //   }
  // }
  Future<void> _renewToken() async {
    // Implement token renewal logic here
    var newToken = token; // Replace with actual token renewal
    await _agoraEngine.renewToken(newToken);
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
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

  Future<void> _initializeAgora() async {
    try {
      await [Permission.microphone, Permission.camera].request();

      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _setupEventHandlers();
      await _configureVideoSettings();
      await _joinChannel();
    } catch (e) {
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  Future<String?> _getUserAccount(int uid) async {
    final userInfo = await _agoraEngine.getUserInfoByUid(uid);
    return userInfo.userAccount ?? "";
  }

  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onVideoPublishStateChanged: (VideoSourceTypevideoSourceType,
            v1,
            StreamPublishState streamPublishState1,
            StreamPublishState streamPublishState2,
            v2) {

        },
        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) async {
          // Handle both camera and screen sharing UIDs
          // final userAccount = await _agoraEngine.getUserInfoByUid(remoteUid).then((info) => info.userAccount);
          //
          // // Find matching user in API data
          // final apiUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
          //       (u) => u.id == userAccount,
          // );
          //
          // if (apiUser != null) {
          //   // Skip local user
          //    setState(() {
          //      _remoteVideos.add(RemoteVideoData(
          //        uid: remoteUid,
          //        joinUser: apiUser,
          //        isScreenShare: false,
          //        position: _getNextPosition(),
          //        scale: 1.0,
          //      ));
          //    });
          try {
            // Add slight delay for Agora to sync user info
            widget.meetingDetailsModel = await joinMeetings(channelName);
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 200));
            final userInfo = await _agoraEngine.getUserInfoByUid(remoteUid);
            final userAccount = userInfo.userAccount;

            if (userAccount?.isEmpty ?? true) {
              print('Failed to get userAccount for UID: $remoteUid');
              return;
            }

            final apiUser = widget.meetingDetailsModel?.data?.users?.firstWhere(
                  (u) => u.id == userAccount,
            );

            if (apiUser != null) {
              String? id = await _getUserAccount(remoteUid);
              setState(() {
                _remoteVideos.add(RemoteVideoData(
                  uid: remoteUid,
                  joinUser: apiUser,
                  isScreenShare: false,
                  position: _getNextPosition(),
                  scale: 1.0,
                ));
              });
            }
          } catch (e) {
            print('Error in onUserJoined: $e');
          }
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          _renewToken();
        },
        onUserEnableVideo:
            (RtcConnection s, int remoteUid, bool isVideoMuted) async {
          String? id = await _getUserAccount(remoteUid);
          widget.meetingDetailsModel?.data?.users
              ?.singleWhere((user) => user.id == id)
              .meetingDetails
              ?.single
              .isVideoOn = isVideoMuted ? 1 : 0;
          setState(() {});

        },
        onUserMuteAudio: (RtcConnection s, int remoteUid, bool isMuted) async {

          String? id = await _getUserAccount(remoteUid);
          widget.meetingDetailsModel?.data?.users
              ?.singleWhere((user) => user.id == id)
              .meetingDetails
              ?.single
              .isMicOn = isMuted ? 0 : 1;
          setState(() {});
        },
        onUserMuteVideo:
            (RtcConnection s, int remoteUid, bool isVideoMuted) async {
          String? id = await _getUserAccount(remoteUid);
          widget.meetingDetailsModel?.data?.users
              ?.singleWhere((user) => user.id == id)
              .meetingDetails
              ?.single
              .isVideoOn = isVideoMuted ? 1 : 0;

          setState(() {});
        },
        onRemoteVideoStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed) async {
          if (state == RemoteVideoState.remoteVideoStateStarting) {
            print('state ${state.name}');

            if (!_remoteVideos.any((v) => v.uid == remoteUid)) {
              print('state ${state.name}');
              widget.meetingDetailsModel = await joinMeetings(channelName);

              setState(() {
                _remoteVideos.add(RemoteVideoData(
                  uid: remoteUid,

                  isScreenShare: false,
                  position: _getNextPosition(),
                  scale: 1.0,
                ));
              });
            }
          }
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
          _updateParticipantCount();
        },
        onUserInfoUpdated: (value, UserInfo userInfo) {},
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) async {
          String? userId=await _getUserAccount(remoteUid);
          Users? usersRemoveData=widget.meetingDetailsModel?.data?.users?.singleWhere((user) => user.id == userId);

          setState(() => _remoteVideos.removeWhere((v) => v.uid == remoteUid));

          _showSystemMessage('${usersRemoveData?.firstName??""} ${usersRemoveData?.lastName??""} left Meeting');

          _updateParticipantCount();
        },
        onError: (ErrorCodeType err, String msg) {
          print(msg);
          _showErrorDialog('Agora Error', err.name);
        },
        onRtcStats: (RtcConnection connection, RtcStats stats) => {},
        onNetworkQuality: (RtcConnection connection, int rxQuality,
            QualityType qualityType, QualityType qualityType2) {
          setState(() => _networkQuality = rxQuality);
        },
      ),
    );
  }

  Future<void> _configureVideoSettings() async {
    await _agoraEngine.enableVideo();
    await _agoraEngine
        .setVideoEncoderConfiguration(const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 640, height: 480),
      frameRate: 15,
      bitrate: 2000,
    ));
// Highlight: Keep preview running initially
    await _agoraEngine.startPreview();
    await _agoraEngine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);
    await _agoraEngine.enableVideo();
  }

  Future<void> _joinChannel() async {
    print('token $token');
    print('channelName $channelName');
    try {
      await _agoraEngine.joinChannelWithUserAccount(
        token: token,
        channelId: channelName,
        userAccount: AppData.logInUserId,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishScreenTrack: true,
          publishScreenCaptureVideo: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      print(e);
      _showErrorDialog('Connection Error', e.toString());
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

  void _updateParticipantCount() {}

  Future<void> _toggleScreenSharing() async {
    try {

      if (widget.meetingDetailsModel?.data?.settings?.shareScreen == '1' || widget.isHost==true) {

        if (_isScreenSharing) {
// Stop screen sharing
          await _agoraEngine.stopScreenCapture();
// await _agoraEngine.leaveChannel();
// await _joinChannel();
// Restart camera stream
          await _agoraEngine.updateChannelMediaOptions(
              const ChannelMediaOptions(
                publishScreenTrack: false,
                publishSecondaryScreenTrack: false,
                publishCameraTrack: true,
                publishMicrophoneTrack: false,
                publishScreenCaptureAudio: false,
                publishScreenCaptureVideo: false,
                autoSubscribeAudio: false,
                publishMediaPlayerAudioTrack: false,
                clientRoleType: ClientRoleType.clientRoleBroadcaster,
              ));
          await changeMeetingStatus(
              context,
              widget.meetingDetailsModel?.data?.meeting?.id,
              AppData.logInUserId,
              'cam',
              true)
              .then((resp) {
            print("join response ${resp.data}");
          });
          await _agoraEngine.startPreview();
        } else {
// Stop camera stream
          await _agoraEngine.stopPreview();
// Start screen sharing
          await _agoraEngine.startScreenCapture(const ScreenCaptureParameters2(
            captureVideo: true,
            captureAudio: true,
            videoParams: ScreenVideoParameters(
              dimensions: VideoDimensions(width: 1280, height: 720),
              frameRate: 15,
              contentHint: VideoContentHint.contentHintMotion,
              bitrate: 2000,
            ),
          ));
// Update channel to publish screen track
// await _agoraEngine.updateChannelMediaOptions(const ChannelMediaOptions(
//   publishCameraTrack: false,
//   publishScreenTrack: true,
//   clientRoleType: ClientRoleType.clientRoleBroadcaster,
// ));
          await _agoraEngine.updateChannelMediaOptions(
            const ChannelMediaOptions(
              publishScreenTrack: true,
              publishSecondaryScreenTrack: true,
              publishCameraTrack: false,
              publishMicrophoneTrack: true,
              publishScreenCaptureAudio: true,
              publishScreenCaptureVideo: true,
              autoSubscribeAudio: true,
              publishMediaPlayerAudioTrack: true,
              clientRoleType: ClientRoleType
                  .clientRoleBroadcaster, // or ClientRoleType.clientRoleAudience
            ),
          );
          await changeMeetingStatus(
              context,
              widget.meetingDetailsModel?.data?.meeting?.id,
              AppData.logInUserId,
              'screen',
              true)
              .then((resp) {
            print("join response ${resp.data}");
          });
        }
        setState(() => _isScreenSharing = !_isScreenSharing);
      }else{
        _showSystemMessage('Screen share permission not allowed from host');

      }
    } catch (e) {
      _showErrorDialog('Screen Share Error', e.toString());
    }

  }


  String _formatDuration(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _showSystemMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.loose,
        children: [
          Positioned.fill(
            top: 30,
            child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 20,
                  maxCrossAxisExtent:
                  (MediaQuery.of(context).size.width - 20) / 2,
                  childAspectRatio: _calculateAspectRatio(context),
                ),
                itemCount: _remoteVideos.length ?? 0,
                itemBuilder: (context, index) {
                  return _buildVideoWindow(
                      _remoteVideos[index], getColorByIndex(index));
                }),
          ),
          if (_isJoined) _buildLocalPreview(),
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              spacing: 10,
              children: [
                FloatingActionButton(
                  heroTag: "more_fab_tag_${UniqueKey()}", // Ensure a unique tag

                  elevation: 0,
                  backgroundColor: Colors.blueGrey.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  onPressed: () {
                    setState(() {
                      _showFloatingOptions = !_showFloatingOptions;
                    });
                  },
                  child: Icon(_showFloatingOptions
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_up),
                ),
                if (_showFloatingOptions) ...[
                  FloatingActionButton(
                    heroTag: "hand_fab_tag_${UniqueKey()}", // Ensure a unique tag

                    elevation: 0,

                    backgroundColor: const Color(0xFF3D4D55).withOpacity(0.4),
// Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Radius
                    ),
                    onPressed: () {},
                    child: Icon(_isMuted
                        ? CupertinoIcons.hand_raised
                        : CupertinoIcons.hand_raised),
                  ),
                  FloatingActionButton(
                    heroTag: "audio_fab_tag_${UniqueKey()}", // Ensure a unique tag

                    elevation: 0,

                    backgroundColor: const Color(0xFF3D4D55).withOpacity(0.4),
// Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Radius
                    ),
                    onPressed: _toggleAudio,
                    child: Icon(
                        _isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic),
                  ),
                  FloatingActionButton(
                    heroTag: "camera_fab_tag_${UniqueKey()}", // Ensure a unique tag

                    elevation: 0,

                    backgroundColor: const Color(0xFF3D4D55).withOpacity(0.4),
// Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Radius
                    ),

                    onPressed: _toggleVideo,
                    child: Icon(_isLocalVideoEnabled
                        ? Icons.videocam
                        : Icons.videocam_off),
                  ),
                  FloatingActionButton(
                    heroTag: "camera_fab_tag_${UniqueKey()}", // Ensure a unique tag
                    elevation: 0,
                    backgroundColor: const Color(0xFF3D4D55).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Radius
                    ),
                    onPressed: _switchCamera,
                    child: Icon(_isFrontCamera
                        ? CupertinoIcons.camera_rotate
                        : CupertinoIcons.camera_rotate_fill),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: PopupMenuButton<int>(
              offset: const Offset(0, 50),
              icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.more_vert, color: Colors.white)),
              color: const Color(0xFF263238),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: (){
                    // MeetingInfoScreen().launch(context,pageRouteAnimation:PageRouteAnimation.Slide);
                  },
                  value: 1,
                  child: const ListTile(
                    trailing: Icon(Icons.info, color: Colors.white),
                    title: Text("Information",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    var  update=await SettingsHostControlsScreen(widget.meetingDetailsModel?.data?.settings,widget.meetingDetailsModel?.data?.meeting?.id??"").launch(context,pageRouteAnimation:PageRouteAnimation.Slide);
                    if(update){
                      widget.meetingDetailsModel = await joinMeetings(channelName);
                      setState(() {});

                    }
                  },
                  value: 2,
                  child: const ListTile(
                    trailing: Icon(Icons.settings, color: Colors.white),
                    title:
                    Text("Setting", style: TextStyle(color: Colors.white)),
                  ),
                ),
                PopupMenuItem(
                  value: 3,
                  child: ListTile(
                    trailing: IconButton(
                        onPressed: (){
                          Clipboard.setData(
                              ClipboardData(text: channelName));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Meeting code copied to clipboard")),
                          );
                        },
                        icon: const Icon(Icons.copy, color: Colors.white)),
                    title: Text("Meeting ID : $channelName",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                PopupMenuItem(
                  onTap: (){
                    SearchUserScreen(channel: channelName,).launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                  value: 4,
                  child: ListTile(
                    trailing: const Icon(Icons.link, color: Colors.white),
                    title: Text(
                        "Send Invitation link : https://doctak.net/$channelName",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              onSelected: (value) {
// Handle selection
              },
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(50)),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                ),
              ).onTap(() {
                Navigator.pop(context);
              }),
            ),
          ),
          if (_networkQuality != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.network_check,
                      color: _getNetworkQualityColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getNetworkQualityText(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildControlBar(),
    );
  }

  bool _showFloatingOptions = true;
  double _calculateAspectRatio(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return screenWidth /
        (screenHeight * 0.6); // Adjust the factor (0.55) as needed
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
        return 'Excellent';
      case 2:
        return 'Good';
      case 3:
        return 'Poor';
      case 4:
        return 'Bad';
      case 5:
        return 'Very Bad';
      case 6:
        return 'Disconnected';
      default:
        return 'Unknown';
    }
  }

  Color getColorByIndex(int index) {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return colors[index % colors.length]; // Ensures the index wraps around
  }

  Widget _buildVideoWindow(RemoteVideoData videoData, color) {
    return GestureDetector(
      child: Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color:
            videoData.joinUser?.meetingDetails?.single.isScreenShared == 1
                ? Colors.green
                : Colors.grey,
            width: 4,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              videoData.joinUser?.meetingDetails?.single.isVideoOn != 1 ||
                  videoData.joinUser?.meetingDetails?.single
                      .isScreenShared ==
                      1
                  ? AgoraVideoView(
                controller: VideoViewController.remote(
                    rtcEngine: _agoraEngine,
                    canvas: VideoCanvas(
                      uid: videoData.uid,
                      sourceType: VideoSourceType.videoSourceRemote,
                    ),
                    connection: RtcConnection(channelId: channelName),
                    useFlutterTexture: true,
                    useAndroidSurfaceView: true),
              )
                  : Container(
                color: color,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 100,
                      backgroundImage: NetworkImage(
                          '${AppData.imageUrl}${videoData.joinUser?.profilePic}'),
                    ),
                  ],
                ),
              ),
              Positioned(
                  bottom: 8,
                  child: Row(
                    children: [
                      Icon(
                        videoData.joinUser?.meetingDetails?.single.isMicOn == 1
                            ? CupertinoIcons.mic
                            : CupertinoIcons.mic_off,
                        color: Colors.white,
                      ),
                      Text(
                        '${videoData.joinUser?.firstName ?? ""} ${videoData.joinUser?.lastName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white),
                      )
                    ],
                  ))
            ],
          ),
        ),
      ),
// ),
    );
  }

  Widget _buildLocalPreview() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) =>
            setState(() => _localVideoPosition += details.delta),
        onDoubleTap: () => setState(
                () => _localVideoScale = _localVideoScale == 1.0 ? 1.5 : 1.0),
        child: Transform.scale(
          scale: _localVideoScale,
          child: Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _isScreenSharing
                  ? AgoraVideoView(
                controller: VideoViewController(
                  useAndroidSurfaceView: true,
                  useFlutterTexture: true,
                  rtcEngine: _agoraEngine,
                  canvas: const VideoCanvas(
                      uid: 0,
                      sourceType: VideoSourceType.videoSourceScreen),
                ),
              )
                  : !_isLocalVideoEnabled
                  ? Column(
                children: [
                  Expanded(
                    child: CircleAvatar(
                      radius: 100,
                      backgroundImage: NetworkImage(
                          '${AppData.imageUrl}${AppData.profile_pic}'),
                    ),
                  ),
                ],
              )
                  : AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _agoraEngine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      width: 100.w,
      height: 90,
// margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF263238),
// borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: 4,
        children: [
          Column(
            children: [
              MaterialButton(
                color: const Color(0xFF3D4D55), // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Radius
                ),
                onPressed: () {

                },
                child: SvgPicture.asset(
                  icChat,
                  color: Colors.white,
                ),
              ),
              const Text(
                'chat',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
// MaterialButton(
//   minWidth: 50,
//   color: Color(0xFF3D4D55), // Background color
//   shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(20), // Radius
//   ),
//
//   onPressed: _toggleVideo,
//   child: Icon(_isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off),
// ),
          Column(
            children: [
              MaterialButton(
                color: const Color(0xFF3D4D55),
// Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Radius
                ),

                onPressed: _toggleScreenSharing,
                child: Icon(
                  _isScreenSharing
                      ? Icons.stop_screen_share
                      : Icons.screen_share,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Share',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),

          Column(
            children: [
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Radius
                ),
                color: Colors.red,
                onPressed: _confirmEndCall,
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                ),
              ),
              const Text(
                'End Meeting',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAudio() async {
    if (widget.meetingDetailsModel?.data?.settings?.toggleMicrophone == 1 || widget.isHost==true) {
      setState(() => _isMuted = !_isMuted);
      await changeMeetingStatus(
          context,
          widget.meetingDetailsModel?.data?.meeting?.id,
          AppData.logInUserId,
          'mic',
          _isMuted)
          .then((resp) {
        print("join response ${resp.data}");
      });
      _agoraEngine.muteLocalAudioStream(_isMuted);
    }else{
      _showSystemMessage("You don't have permission to enable audio");
    }
  }

  Future<void> _toggleVideo() async {
    if (widget.meetingDetailsModel?.data?.settings?.toggleVideo == 1 || widget.isHost==true) {
      setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
      _agoraEngine.muteLocalVideoStream(!_isLocalVideoEnabled);
      _agoraEngine.enableLocalVideo(_isLocalVideoEnabled);
      await changeMeetingStatus(
          context,
          widget.meetingDetailsModel?.data?.meeting?.id,
          AppData.logInUserId,
          'cam',
          _isLocalVideoEnabled)
          .then((resp) {
        print("join response ${resp.data}");
      });
    }else{
      _showSystemMessage("You don't have permission to enable video");
    }
  }

  Future<void> _switchCamera() async {
    await _agoraEngine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  void _confirmEndCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end the call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.isHost ?? false) {
                await endMeeting(
                    context, widget.meetingDetailsModel?.data?.meeting?.id)
                    .then((resp) {
                  print("join response ${resp.data}");
                });
              }
              AppData.chatMessages.clear();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    super.dispose();
  }
}

class RemoteVideoData {
  final int uid;
  final Users? joinUser;
  final Offset position;
  final bool isScreenShare;
  final double scale;

  RemoteVideoData({
    required this.uid,
    required this.position,
    this.joinUser,
    required this.isScreenShare,
    this.scale = 1.0,
  });

  RemoteVideoData copyWith({
    Offset? position,
    bool? isScreenShare,
    double? scale,
  }) {
    return RemoteVideoData(
      uid: uid,
      position: position ?? this.position,
      joinUser: joinUser ?? Users(),
      isScreenShare: isScreenShare ?? this.isScreenShare,
      scale: scale ?? this.scale,
    );
  }
}
