# CME Module — Flutter Implementation Guide
> Complete reference for building the Continuing Medical Education module in doctak_app.
> Based on full analysis of the DoctakRepository Laravel backend (35 tables, 9 controllers, 10 services).

---

## Table of Contents
1. [Feature Decision Matrix](#1-feature-decision-matrix)
2. [Folder & File Structure](#2-folder--file-structure)
3. [Data Models (Dart)](#3-data-models-dart)
4. [API Service Layer](#4-api-service-layer)
5. [BLoC / State Management](#5-bloc--state-management)
6. [Screen-by-Screen UI Spec](#6-screen-by-screen-ui-spec)
7. [Navigation Architecture](#7-navigation-architecture)
8. [Live Meeting Integration](#8-live-meeting-integration)
9. [Certificate PDF Handling](#9-certificate-pdf-handling)
10. [Quiz Engine](#10-quiz-engine)
11. [Analytics & Credits](#11-analytics--credits)
12. [Notifications](#12-notifications)
13. [Implementation Phases](#13-implementation-phases)
14. [Key Dependencies](#14-key-dependencies)
15. [API Quick Reference](#15-api-quick-reference)

---

## 1. Feature Decision Matrix

### ✅ MUST HAVE (Phase 1 — Core)
| Feature | Reason |
|---------|--------|
| Browse & search CME events | Primary discovery flow |
| Event detail page | Full info: credits, speakers, agenda, pricing |
| Register / cancel registration | Core user action |
| My Events (registered/attended/upcoming) | Personal hub |
| Live meeting (Agora RTC) | Already in app — extend existing |
| Attendance tracking (heartbeat) | Required for credit auto-award |
| Credit auto-award on attendance | Core value proposition |
| Certificate listing & download | Users' proof of completion |
| CME notifications inbox | Essential engagement |
| Waitlist: join/leave/position | When events are full |

### ✅ SHOULD HAVE (Phase 2 — Enhanced)
| Feature | Reason |
|---------|--------|
| Quiz/Assessment during events | Many events require quiz for credits |
| Learning Paths — browse & enroll | Structured education journeys |
| Learning Path progress tracking | Drives retention |
| Analytics dashboard (user) | Shows credit progress |
| Compliance tracking (vs. annual goal) | High value for doctors |
| CME Profile setup | Personalisation |
| Event creation (simplified) | Doctors create their own events |
| Speaker invitation (accept/decline) | Invited speakers need in-app flow |
| Live polls during sessions | Interactive |
| Live Q&A during sessions | Interactive |

### 🔮 NICE TO HAVE (Phase 3 — Delight)
| Feature | Reason |
|---------|--------|
| Gamification (XP, badges, leaderboard) | Partially built on backend — extend together |
| Certificate sharing (LinkedIn, Twitter) | Social proof |
| CME Transcript PDF | Professional credential export |
| Recorded events (on-demand modules) | Async learning |
| Subscription management | Billing/plan |
| Certificate public verification | Deep link: `doctak.net/cme/verify/{id}` |

### ❌ NOT IN APP (Web Admin Only)
| Feature | Reason |
|---------|--------|
| Admin dashboard | Admin web panel only |
| Event approval/reject/publish | Admin/moderator web task |
| System-wide analytics | Admin only |
| Category management | Admin only |
| Revenue reporting | Admin only |
| Email template management | Admin only |
| User suspension | Admin only |

---

## 2. Folder & File Structure

```
lib/
└── presentation/
    └── cme_screen/
        ├── cme_main_screen.dart              # Root screen with bottom tab (Events / Paths / Analytics / Profile)
        │
        ├── events/
        │   ├── cme_events_screen.dart        # Browse/search/filter events list
        │   ├── cme_event_detail_screen.dart  # Full event detail page
        │   ├── cme_event_create_screen.dart  # Create new event (Phase 2)
        │   ├── cme_my_events_screen.dart     # Tabs: Upcoming / Attended / Waitlist / Created
        │   ├── cme_event_join_screen.dart    # Pre-join checklist (camera/mic test)
        │   └── widgets/
        │       ├── cme_event_card.dart       # Reusable event card
        │       ├── cme_event_filter_sheet.dart # Bottom sheet filter
        │       ├── cme_credit_badge.dart     # Credit hours pill badge
        │       ├── cme_speaker_tile.dart     # Speaker avatar + name + role
        │       └── cme_registration_button.dart # Register / Cancel / Waitlist
        │
        ├── meeting/
        │   ├── cme_meeting_screen.dart       # Live Agora meeting (extend CallScreen)
        │   ├── cme_meeting_chat_tab.dart     # Chat panel
        │   ├── cme_meeting_qa_tab.dart       # Q&A panel
        │   ├── cme_meeting_polls_tab.dart    # Live polls panel
        │   └── cme_meeting_participants_tab.dart # Participants list
        │
        ├── quiz/
        │   ├── cme_quiz_screen.dart          # Quiz taking experience
        │   ├── cme_quiz_result_screen.dart   # Results page
        │   └── widgets/
        │       ├── cme_question_widget.dart  # MCQ / T-F / Essay / Multi-select
        │       └── cme_timer_widget.dart     # Countdown timer
        │
        ├── certificates/
        │   ├── cme_certificates_screen.dart  # Certificate gallery
        │   ├── cme_certificate_detail.dart   # Single cert with share/download
        │   └── widgets/
        │       └── cme_certificate_card.dart # Certificate card with expiry
        │
        ├── learning_paths/
        │   ├── cme_paths_browse_screen.dart  # Browse all paths
        │   ├── cme_path_detail_screen.dart   # Path detail + event sequence
        │   ├── cme_my_paths_screen.dart      # My enrolled paths + progress
        │   └── widgets/
        │       ├── cme_path_card.dart        # Path card with progress bar
        │       └── cme_path_event_tile.dart  # Event in a path list
        │
        ├── analytics/
        │   ├── cme_analytics_screen.dart     # Credits + compliance + performance
        │   └── widgets/
        │       ├── cme_credits_chart.dart    # Bar/pie chart by credit type
        │       ├── cme_compliance_card.dart  # Compliance progress ring
        │       └── cme_activity_timeline.dart # Recent activity list
        │
        ├── notifications/
        │   └── cme_notifications_screen.dart # CME-specific notification inbox
        │
        ├── profile/
        │   └── cme_profile_screen.dart       # Medical license, specialty, preferences
        │
        └── bloc/
            ├── events/
            │   ├── cme_events_bloc.dart
            │   ├── cme_events_event.dart
            │   └── cme_events_state.dart
            ├── event_detail/
            │   ├── cme_event_detail_bloc.dart
            │   ├── cme_event_detail_event.dart
            │   └── cme_event_detail_state.dart
            ├── meeting/
            │   ├── cme_meeting_bloc.dart
            │   ├── cme_meeting_event.dart
            │   └── cme_meeting_state.dart
            ├── quiz/
            │   ├── cme_quiz_bloc.dart
            │   ├── cme_quiz_event.dart
            │   └── cme_quiz_state.dart
            ├── certificates/
            │   ├── cme_certificates_bloc.dart
            │   ├── cme_certificates_event.dart
            │   └── cme_certificates_state.dart
            ├── learning_paths/
            │   ├── cme_paths_bloc.dart
            │   ├── cme_paths_event.dart
            │   └── cme_paths_state.dart
            └── analytics/
                ├── cme_analytics_bloc.dart
                ├── cme_analytics_event.dart
                └── cme_analytics_state.dart

lib/
└── data/
    └── network/
        └── api/
            └── cme/
                ├── cme_api_service.dart          # Retrofit/Dio service interface
                ├── cme_events_repository.dart
                ├── cme_certificates_repository.dart
                ├── cme_learning_paths_repository.dart
                ├── cme_analytics_repository.dart
                ├── cme_notifications_repository.dart
                └── cme_meeting_repository.dart
    └── models/
        └── cme/
            ├── cme_event_model.dart
            ├── cme_event_detail_model.dart
            ├── cme_credit_model.dart
            ├── cme_attendee_model.dart
            ├── cme_certificate_model.dart
            ├── cme_quiz_model.dart
            ├── cme_quiz_question_model.dart
            ├── cme_quiz_result_model.dart
            ├── cme_learning_path_model.dart
            ├── cme_analytics_model.dart
            ├── cme_notification_model.dart
            ├── cme_profile_model.dart
            ├── cme_poll_model.dart
            ├── cme_qa_model.dart
            └── cme_chat_message_model.dart
```

---

## 3. Data Models (Dart)

```dart
// ─── cme_event_model.dart ───────────────────────────────────────────────────
class CmeEvent {
  final String id;
  final String title;
  final String description;
  final List<String> learningObjectives;
  final DateTime startDate;
  final DateTime endDate;
  final String timezone;
  final int? maxCapacity;
  final int registeredCount;
  final String? location;
  final CmeEventType eventType;          // live | recorded | hybrid
  final CmeEventStatus status;           // draft | published | cancelled | completed
  final String? coverImage;
  final bool isFeatured;
  final CmeEventCategoryModel? category;
  final List<CmeCreditModel> credits;    // can be multiple credit types
  final CmePricingModel? pricing;
  final CmeRegistrationStatus registrationStatus; // not_registered | registered | waitlist | attended
  final int? waitlistPosition;
  final String? seriesId;
  final String createdBy;
  final DateTime createdAt;

  bool get isFull => maxCapacity != null && registeredCount >= maxCapacity!;
  bool get isLive => eventType == CmeEventType.live;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing =>
      startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  double get totalCreditHours =>
      credits.fold(0, (sum, c) => sum + c.creditHours);
}

enum CmeEventType { live, recorded, hybrid }
enum CmeEventStatus { draft, published, cancelled, completed }
enum CmeRegistrationStatus { notRegistered, registered, waitlist, attended }

// ─── cme_credit_model.dart ─────────────────────────────────────────────────
class CmeCreditModel {
  final String id;
  final double creditHours;
  final String creditType;     // 'AMA PRA Category 1', 'ACCME', 'ANCC', 'MOC', etc.
  final String? accreditationBody;
  final String? accreditationNumber;
  final DateTime? expirationDate;
  final Map<String, dynamic>? requirements; // minAttendance%, passingScore%
}

// ─── cme_certificate_model.dart ────────────────────────────────────────────
class CmeCertificateModel {
  final String id;
  final String userId;
  final String eventId;
  final String certificateNumber;     // CME-2026-EVTCODE-XXXXX
  final DateTime issueDate;
  final DateTime? expirationDate;
  final String? pdfPath;
  final String? qrCode;
  final bool isVerified;
  final double creditsEarned;
  final String eventTitle;
  final String issuedBy;
}

// ─── cme_quiz_model.dart ───────────────────────────────────────────────────
class CmeQuizModel {
  final String id;
  final String eventId;
  final String moduleId;
  final String title;
  final String? description;
  final int passingScore;              // default 70
  final int maxAttempts;               // default 3
  final int? timeLimitMinutes;
  final bool randomizeQuestions;
  final bool showResultsImmediately;
  final bool allowReview;
  final CmeQuizType quizType;          // pre_test|post_test|knowledge_check|final_exam
  final bool isRequired;
  final List<CmeQuizQuestion> questions;
  final int? userAttemptCount;         // from API
  final CmeQuizResult? lastResult;     // from API if already attempted
}

class CmeQuizQuestion {
  final String id;
  final String questionText;
  final CmeQuestionType questionType;  // multiple_choice|true_false|essay|multiple_select
  final List<String> options;          // parsed from JSON
  final String? explanation;
  final int points;
  final String? imageUrl;
}

enum CmeQuizType { preTest, postTest, knowledgeCheck, finalExam }
enum CmeQuestionType { multipleChoice, trueFalse, essay, multipleSelect }

// ─── cme_learning_path_model.dart ──────────────────────────────────────────
class CmeLearningPathModel {
  final String id;
  final String pathName;
  final String description;
  final String? coverImage;
  final String difficultyLevel;        // beginner|intermediate|advanced
  final double totalCreditHours;
  final int estimatedDurationWeeks;
  final List<String> prerequisites;
  final List<String> learningObjectives;
  final List<CmeEvent> events;         // ordered event sequence
  final bool isFeatured;
  final int enrollmentCount;
  // User-specific (populated per user):
  final CmePathEnrollmentModel? enrollment;
}

class CmePathEnrollmentModel {
  final String id;
  final CmePathStatus status;          // enrolled|in_progress|completed|dropped
  final double progressPercentage;
  final DateTime enrolledAt;
  final DateTime? completedAt;
}

enum CmePathStatus { enrolled, inProgress, completed, dropped }

// ─── cme_analytics_model.dart ──────────────────────────────────────────────
class CmeAnalyticsModel {
  final int totalEventsAttended;
  final double totalCreditsEarned;
  final Map<String, double> creditsByType;  // {'AMA PRA Cat1': 12.5, ...}
  final double completionRate;
  final double averageRatingGiven;
  final int certificatesEarned;
  final CmeComplianceModel compliance;
  final List<CmeRecentActivity> recentActivity;
}

class CmeComplianceModel {
  final double requiredCredits;
  final double earnedCredits;
  final double percentage;
  final String status;                 // compliant|on_track|needs_attention
  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final int daysRemaining;
}

// ─── cme_poll_model.dart ───────────────────────────────────────────────────
class CmePollModel {
  final String id;
  final String question;
  final List<String> options;
  final bool isActive;
  final bool allowMultipleResponses;
  final bool showResultsImmediately;
  final List<int>? userSelectedOptions;   // null = not voted yet
  final Map<int, int>? resultCounts;      // option index → vote count
}

// ─── cme_qa_model.dart ─────────────────────────────────────────────────────
class CmeQaModel {
  final String id;
  final String userId;
  final String userNameDisplay;
  final String question;
  final String? answer;
  final bool isAnswered;
  final int upvotes;
  final bool isFeatured;
  final bool currentUserUpvoted;
}

// ─── cme_profile_model.dart ────────────────────────────────────────────────
class CmeProfileModel {
  final String? medicalLicenseNumber;
  final String? licenseState;
  final String? specialtyPrimary;
  final String? specialtySecondary;
  final List<String> boardCertifications;
  final int annualCmeRequirement;      // target hours/year
  final DateTime? cycleStartDate;
  final DateTime? cycleEndDate;
  final bool complianceTrackingEnabled;
  final bool autoCertificateGeneration;
  final String preferredCertificateFormat; // default|modern|classic|minimal
  final CmeNotificationPreferences notificationPreferences;
}

class CmeNotificationPreferences {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool eventReminders;
  final bool certificateReady;
  final bool deadlineWarnings;
  final bool weeklyDigest;
}
```

---

## 4. API Service Layer

```dart
// lib/data/network/api/cme/cme_api_service.dart

// Base URL: AppData.baseUrl + '/api/cme'
// Auth: 'Authorization': 'Bearer ${AppData.userToken}'

class CmeApiService {

  // === EVENTS ===
  Future<CmeEventsResponse> getEvents({
    int page = 1,
    String? search,
    String? categoryId,
    String? eventType,       // live|recorded|hybrid
    String? status,
    String? dateFrom,
    String? dateTo,
    bool? isFeatured,
    String? specialty,
    String? creditType,
    String? sort,            // date_asc|date_desc|credits|popular
  });

  Future<CmeEventDetailResponse> getEventDetail(String eventId);
  Future<ApiResponse> registerForEvent(String eventId);
  Future<ApiResponse> cancelRegistration(String eventId);
  Future<CmeRegistrationStatus> getRegistrationStatus(String eventId);
  Future<CmeMeetingTokenResponse> joinEvent(String eventId);
  Future<ApiResponse> leaveEvent(String eventId, {required int sessionDurationSeconds});
  Future<ApiResponse> trackParticipation(String eventId, String action, int duration);
  Future<MyEventsResponse> getMyEvents();
  Future<List<CmeEvent>> getUpcomingEvents();
  Future<List<CmeEvent>> getAttendedEvents();
  Future<List<CmeEvent>> getFeaturedEvents();

  // === CHAT (during meeting) ===
  Future<List<CmeChatMessage>> getChatMessages(String eventId, {int? since});
  Future<ApiResponse> sendChatMessage(String eventId, String message);

  // === POLLS (during meeting) ===
  Future<List<CmePollModel>> getPolls(String eventId);
  Future<ApiResponse> submitPollVote(String eventId, String pollId, List<int> selectedOptions);

  // === Q&A (during meeting) ===
  Future<List<CmeQaModel>> getQaQuestions(String eventId);
  Future<ApiResponse> submitQuestion(String eventId, String question);
  Future<ApiResponse> upvoteQuestion(String eventId, String qaId);

  // === QUIZ ===
  Future<CmeQuizModel> getQuiz(String eventId, String moduleId, String quizId);
  Future<CmeQuizResult> submitQuiz(String eventId, String moduleId, String quizId, Map<String, dynamic> answers);
  Future<ApiResponse> autoSaveQuiz(String eventId, String moduleId, String quizId, Map<String, dynamic> answers);
  Future<List<CmeQuizResult>> getQuizAttempts(String eventId, String moduleId, String quizId);

  // === CERTIFICATES ===
  Future<List<CmeCertificateModel>> getMyCertificates();
  Future<CmeCertificateModel> getCertificate(String certificateId);
  Future<String> downloadCertificate(String certificateId); // returns URL
  Future<CmeCertificateModel?> getCertificateForEvent(String eventId);

  // === LEARNING PATHS ===
  Future<List<CmeLearningPathModel>> browsePaths({String? difficulty, String? categoryId});
  Future<List<CmeLearningPathModel>> getMyPaths();
  Future<CmeLearningPathModel> getPathDetail(String pathId);
  Future<ApiResponse> enrollInPath(String pathId);
  Future<ApiResponse> unenrollFromPath(String enrollmentId);
  Future<ApiResponse> pausePath(String enrollmentId);
  Future<ApiResponse> resumePath(String enrollmentId);
  Future<double> getPathProgress(String enrollmentId);

  // === ANALYTICS ===
  Future<CmeAnalyticsModel> getAnalytics({String? period}); // week|month|quarter|year
  Future<CmeComplianceModel> getCompliance();
  Future<Map<String, double>> getCreditsByType();

  // === NOTIFICATIONS ===
  Future<List<CmeNotificationModel>> getNotifications({int page = 1});
  Future<int> getUnreadCount();
  Future<ApiResponse> markNotificationRead(String notificationId);
  Future<ApiResponse> markAllNotificationsRead();
  Future<ApiResponse> deleteNotification(String notificationId);
  Future<CmeNotificationPreferences> getNotificationSettings();
  Future<ApiResponse> updateNotificationSettings(CmeNotificationPreferences prefs);

  // === WAITLIST ===
  Future<List<CmeWaitlistEntry>> getMyWaitlists();
  Future<ApiResponse> joinWaitlist(String eventId);
  Future<ApiResponse> leaveWaitlist(String waitlistId);
  Future<ApiResponse> toggleAutoRegister(String waitlistId);
  Future<int> getWaitlistPosition(String waitlistId);

  // === PROFILE ===
  Future<CmeProfileModel> getCmeProfile();
  Future<ApiResponse> updateCmeProfile(CmeProfileModel profile);
  Future<List<dynamic>> getAchievements(); // Phase 3
}
```

---

## 5. BLoC / State Management

### Events BLoC
```dart
// Events
abstract class CmeEventsEvent {}
class FetchCmeEventsEvent extends CmeEventsEvent {
  final CmeEventFilters filters;
  final bool isRefresh;
}
class LoadMoreCmeEventsEvent extends CmeEventsEvent {}
class SearchCmeEventsEvent extends CmeEventsEvent { final String query; }
class ApplyFiltersEvent extends CmeEventsEvent { final CmeEventFilters filters; }

// States
abstract class CmeEventsState {}
class CmeEventsInitial extends CmeEventsState {}
class CmeEventsLoading extends CmeEventsState {}
class CmeEventsLoaded extends CmeEventsState {
  final List<CmeEvent> events;
  final bool hasMore;
  final CmeEventFilters activeFilters;
}
class CmeEventsError extends CmeEventsState { final String message; }
```

### Meeting BLoC (extends existing meeting concept)
```dart
// States include:
class CmeMeetingConnected extends CmeMeetingState {
  final List<CmeChatMessage> chatMessages;
  final List<CmePollModel> activePolls;
  final List<CmeQaModel> qaQuestions;
  final List<Participant> participants;
  final int attendanceDurationSeconds;
  final CmeQuizModel? pendingQuiz;      // quiz popped up mid-session
}
```

### Quiz BLoC
```dart
// States
class CmeQuizInProgress extends CmeQuizState {
  final CmeQuizModel quiz;
  final int currentQuestionIndex;
  final Map<String, dynamic> answers;   // questionId → answer
  final int? timeRemainingSeconds;
  final bool isSubmitting;
}
class CmeQuizCompleted extends CmeQuizState {
  final CmeQuizResult result;
  final bool certificateEligible;
}
```

---

## 6. Screen-by-Screen UI Spec

### 6.1 CME Dashboard / Main Screen

**Layout:** tab-based inside `cme_main_screen.dart`

```
AppBar: "CME Education" [Notification bell with badge]
TabBar: Events | My Learning | Analytics | Profile

Body (Events tab default):
┌─────────────────────────────────────────────┐
│ [Search bar: "Search CME Events..."]   [⚙ Filter] │
├─────────────────────────────────────────────┤
│ ── FEATURED ─────────────────────────────── │
│ [Horizontal scroll: Featured event cards]   │
├─────────────────────────────────────────────┤
│ Category chips: [All] [Cardiology] [Surgery]│
│                 [Neurology] [Oncology]...    │
├─────────────────────────────────────────────┤
│ ── UPCOMING EVENTS ──────────────────────── │
│ [Event card]                                │
│ [Event card]                                │
│ ...                                         │
└─────────────────────────────────────────────┘
```

**CmeEventCard widget:**
```
┌──────────────────────────────────────────┐
│ [Cover image 16:9]              [LIVE 🔴]│
├──────────────────────────────────────────┤
│ Cardiology • Mar 15, 2026 • 2:00 PM UTC  │
│ ── Advanced Cardiac Imaging Techniques ──│
│ Dr. Sarah Ahmed • Mt. Sinai Hospital     │
│                                          │
│ [1.5 CME] [Free]  [●●●○ 234/300 seats]  │
│                                    [Register →] │
└──────────────────────────────────────────┘
```

**Design tokens:**
- Background: `#F8FAFC`
- Card radius: `16px`
- LIVE badge: red `#EF4444` with pulse dot
- CME credit badge: `#10B981` green pill
- Free badge: `#3B82F6` blue pill
- Paid badge: `#8B5CF6` purple pill

---

### 6.2 Event Detail Screen

**Sections (scrollable):**
1. **Header** — Cover image (full-width, 200px), title overlay with gradient
2. **Status bar** — Date/time • Duration • Type badge • Status badge
3. **Quick stats row** — `[1.5 AMA CME] [300 seats] [Free] [★ Speaker]`
4. **Register/Waitlist CTA button** — full width, sticky bottom
5. **Tabs:** Overview | Credits | Speakers | Schedule | Reviews

**Overview tab:**
- Description
- Learning Objectives (bullet list with ✓ icons)
- Location / Meeting Room info

**Credits tab:**
- Card per credit type:
  ```
  ┌─── AMA PRA Category 1 ────────────────────┐
  │ 1.5 Credit Hours                            │
  │ Accredited by: ACCME                        │
  │ Valid until: March 2028                     │
  │ Requirements: ≥85% attendance               │
  └─────────────────────────────────────────────┘
  ```

**Speakers tab:**
- Avatar + name + role badge (Primary Speaker / Moderator / Panelist)
- Short bio
- Specialty tags

**Registration Status:**
- `registered` → show green "Registered ✓" with cancel option
- `waitlist` → show "Waitlist #3" with position and leave option
- `attended` → show "Attended ✓" + certificate download button if available
- `not_registered` + `isFull=false` → orange "Register" button
- `not_registered` + `isFull=true` → gray "Join Waitlist" button

---

### 6.3 Live Meeting Screen (`cme_meeting_screen.dart`)

**Extends the existing CallScreen with CME-specific overlays.**

```
┌─────────────────────────────────────────────┐
│  ← [Event Title]          [🎙][📹][••••]   │
├──────────────────────────┬──────────────────┤
│                           │                  │
│   [Main video feed]       │  [Side panel]    │
│                           │                  │
├───────────────────────────┴──────────────────┤
│  [💬 Chat] [🙋 Q&A] [📊 Polls] [👥 Ppl]   │
├─────────────────────────────────────────────┤
│  [Attendance timer: 1h 23m]  [Credits: 1.5] │
└─────────────────────────────────────────────┘
```

**Tab panels (animated bottom drawer):**

**Chat panel:**
- Message bubbles (own = right/teal, others = left/gray)
- System messages in center (gray italic): "Event started"
- Text input + send button
- Polls new poll indication: "📊 New Poll!"

**Q&A panel:**
- Card per question: question text + upvote count + [Answered] badge
- My questions highlighted
- Sort by: Most Upvoted / Newest
- FAB: Ask a question (dialog)

**Polls panel:**
- Poll card: question + option list (tap to vote radio/checkbox)
- Shows result bar after voting (if `show_results_immediately=true`)
- "Results will be shown after poll closes" if not

**Participants panel:**
- Hosts separator (crown icon)  
- Speakers separator  
- Attendees (count badge)

**Quiz popup (mid-session):**
- If event has a `knowledge_check` quiz triggered, slide-up bottom sheet:
  ```
  ┌── Knowledge Check ─────────────┐
  │ 5 questions • 5 min limit       │
  │ Required for CME credit         │
  │         [Start Quiz]            │
  └────────────────────────────────┘
  ```

**Attendance tracking:**
- `Timer.periodic(Duration(minutes: 1))` → call `trackParticipation(action='heartbeat', duration=currentSeconds)`
- Show live timer "Time in session: 1h 23m"
- Show credit progress: "Earning: 0.8 / 1.5 CME" (based on % attended vs required)

---

### 6.4 Quiz Screen (`cme_quiz_screen.dart`)

```
AppBar: "Post-Test • Question 3 of 10"     [⏱ 12:45]
Progress bar: ████████░░░░░ 30%

┌─────────────────────────────────────────────┐
│                                              │
│  Which of the following best describes...   │
│                                              │
│  [Image if has imageUrl]                    │
│                                              │
│  ┌── A ──────────────────────────────────┐  │
│  │ Sinus rhythm with normal PR interval   │  │
│  └────────────────────────────────────────┘  │
│  ┌── B ──────────────────────────────────┐  │
│  │ Atrial fibrillation                    │◄ selected │
│  └────────────────────────────────────────┘  │
│  ┌── C ──────────────────────────────────┐  │
│  │ First degree AV block                  │  │
│  └────────────────────────────────────────┘  │
│                                              │
└─────────────────────────────────────────────┘

[← Previous]                  [Next →]
            [Submit Quiz]          (on last Q)
```

**Selected option:** teal border + teal background tint  
**Timer:** counts down, turns red at <2 minutes  
**Auto-save:** debounce 500ms → call `autoSaveQuiz()` whenever an answer changes  

**Results Screen:**
```
┌─── Your Result ─────────────────────────────┐
│              ✅ PASSED                        │
│         Score: 85 / 100                      │
│    ████████████████░░░░  85%                 │
│         (Pass mark: 70%)                     │
│                                              │
│  Time taken: 8 minutes 32 seconds            │
│  Questions: 8.5 / 10 correct                 │
│                                              │
│  ✅ You are eligible for CME credit          │
│                                              │
│  [View Answer Review]   [Continue to Event]  │
└─────────────────────────────────────────────┘
```

---

### 6.5 Certificate Gallery (`cme_certificates_screen.dart`)

**Headers strip:**
```
┌──────────────┬──────────────┬───────────────┐
│  12          │  24.5        │  2            │
│  Certificates│  CME Hours   │  Expiring Soon│
└──────────────┴──────────────┴───────────────┘
```

**Certificate card:**
```
┌──────────────────────────────────────┐
│  🏆  Advanced Cardiac Imaging         │
│      Issued: Jan 15, 2026             │
│      Expires: Jan 15, 2028            │
│      1.5 AMA PRA Category 1           │
│  ──────────────────────────────────  │
│  CME-2026-ACI-X7K2P                  │
│  [Download PDF] [Share] [📋 Copy ID] │
└──────────────────────────────────────┘
```

**Expiring soon** cards have orange left border + "⚠ Expires in 45 days"

**Detail screen:**
- Full certificate preview (uses `pdf_viewer_flutter` or webview)
- Action row: Download | Email | Share to LinkedIn | Twitter
- Verification QR code display
- Event details collapsible section

---

### 6.6 Learning Paths Screen

**Browse tab:**
```
[Difficulty: All ▾]   [Category ▾]   [Duration ▾]

┌── FEATURED PATH ─────────────────────────────┐
│ [Wide card with cover image]                  │
│ Cardiology Fellowship Prep                    │
│ Advanced • 12 weeks • 15 CME hours            │
│ [Enroll - Free]                 ★ 4.8 (234)  │
└──────────────────────────────────────────────┘

[Path card]
[Path card]
```

**My Paths tab:**
```
Enrolled Paths:

┌── Cardiology Fellowship Prep ─────────────┐
│ ████████████████████░░░░░░░░░  67%         │
│ 8 of 12 events completed                  │
│ [Continue]  [View Details]    [⏸ Pause]   │
└────────────────────────────────────────────┘
```

**Path Detail Screen:**
```
AppBar: [Cover image] + title overlay
[Progress ring if enrolled: 67%]
[Enroll] or [Continue] button

Section: About
Section: Learning Objectives (bullet list)
Section: Prerequisites (if any)

Section: Events in this Path (12 total)
  1. ✅ Introduction to Echo      1h
  2. ✅ Advanced Ventricular...   2h  
  3. 🔵 Cardiac MRI Techniques   1.5h  ← (current/next)
  4. 🔒 Complex Valve Disease     2h   ← (locked or open)
  ...
```

Event status icons: ✅ completed · 🔵 next · ⭕ not started · 🔒 locked (prereqs not met)

---

### 6.7 Analytics Screen

**Compliance Ring (top):**
```
┌─────── Compliance Status ─────────────────┐
│         ████████████░░░░░░  78%            │
│          ON TRACK ✓                         │
│     19.5 / 25 hours earned                 │
│     128 days remaining in cycle            │
└────────────────────────────────────────────┘
```

**Credits by Type bar chart:**
```
AMA PRA Cat 1  ████████████████ 14.5h
ACCME          ████████ 8.0h
ANCC           ████ 4.0h
Other          ██ 2.0h
```

**Recent Activity timeline:**
```
📜 Certificate earned — Cardiac MRI   Mar 8
✅ Attended — EKG Masterclass          Mar 5
📝 Quiz passed (92%) — ICU Protocols   Mar 3
📚 Enrolled — Cardiology Path          Mar 1
```

**Stats row:**
```
[12 Events] [24.5h Credits] [95% Completion] [4 Paths]
```

---

### 6.8 CME Profile Screen

**Sections:**
1. **Medical License** — License number, state/country, specialty (primary + secondary)
2. **CME Requirements** — Annual requirement (input), cycle dates
3. **Board Certifications** — Multi-chip input
4. **Certificate Preferences** — Template selector (4 options with previews)
5. **Notification Preferences** — Toggle list:
   - Event reminders
   - Certificate ready alerts
   - Deadline warnings (<90 days)
   - Weekly digest
6. **Auto-certificate generation** — Toggle (ON = cert generated immediately when credits awarded)

---

## 7. Navigation Architecture

```
HomeScreen
└── CME tab (new bottom tab or from profile menu)
    └── CmeMainScreen (TabBar)
        ├── Events Tab
        │   ├── CmeEventsScreen        ← events list
        │   │   └── CmeEventDetailScreen
        │   │       ├── CmeMeetingScreen (Agora)
        │   │       │   └── CmeQuizScreen (popup/route)
        │   │       │       └── CmeQuizResultScreen
        │   │       └── Certificate detail (if attended)
        │   └── CmeMyEventsScreen      ← my events
        │       └── → CmeEventDetailScreen
        │
        ├── My Learning Tab
        │   ├── CmePathsBrowseScreen
        │   │   └── CmePathDetailScreen
        │   │       └── → CmeEventDetailScreen
        │   └── CmeMyPathsScreen
        │       └── → CmePathDetailScreen
        │
        ├── Analytics Tab
        │   └── CmeAnalyticsScreen
        │       └── CmeCertificatesScreen
        │           └── CmeCertificateDetail
        │
        └── Profile Tab
            └── CmeProfileScreen

// CME notifications accessible from AppBar bell anywhere in CME
CmeNotificationsScreen (global push route)
```

---

## 8. Live Meeting Integration

The existing `CallScreen`/meeting system uses Agora. CME meetings use **the same Agora infrastructure** but need additional layers.

**Token endpoint:** `POST /api/cme/events/{event}/join`
```json
Response: {
  "token": "...",
  "channel": "cme_event_550e8400",
  "uid": 12345,
  "event_id": "550e8400-...",
  "meeting_room_id": "...",
  "is_host": false,
  "is_speaker": false
}
```

**Attendance heartbeat:**
```dart
// Start on join
Timer.periodic(Duration(minutes: 1), (timer) {
  cmeApiService.trackParticipation(
    eventId,
    'heartbeat',
    ++_minutesElapsed * 60,
  );
});

// On leave
await cmeApiService.leaveEvent(eventId,
  sessionDurationSeconds: _sessionTimer.elapsed.inSeconds
);
```

**Real-time chat/polls/Q&A options (choose one):**
- **Option A: Polling** — `Timer.periodic(Duration(seconds: 5))` → `getChatMessages(since: lastMessageId)`. Simple, no additional infra.
- **Option B: Pusher** — Subscribe to `cme-event-{id}` channel. Already have Pusher in app.
  ```
  Events: 'new-chat-message', 'new-poll', 'poll-closed', 'new-question', 'qa-answered'
  ```
- **Recommendation: Pusher** — already integrated, same pattern as call notifications.

**Pusher channel structure:**
```
Channel: cme-event-{event_id}
Events:
  new-chat-message  → { message, user, timestamp }
  new-poll          → { poll_id, question, options }
  poll-closed       → { poll_id, results }
  new-qa-question   → { qa_id, question, upvotes }
  qa-answered       → { qa_id, answer }
  module-changed    → { module_id, module_title }
  event-ended       → {}
```

---

## 9. Certificate PDF Handling

```dart
// Download and view certificate
Future<void> viewCertificate(String certificateId) async {
  // 1. Get download URL from API
  final url = await cmeApiService.downloadCertificate(certificateId);
  
  // 2. Download to local file
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/cme_cert_$certificateId.pdf';
  
  // Option A — open with system PDF viewer
  await OpenFile.open(filePath);
  
  // Option B — in-app with flutter_pdfview
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => CmePdfViewerScreen(pdfPath: filePath)
  ));
}

// Share certificate
Future<void> shareCertificate(CmeCertificateModel cert) async {
  final url = await cmeApiService.downloadCertificate(cert.id);
  await Share.shareXFiles([XFile(localPdfPath)],
    text: 'I earned a CME certificate for ${cert.eventTitle} on DocTak! '
          'Certificate #${cert.certificateNumber}',
    subject: 'CME Certificate — ${cert.eventTitle}',
  );
}
```

**Required packages:** `flutter_pdfview` or `syncfusion_flutter_pdfviewer`, `open_file`, `path_provider`

---

## 10. Quiz Engine

### Quiz flow state machine:
```
IDLE → LOADING → IN_PROGRESS → (time_up | all_answered + submitted) → SUBMITTING → COMPLETED
                    ↓
               AUTO_SAVED (every answer change)
```

### Timer implementation:
```dart
// In CmeQuizBloc
void _startTimer(int totalSeconds) {
  _timerSeconds = totalSeconds;
  _timer = Timer.periodic(Duration(seconds: 1), (t) {
    if (_timerSeconds <= 0) {
      t.cancel();
      add(CmeQuizTimeUpEvent()); // auto-submit
    } else {
      _timerSeconds--;
      emit(state.copyWith(timeRemainingSeconds: _timerSeconds));
    }
  });
}
```

### Auto-save:
```dart
// Debounced auto-save
Timer? _autoSaveTimer;
void _scheduleAutoSave() {
  _autoSaveTimer?.cancel();
  _autoSaveTimer = Timer(Duration(milliseconds: 500), () {
    cmeApiService.autoSaveQuiz(eventId, moduleId, quizId, currentAnswers);
  });
}
```

### Question rendering by type:
```dart
Widget buildQuestion(CmeQuizQuestion question) {
  return switch (question.questionType) {
    CmeQuestionType.multipleChoice => CmeMcqWidget(question: question),
    CmeQuestionType.trueFalse      => CmeTrueFalseWidget(question: question),
    CmeQuestionType.multipleSelect => CmeMultiSelectWidget(question: question),
    CmeQuestionType.essay          => CmeEssayWidget(question: question),
  };
}
```

---

## 11. Analytics & Credits

### Credits summary widget:
```dart
// Fetch on analytics screen init
final analytics = await cmeApiService.getAnalytics(period: 'year');

// Show compliance ring using CustomPaint or fl_chart
final compliance = analytics.compliance;
double pct = compliance.percentage / 100;
// Green if >= 100%, orange >= 75%, red < 75%
Color color = pct >= 1.0 ? Colors.green : pct >= 0.75 ? Colors.orange : Colors.red;
```

### Credit breakdown chart:
```dart
// Use fl_chart BarChart or PieChart
final creditData = analytics.creditsByType;
// { 'AMA PRA Category 1': 14.5, 'ACCME': 8.0, ... }
```

---

## 12. Notifications

**CME uses 7 notification types:**

| Type | Icon | Color | Action on tap |
|------|------|-------|---------------|
| `registration_confirmation` | ✅ | Green | Open event detail |
| `reminder` | 🔔 | Orange | Open event detail / join if live |
| `certificate_ready` | 🏆 | Gold | Open certificate |
| `waitlist_available` | 📋 | Blue | Register for event |
| `deadline_warning` | ⚠️ | Red | Open analytics/compliance |
| `event_update` | ℹ️ | Gray | Open event detail |
| `cancellation` | ❌ | Red | Dismiss / view |

**CME notification badge:** Show separate unread count on CME tab icon.
```dart
// Poll unread count (or use existing FCM push for badges)
final unreadCount = await cmeApiService.getUnreadCount();
```

---

## 13. Implementation Phases

### Phase 1 — Core (4-6 weeks)
1. Data models + API service (all endpoints)
2. Browse events screen + search + filters
3. Event detail screen (all tabs)
4. Register / cancel / waitlist
5. My Events screen (tabs)
6. CME meeting screen (Agora + attendance heartbeat)
7. Certificate listing + download
8. CME notification inbox
9. CME main screen shell + navigation

### Phase 2 — Enhanced (3-4 weeks)
1. Quiz engine (all 4 question types + timer + auto-save)
2. Live chat, polls, Q&A in meeting
3. Learning paths browse + enroll + progress
4. Analytics screen (credits + compliance ring + chart)
5. CME profile setup
6. Event creation (simplified)
7. Speaker accept/decline flow

### Phase 3 — Delight (2-3 weeks)
1. Gamification (XP bar, badges, leaderboard)
2. Certificate sharing (LinkedIn, Twitter)
3. CME transcript PDF download
4. Recorded events / on-demand modules
5. Push notification deep link integration
6. Certificate public verification deep link

---

## 14. Key Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  # Charts
  fl_chart: ^0.71.0
  
  # PDF viewing
  flutter_pdfview: ^1.3.2          # or syncfusion_flutter_pdfviewer
  
  # File handling
  open_file: ^3.3.2
  path_provider: ^2.1.4             # already in project?
  
  # Sharing (already have share_plus)
  share_plus: ^11.0.0               # already in project
  
  # Cached images (likely already present)
  cached_network_image: ^3.4.1
  
  # Pull to refresh (likely already present)
  easy_refresh: ^3.4.0
  
  # Shimmer loading
  shimmer: ^3.0.0
```

---

## 15. API Quick Reference

All endpoints: `BASE_URL/api/cme/...`  
Header: `Authorization: Bearer {token}`  
Content-Type: `application/json`

| Priority | Method | Endpoint | Phase |
|----------|--------|----------|-------|
| P1 | GET | `/events` | 1 |
| P1 | GET | `/events/{id}` | 1 |
| P1 | POST | `/events/{id}/register` | 1 |
| P1 | DELETE | `/events/{id}/unregister` | 1 |
| P1 | GET | `/events/{id}/registration-status` | 1 |
| P1 | POST | `/events/{id}/join` | 1 |
| P1 | POST | `/events/{id}/leave` | 1 |
| P1 | POST | `/events/{id}/track-participation` | 1 |
| P1 | GET | `/events/my/events` | 1 |
| P1 | GET | `/events/my/upcoming` | 1 |
| P1 | GET | `/events/my/attended` | 1 |
| P1 | GET | `/certificates` | 1 |
| P1 | GET | `/certificates/{id}/download` | 1 |
| P1 | POST | `/waitlist/{event}/join` | 1 |
| P1 | DELETE | `/waitlist/{id}/leave` | 1 |
| P1 | GET | `/notifications` | 1 |
| P1 | GET | `/notifications/count` | 1 |
| P1 | POST | `/notifications/mark-all-read` | 1 |
| P2 | GET | `/events/{id}/chat/messages` | 2 |
| P2 | POST | `/events/{id}/chat` | 2 |
| P2 | GET | `/events/{id}/polls` | 2 |
| P2 | POST | `/events/{id}/polls/{poll}/vote` | 2 |
| P2 | GET | `/events/{event}/modules/{module}/quiz/{quiz}` | 2 |
| P2 | POST | `/events/{event}/modules/{module}/quiz/{quiz}/submit` | 2 |
| P2 | GET | `/learning-paths/browse` | 2 |
| P2 | POST | `/learning-paths/{id}/enroll` | 2 |
| P2 | GET | `/learning-paths/my/enrolled` | 2 |
| P2 | GET | `/analytics` | 2 |
| P2 | GET | `/analytics/compliance` | 2 |
| P2 | GET | `/profile/credits` | 2 |
| P3 | GET | `/profile/achievements` | 3 |
| P3 | GET | `/public/verify-certificate` | 3 |

---

## Notes for Developer

1. **Event cards in feed:** The social feed already has a `cme_card.blade.php`. Add a `CmeEventFeedCard` widget in `SVPostComponent` area to surface CME events in the main social feed.

2. **Agora channel naming:** CME uses `cme_event_{uuid}` as channel names — ensure no collision with existing call channels.

3. **Auth token:** Same `AppData.userToken` as all other API calls. No separate CME auth.

4. **Pagination:** All list endpoints support `?page=N&per_page=15`. Use infinite scroll pattern already established in other list screens.

5. **Plans gate:** Event creation is gated by `can_use_feature('cme_credits', 'create')`. Show upgrade prompt if API returns 403 on event creation.

6. **Offline behaviour:** Cache last-fetched events list and certificates list in Hive/shared_prefs for offline browsing. Quiz auto-save should queue requests if offline.

7. **Compliance deadline warning:** On app launch, check `compliance.daysRemaining < 90 && compliance.percentage < 75` and show a home-screen banner.
