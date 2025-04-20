import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_event.dart';
import '../../bloc/settings/settings_state.dart';
import '../../models/meeting_settings.dart';
import '../../utils/constants.dart';

class SettingsPanel extends StatefulWidget {
  final String meetingId;
  final bool isHost;

  const SettingsPanel({
    Key? key,
    required this.meetingId,
    required this.isHost,
  }) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late MeetingSettings currentSettings;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Load settings
    context.read<SettingsBloc>().add(
      LoadMeetingSettingsEvent(widget.meetingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.settings, color: kPrimaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Meeting Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!widget.isHost)
                  const Chip(
                    label: Text('View Only'),
                    backgroundColor: kLightColor,
                    labelStyle: TextStyle(fontSize: 12),
                    padding: EdgeInsets.all(0),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings list
          Expanded(
            child: BlocConsumer<SettingsBloc, SettingsState>(
              listener: (context, state) {
                if (state is SettingsLoaded || state is SettingsUpdateSuccess) {
                  _isLoading = false;

                  // Get settings from state
                  if (state is SettingsLoaded) {
                    currentSettings = state.settings;
                  } else if (state is SettingsUpdateSuccess) {
                    currentSettings = state.settings;

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings updated successfully'),
                        backgroundColor: kSuccessColor,
                      ),
                    );
                  }
                } else if (state is SettingsLoading || state is SettingsUpdating) {
                  _isLoading = true;
                } else if (state is SettingsError) {
                  _isLoading = false;

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${state.message}'),
                      backgroundColor: kDangerColor,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is SettingsLoaded || state is SettingsUpdateSuccess) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    children: [
                      // Host Controls Section
                      _buildSectionHeader('Host Controls'),
                      _buildToggleSetting(
                        title: 'Start/Stop Meeting',
                        subtitle: 'Only host can start or end meeting',
                        value: currentSettings.startStopMeeting,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('startStopMeeting', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Add/Remove Host',
                        subtitle: 'Allow host to assign co-hosts',
                        value: currentSettings.addRemoveHost,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('addRemoveHost', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Mute All Participants',
                        subtitle: 'Host can mute everyone at once',
                        value: currentSettings.muteAll,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('muteAll', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Unmute All Participants',
                        subtitle: 'Host can unmute everyone at once',
                        value: currentSettings.unmuteAll,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('unmuteAll', value);
                        } : null,
                      ),

                      const SizedBox(height: 24),

                      // Participant Permissions Section
                      _buildSectionHeader('Participant Permissions'),
                      _buildToggleSetting(
                        title: 'Share Screen',
                        subtitle: 'Allow participants to share screen',
                        value: currentSettings.shareScreen,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('shareScreen', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Raise Hand',
                        subtitle: 'Allow participants to raise hand',
                        value: currentSettings.raisedHand,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('raisedHand', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Send Reactions',
                        subtitle: 'Allow participants to send reactions',
                        value: currentSettings.sendReactions,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('sendReactions', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Toggle Microphone',
                        subtitle: 'Allow participants to mute/unmute themselves',
                        value: currentSettings.toggleMicrophone,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('toggleMicrophone', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Toggle Video',
                        subtitle: 'Allow participants to turn video on/off',
                        value: currentSettings.toggleVideo,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('toggleVideo', value);
                        } : null,
                      ),

                      const SizedBox(height: 24),

                      // Security Section
                      _buildSectionHeader('Security'),
                      _buildToggleSetting(
                        title: 'Enable Waiting Room',
                        subtitle: 'Participants must be admitted by host',
                        value: currentSettings.enableWaitingRoom,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('enableWaitingRoom', value);
                        } : null,
                      ),
                      const Divider(),
                      _buildToggleSetting(
                        title: 'Require Password',
                        subtitle: 'Participants must enter password to join',
                        value: currentSettings.requirePassword,
                        onChanged: widget.isHost ? (value) {
                          _updateSetting('requirePassword', value);
                        } : null,
                      ),

                      const SizedBox(height: 40),
                    ],
                  );
                }

                // Error or unexpected state
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: kDangerColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text('Failed to load settings'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<SettingsBloc>().add(
                            LoadMeetingSettingsEvent(widget.meetingId),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Save button
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveSettings : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  void _updateSetting(String name, bool value) {
    if (!widget.isHost) return;

    // Update locally
    setState(() {
      switch (name) {
        case 'startStopMeeting':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: value,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'muteAll':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: value,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'unmuteAll':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: value,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'addRemoveHost':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: value,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'shareScreen':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: value,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'raisedHand':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: value,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'sendReactions':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: value,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'toggleMicrophone':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: value,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'toggleVideo':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: value,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'enableWaitingRoom':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: value,
            requirePassword: currentSettings.requirePassword,
          );
          break;
        case 'requirePassword':
          currentSettings = MeetingSettings(
            id: currentSettings.id,
            meetingId: currentSettings.meetingId,
            startStopMeeting: currentSettings.startStopMeeting,
            muteAll: currentSettings.muteAll,
            unmuteAll: currentSettings.unmuteAll,
            addRemoveHost: currentSettings.addRemoveHost,
            shareScreen: currentSettings.shareScreen,
            raisedHand: currentSettings.raisedHand,
            sendReactions: currentSettings.sendReactions,
            toggleMicrophone: currentSettings.toggleMicrophone,
            toggleVideo: currentSettings.toggleVideo,
            enableWaitingRoom: currentSettings.enableWaitingRoom,
            requirePassword: value,
          );
          break;
      }

      _hasChanges = true;
    });
  }

  void _saveSettings() {
    if (!widget.isHost || !_hasChanges) return;

    // Prepare settings map
    final Map<String, dynamic> settings = {
      'start_stop_meetingCheckbox': currentSettings.startStopMeeting ? 1 : 0,
      'muteAllCheckbox': currentSettings.muteAll ? 1 : 0,
      'unmuteAllCheckbox': currentSettings.unmuteAll ? 1 : 0,
      'addRemoveHostCheckbox': currentSettings.addRemoveHost ? 1 : 0,
      'shareScreenCheckbox': currentSettings.shareScreen ? 1 : 0,
      'raiseHandCheckbox': currentSettings.raisedHand ? 1 : 0,
      'sendReactionsCheckbox': currentSettings.sendReactions ? 1 : 0,
      'toggleMicCheckbox': currentSettings.toggleMicrophone ? 1 : 0,
      'toggleVideoCheckbox': currentSettings.toggleVideo ? 1 : 0,
      'enableWaitingRoomCheckbox': currentSettings.enableWaitingRoom ? 1 : 0,
      'requirePasswordCheckbox': currentSettings.requirePassword ? 1 : 0,
    };

    // Update settings
    context.read<SettingsBloc>().add(
      UpdateMeetingSettingsEvent(
        meetingId: widget.meetingId,
        settings: settings,
      ),
    );

    // Reset changes flag
    setState(() {
      _hasChanges = false;
    });
  }
}