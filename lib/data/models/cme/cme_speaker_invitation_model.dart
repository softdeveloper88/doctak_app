import 'package:doctak_app/data/models/cme/cme_event_model.dart';

class CmeSpeakerInvitation {
  CmeSpeakerInvitation({
    required this.id,
    required this.eventId,
    this.status,
    this.role,
    this.event,
  });

  factory CmeSpeakerInvitation.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'] as Map<String, dynamic>?;
    return CmeSpeakerInvitation(
      id: '${json['id'] ?? ''}',
      eventId: '${json['eventId'] ?? json['cme_event_id'] ?? ''}',
      status: json['invitationStatus'] as String? ??
          json['invitation_status'] as String?,
      role: json['speakerRole'] as String? ??
          json['role'] as String? ??
          json['speaker_role'] as String?,
      event: eventJson != null ? CmeEventData.fromNodeJson(eventJson) : null,
    );
  }

  final String id;
  final String eventId;
  final String? status;
  final String? role;
  final CmeEventData? event;
}
