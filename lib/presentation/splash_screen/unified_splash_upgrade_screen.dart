import 'dart:async';
import 'dart:convert';
import 'dart:io';

// TODO: app_links temporarily disabled due to SDK compatibility
// import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/notification_navigation.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/incoming_share_service.dart';
import 'package:doctak_app/core/utils/session_manager.dart';
import 'package:doctak_app/presentation/age_assurance/age_assurance_screen.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/language_selection_screen/language_selection_screen.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/splash_branding.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

enum ScreenState { loading, upgrade, splash }

class UnifiedSplashUpgradeScreen extends StatefulWidget {
  const UnifiedSplashUpgradeScreen({super.key});

  @override
  State<UnifiedSplashUpgradeScreen> createState() =>
      _UnifiedSplashUpgradeScreenState();
}

// Custom painter for light beam effect
class LightBeamPainter extends CustomPainter {
  final Color color;

  LightBeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw a gentle curve from top right to center
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UnifiedSplashUpgradeScreenState extends State<UnifiedSplashUpgradeScreen>
    with SingleTickerProviderStateMixin {
  ScreenState _currentState = ScreenState.loading;

  // Version information
  String _versionNumber = '';
  String _latestVersionString = '';
  String _currentVersionString = '';
  String _upgradeMessage = '';
  String? _updateUrl;
  bool? _isSkippible;
  PackageInfo? _packageInfo;

  // Animation controller
  late AnimationController _animationController;

  // Deep linking - TODO: AppLinks temporarily disabled due to SDK compatibility
  // late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  DateTime? _splashStart;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Main initialization method
  Future<void> _initialize() async {
    // Get package info
    await _initializePackageInfo();

    // Check app version
    await _checkAppVersion();

    // If no update is required, proceed with normal splash screen flow
    if (_currentState == ScreenState.splash) {
      await _initializeSplashScreen();
    }
  }

  // Initialize package info
  Future<void> _initializePackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionNumber = _packageInfo!.version;
          _currentVersionString = _packageInfo!.version;
        });
      }
    } catch (e) {
      debugPrint('Error getting version info: $e');
    }
  }

  bool _isMandatoryValue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  // Check if app needs updating
  Future<void> _checkAppVersion() async {
    if (_packageInfo != null) {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final latestVersionInfo = await _fetchLatestVersion();
      var latestVersion;
      String? latestVersionLocal;
      var mandatory = false;
      String upgradeMessage = '';
      String? updateUrl;

      if (latestVersionInfo.isNotEmpty && latestVersionInfo['data'] != null) {
        final data = latestVersionInfo['data'] as Map<String, dynamic>;
        latestVersion = data['version'];
        await prefs.setString('latest_version', '$latestVersion');
        latestVersionLocal = await prefs.getString('latest_version');
        mandatory = _isMandatoryValue(data['mandatory']);
        upgradeMessage = (data['message'] as String?)?.trim() ?? '';
        updateUrl = (data['update_url'] as String?)?.trim();
        if (updateUrl != null && updateUrl.isEmpty) updateUrl = null;
        if (mounted) {
          setState(() {
            _latestVersionString = latestVersionLocal ?? '';
            _currentVersionString = _packageInfo!.version;
            _upgradeMessage = upgradeMessage;
            _updateUrl = updateUrl;
          });
        }
      } else {
        latestVersionLocal = await prefs.getString('latest_version') ?? '1.0.1';
        if (mounted) {
          setState(() {
            _latestVersionString = latestVersionLocal ?? '1.0.1';
            _currentVersionString = _packageInfo!.version;
          });
        }
      }

      try {
        Version version1 = Version.parse(_packageInfo!.version);
        Version version2 = Version.parse(latestVersionLocal ?? '1.0.1');

        if (version1 < version2 && mandatory) {
          if (mounted) {
            setState(() {
              _isSkippible = false;
              _currentState = ScreenState.upgrade;
            });
          }
        } else if (version1 < version2 && !mandatory) {
          if (mounted) {
            setState(() {
              _isSkippible = true;
              _currentState = ScreenState.upgrade;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _currentState = ScreenState.splash;
            });
          }
        }
      } catch (e) {
        debugPrint('Error comparing versions: $e');
        if (mounted) {
          setState(() {
            _currentState = ScreenState.splash;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentState = ScreenState.splash;
        });
      }
    }
  }

  // Fetch latest version from server
  Future<Map<String, dynamic>> _fetchLatestVersion() async {
    try {
      http.Response response;
      if (Platform.isAndroid) {
        response = await http
            .get(Uri.parse('${AppData.remoteUrl}/version/Android'))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('Version check timed out');
                return http.Response('{}', 408); // Request timeout
              },
            );
      } else {
        response = await http
            .get(Uri.parse('${AppData.remoteUrl}/version/iOS'))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('Version check timed out');
                return http.Response('{}', 408);
              },
            );
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Version check failed with status: ${response.statusCode}');
        return <String, dynamic>{};
      }
    } catch (e) {
      debugPrint('Error fetching version: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _ensureMinSplashElapsed() async {
    if (_splashStart == null) return;
    final elapsed = DateTime.now().difference(_splashStart!);
    if (elapsed < SplashBranding.minDuration) {
      await Future.delayed(SplashBranding.minDuration - elapsed);
    }
  }

  // Initialize splash screen logic
  Future<void> _initializeSplashScreen() async {
    _splashStart = DateTime.now();
    try {
      setStatusBarColor(Colors.transparent);

      // Fire off dropdown data loads in background (non-blocking)
      // These are for settings/forms later, not required for login/navigation
      BlocProvider.of<SplashBloc>(
        context,
      ).add(LoadDropdownData('', '', '', ''));
      BlocProvider.of<SplashBloc>(context).add(LoadDropdownData1('', ''));

      // Proceed with user session initialization (with timeout)
      await _initializeUserSession().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            'User session initialization timed out, forcing navigation',
          );
          // Force navigation to login on timeout
          if (mounted) {
            LoginScreen().launch(context, isNewTask: true);
          }
        },
      );
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      // Fallback to login screen on any error
      if (mounted) {
        LoginScreen().launch(context, isNewTask: true);
      }
    }
  }

  // Initialize user session
  Future<void> _initializeUserSession() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    // Check if this is the first time opening the app
    bool isFirstTime = await prefs.getBool('is_first_time') ?? true;
    String? selectedLanguage = await prefs.getString('selected_language');

    // If first time or no language selected, show language selection screen
    if (isFirstTime || selectedLanguage == null) {
      await _ensureMinSplashElapsed();
      const LanguageSelectionScreen().launch(context, isNewTask: true);
      return;
    }

    bool rememberMe = await prefs.getBool('rememberMe') ?? false;
    String? userToken = await prefs.getString('token');
    String? userId = await prefs.getString('userId');

    // iOS keeps Keychain data after an uninstall, so a reinstall can still hold a
    // stale/revoked token and would auto-navigate to home. Validate it with the
    // server once per install. A normal app update keeps a valid token, so the
    // user is never logged out; only a genuinely invalid session routes to login.
    if (rememberMe && userToken != null && userToken.isNotEmpty) {
      final check = await SessionManager.verifyStoredSessionOncePerInstall(
        token: userToken,
        userId: userId,
      );
      if (check == SessionCheck.invalid) {
        userToken = null; // session was cleared — fall through to login below
      }
    }

    if (userToken != null) {
      // Initialize user data
      AppData.deviceToken = await prefs.getString('device_token') ?? '';
      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = await prefs.getString('name') ?? '';
      AppData.profile_pic = await prefs.getString('profile_pic') ?? '';
      AppData.profilePicNotifier.value = AppData.profilePicUrl;
      AppData.background = await prefs.getString('background') ?? '';
      AppData.email = await prefs.getString('email') ?? '';
      final rawSpecialty = await prefs.getString('specialty') ?? '';
      await SpecialtyDisplay.instance.ensureLoaded();
      final resolvedSpecialty =
          SpecialtyDisplay.instance.resolve(rawSpecialty).isNotEmpty
              ? SpecialtyDisplay.instance.resolve(rawSpecialty)
              : rawSpecialty;
      AppData.specialty = resolvedSpecialty;
      if (resolvedSpecialty != rawSpecialty && resolvedSpecialty.isNotEmpty) {
        await prefs.setString('specialty', resolvedSpecialty);
      }
      final isVerified = await prefs.getString('is_verified') ?? 'false';
      AppData.isVerified = isVerified == 'true';
      AppData.university = await prefs.getString('university') ?? '';
      AppData.userType = await prefs.getString('user_type') ?? '';
      AppData.city = await prefs.getString('city') ?? '';
      AppData.countryName = await prefs.getString('country') ?? '';
      AppData.currency = await prefs.getString('currency') ?? '';
      // Re-register FCM after restoring a remembered session (non-blocking).
      unawaited(NotificationService.syncDeviceToken());
      // Restore personal ↔ business workspace before opening the home shell.
      await ActingContextService.instance.initialize();
    }

    await _ensureMinSplashElapsed();

    if (rememberMe) {
      if (userToken != null) {
        await _initDeepLinks(context);
      } else {
        LoginScreen().launch(context, isNewTask: true);
      }
    } else {
      LoginScreen().launch(context, isNewTask: true);
    }
  }

  // Deep link initialization - using app_links package
  Future<void> _initDeepLinks(BuildContext context) async {
    try {
      // Check for initial deep link (cold start)
      final initialUri = await deepLinkService.getInitialLink();

      if (initialUri != null) {
        debugPrint('🔗 Splash: Initial deep link found: $initialUri');

        // Parse and handle the deep link
        final deepLinkData = deepLinkService.parseDeepLink(initialUri);

        if (deepLinkData.type != DeepLinkType.unknown) {
          // Handle the deep link navigation
          await deepLinkService.handleDeepLink(context, deepLinkData);
          return; // Deep link handled, don't navigate to dashboard
        }
      }

      // Check for any pending deep link stored before login
      if (deepLinkService.hasPendingDeepLink) {
        debugPrint('🔗 Splash: Handling pending deep link');
        await deepLinkService.handlePendingDeepLink(context);
        return;
      }

      // No deep link, navigate to dashboard (age assurance first if needed)
      await openAfterAgeAssurance(
        context,
        destination: const SVDashboardScreen(),
      );
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        await NotificationNavigation.consumePendingTap();
      }

      // Receive OS share intents (Chrome / WhatsApp → compose)
      unawaited(
        IncomingShareService.instance.start().then(
          (_) => IncomingShareService.instance.consumePending(),
        ),
      );

      // Start listening for future deep links
      deepLinkService.listenForLinks((uri) {
        debugPrint('🔗 Splash: Deep link received while app running: $uri');
        final deepLinkData = deepLinkService.parseDeepLink(uri);
        deepLinkService.handleDeepLink(context, deepLinkData);
      });
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
      // Always ensure we navigate somewhere on error
      if (mounted) {
        await openAfterAgeAssurance(
          context,
          destination: const SVDashboardScreen(),
        );
      }
    }
  }

  // Launch app store for update
  Future<void> _launchAppOrPlayStore() async {
    await AppSharedPreferences().clearSharedPreferencesData(context);

    final appId = Platform.isAndroid ? _packageInfo!.packageName : '6448684340';
    final fallbackUrl = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=$appId'
        : 'https://apps.apple.com/app/id$appId';
    final target = (_updateUrl != null && _updateUrl!.isNotEmpty)
        ? _updateUrl!
        : fallbackUrl;
    final url = Uri.tryParse(target);
    if (url == null) return;

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _currentState == ScreenState.loading
            ? _buildLoadingScreen()
            : _currentState == ScreenState.upgrade
            ? _buildUpgradeScreen()
            : _buildSplashScreen(),
      ),
    );
  }

  // MARK: - Loading Screen
  Widget _buildLoadingScreen() {
    final theme = OneUITheme.of(context);

    return Container(
      key: const ValueKey<String>('loadingScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackground,
            theme.surfaceVariant.withValues(alpha: 0.5),
            theme.primary.withValues(alpha: 0.05),
          ],
          stops: const [0.2, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background animated patterns
          Positioned.fill(
            child: Opacity(opacity: 0.1, child: _buildBackgroundPatterns()),
          ),
          // Logo and animations
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale and fade animations
                SplashLogoLottie(width: 40.w)
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                    ),
                const SizedBox(height: 40),
                // Loading indicator
                _buildPremiumLoadingIndicator(),
                const SizedBox(height: 20),
                // Tagline
                Text(
                  "Your medical community",
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Splash Screen
  Widget _buildSplashScreen() {
    final theme = OneUITheme.of(context);

    return Container(
      key: const ValueKey<String>('splashScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackground,
            theme.surfaceVariant.withValues(alpha: 0.5),
            theme.primary.withValues(alpha: 0.05),
          ],
          stops: const [0.2, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background animated patterns
          Positioned.fill(
            child: Opacity(opacity: 0.1, child: _buildBackgroundPatterns()),
          ),

          // Decorative top design element
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.primary.withValues(alpha: 0.2),
                    theme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(300),
                ),
              ),
            ),
          ),

          // Light beam effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: LightBeamPainter(
                color: theme.primary.withValues(alpha: 0.06),
              ),
              child: Container(),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: SplashLogoLottie(width: 40.w),
                ),
                const SizedBox(height: 35),

                // Premium loading indicator
                _buildPremiumLoadingIndicator(),

                const SizedBox(height: 20),

                // Tagline
                Text(
                  "Your medical community",
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // Version info
                _buildVersionDisplay(),
              ],
            ),
          ),

          // Bottom design element
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.2,
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    theme.primary.withValues(alpha: 0.2),
                    theme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(200),
                ),
              ),
            ),
          ),

          // Powered by DocTak.net
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: theme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  "Powered by DocTak.net",
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
          ),
        ],
      ),
    );
  }

  // MARK: - Upgrade Screen
  Widget _buildUpgradeScreen() {
    final theme = OneUITheme.of(context);
    final maxWidth = MediaQuery.of(context).size.width - 48;

    return Container(
      key: const ValueKey<String>('upgradeScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackground,
            theme.surfaceVariant.withValues(alpha: 0.5),
            theme.primary.withValues(alpha: 0.05),
          ],
          stops: const [0.2, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildUpdateAnimation(size: 140),
                        const SizedBox(height: 12),
                        Text(
                          'New Version Available',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 800.ms),
                        const SizedBox(height: 8),
                        Text(
                          _upgradeMessage.isNotEmpty
                              ? _upgradeMessage
                              : (_isSkippible ?? false
                                  ? 'A new version of DocTak is available with exciting new features and improvements!'
                                  : 'Please update to the latest version of the app to continue using all features.'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(duration: 800.ms),
                        const SizedBox(height: 12),
                        _buildVersionInfoRow(compact: true),
                        const SizedBox(height: 12),
                        _buildFeaturesList(compact: true),
                        const SizedBox(height: 16),
                        _buildUpgradeButton(theme),
                        if (_isSkippible ?? false) ...[
                          const SizedBox(height: 8),
                          _buildSkipButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: theme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Powered by DocTak.net",
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(OneUITheme theme) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isSkippible == false)
            Positioned.fill(child: _buildShimmerEffect()),
          ElevatedButton(
            onPressed: _launchAppOrPlayStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSkippible ?? false ? 'Update Now' : 'Update Required',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonPrimaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isSkippible ?? false
                      ? Icons.file_download_outlined
                      : Icons.priority_high_rounded,
                  color: theme.buttonPrimaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _currentState = ScreenState.splash;
        });
        _initializeSplashScreen();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  // MARK: - Shared UI Components

  // Background patterns effect
  Widget _buildBackgroundPatterns() {
    final theme = OneUITheme.of(context);
    return Stack(
      children: [
        // Medical icons or patterns
        Positioned(
          top: 100,
          left: 20,
          child:
              Icon(
                    Icons.medical_services_outlined,
                    size: 40,
                    color: theme.primary.withValues(alpha: 0.3),
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(seconds: 2),
                  ),
        ),
        Positioned(
          bottom: 120,
          right: 30,
          child:
              Icon(
                    Icons.health_and_safety_outlined,
                    size: 36,
                    color: theme.primary.withValues(alpha: 0.3),
                  )
                  .animate()
                  .fadeIn(duration: 1800.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(seconds: 2),
                  ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.7,
          child:
              Icon(
                    Icons.favorite_border,
                    size: 32,
                    color: theme.primary.withValues(alpha: 0.3),
                  )
                  .animate()
                  .fadeIn(duration: 2000.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(seconds: 2),
                  ),
        ),
      ],
    );
  }

  // Premium loading indicator
  Widget _buildPremiumLoadingIndicator() {
    final theme = OneUITheme.of(context);
    return SizedBox(
      width: 60,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          Container(
            height: 6,
            width: 60,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Animated loading dot
          Positioned(
            left: 0,
            child:
                Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveX(begin: 0, end: 48, duration: 1500.ms)
                    .then()
                    .moveX(begin: 48, end: 0, duration: 1500.ms),
          ),
        ],
      ),
    );
  }

  // Version display badge
  Widget _buildVersionDisplay() {
    final theme = OneUITheme.of(context);
    if (_versionNumber.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: theme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            "v$_versionNumber",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 700.ms);
  }

  // MARK: - Upgrade Screen Components

  // Update animation illustration
  Widget _buildUpdateAnimation({double size = 220}) {
    final theme = OneUITheme.of(context);
    final middleSize = size * 180 / 220;
    final centerSize = size * 110 / 220;
    final iconSize = size * 50 / 220;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle (pulsing effect)
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.primary.withValues(alpha: 0.1),
                      theme.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 800.ms)
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                duration: 2000.ms,
              ),

          // Middle circle
          Container(
            width: middleSize,
            height: middleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Update animation effects
          _buildUpdateEffects(size: size),

          // Center icon
          Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isSkippible ?? false
                        ? Icons.rocket_launch_rounded
                        : Icons.system_update_rounded,
                    size: iconSize,
                    color: theme.buttonPrimaryText,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 1000.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
              ),
        ],
      ),
    );
  }

  // Update effects (floating elements)
  Widget _buildUpdateEffects({double size = 220}) {
    final scale = size / 220;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Top right dot
        Positioned(
          top: 30 * scale,
          right: 40 * scale,
          child: _buildFloatingElement(
            icon: Icons.auto_awesome,
            size: 16,
            delay: 600.ms,
          ),
        ),

        // Bottom left dot
        Positioned(
          bottom: 30 * scale,
          left: 40 * scale,
          child: _buildFloatingElement(
            icon: Icons.add_moderator,
            size: 16,
            delay: 800.ms,
          ),
        ),

        // Left side dot
        Positioned(
          left: 20 * scale,
          top: 100 * scale,
          child: _buildFloatingElement(
            icon: Icons.security_update_good,
            size: 18,
            delay: 400.ms,
          ),
        ),
      ],
    );
  }

  // Floating element for update animation
  Widget _buildFloatingElement({
    required IconData icon,
    required double size,
    required Duration delay,
  }) {
    final theme = OneUITheme.of(context);
    return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: size, color: theme.primary),
        )
        .animate()
        .fadeIn(delay: delay, duration: 500.ms)
        .then()
        .slideY(begin: 0.05, end: -0.05, duration: 2000.ms)
        .then()
        .slideY(begin: -0.05, end: 0.05, duration: 2000.ms);
  }

  // Version comparison row
  Widget _buildVersionInfoRow({bool compact = false}) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 12 : 20,
        horizontal: compact ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.divider.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Current version (with floating label)
          Column(
            children: [
              _buildFloatingLabel('CURRENT', theme.textSecondary),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.mobile_friendly,
                    size: 18,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentVersionString,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Arrow animation
          _buildArrowAnimation(),

          // New version (with floating label)
          Column(
            children: [
              _buildFloatingLabel('NEW', theme.primary),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.upgrade,
                    size: 18,
                    color: theme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _latestVersionString,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  // Floating label component
  Widget _buildFloatingLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Poppins',
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Animated arrow between versions
  Widget _buildArrowAnimation() {
    final theme = OneUITheme.of(context);
    return SizedBox(
      width: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrow line
          Container(height: 2, color: theme.border.withValues(alpha: 0.3)),

          // Animated arrow head
          Icon(Icons.arrow_forward, color: theme.primary, size: 20)
              .animate(onPlay: (controller) => controller.repeat())
              .moveX(begin: -5, end: 5, duration: 1200.ms)
              .then()
              .moveX(begin: 5, end: -5, duration: 1200.ms),
        ],
      ),
    );
  }

  // Features list for update screen
  Widget _buildFeaturesList({bool compact = false}) {
    final theme = OneUITheme.of(context);
    final features = _isSkippible ?? false
        ? [
            "New features and improvements",
            "Bug fixes and performance updates",
            "Enhanced security measures",
          ]
        : [
            "Critical security update required",
            "Important compatibility improvements",
            "Essential bug fixes and stability enhancements",
          ];
    final visibleFeatures = compact ? features.take(2).toList() : features;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: compact ? 6 : 12),
          child: Text(
            "What's New:",
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(compact ? 10 : 16),
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: visibleFeatures
                .map((feature) => _buildFeatureItem(feature, compact: compact))
                .toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  // Feature item with icon
  Widget _buildFeatureItem(String feature, {bool compact = false}) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 12, color: theme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                color: theme.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer effect for mandatory update button
  Widget _buildShimmerEffect() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Glowing effect
          Positioned.fill(child: Container(color: Colors.transparent)),

          // Animated shimmer
          Positioned(
            left: -100,
            child:
                Container(
                      height: 48,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveX(begin: 0, end: 300, duration: 1500.ms),
          ),
        ],
      ),
    );
  }
}
