import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/core/utils/saved_login_credentials.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/blog/blog_detail_screen.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_detail_screen.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deep Link Types supported by the app
enum DeepLinkType {
  post,
  job,
  jobManage,
  conference,
  meeting,
  call,
  profile,
  organization,
  group,
  blog,
  discussCase,
  emailVerify,
  login,
  unknown,
}

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

  /// Base URL for generating shareable links (always the live public site).
  static String get baseUrl => AppEnvironment.publicWebUrl;

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
        final segment = pathSegments.first.toLowerCase();
        switch (segment) {
          case 'post':
          case 'posts':
            type = DeepLinkType.post;
            if (pathSegments.length > 1) id = pathSegments[1];
            break;
          case 'job':
          case 'jobs':
            type = DeepLinkType.job;
            if (pathSegments.length > 1) id = pathSegments[1];
            break;
          case 'profile':
          case 'user':
            type = DeepLinkType.profile;
            if (pathSegments.length > 1) id = pathSegments[1];
            break;
          case 'login':
            type = DeepLinkType.login;
            break;
          case 'verify-email':
          case 'verify_email':
            type = DeepLinkType.emailVerify;
            break;
        }
        if (type != DeepLinkType.unknown) {
          debugPrint('🔗 DeepLinkService: Parsed custom scheme path: type=$type, id=$id');
          return DeepLinkData(
            type: type,
            id: id,
            queryParams: Map<String, String>.from(queryParams),
            originalUri: uri,
          );
        }
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
          case 'group':
          case 'groups':
            type = DeepLinkType.group;
            break;
          case 'login':
            type = DeepLinkType.login;
            break;
          case 'verify-email':
          case 'verify_email':
            type = DeepLinkType.emailVerify;
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
          // /jobs/manage/{id} or /jobs/manage/{id}/payment-success
          if (pathSegments.length >= 3 &&
              pathSegments[1].toLowerCase() == 'manage') {
            type = DeepLinkType.jobManage;
            id = pathSegments[2];
          } else {
            type = DeepLinkType.job;
            if (pathSegments.length > 1) {
              id = pathSegments[1];
            } else if (queryParams.containsKey('id')) {
              id = queryParams['id'];
            }
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
        case 'join-meeting':
          type = DeepLinkType.meeting;
          if (pathSegments.length >= 3 &&
              pathSegments[1].toLowerCase() == 'live') {
            id = pathSegments[2];
          } else if (pathSegments.length > 1) {
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
        case 'u': // username-based profile URL
          type = DeepLinkType.profile;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'b':
        case 'business':
        case 'org':
        case 'organizations':
          type = DeepLinkType.organization;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('slug')) {
            id = queryParams['slug'];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'group':
        case 'groups':
          type = DeepLinkType.group;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'blog':
        case 'blogs':
        case 'article':
        case 'articles':
          type = DeepLinkType.blog;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'discuss-case':
        case 'discuss_case':
        case 'case':
        case 'cases':
          type = DeepLinkType.discussCase;
          if (pathSegments.length > 1) {
            id = pathSegments[1];
          } else if (queryParams.containsKey('id')) {
            id = queryParams['id'];
          }
          break;

        case 'verify-email':
        case 'verify_email':
          type = DeepLinkType.emailVerify;
          break;

        case 'login':
          type = DeepLinkType.login;
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

    // Email verification + post-verify login links work without an existing session.
    if (deepLink.type == DeepLinkType.emailVerify) {
      return await _handleEmailVerifyDeepLink(context, deepLink);
    }
    if (deepLink.type == DeepLinkType.login &&
        (deepLink.queryParams['verified'] == '1' || deepLink.queryParams['verified'] == 'already')) {
      return await _handleLoginVerifiedDeepLink(context, deepLink);
    }
    if (deepLink.type == DeepLinkType.login && deepLink.queryParams['reset'] == '1') {
      return await _handleLoginPasswordResetDeepLink(context, deepLink);
    }

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

        case DeepLinkType.jobManage:
          return await _handleJobManageDeepLink(context, deepLink);

        case DeepLinkType.conference:
          return await _handleConferenceDeepLink(context, deepLink);

        case DeepLinkType.meeting:
          return await _handleMeetingDeepLink(context, deepLink);

        case DeepLinkType.call:
          return await _handleCallDeepLink(context, deepLink);

        case DeepLinkType.profile:
          return await _handleProfileDeepLink(context, deepLink);

        case DeepLinkType.organization:
          return await _handleOrganizationDeepLink(context, deepLink);

        case DeepLinkType.group:
          return await _handleGroupDeepLink(context, deepLink);

        case DeepLinkType.blog:
          return await _handleBlogDeepLink(context, deepLink);

        case DeepLinkType.discussCase:
          return await _handleDiscussCaseDeepLink(context, deepLink);

        case DeepLinkType.emailVerify:
          return await _handleEmailVerifyDeepLink(context, deepLink);

        case DeepLinkType.login:
          return await _handleLoginVerifiedDeepLink(context, deepLink);

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

  /// Handle /jobs/manage/{id} (e.g. return from Stripe promotion payment)
  Future<bool> _handleJobManageDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final jobId = deepLink.id;
    final promo = deepLink.queryParams['promo'];
    debugPrint('🔗 DeepLinkService: Navigating to jobs manage: $jobId promo=$promo');

    if (!context.mounted) return false;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => JobsScreen(manageJobId: jobId),
      ),
      (route) => false,
    );

    // Toast after navigation frame so it isn't lost under the route transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (promo == 'ok') {
        toast('Promotion payment successful');
      } else if (promo == 'cancel') {
        toast('Payment cancelled — listing saved as free');
      } else if (promo == 'error') {
        toast('Payment received but verification failed. Contact support if needed.');
      }
    });
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

  /// Handle call deep link.
  ///
  /// Calls are delivered exclusively through calling_module_v2 (FCM data push +
  /// CallKit), never via an app deep link, so this is intentionally a no-op.
  Future<bool> _handleCallDeepLink(BuildContext context, DeepLinkData deepLink) async {
    debugPrint('🔗 DeepLinkService: call deep links are handled by calling_module_v2 — ignoring');
    return false;
  }

  /// Handle business organization profile deep link (`/b/{slug}`).
  Future<bool> _handleOrganizationDeepLink(
    BuildContext context,
    DeepLinkData deepLink,
  ) async {
    final identifier = deepLink.id?.trim();
    if (identifier == null || identifier.isEmpty) {
      debugPrint('🔗 DeepLinkService: Organization slug/id is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to organization: $identifier');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OrganizationProfileScreen(identifier: identifier),
      ),
      (route) => false,
    );

    return true;
  }

  /// Handle group profile deep link (`/groups/{id}?invite={invitationId}`).
  Future<bool> _handleGroupDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final groupId = deepLink.id?.trim();
    if (groupId == null || groupId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Group ID is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    final invitationId = deepLink.queryParams['invite'];

    debugPrint('🔗 DeepLinkService: Navigating to group: $groupId invite=$invitationId');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(
          groupId: groupId,
          pendingInvitationId: invitationId,
        ),
      ),
      (route) => false,
    );

    return true;
  }

  /// Handle discuss-case deep link (`/discuss-case/{id}`).
  Future<bool> _handleDiscussCaseDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final caseIdRaw = deepLink.id?.trim();
    final caseId = int.tryParse(caseIdRaw ?? '');
    if (caseId == null) {
      debugPrint('🔗 DeepLinkService: Invalid discuss-case id: $caseIdRaw');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to discuss case: $caseId');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DiscussionDetailScreen(caseId: caseId)),
      (route) => false,
    );
    return true;
  }

  /// Handle blog/article deep link (`/blogs/{id}` or `/articles/{id}`).
  Future<bool> _handleBlogDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final blogId = deepLink.id?.trim();
    if (blogId == null || blogId.isEmpty) {
      debugPrint('🔗 DeepLinkService: Blog ID is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to blog: $blogId');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => BlogDetailScreen(blogId: blogId),
      ),
      (route) => false,
    );

    return true;
  }

  /// Handle profile deep link
  Future<bool> _handleProfileDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final userId = deepLink.id;
    if (userId == null || userId.isEmpty) {
      debugPrint('🔗 DeepLinkService: User ID is missing');
      const SVDashboardScreen().launch(context, isNewTask: true);
      return false;
    }

    debugPrint('🔗 DeepLinkService: Navigating to profile: $userId');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SVProfileFragment(userId: userId)),
      (route) => false,
    );

    return true;
  }

  /// Opened from https://doctak.net/verify-email?token=... (Universal / App Link).
  Future<bool> _handleEmailVerifyDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final token = deepLink.queryParams['token']?.trim() ?? '';
    if (token.isEmpty) {
      toast('Verification link is missing a token.');
      return false;
    }

    try {
      final base = AppEnvironment.nodeApiUrl.replaceAll(RegExp(r'/$'), '');
      // Server page verifies the token when loaded.
      final response = await http.get(Uri.parse('$base/verify-email?token=${Uri.encodeComponent(token)}'));
      final body = response.body;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 400 &&
          !body.contains('Verification link invalid') &&
          !body.contains('error=invalid');

      if (!ok) {
        toast('That verification link is invalid or expired.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_verified_at', DateTime.now().toIso8601String());
      if (context.mounted) {
        toast('Email verified successfully');
        if (AppData.userToken != null && AppData.userToken!.isNotEmpty) {
          const SVDashboardScreen().launch(context, isNewTask: true);
        }
      }
      return true;
    } catch (e) {
      debugPrint('🔗 DeepLinkService: email verify failed: $e');
      toast('Could not verify email. Open the link in your browser.');
      return false;
    }
  }

  /// Website verified then bounced back via doctak://open/login?verified=1
  Future<bool> _handleLoginVerifiedDeepLink(BuildContext context, DeepLinkData deepLink) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_verified_at', DateTime.now().toIso8601String());
    if (context.mounted) {
      toast('Email verified');
      if (AppData.userToken != null && AppData.userToken!.isNotEmpty) {
        const SVDashboardScreen().launch(context, isNewTask: true);
      }
    }
    return true;
  }

  /// Password reset completed on web → doctak://open/login?reset=1
  Future<bool> _handleLoginPasswordResetDeepLink(BuildContext context, DeepLinkData deepLink) async {
    await SavedLoginCredentials.prepareForNewPasswordLogin();

    // Drop any cached session so splash/auto-login cannot skip the new password.
    AppData.userToken = null;
    AppData.logInUserId = null;
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.remove('token');
      await prefs.remove('token_expires_at');
      await prefs.setBool('rememberMe', false);
    } catch (_) {
      // Login screen still works even if secure storage clear fails.
    }

    if (context.mounted) {
      toast('Password updated. Sign in with your new password.');
      const LoginScreen().launch(context, isNewTask: true);
    }
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

  /// Generate a shareable link for a meeting.
  /// Points to the public meeting page: /meetings/live/{channel}
  static String generateMeetingLink(String meetingId, {String? title}) {
    return '$baseUrl/meetings/live/$meetingId';
  }

  /// Generate a shareable link for a blog/article.
  static String generateBlogLink(String blogId, {String? slug}) {
    if (slug != null && slug.isNotEmpty) {
      return '$baseUrl/blogs/$slug';
    }
    return '$baseUrl/blogs/$blogId';
  }

  /// Generate a shareable link for a case discussion.
  static String generateCaseLink(int caseId) {
    return '$baseUrl/discuss-case/$caseId';
  }

  /// Generate a shareable link for a group.
  static String generateGroupLink(String groupSlugOrId) {
    return '$baseUrl/groups/$groupSlugOrId';
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
    JobsNodeApiService.track(jobId, type: 'share');
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

  /// Generate a shareable link for a user profile
  static String generateProfileLink(String userId, {String? username}) {
    // Use username-based URL if available for cleaner links
    if (username != null && username.isNotEmpty) {
      return '$baseUrl/u/$username';
    }
    return '$baseUrl/profile/$userId';
  }

  /// Share a user profile via system share sheet
  static Future<void> shareProfile({required String userId, String? name, String? username}) async {
    final link = generateProfileLink(userId, username: username);
    final shareText = (name != null && name.isNotEmpty)
        ? 'Check out $name\'s profile on DocTak\n\n$link'
        : 'Check out this profile on DocTak\n\n$link';

    await SharePlus.instance.share(ShareParams(text: shareText, title: name ?? 'DocTak Profile'));
  }
}

/// Global instance for easy access
final deepLinkService = DeepLinkService();
