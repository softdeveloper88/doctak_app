import 'package:doctak_app/data/models/cme/cme_event_model.dart';

/// Learner tab bucket — mirrors `lib/cme-learning-segment.ts` on the Node API.
String cmeLearningSegmentState(CmeEventData event) {
  final status = event.registrationStatus?.toLowerCase();
  if (status == null || status.isEmpty || status == 'cancelled') return 'none';

  if (_isLearnerCreditComplete(event)) return 'completed';

  final started = _hasAttendanceAttempt(event);
  final ended = _isEventEnded(event);

  if (started && !ended) return 'progress';
  return 'registered';
}

bool _isLearnerCreditComplete(CmeEventData event) {
  final lp = event.learnerProgress;
  final certId = lp?.certificateId ?? event.myCertificateId;
  if (certId != null && certId.isNotEmpty) return true;
  if (lp?.feedbackSubmitted == true) return true;
  if (event.myFeedbackSubmitted == true) return true;
  return false;
}

bool _hasAttendanceAttempt(CmeEventData event) {
  if (event.registrationStatus == 'attended' || event.isAttending == true) {
    return true;
  }
  final attendance = event.attendancePercentage ?? event.myProgressPercent;
  return attendance is num && attendance > 0;
}

bool _isEventEnded(CmeEventData event) {
  if (event.isCancelled) return true;
  final dbStatus = event.status?.toLowerCase();
  if (dbStatus == 'completed' || dbStatus == 'cancelled' || dbStatus == 'ended') {
    return true;
  }
  final isRecorded = event.type == 'recorded' || event.format == 'on_demand';
  if (isRecorded) return false;
  return event.isAfterSession;
}

/// Whether an event is still discoverable on the Browse tab (not enrolled + still open).
bool cmeIsOpenForBrowse(CmeEventData event) {
  if (cmeLearningSegmentState(event) != 'none') return false;
  if (event.isCancelled) return false;

  final dbStatus = event.status?.toLowerCase();
  if (dbStatus == 'completed' || dbStatus == 'cancelled' || dbStatus == 'ended') {
    return false;
  }

  final isRecorded = event.type == 'recorded' || event.format == 'on_demand';
  if (isRecorded) {
    return dbStatus == 'published' || dbStatus == 'upcoming' || dbStatus == null;
  }

  if (event.isAfterSession) return false;
  return dbStatus == 'published' || dbStatus == 'upcoming' || dbStatus == null;
}

/// Client-side segment filter — mirrors web `matchesCmeLearningSegment`.
bool matchesLearningSegment(CmeEventData event, String segment) {
  switch (segment) {
    case 'browse':
      return cmeIsOpenForBrowse(event);
    case 'registered':
      return cmeLearningSegmentState(event) == 'registered';
    case 'progress':
      return cmeLearningSegmentState(event) == 'progress';
    case 'completed':
      return cmeLearningSegmentState(event) == 'completed';
    default:
      return true;
  }
}

/// Cover badge for learner list cards — avoids misleading event "COMPLETED" on enrolled items.
String? cmeCardCoverBadgeStatus(CmeEventData event) {
  if (event.canManage == true) return event.displayStatus;

  switch (cmeLearningSegmentState(event)) {
    case 'completed':
      return 'credit_earned';
    case 'progress':
      return 'credit_pending';
    case 'registered':
      if (event.isLive) return 'live';
      return event.isUpcoming ? 'upcoming' : null;
    default:
      return event.displayStatus;
  }
}
