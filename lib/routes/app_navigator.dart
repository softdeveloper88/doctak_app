import 'package:flutter/material.dart';

import 'package:doctak_app/core/utils/common_navigator.dart'
    show PageRouteAnimation, buildPageRoute;
import 'package:doctak_app/core/utils/navigator_service.dart';

// Typed destinations.
import 'package:doctak_app/presentation/complete_profile/complete_profile_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/diagnosis_module/screens/diagnosis_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/presentation/web_screen/web_page_screen.dart';

/// Centralized, type-safe navigation for the whole app.
///
/// This is the single entry point every screen change should go through. It has
/// two layers:
///
///  * **Primitives** ([push], [pushReplacement], [pushAndRemoveAll], [pop], …)
///    centralize *how* the app navigates — route construction, transition
///    animations (via [buildPageRoute]) and the shared navigator key. Use these
///    directly for one-off destinations or screens that must be wrapped (e.g. a
///    screen wrapped in a `BlocProvider`).
///
///  * **Typed destinations** (`toDashboard`, `toProfile`, `toJobDetails`, …)
///    centralize *where* the app navigates — a single, discoverable place that
///    knows each screen's constructor. Prefer these at call sites.
///
/// Navigation triggered from *outside* the widget tree (push notifications,
/// background services, deep links) should use the `…Global` variants, which
/// rely on [NavigatorService.navigatorKey] — the key wired into the root
/// `MaterialApp`.
class AppNavigator {
  AppNavigator._();

  // ---------------------------------------------------------------------------
  // Primitives (context based)
  // ---------------------------------------------------------------------------

  /// Pushes [screen] onto the current navigator.
  static Future<T?> push<T>(
    BuildContext context,
    Widget screen, {
    PageRouteAnimation? animation,
    Duration? duration,
  }) {
    return Navigator.of(context).push<T>(
      buildPageRoute<T>(screen, animation, duration),
    );
  }

  /// Replaces the current route with [screen].
  static Future<T?> pushReplacement<T>(
    BuildContext context,
    Widget screen, {
    PageRouteAnimation? animation,
    Duration? duration,
  }) {
    return Navigator.of(context).pushReplacement<T, dynamic>(
      buildPageRoute<T>(screen, animation, duration),
    );
  }

  /// Pushes [screen] and removes every route beneath it (a fresh stack).
  static Future<T?> pushAndRemoveAll<T>(
    BuildContext context,
    Widget screen, {
    PageRouteAnimation? animation,
    Duration? duration,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      buildPageRoute<T>(screen, animation, duration),
      (route) => false,
    );
  }

  /// Pops the current route, optionally returning [result].
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Pops only when there is a route to pop (no-op otherwise).
  static Future<bool> maybePop<T>(BuildContext context, [T? result]) {
    return Navigator.of(context).maybePop<T>(result);
  }

  /// Whether the current navigator has a route it can pop.
  static bool canPop(BuildContext context) => Navigator.of(context).canPop();

  // ---------------------------------------------------------------------------
  // Primitives (global key — use outside the widget tree)
  // ---------------------------------------------------------------------------

  static NavigatorState? get _rootNavigator =>
      NavigatorService.navigatorKey.currentState;

  /// Pushes [screen] using the root navigator key. Returns `null` when no
  /// navigator is attached yet.
  static Future<T?> pushGlobal<T>(
    Widget screen, {
    PageRouteAnimation? animation,
    Duration? duration,
  }) async {
    final navigator = _rootNavigator;
    if (navigator == null) return null;
    return navigator.push<T>(buildPageRoute<T>(screen, animation, duration));
  }

  /// Pushes [screen] using the root navigator key and clears the stack.
  static Future<T?> pushAndRemoveAllGlobal<T>(
    Widget screen, {
    PageRouteAnimation? animation,
    Duration? duration,
  }) async {
    final navigator = _rootNavigator;
    if (navigator == null) return null;
    return navigator.pushAndRemoveUntil<T>(
      buildPageRoute<T>(screen, animation, duration),
      (route) => false,
    );
  }

  /// Pops the root navigator (e.g. dismissing an overlay shown from a service).
  static void popGlobal<T>([T? result]) => _rootNavigator?.pop<T>(result);

  // ---------------------------------------------------------------------------
  // Typed destinations
  // ---------------------------------------------------------------------------

  /// Home dashboard. Clears the back stack by default (post-login / logout).
  static Future<T?> toDashboard<T>(
    BuildContext context, {
    bool clearStack = true,
  }) {
    const screen = SVDashboardScreen();
    return clearStack
        ? pushAndRemoveAll<T>(context, screen,
            animation: PageRouteAnimation.Slide)
        : push<T>(context, screen);
  }

  /// A user's profile. Pass [userId] for another user, omit for the current one.
  static Future<T?> toProfile<T>(
    BuildContext context, {
    String? userId,
    bool viewAsPublic = false,
  }) {
    return push<T>(
      context,
      SVProfileFragment(userId: userId, viewAsPublic: viewAsPublic),
    );
  }

  /// Organization / business public profile.
  static Future<T?> toOrganizationProfile<T>(
    BuildContext context,
    String identifier,
  ) {
    return push<T>(
      context,
      OrganizationProfileScreen(identifier: identifier),
    );
  }

  /// People or business profile based on supplied fields.
  static void openActorProfile(
    BuildContext context, {
    String? userId,
    String? organizationId,
    String? organizationSlug,
    bool? isBusinessPagePost,
    String? accountType,
    bool viewAsPublic = false,
  }) {
    ProfileNavigation.open(
      context,
      userId: userId,
      organizationId: organizationId,
      organizationSlug: organizationSlug,
      isBusinessPagePost: isBusinessPagePost,
      accountType: accountType,
      viewAsPublic: viewAsPublic,
    );
  }

  /// Login screen. Clears the back stack by default (logout / session expiry).
  static Future<T?> toLogin<T>(
    BuildContext context, {
    bool clearStack = true,
  }) {
    const screen = LoginScreen();
    return clearStack
        ? pushAndRemoveAll<T>(context, screen)
        : push<T>(context, screen);
  }

  /// Sign-up screen, optionally pre-filled from a social login.
  static Future<T?> toSignUp<T>(
    BuildContext context, {
    bool isSocialLogin = false,
    String? firstName,
    String? lastName,
    String? email,
    String? token,
  }) {
    return push<T>(
      context,
      SignUpScreen(
        isSocialLogin: isSocialLogin,
        firstName: firstName,
        lastName: lastName,
        email: email,
        token: token,
      ),
    );
  }

  /// Complete-profile flow.
  static Future<T?> toCompleteProfile<T>(BuildContext context) =>
      push<T>(context, const CompleteProfileScreen());

  /// Subscription / paywall screen.
  static Future<T?> toSubscription<T>(BuildContext context) =>
      push<T>(context, const SubscriptionScreen());

  /// Terms & conditions screen.
  static Future<T?> toTermsAndConditions<T>(BuildContext context) =>
      push<T>(context, const TermsAndConditionScreen());

  /// In-app web view / HTML renderer.
  static Future<T?> toWebPage<T>(
    BuildContext context, {
    String url = '',
    String pageName = '',
    String htmlString = '',
    bool hasHeaders = false,
    bool isHtml = false,
  }) {
    return push<T>(
      context,
      WebPageScreen(
        url: url,
        pageName: pageName,
        htmlString: htmlString,
        hasHeaders: hasHeaders,
        isHtml: isHtml,
      ),
    );
  }

  /// Job posting details.
  static Future<T?> toJobDetails<T>(
    BuildContext context, {
    required String jobId,
    bool isFromSplash = false,
  }) {
    return push<T>(
      context,
      JobsDetailsScreen(jobId: jobId, isFromSplash: isFromSplash),
    );
  }

  /// Post details — pass either [postId] or [commentId].
  static Future<T?> toPostDetails<T>(
    BuildContext context, {
    int? postId,
    int? commentId,
  }) {
    return push<T>(
      context,
      PostDetailsScreen(postId: postId, commentId: commentId),
    );
  }

  /// CME event detail.
  static Future<T?> toCmeEventDetail<T>(
    BuildContext context, {
    required String eventId,
  }) {
    return push<T>(context, CmeEventDetailScreen(eventId: eventId));
  }

  /// Diagnosis detail.
  static Future<T?> toDiagnosisDetail<T>(
    BuildContext context, {
    required int diagnosisId,
  }) {
    return push<T>(context, DiagnosisDetailScreen(diagnosisId: diagnosisId));
  }
}
