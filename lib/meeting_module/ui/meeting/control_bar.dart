import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/meeting/meeting_bloc.dart';
import '../../bloc/meeting/meeting_event.dart';
import '../../bloc/meeting/meeting_state.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/chat/chat_state.dart';
import '../../services/agora_service.dart';
import '../../utils/constants.dart';

class ControlBar extends StatelessWidget {
  final bool isHost;
  final VoidCallback onToggleChat;
  final VoidCallback onToggleParticipants;
  final String meetingId;
  final String userId;

  const ControlBar({
    Key? key,
    required this.isHost,
    required this.onToggleChat,
    required this.onToggleParticipants,
    required this.meetingId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final agoraService = context.read<AgoraService>();

    // Get unread chat count from ChatBloc
    final chatState = context.watch<ChatBloc>().state;
    int unreadCount = 0;
    if (chatState is ChatLoaded) {
      unreadCount = chatState.unreadCount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine how many buttons we can fit
            final maxWidth = constraints.maxWidth;

            if (maxWidth < 400) {
              // Mobile portrait - show minimal controls
              return _buildMobileControls(context, agoraService, unreadCount);
            } else {
              // Tablet or landscape - show full controls
              return _buildFullControls(context, agoraService, isLandscape, unreadCount);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileControls(
      BuildContext context,
      AgoraService agoraService,
      int unreadCount
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio toggle
        _buildControlButton(
          onPressed: () => _toggleMicrophone(context, agoraService),
          icon: agoraService.isMicOn ? Icons.mic : Icons.mic_off,
          label: 'Mic',
          isActive: agoraService.isMicOn,
          color: agoraService.isMicOn ? kPrimaryColor : kDangerColor,
        ),
        const SizedBox(width: 10),

        // Video toggle
        _buildControlButton(
          onPressed: () => _toggleCamera(context, agoraService),
          icon: agoraService.isCameraOn ? Icons.videocam : Icons.videocam_off,
          label: 'Camera',
          isActive: agoraService.isCameraOn,
          color: agoraService.isCameraOn ? kPrimaryColor : kDangerColor,
        ),
        const SizedBox(width: 10),

        // More menu with other controls
        PopupMenuButton(
          tooltip: 'More options',
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: kLightColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert,
              color: kSecondaryColor,
            ),
          ),
          itemBuilder: (context) => [
            // Screen share
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    agoraService.isScreenSharing
                        ? Icons.stop_screen_share
                        : Icons.screen_share,
                    color: agoraService.isScreenSharing ? kDangerColor : null,
                  ),
                  const SizedBox(width: 10),
                  Text(agoraService.isScreenSharing
                      ? 'Stop Sharing'
                      : 'Share Screen'),
                ],
              ),
              onTap: () => _toggleScreenShare(context, agoraService),
            ),

            // Hand raise
            PopupMenuItem(
              child: BlocBuilder<MeetingBloc, MeetingState>(
                builder: (context, state) {
                  bool isHandRaised = false;
                  if (state is HandRaiseToggled) {
                    isHandRaised = state.raised;
                  }

                  return Row(
                    children: [
                      Icon(
                        Icons.pan_tool,
                        color: isHandRaised ? kWarningColor : null,
                      ),
                      const SizedBox(width: 10),
                      Text(isHandRaised ? 'Lower Hand' : 'Raise Hand'),
                    ],
                  );
                },
              ),
              onTap: () => _toggleHandRaise(context),
            ),

            // Chat
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.chat),
                  const SizedBox(width: 10),
                  const Text('Chat'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: kDangerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: onToggleChat,
            ),

            // Participants
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 10),
                  Text('Participants'),
                ],
              ),
              onTap: onToggleParticipants,
            ),
          ],
        ),
        const SizedBox(width: 10),

        // End call button
        _buildEndCallButton(context, false),
      ],
    );
  }

  Widget _buildFullControls(
      BuildContext context,
      AgoraService agoraService,
      bool isLandscape,
      int unreadCount
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio toggle
        _buildControlButton(
          onPressed: () => _toggleMicrophone(context, agoraService),
          icon: agoraService.isMicOn ? Icons.mic : Icons.mic_off,
          label: 'Mic',
          isActive: agoraService.isMicOn,
          color: agoraService.isMicOn ? kPrimaryColor : kDangerColor,
          showLabel: isLandscape,
        ),
        const SizedBox(width: 10),

        // Video toggle
        _buildControlButton(
          onPressed: () => _toggleCamera(context, agoraService),
          icon: agoraService.isCameraOn ? Icons.videocam : Icons.videocam_off,
          label: 'Camera',
          isActive: agoraService.isCameraOn,
          color: agoraService.isCameraOn ? kPrimaryColor : kDangerColor,
          showLabel: isLandscape,
        ),
        const SizedBox(width: 10),

        // Screen share
        _buildControlButton(
          onPressed: () => _toggleScreenShare(context, agoraService),
          icon: agoraService.isScreenSharing
              ? Icons.stop_screen_share
              : Icons.screen_share,
          label: agoraService.isScreenSharing ? 'Stop' : 'Share',
          isActive: agoraService.isScreenSharing,
          color: agoraService.isScreenSharing ? kWarningColor : kSecondaryColor,
          showLabel: isLandscape,
        ),
        const SizedBox(width: 10),

        // Hand raise
        BlocBuilder<MeetingBloc, MeetingState>(
          buildWhen: (previous, current) =>
          current is HandRaiseToggled ||
              previous is HandRaiseToggled,
          builder: (context, state) {
            bool isHandRaised = false;
            if (state is HandRaiseToggled) {
              isHandRaised = state.raised;
            }

            return _buildControlButton(
              onPressed: () => _toggleHandRaise(context),
              icon: Icons.pan_tool,
              label: 'Hand',
              isActive: isHandRaised,
              color: isHandRaised ? kWarningColor : kSecondaryColor,
              showLabel: isLandscape,
            );
          },
        ),
        const SizedBox(width: 10),

        // Chat button
        Stack(
          children: [
            _buildControlButton(
              onPressed: onToggleChat,
              icon: Icons.chat,
              label: 'Chat',
              color: kSecondaryColor,
              showLabel: isLandscape,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kDangerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),

        // Participants button
        _buildControlButton(
          onPressed: onToggleParticipants,
          icon: Icons.people,
          label: 'People',
          color: kSecondaryColor,
          showLabel: isLandscape,
        ),

        // End call button (more space if in landscape)
        SizedBox(width: isLandscape ? 20 : 10),
        _buildEndCallButton(context, isLandscape),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color color = kSecondaryColor,
    bool isActive = false,
    bool showLabel = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isActive ? color : kLightColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 20,
            ),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? color : kSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEndCallButton(BuildContext context, bool isLandscape) {
    return InkWell(
      onTap: () => _showLeaveOptions(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 20 : 15,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: kDangerColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 20,
            ),
            if (isLandscape) ...[
              const SizedBox(width: 5),
              const Text(
                'Leave',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleMicrophone(BuildContext context, AgoraService agoraService) {
    final newState = !agoraService.isMicOn;

    // Update Agora state
    context.read<MeetingBloc>().add(ToggleMicrophoneEvent(newState));
  }

  void _toggleCamera(BuildContext context, AgoraService agoraService) {
    final newState = !agoraService.isCameraOn;

    // Update Agora state
    context.read<MeetingBloc>().add(ToggleCameraEvent(newState));
  }

  void _toggleScreenShare(BuildContext context, AgoraService agoraService) {
    final newState = !agoraService.isScreenSharing;

    // Update Agora state
    context.read<MeetingBloc>().add(ToggleScreenShareEvent(newState));
  }

  void _toggleHandRaise(BuildContext context) {
    // We need to get the current state from the Bloc
    final meetingBloc = context.read<MeetingBloc>();
    final state = meetingBloc.state;

    bool isCurrentlyRaised = false;
    if (state is HandRaiseToggled) {
      isCurrentlyRaised = state.raised;
    }

    // Toggle the state
    meetingBloc.add(ToggleHandRaiseEvent(!isCurrentlyRaised));
  }

  void _showLeaveOptions(BuildContext context) {
    if (isHost) {
      // Host has more options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: kSecondaryColor),
                title: const Text('Leave Meeting'),
                subtitle: const Text('You will leave but the meeting will continue for others'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveMeeting(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: kDangerColor),
                title: const Text('End Meeting for All', style: TextStyle(color: kDangerColor)),
                subtitle: const Text('The meeting will end for all participants'),
                onTap: () {
                  Navigator.pop(context);
                  _showEndMeetingConfirmation(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } else {
      // Participant just leaves
      _showLeaveConfirmation(context);
    }
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Meeting?'),
        content: const Text('Are you sure you want to leave this meeting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveMeeting(context);
            },
            style: TextButton.styleFrom(foregroundColor: kDangerColor),
            child: const Text('Leave'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void _showEndMeetingConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Meeting for All?'),
        content: const Text(
            'Are you sure you want to end this meeting for all participants? '
                'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endMeeting(context);
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

  void _leaveMeeting(BuildContext context) {
    context.read<MeetingBloc>().add(LeaveMeetingEvent(meetingId));
    Navigator.of(context).pop(); // Return to previous screen
  }

  void _endMeeting(BuildContext context) {
    context.read<MeetingBloc>().add(EndMeetingEvent(meetingId));
    Navigator.of(context).pop(); // Return to previous screen
  }
}