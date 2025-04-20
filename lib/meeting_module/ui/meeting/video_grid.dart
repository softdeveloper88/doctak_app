import 'package:doctak_app/meeting_module/bloc/participants/participants_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/participants/participants_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/participant.dart';
import '../../services/agora_service.dart';
import '../../utils/constants.dart';

class VideoGrid extends StatelessWidget {
  final Participant? mainParticipant;
  final List<Participant> participants;
  final String currentUserId;

  const VideoGrid({
    Key? key,
    this.mainParticipant,
    required this.participants,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agoraService = Provider.of<AgoraService>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    // Filter participants to exclude the main participant for the thumbnails
    List<Participant> thumbnailParticipants = [];
    if (mainParticipant != null) {
      thumbnailParticipants = participants
          .where((p) => p.userId != mainParticipant!.userId)
          .toList();
    } else {
      thumbnailParticipants = participants;
    }

    return Stack(
      children: [
        // Main video view
        if (mainParticipant != null)
          _buildMainVideo(mainParticipant!, agoraService),

        // Background when no main video
        if (mainParticipant == null)
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'No active video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

        // Participant thumbnails
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Container(
            height: isLandscape ? 120 : 100,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: thumbnailParticipants.length,
              itemBuilder: (context, index) {
                final participant = thumbnailParticipants[index];
                return _buildVideoThumbnail(participant, agoraService, context);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainVideo(Participant participant, AgoraService agoraService) {
    bool isLocalUser = participant.userId == currentUserId;
    bool hasVideoOrScreen = participant.isVideoOn || participant.isScreenShared;

    // For local user
    if (isLocalUser) {
      if (participant.isScreenShared) {
        return agoraService.createLocalScreenShareView();
      } else if (participant.isVideoOn) {
        return agoraService.createLocalView();
      }
    }
    // For remote users
    else {
      if (hasVideoOrScreen) {
        return agoraService.createRemoteView(int.parse(participant.userId));
      }
    }

    // Fallback if no video is available
    return Container(
      color: Colors.black,
      child: Center(
        child: participant.profilePic != null
            ? CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(participant.profilePic!),
        )
            : CircleAvatar(
          radius: 60,
          backgroundColor: kPrimaryColor,
          child: Text(
            participant.firstName[0] + participant.lastName[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(
      Participant participant,
      AgoraService agoraService,
      BuildContext context,
      ) {
    bool isLocalUser = participant.userId == currentUserId;
    bool hasVideoOrScreen = participant.isVideoOn || participant.isScreenShared;

    return GestureDetector(
      onTap: () {
        // Pin this participant
        context.read<ParticipantsBloc>().add(
          PinParticipantEvent(participant.userId),
        );
      },
      child: Container(
        width: 160,
        height: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: participant.isSpeaking
              ? Border.all(color: kPrimaryColor, width: 2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video content
            isLocalUser
                ? (participant.isScreenShared
                ? agoraService.createLocalScreenShareView()
                : participant.isVideoOn
                ? agoraService.createLocalView()
                : _buildAvatarPlaceholder(participant))
                : (hasVideoOrScreen
                ? agoraService.createRemoteView(int.parse(participant.userId))
                : _buildAvatarPlaceholder(participant)),

            // Overlay for participant info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    // Name
                    Expanded(
                      child: Text(
                        isLocalUser
                            ? '${participant.firstName} (You)'
                            : participant.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Mic status
                    Icon(
                      participant.isMicOn ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            // Indicator for screen sharing
            if (participant.isScreenShared)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kInfoColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.screen_share,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Sharing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Hand raised indicator
            if (participant.isHandUp)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kWarningColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pan_tool,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

            // Host indicator
            if (participant.isHost)
              Positioned(
                top: 25,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Host',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(Participant participant) {
    return Center(
      child: participant.profilePic != null
          ? CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(participant.profilePic!),
      )
          : CircleAvatar(
        radius: 30,
        backgroundColor: kPrimaryColor,
        child: Text(
          participant.firstName[0] + participant.lastName[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}