import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Deep Link Types supported by the app
enum DeepLinkType { post, job, conference, meeting, call, profile, unknown }

/// Model class to hold parsed deep link data
class DeepLinkData {
  final DeepLinkType type;
  final String? id;
  final Map<String, String> queryParams;
  final Uri originalUri;

  DeepLinkData({required this.type, this.id, required this.queryParams, required this.originalUri});

  @override
  String toString() {
    return 'DeepLinkData(type: $type, id: $id, params: $queryParams)';
  }
}

/// Service to handle deep linking throughout the app
/// Uses app_links package for handling incoming links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Pending deep link to be handled after login
  DeepLinkData? _pendingDeepLink;

  /// Flag to track initialization
  bool _isInitialized = false;

  /// Base URL for generating shareable links
  static const String baseUrl = 'https://doctak.net';

  /// Getters
  DeepLinkData? get pendingDeepLink => _pendingDeepLink;
  bool get hasPendingDeepLink => _pendingDeepLink != null;

  /// Initialize the deep link service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _appLinks = AppLinks();
      _isInitialized = true;
      debugPrint('🔗 DeepLinkService: Initialized successfully');
    } catch (e) {
      debugPrint('🔗 DeepLinkService: Error initializing: $e');
    }
  }

  /// Get the initial/cold start deep link
  Future<Uri?> getInitialLink() async {
    if (!_isInitialized) await initialize();

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 DeepLinkService: Initial link received: $initialLink');
      }
      return initialLink;
    } catch (e) {
      debugPrint('🔗 DeepLinkService: Error getting initial link: $e');
      return null;
    }
  }

  /// Listen for incoming deep links when app is running
  void listenForLinks(void Function(Uri uri) onLink) {
    if (!_isInitialized) {
      debugPrint('🔗 DeepLinkService: Not initialized, cannot listen for links');
      return;
    }

    // Cancel existing subscription
    _linkSubscription?.cancel();

    // Start listening
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 DeepLinkService: Link received: $uri');
        onLink(uri);
      },
      onError: (error) {
        debugPrint('🔗 DeepLinkService: Error receiving link: $error');
      },
    );

    debugPrint('🔗 DeepLinkService: Now listening for deep links');
  }

  /// Parse a deep link URI into DeepLinkData
  DeepLinkData parseDeepLink(Uri uri) {
    debugPrint('🔗 DeepLinkService: Parsing URI: $uri');
    debugPrint('🔗 DeepLinkService: Scheme: ${uri.scheme}');
    debugPrint('🔗 DeepLinkService: Host: ${uri.host}');
    debugPrint('🔗 DeepLinkService: Path: ${uri.path}');
    debugPrint('🔗 DeepLinkService: Path segments: ${uri.pathSegments}');

    var pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    DeepLinkType type = DeepLinkType.unknown;
    String? id;

    // Handle custom URL scheme: doctak://open/post/123
    // or doctak://open?type=post&id=123
    if (uri.scheme == 'doctak') {
      if (uri.host == 'open' && pathSegments.isNotEmpty) {
        // doctak://open/post/123 format
        // pathSegments would be ['post', '123']
      } else if (queryParams.containsKey('type')) {
        // doctak://open?type=post&id=123 format
        final typeParam = queryParams['type']?.toLowerCase();
        id = queryParams['id'];
        switch (typeParam) {
          case 'post':
            type = DeepLinkType.post;
            break;
          case 'job':
            type = DeepLinkType.job;
            break;
          case 'conference':
            type = DeepLinkType.conference;
            break;
          case 'meeting':
            type = DeepLinkType.meeting;
            break;
          case 'call':
            type = DeepLinkType.call;
            break;
          case 'profile':
            type = DeepLinkType.profile;
            break;
        }
        if (type != DeepLinkType.unknown) {
          debugPrint('🔗 DeepLinkService: Parsed custom scheme: type=$type, id=$id');
          return DeepLinkData(type: type, id: id, queryParams: Map<String, String>.from(queryParams), originalUri: uri);
        }
      }
    }

    if (pathSegments.isNotEmpty) {
      final firstSegment = pathSegments.first.toLowerCase();

      switch (firstSegment) {
        case 'post':
        case 'posts':
          type = DeepLinkType.post;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'job':
        case 'jobs':
          type = DeepLinkType.job;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'conference':
        case 'conferences':
          type = DeepLinkType.conference;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'meeting':
        case 'meetings':
          type = DeepLinkType.meeting;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'call':
        case 'calls':
          type = DeepLinkType.call;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'profile':
        case 'user':
          type = DeepLinkType.profile;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        default:
          // Check if it's a numeric ID directly (legacy format)
          if (int.tryParse(firstSegment) != null) {
            // Could be a post ID directly
            id = firstSegment;
            type = DeepLinkType.post;
          }
          break;
      }
    }

    // Also check query parameters for ID if not found
    if (id == null || id.isEmpty) {
      id = queryParams['post_id'] ?? queryParams['job_id'] ?? queryParams['meeting_id'] ?? queryParams['conference_id'] ?? queryParams['id'];
    }

    final result = DeepLinkData(type: type, id: id, queryParams: Map<String, String>.from(queryParams), originalUri: uri);

    debugPrint('🔗 DeepLinkService: Parsed result: $result');
    return result;
  }

  /// Store a deep link to be handled after user is authenticated
  void storePendingDeepLink(DeepLinkData deepLink) {
    _pendingDeepLink = deepLink;
    debugPrint('🔗 DeepLinkService: Stored pending deep link: $deepLink');
  }

  /// Clear the pending deep link
  void clearPendingDeepLink() {
    _pendingDeepLink = null;
    debugPrint('🔗 DeepLinkService: Cleared pending deep link');
  }

  /// Handle and navigate based on deep link data
  /// Returns true if navigation was successful
  Future<bool> handleDeepLink(BuildContext context, DeepLinkData deepLink) async {
    debugPrint('🔗 DeepLinkService: Handling deep link: $deepLink');

    // Check if user is logged in
    if (AppData.userToken == null || AppData.userToken!.isEmpty) {
      debugPrint('🔗 DeepLinkService: User not logged in, storing pending link');
      storePendingDeepLink(deepLink);
      return false;
    }

    try {
      switch (deepLink.type) {
        case DeepLinkType.post:
          return await _handlePostDeepLink(context, deepLink);

        case DeepLinkType.job:
          return await _handleJobDeepLink(context, deepLink);

        case DeepLinkType.conference:
          return await _handleConferenceDeepLink(context, deepLink);

        case DeepLinkType.meeting:
          return await _handleMeetingDeepLink(context, deepLink);

        case DeepLinkType.call:
          return await _handleCallDeepLink(context, deepLink);

        case DeepLinkType.profile:
          // Profile deep link - can be implemented later
          debugPrint('🔗 DeepLinkService: Profile deep links not yet implemented');
          return false;

        case DeepLinkType.unknown:
          debugPrint('🔗 DeepLinkService: Unknown deep link type, navigating to dashboard');
          const SVDashboardScreen().launch(context, isNewTask: true);
          return true;
      }
    } catch (e) {
      debugPrint('🔗 DeepLinkService: Error handling deep link: $e');
      // On error, navigate to dashboard
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }
  }

  /// Handle post deep link
  Future<bool> _handlePostDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final postId = deepLink.id;
    if (postId == null || postId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Post ID is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    final parsedId = int.tryParse(postId);
    if (parsedId == null) {
      debugPrint('🔗 DeepLinkService: Invalid post ID: $postId');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to post details: $parsedId');

    // Navigate to post details screen
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: parsedId)), (route) => false);

    return true;
  }

  /// Handle job deep link
  Future<bool> _handleJobDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final jobId = deepLink.id;
    if (jobId == null || jobId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Job ID is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to job details: $jobId');

    // Navigate to job details screen
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => JobsDetailsScreen(jobId: jobId, isFromSplash: true)), (route) => false);

    return true;
  }

  /// Handle conference deep link
  Future<bool> _handleConferenceDeepLink(BuildContext context, DeepLinkData deepLink) async {
    debugPrint('🔗 DeepLinkService: Navigating to conferences screen');

    // Navigate to conferences screen
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const ConferencesScreen(isFromSplash: true)), (route) => false);

    return true;
  }

  /// Handle meeting deep link
  Future<bool> _handleMeetingDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final meetingId = deepLink.id;

    debugPrint('🔗 DeepLinkService: Navigating to meeting: $meetingId');

    if (meetingId == null || meetingId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Meeting ID is missing');
      // Navigate to dashboard if no meeting ID
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    // Navigate to ManageMeetingScreen with auto-join enabled
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => ManageMeetingScreen(meetingCode: meetingId, autoJoin: true)), (route) => false);

    return true;
  }

  /// Handle call deep link
  Future<bool> _handleCallDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final callId = deepLink.id;
    if (callId == null || callId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Call ID is missing');
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to call: $callId');

    // Extract call parameters from query params
    final params = deepLink.queryParams;
    final contactId = params['contact_id'] ?? params['user_id'] ?? '';
    final contactName = params['name'] ?? 'Unknown';
    final contactAvatar = params['avatar'] ?? '';
    final isVideo = params['video'] == 'true' || params['has_video'] == 'true';

    // Navigate to call screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => CallScreen(callId: callId, contactId: contactId, contactName: contactName, contactAvatar: contactAvatar, isIncoming: true, isVideoCall: isVideo),
      ),
      (route) => false,
    );

    return true;
  }

  /// Handle any pending deep link after user logs in
  Future<bool> handlePendingDeepLink(BuildContext context) async {
    if (_pendingDeepLink == null) {
      debugPrint('🔗 DeepLinkService: No pending deep link');
      return false;
    }

    final result = await handleDeepLink(context, _pendingDeepLink!);
    clearPendingDeepLink();
    return result;
  }

  /// Cancel link subscription
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('🔗 DeepLinkService: Disposed');
  }

  // ============== SHARE LINK GENERATION ==============

  /// Generate a shareable link for a post
  static String generatePostLink(int postId, {String? title}) {
    return '$baseUrl/post/$postId';
  }

  /// Generate a shareable link for a job
  static String generateJobLink(String jobId, {String? title}) {
    return '$baseUrl/job/$jobId';
  }

  /// Generate a shareable link for a conference
  static String generateConferenceLink(String conferenceId, {String? title}) {
    return '$baseUrl/conference/$conferenceId';
  }

  /// Generate a shareable link for a meeting
  static String generateMeetingLink(String meetingId, {String? title}) {
    return '$baseUrl/meeting/$meetingId';
  }

  /// Generate a shareable link for a call
  static String generateCallLink(String callId, {String? contactId, String? contactName, bool isVideo = false}) {
    final params = <String, String>{};
    if (contactId != null) params['contact_id'] = contactId;
    if (contactName != null) params['name'] = contactName;
    if (isVideo) params['video'] = 'true';

    final queryString = params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}' : '';

    return '$baseUrl/call/$callId$queryString';
  }

  /// Share a post via system share sheet
  static Future<void> sharePost({required int postId, String? title, String? description}) async {
    final link = generatePostLink(postId, title: title);
    final shareText = title != null ? '$title\n\n$link' : 'Check out this post on DocTak\n\n$link';

    await Share.share(shareText, subject: title ?? 'DocTak Post');
  }

  /// Share a job via system share sheet
  static Future<void> shareJob({required String jobId, String? title, String? company, String? location}) async {
    final link = generateJobLink(jobId, title: title);

    String shareText = 'Check out this job opportunity on DocTak';
    if (title != null) shareText = title;
    if (company != null) shareText += ' at $company';
    if (location != null) shareText += ' - $location';
    shareText += '\n\n$link';

    await Share.share(shareText, subject: title ?? 'DocTak Job Opportunity');
  }

  /// Share a conference via system share sheet
  static Future<void> shareConference({required String conferenceId, String? title, String? date, String? location}) async {
    final link = generateConferenceLink(conferenceId, title: title);

    String shareText = 'Check out this conference on DocTak';
    if (title != null) shareText = title;
    if (date != null) shareText += '\nDate: $date';
    if (location != null) shareText += '\nLocation: $location';
    shareText += '\n\n$link';

    await Share.share(shareText, subject: title ?? 'DocTak Conference');
  }

  /// Share a meeting link via system share sheet
  static Future<void> shareMeeting({required String meetingId, String? title, String? date, String? time}) async {
    final link = generateMeetingLink(meetingId, title: title);

    String shareText = 'Join my meeting on DocTak';
    if (title != null) shareText = 'Join: $title';
    if (date != null) shareText += '\nDate: $date';
    if (time != null) shareText += '\nTime: $time';
    shareText += '\n\nClick to join:\n$link';

    await Share.share(shareText, subject: title ?? 'DocTak Meeting Invitation');
  }
}

/// Global instance for easy access
final deepLinkService = DeepLinkService();
