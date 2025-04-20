import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/participants/participants_bloc.dart';
import '../../bloc/participants/participants_event.dart';
import '../../bloc/participants/participants_state.dart';
import '../../models/participant.dart';
import '../../utils/constants.dart';

class ParticipantPanel extends StatelessWidget {
  final String meetingId;
  final bool isHost;

  const ParticipantPanel({
    Key? key,
    required this.meetingId,
    required this.isHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Participant list
          Expanded(
            child: BlocBuilder<ParticipantsBloc, ParticipantsState>(
              builder: (context, state) {
                if (state is ParticipantsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ParticipantsLoaded) {
                  final participants = state.participants;

                  if (participants.isEmpty) {
                    return const Center(
                      child: Text('No participants yet'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return _buildParticipantItem(context, participant);
                    },
                  );
                } else if (state is ParticipantsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: kDangerColor, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ParticipantsBloc>().add(
                              LoadParticipantsEvent(meetingId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: Text('No participants information available'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Participants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isHost)
            ElevatedButton.icon(
              onPressed: () => _showInviteDialog(context),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Invite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontSize: 12),
                minimumSize: const Size(0, 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(BuildContext context, Participant participant) {
    return Card(
      elevation: 0,
      color: participant.isSpeaking ? kPrimaryColor.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: participant.isSpeaking
              ? kPrimaryColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.1),
          width: participant.isSpeaking ? 1.5 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: kPrimaryColor.withOpacity(0.2),
              backgroundImage: participant.profilePic != null
                  ? NetworkImage(participant.profilePic!)
                  : null,
              child: participant.profilePic == null
                  ? Text(
                '${participant.firstName[0]}${participant.lastName[0]}',
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant.fullName,
                          style: TextStyle(
                            fontWeight: participant.isSpeaking ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (participant.isHandUp)
                        const Icon(
                          Icons.pan_tool,
                          color: kWarningColor,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (participant.isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      if (participant.isScreenShared)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kInfoColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sharing Screen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (participant.isSpeaking && !participant.isHost && !participant.isScreenShared)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kSuccessColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Speaking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mic status
                Icon(
                  participant.isMicOn ? Icons.mic : Icons.mic_off,
                  color: participant.isMicOn ? kSuccessColor : kSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),

                // Camera status
                Icon(
                  participant.isVideoOn ? Icons.videocam : Icons.videocam_off,
                  color: participant.isVideoOn ? kSuccessColor : kSecondaryColor,
                  size: 20,
                ),

                // More options for host
                if (isHost && participant.userId != 'currentUserId')
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text(
                          'Make ${participant.isHost ? 'Attendee' : 'Host'}',
                        ),
                        onTap: () {
                          // Toggle host status functionality would go here
                        },
                      ),
                      const PopupMenuItem(
                        child: Text('Remove from Meeting'),
                        onTap: null, // Remove functionality would go here
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Participants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this meeting code with others to join:'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: kLightColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meetingId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: kPrimaryColor),
                    onPressed: () {
                      // Copy meeting ID to clipboard
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meeting code copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
}