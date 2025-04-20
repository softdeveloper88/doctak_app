import 'package:doctak_app/meeting_module/ui/meeting/participant_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/meeting/meeting_bloc.dart';
import '../../bloc/meeting/meeting_event.dart';
import '../../bloc/meeting/meeting_state.dart';
import '../../bloc/participants/participants_bloc.dart';
import '../../bloc/participants/participants_event.dart';
import '../../bloc/participants/participants_state.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/chat/chat_event.dart';
import '../../bloc/chat/chat_state.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_event.dart';
import '../../bloc/settings/settings_state.dart';
import '../../models/message.dart';
import '../../models/participant.dart';
import '../../services/agora_service.dart';
import '../../services/pusher_service.dart';
import '../../utils/constants.dart';

import 'package:flutter/services.dart';

import 'chat_panel.dart';
import 'control_bar.dart';
import 'settings_panel.dart';
import 'video_grid.dart';

class MeetingPage extends StatefulWidget {
  final String meetingId;
  final String userId;
  final String meetingCode;
  final bool isHost;

  const MeetingPage({
    Key? key,
    required this.meetingId,
    required this.userId,
    required this.meetingCode,
    required this.isHost,
  }) : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> with WidgetsBindingObserver {
  late PusherService _pusherService;
  bool _isFullScreen = false;
  bool _isChatVisible = false;
  bool _isParticipantsVisible = true;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;

  // For managing the timer
  DateTime? _meetingStartTime;
  Duration _meetingDuration = Duration.zero;
  DateTime? _meetingExpiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize pusher service
    _pusherService = PusherService(widget.meetingId);
    _initializePusher();

    // Initialize meeting start time and expiry
    _meetingStartTime = DateTime.now();
    _meetingExpiry = _meetingStartTime?.add(const Duration(hours: 1));

    // Start meeting timer
    _startMeetingTimer();

    // Load participants, chat history, and settings
    _loadInitialData();

    // Set chat visibility
    context
        .read<ChatBloc>()
        .isVisible = _isChatVisible;

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePusher() async {
    await _pusherService.initialize();

    // Listen to pusher events
    _pusherService.onNewMessage.listen((data) {
      if (mounted) {
        // Convert data to Message and add to ChatBloc
        context.read<ChatBloc>().add(NewMessageReceivedEvent(
          Message.fromJson(data),
        ));
      }
    });

    _pusherService.onMeetingEnded.listen((data) {
      if (mounted) {
        // Handle meeting ended
        context.read<MeetingBloc>().add(const MeetingEndedEvent());
        _showMeetingEndedDialog(data['ended_by']);
      }
    });

    _pusherService.onSettingsUpdated.listen((data) {
      if (mounted) {
        // Handle settings updated
        // Typically need to reload settings
        context.read<SettingsBloc>().add(
          LoadMeetingSettingsEvent(widget.meetingId),
        );
      }
    });

    _pusherService.onUserAllowed.listen((channel) {
      if (mounted) {
        // This is for joining users to know they're allowed in
        // Redirect or reload participants list
        context.read<ParticipantsBloc>().add(
          LoadParticipantsEvent(widget.meetingId),
        );
      }
    });

    _pusherService.onRecordingStarted.listen((data) {
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
        });
        _startRecordingTimer();
      }
    });

    _pusherService.onRecordingStopped.listen((data) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingStartTime = null;
          _recordingDuration = Duration.zero;
        });
      }
    });

    _pusherService.onMeetingStatus.listen((data) {
      if (mounted) {
        // Update participant status
        context.read<ParticipantsBloc>().add(
          ParticipantStatusChangedEvent(
            data['userId'],
            data['action'],
            data['status'],
          ),
        );
      }
    });
  }

  void _loadInitialData() {
    // Load participants
    context.read<ParticipantsBloc>().add(
      LoadParticipantsEvent(widget.meetingId),
    );

    // Load chat history
    context.read<ChatBloc>().add(
      LoadChatHistory(widget.meetingId),
    );

    // Load meeting settings
    context.read<SettingsBloc>().add(
      LoadMeetingSettingsEvent(widget.meetingId),
    );
  }

  void _startMeetingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          if (_meetingStartTime != null) {
            _meetingDuration = now.difference(_meetingStartTime!);
          }
        });
        _startMeetingTimer(); // Continue the timer
      }
    });
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording && _recordingStartTime != null) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
        _startRecordingTimer(); // Continue the timer
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
      _isParticipantsVisible = !_isChatVisible;
    });

    // Update chat visibility in bloc
    context
        .read<ChatBloc>()
        .isVisible = _isChatVisible;

    // Reset unread counter if opening chat
    if (_isChatVisible) {
      context.read<ChatBloc>().resetUnreadCounter();
    }
  }

  void _toggleParticipants() {
    setState(() {
      _isParticipantsVisible = !_isParticipantsVisible;
      if (_isParticipantsVisible) {
        _isChatVisible = false;
      }
    });

    // Update chat visibility in bloc
    context
        .read<ChatBloc>()
        .isVisible = _isChatVisible;
  }

  void _showMeetingEndedDialog(String endedBy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: kDangerColor),
                const SizedBox(width: 10),
                const Text('Meeting Ended'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This meeting has been ended by $endedBy.'),
                const SizedBox(height: 10),
                const Text('You have been disconnected from the meeting.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Leave Meeting?'),
            content: const Text('Are you sure you want to leave this meeting?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<MeetingBloc>().add(
                      LeaveMeetingEvent(widget.meetingId));
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(foregroundColor: kDangerColor),
                child: const Text('Leave'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    ) ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused) {
      // App moved to background - might want to mute audio/video
      final agoraService = context.read<AgoraService>();
      if (agoraService.isMicOn) {
        // Maybe mute audio temporarily
      }
      if (agoraService.isCameraOn) {
        // Maybe turn off camera temporarily
      }
    } else if (state == AppLifecycleState.resumed) {
      // App moved to foreground - refresh data
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pusherService.dispose();

    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isLandscape = screenSize.width > screenSize.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top app bar
              _buildAppBar(isLandscape),

              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Video grid area (main content)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Main video area
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Main video display
                                BlocBuilder<ParticipantsBloc,
                                    ParticipantsState>(
                                  builder: (context, state) {
                                    if (state is ParticipantsLoaded) {
                                      final pinnedUserId = state
                                          .pinnedParticipantId;
                                      final activeSpeakerId = state
                                          .activeSpeakerId;

                                      // Determine which participant to show in main view
                                      Participant? mainParticipant;
                                      if (pinnedUserId != null) {
                                        mainParticipant = state.participants
                                            .firstWhere(
                                                (p) => p.userId == pinnedUserId,
                                            orElse: () =>
                                            state.participants.first);
                                      } else if (activeSpeakerId != null) {
                                        mainParticipant = state.participants
                                            .firstWhere(
                                                (p) =>
                                            p.userId == activeSpeakerId,
                                            orElse: () =>
                                            state.participants.first);
                                      } else
                                      if (state.participants.isNotEmpty) {
                                        // Find a participant with video on or screen sharing
                                        mainParticipant = state.participants
                                            .firstWhere(
                                                (p) =>
                                            p.isVideoOn || p.isScreenShared,
                                            orElse: () =>
                                            state.participants.first);
                                      }

                                      return VideoGrid(
                                        mainParticipant: mainParticipant,
                                        participants: state.participants,
                                        currentUserId: widget.userId,
                                      );
                                    }

                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                ),

                                // Timer overlay at top-left
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatDuration(_meetingDuration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Recording indicator at top
                                if (_isRecording)
                                  Positioned(
                                    top: 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kDangerColor,
                                          borderRadius: BorderRadius.circular(
                                              20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.circle,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'REC ${_formatDuration(
                                                  _recordingDuration)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Fullscreen button at top-right
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: _toggleFullScreen,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isFullScreen
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom control bar
                          ControlBar(
                            isHost: widget.isHost,
                            onToggleChat: _toggleChat,
                            onToggleParticipants: _toggleParticipants,
                            meetingId: widget.meetingId,
                            userId: widget.userId,
                          ),
                        ],
                      ),
                    ),

                    // Right sidebar (chat/participants)
                    if (!isLandscape || screenSize.width > 800)
                      SizedBox(
                        width: isLandscape ? 300 : screenSize.width * 0.3,
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _isChatVisible
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: ParticipantPanel(
                            meetingId: widget.meetingId,
                            isHost: widget.isHost,
                          ),
                          secondChild: ChatPanel(
                            meetingId: widget.meetingId,
                            userId: widget.userId,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isLandscape) {
    if (isLandscape && _isFullScreen) {
      return const SizedBox
          .shrink(); // Hide app bar in fullscreen landscape mode
    }

    return Container(
      height: 56,
      color: Colors.white,
      child: Row(
        children: [
          // Logo or back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                _onWillPop().then((canPop) {
                  if (canPop) Navigator.of(context).pop();
                }),
          ),

          // Meeting info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting',
                  style: kSubheadingStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Code: ${widget.meetingCode}',
                  style: kCaptionStyle,
                ),
              ],
            ),
          ),

          // Meeting code copy button
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.meetingCode)).then((
                  _) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            },
            tooltip: 'Copy meeting code',
          ),

          // More options
          if (widget.isHost)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              itemBuilder: (context) =>
              [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 10),
                      Text('Meeting Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, size: 20),
                      SizedBox(width: 10),
                      Text('Invite Participants'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'recording',
                  child: Row(
                    children: [
                      Icon(
                        _isRecording ? Icons.stop_circle : Icons
                            .fiber_manual_record,
                        size: 20,
                        color: _isRecording ? kDangerColor : null,
                      ),
                      SizedBox(width: 10),
                      Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'end',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 20, color: kDangerColor),
                      SizedBox(width: 10),
                      Text('End Meeting for All',
                          style: TextStyle(color: kDangerColor)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'settings') {
                  _showSettingsPanel();
                } else if (value == 'invite') {
                  _showInviteDialog();
                } else if (value == 'recording') {
                  _toggleRecording();
                } else if (value == 'end') {
                  _showEndMeetingConfirmation();
                }
              },
            ),
        ],
      ),
    );
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) =>
          SettingsPanel(
            meetingId: widget.meetingId,
            isHost: widget.isHost,
          ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Invite Participants'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this meeting code with others to join:'),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: kLightColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.meetingCode,
                          style: kSubheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: kPrimaryColor),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget
                              .meetingCode)).then((_) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Meeting code copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Or share the link:',
                  style: kBodyStyle,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton(Icons.chat, Colors.green, 'WhatsApp'),
                    _buildShareButton(Icons.email, Colors.red, 'Email'),
                    _buildShareButton(Icons.message, Colors.blue, 'SMS'),
                    _buildShareButton(Icons.more_horiz, Colors.grey, 'More'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    );
  }

  Widget _buildShareButton(IconData icon, Color color, String label) {
    return InkWell(
      onTap: () {
        // Share functionality would be implemented here
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing via $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: kCaptionStyle,
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    if (_isRecording) {
      context.read<MeetingBloc>().add(StopRecordingEvent(widget.meetingId));
    } else {
      context.read<MeetingBloc>().add(StartRecordingEvent(widget.meetingId));
    }
  }

  void _showEndMeetingConfirmation() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: kDangerColor),
                const SizedBox(width: 10),
                const Text('End Meeting?'),
              ],
            ),
            content: const Text(
              'Are you sure you want to end this meeting for all participants? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<MeetingBloc>().add(
                      EndMeetingEvent(widget.meetingId));
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                style: TextButton.styleFrom(foregroundColor: kDangerColor),
                child: const Text('End Meeting'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    );
  }
}