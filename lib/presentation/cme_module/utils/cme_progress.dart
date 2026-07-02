import 'package:doctak_app/data/models/cme/cme_event_model.dart';

enum CmeProgressStepState { done, current, upcoming }

class CmeProgressStep {
  const CmeProgressStep({
    required this.id,
    required this.label,
    this.detail,
    required this.state,
  });

  final String id;
  final String label;
  final String? detail;
  final CmeProgressStepState state;
}

enum CmeProgressActionKind {
  register,
  join,
  onDemand,
  quiz,
  feedback,
  certificate,
  none,
}

class CmeProgressAction {
  const CmeProgressAction({required this.label, required this.kind});

  final String label;
  final CmeProgressActionKind kind;
}

bool cmeIsRegistered(CmeEventData event) {
  final status = event.registrationStatus;
  if (status != null) {
    return status != 'cancelled' &&
        (status == 'registered' || status == 'attended' || status == 'waitlist');
  }
  return event.isRegistered == true;
}

bool cmeHasAttended(CmeEventData event) {
  if (event.capabilities?.liveSessionEnded == true && cmeIsRegistered(event)) {
    return true;
  }
  // Website: cme_attendees.registration_status === 'attended' or attendance_percentage
  if (event.registrationStatus == 'attended') return true;
  final attendance = event.attendancePercentage ?? event.myProgressPercent;
  if (attendance is num && attendance >= 50) return true;
  return false;
}

bool cmeIsRecordedEvent(CmeEventData event) {
  return event.type == 'recorded' || event.format == 'on_demand';
}

/// True only when the event actually has a learner quiz (server flag + module target).
bool cmeEventHasQuiz(CmeEventData event) {
  final lp = event.learnerProgress;
  if (lp != null && !lp.hasQuiz) return false;
  if (event.primaryQuizTarget != null) return true;
  if (lp == null) return false;
  if (!lp.hasQuiz) return false;
  // Server flagged quiz but no attempts configured and not in review — skip ghost step.
  if (lp.quizAttemptsMax == 0 && !lp.quizPassed && !lp.quizPendingReview) {
    return false;
  }
  return true;
}

double cmeProgressFraction(CmeEventData event) {
  final steps = buildCmeProgressSteps(event);
  if (steps.isEmpty) return 0;
  final done = steps.where((s) => s.state == CmeProgressStepState.done).length;
  final current = steps.any((s) => s.state == CmeProgressStepState.current) ? 0.5 : 0.0;
  return ((done + current) / steps.length).clamp(0.0, 1.0);
}

List<CmeProgressStep> buildCmeProgressSteps(CmeEventData event) {
  final registered = cmeIsRegistered(event);
  final attended = cmeHasAttended(event);
  final progress = event.learnerProgress;
  final hasQuiz = cmeEventHasQuiz(event);
  final quizDone = !hasQuiz || (progress?.quizPassed ?? false);
  final quizPending = progress?.quizPendingReview ?? false;
  final isRecorded = cmeIsRecordedEvent(event);

  final raw = <({String id, String label, String? detail})>[
    (id: 'register', label: 'Registered', detail: null),
    (
      id: 'attend',
      label: isRecorded ? 'Complete content' : 'Attend session',
      detail: _attendanceDetail(event),
    ),
  ];

  if (hasQuiz) {
    raw.add((
      id: 'quiz',
      label: 'Pass quiz',
      detail: quizPending ? 'Awaiting faculty review' : 'Score ≥ 70%',
    ));
  }

  raw.addAll([
    (id: 'feedback', label: 'Evaluation', detail: '~2 min'),
    (id: 'certificate', label: 'Certificate', detail: 'After evaluation'),
  ]);

  final certId = progress?.certificateId;
  if (certId != null && certId.isNotEmpty) {
    return [
      for (var i = 0; i < raw.length; i++)
        CmeProgressStep(
          id: raw[i].id,
          label: raw[i].label,
          detail: raw[i].detail,
          state: CmeProgressStepState.done,
        ),
    ];
  }

  var currentId = 'register';
  if (!registered) {
    currentId = 'register';
  } else if (!attended) {
    currentId = 'attend';
  } else if (hasQuiz && !quizDone) {
    currentId = 'quiz';
  } else if (!(progress?.feedbackSubmitted ?? false)) {
    currentId = 'feedback';
  } else {
    currentId = 'certificate';
  }

  final currentIndex = raw.indexWhere((step) => step.id == currentId).clamp(0, raw.length - 1);

  return [
    for (var i = 0; i < raw.length; i++)
      CmeProgressStep(
        id: raw[i].id,
        label: raw[i].label,
        detail: raw[i].detail,
        state: i < currentIndex
            ? CmeProgressStepState.done
            : i == currentIndex
                ? CmeProgressStepState.current
                : CmeProgressStepState.upcoming,
      ),
  ];
}

CmeProgressAction resolveCmeProgressAction(CmeEventData event) {
  final fromCapabilities = _resolveCmeProgressActionFromCapabilities(event);
  if (fromCapabilities.label.isNotEmpty) return fromCapabilities;
  return _resolveCmeProgressActionFromSteps(event);
}

CmeProgressAction _resolveCmeProgressActionFromCapabilities(CmeEventData event) {
  final caps = event.capabilities;
  if (caps != null && !caps.showLearnerProgress) {
    return const CmeProgressAction(label: '', kind: CmeProgressActionKind.none);
  }

  if (caps?.registrationFull == true && !cmeIsRegistered(event)) {
    return const CmeProgressAction(label: 'Registration full', kind: CmeProgressActionKind.none);
  }
  if (caps?.liveSessionEnded == true && !cmeIsRegistered(event)) {
    return const CmeProgressAction(label: 'Registration closed', kind: CmeProgressActionKind.none);
  }

  final progress = event.learnerProgress;

  if (caps?.canJoinLive == true && !cmeHasAttended(event)) {
    return const CmeProgressAction(label: 'Join live session', kind: CmeProgressActionKind.join);
  }
  if (caps?.canRegister == true && !cmeIsRegistered(event)) {
    return const CmeProgressAction(label: 'Register for activity', kind: CmeProgressActionKind.register);
  }
  if (progress?.quizPendingReview == true) {
    return const CmeProgressAction(label: 'Awaiting essay review', kind: CmeProgressActionKind.none);
  }
  if (caps?.canSubmitQuiz == true && cmeEventHasQuiz(event)) {
    return const CmeProgressAction(label: 'Take the quiz', kind: CmeProgressActionKind.quiz);
  }
  if (!cmeHasAttended(event) && cmeIsRecordedEvent(event) && cmeIsRegistered(event)) {
    return const CmeProgressAction(label: 'Continue content', kind: CmeProgressActionKind.onDemand);
  }
  if (caps?.canLeaveFeedback == true) {
    return const CmeProgressAction(label: 'Complete evaluation', kind: CmeProgressActionKind.feedback);
  }
  final certId = progress?.certificateId;
  if (certId != null && certId.isNotEmpty) {
    return const CmeProgressAction(label: 'View certificate', kind: CmeProgressActionKind.certificate);
  }
  if (caps?.canViewCertificate == true) {
    return const CmeProgressAction(label: 'View certificate', kind: CmeProgressActionKind.certificate);
  }
  if (progress?.feedbackSubmitted == true && cmeIsRegistered(event)) {
    return const CmeProgressAction(label: 'View certificate', kind: CmeProgressActionKind.certificate);
  }
  return const CmeProgressAction(label: '', kind: CmeProgressActionKind.none);
}

CmeProgressAction _resolveCmeProgressActionFromSteps(CmeEventData event) {
  final progress = event.learnerProgress;
  final certId = progress?.certificateId;
  if (certId != null && certId.isNotEmpty) {
    return const CmeProgressAction(label: 'View certificate', kind: CmeProgressActionKind.certificate);
  }

  final steps = buildCmeProgressSteps(event);
  CmeProgressStep? current;
  for (final step in steps) {
    if (step.state == CmeProgressStepState.current) {
      current = step;
      break;
    }
  }
  if (current == null) {
    return const CmeProgressAction(label: '', kind: CmeProgressActionKind.none);
  }

  switch (current.id) {
    case 'register':
      if (!cmeIsRegistered(event)) {
        return const CmeProgressAction(label: 'Register for activity', kind: CmeProgressActionKind.register);
      }
      break;
    case 'attend':
      if (!cmeHasAttended(event)) {
        if (cmeIsRecordedEvent(event)) {
          return const CmeProgressAction(label: 'Continue content', kind: CmeProgressActionKind.onDemand);
        }
        if (event.isLive && event.isVirtualType) {
          return const CmeProgressAction(label: 'Join live session', kind: CmeProgressActionKind.join);
        }
      }
      break;
    case 'quiz':
      if (cmeEventHasQuiz(event) && !(progress?.quizPassed ?? false)) {
        if (progress?.quizPendingReview == true) {
          return const CmeProgressAction(label: 'Awaiting essay review', kind: CmeProgressActionKind.none);
        }
        return const CmeProgressAction(label: 'Take the quiz', kind: CmeProgressActionKind.quiz);
      }
      break;
    case 'feedback':
      if (!(progress?.feedbackSubmitted ?? false)) {
        return const CmeProgressAction(label: 'Complete evaluation', kind: CmeProgressActionKind.feedback);
      }
      break;
    case 'certificate':
      if (progress?.feedbackSubmitted ?? false) {
        return const CmeProgressAction(label: 'View certificate', kind: CmeProgressActionKind.certificate);
      }
      break;
  }
  return const CmeProgressAction(label: '', kind: CmeProgressActionKind.none);
}

/// User-facing explanation when a learner step is blocked (feedback tab, banners).
String? cmeProgressBlockerMessage(CmeEventData event) {
  final progress = event.learnerProgress;
  if (progress?.feedbackSubmitted == true) return null;
  if (event.capabilities?.canLeaveFeedback == true) return null;

  if (progress?.quizPendingReview == true) {
    return 'Your quiz is with faculty for review. You can complete the evaluation once it is approved.';
  }
  if (!cmeIsRegistered(event)) {
    return 'Register for this activity to unlock the next steps.';
  }
  if (!cmeHasAttended(event)) {
    if (event.capabilities?.liveSessionEnded == true && cmeIsRegistered(event)) {
      return null;
    }
    if (cmeIsRecordedEvent(event)) {
      return 'Complete the on-demand content first, then continue with quiz and evaluation.';
    }
    return 'Attend the session first, then continue with quiz and evaluation.';
  }
  if (cmeEventHasQuiz(event) && !(progress?.quizPassed ?? false)) {
    return 'Pass the quiz to unlock the evaluation.';
  }
  return null;
}

/// True when the activity ended but the learner has not finished credit steps.
bool cmeLearnerCreditInProgress(CmeEventData event) {
  if (!cmeIsRegistered(event)) return false;
  final certId = event.learnerProgress?.certificateId;
  if (certId != null && certId.isNotEmpty) return false;
  return cmeProgressFraction(event) < 1.0;
}

String? _attendanceDetail(CmeEventData event) {
  final pct = event.attendancePercentage ?? event.myProgressPercent;
  if (pct is! num || pct <= 0) return null;
  if (cmeIsRecordedEvent(event)) return '${pct.round()}% watched';
  return '${pct.round()}% attended';
}
