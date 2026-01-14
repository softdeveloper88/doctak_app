import 'dart:async';
import 'dart:convert';
import 'dart:io';

// TODO: app_links temporarily disabled due to SDK compatibility
// import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/language_selection_screen/language_selection_screen.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
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

ScreenState _currentState = ScreenState.splash;

class UnifiedSplashUpgradeScreen extends StatefulWidget {
  const UnifiedSplashUpgradeScreen({Key? key}) : super(key: key);

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
        colors: [color.withOpacity(0.7), color.withOpacity(0.05)],
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
  // Screen state management

  // Version information
  String _versionNumber = '';
  String _latestVersionString = '';
  String _currentVersionString = '';
  bool? _isSkippible;
  PackageInfo? _packageInfo;

  // Animation controller
  late AnimationController _animationController;

  // Deep linking - TODO: AppLinks temporarily disabled due to SDK compatibility
  // late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

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
    // try {
    //   _packageInfo = await PackageInfo.fromPlatform();
    //   if (mounted) {
    //     setState(() {
    //       _versionNumber = _packageInfo!.version;
    //       _currentVersionString = _packageInfo!.version;
    //     });
    //   }
    // } catch (e) {
    //   debugPrint('Error getting version info: $e');
    // }
  }

  // Check if app needs updating
  Future<void> _checkAppVersion() async {
    if (_packageInfo != null) {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final latestVersionInfo = await _fetchLatestVersion();
      var latestVersion;
      var latestVersionLocal;
      var mandatory;

      if (latestVersionInfo.isNotEmpty) {
        latestVersion = latestVersionInfo['data']['version'];
        await prefs.setString('latest_version', latestVersion);
        latestVersionLocal = await prefs.getString('latest_version');
        mandatory = latestVersionInfo['data']['mandatory'];
        if (mounted) {
          setState(() {
            _latestVersionString = latestVersionLocal ?? '';
            _currentVersionString = _packageInfo!.version;
          });
        }
      } else {
        latestVersionLocal = await prefs.getString('latest_version') ?? '1.0.1';
        if (mounted) {
          setState(() {
            _latestVersionString = latestVersionLocal;
            _currentVersionString = _packageInfo!.version;
          });
        }
      }

      try {
        Version version1 = Version.parse(_packageInfo!.version);
        Version version2 = Version.parse(latestVersionLocal);

        if (version1 < version2 && mandatory == 1) {
          if (mounted) {
            setState(() {
              _isSkippible = false;
              _currentState = ScreenState.upgrade;
            });
          }
        } else if (version1 < version2 && mandatory == 0) {
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
      var response;
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

  // Initialize splash screen logic
  Future<void> _initializeSplashScreen() async {
    try {
      setStatusBarColor(Colors.transparent);
      await const Duration(seconds: 1).delay;

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
      const LanguageSelectionScreen().launch(context, isNewTask: true);
      return;
    }

    bool rememberMe = await prefs.getBool('rememberMe') ?? false;
    String? userToken = await prefs.getString('token');
    String? userId = await prefs.getString('userId');

    if (userToken != null) {
      // Initialize user data
      AppData.deviceToken = await prefs.getString('device_token') ?? '';
      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = await prefs.getString('name') ?? '';
      AppData.profile_pic = await prefs.getString('profile_pic') ?? '';
      AppData.background = await prefs.getString('background') ?? '';
      AppData.email = await prefs.getString('email') ?? '';
      AppData.specialty = await prefs.getString('specialty') ?? '';
      AppData.university = await prefs.getString('university') ?? '';
      AppData.userType = await prefs.getString('user_type') ?? '';
      AppData.city = await prefs.getString('city') ?? '';
      AppData.countryName = await prefs.getString('country') ?? '';
      AppData.currency = await prefs.getString('currency') ?? '';
    }

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
      
      // No deep link, navigate to dashboard
      const SVDashboardScreen().launch(context, isNewTask: true);
      
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
        const SVDashboardScreen().launch(context, isNewTask: true);
      }
    }
  }

  // Launch app store for update
  void _launchAppOrPlayStore() {
    AppSharedPreferences().clearSharedPreferencesData(context);

    final appId = Platform.isAndroid ? _packageInfo!.packageName : '6448684340';
    final url = Uri.parse(
      Platform.isAndroid
          ? "market://details?id=$appId"
          : "https://apps.apple.com/app/id$appId",
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
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
    return Container(
      key: const ValueKey<String>('loadingScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.8),
            Colors.blue.shade100.withOpacity(0.5),
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
                Image.asset(
                      'assets/logo/logo.png',
                      width: 40.w,
                      fit: BoxFit.contain,
                    )
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
                    color: Colors.grey.shade700,
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
    return Container(
      key: const ValueKey<String>('splashScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.8),
            Colors.blue.shade100.withOpacity(0.5),
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
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.05),
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
                color: theme.colorScheme.primary.withOpacity(0.06),
              ),
              child: Container(),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale and fade animations
                Padding(
                  padding: const EdgeInsets.all(15),
                  child:
                      Image.asset(
                            'assets/logo/logo.png',
                            width: 40.w,
                            fit: BoxFit.contain,
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 600.ms,
                          ),
                ),
                const SizedBox(height: 35),

                // Premium loading indicator
                _buildPremiumLoadingIndicator(),

                const SizedBox(height: 20),

                // Tagline
                Text(
                  "Your medical community",
                  style: TextStyle(
                    color: Colors.grey.shade700,
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
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.05),
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
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  "Powered by DocTak.net",
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
    return Container(
      key: const ValueKey<String>('upgradeScreen'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.8),
            Colors.blue.shade100.withOpacity(0.5),
          ],
          stops: const [0.2, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: 40),
              // Update Illustration
              _buildUpdateAnimation(),
              const SizedBox(height: 32),
              // Update Title
              Text(
                'New Version Available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: 16),
              // Update Message
              Text(
                _isSkippible ?? false
                    ? 'A new version of DocTak is available with exciting new features and improvements!'
                    : 'Please update to the latest version of the app to continue using all features.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: 32),
              // Current and New Version Display
              _buildVersionInfoRow(),
              const SizedBox(height: 40),
              // Features list
              _buildFeaturesList(),

              const SizedBox(height: 30),

              // Update Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shimmer effect
                    if (_isSkippible == false)
                      Positioned.fill(child: _buildShimmerEffect()),

                    // Button
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
                            _isSkippible ?? false
                                ? 'Update Now'
                                : 'Update Required',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isSkippible ?? false
                                ? Icons.file_download_outlined
                                : Icons.priority_high_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms),

              // Skip Button (if update is optional)
              if (_isSkippible ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _currentState = ScreenState.splash;
                      });
                      _initializeSplashScreen();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 16,
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
                  ),
                ).animate().fadeIn(duration: 800.ms),
              const Spacer(),

              // Powered by DocTak.net
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Powered by DocTak.net",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Shared UI Components

  // Background patterns effect
  Widget _buildBackgroundPatterns() {
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
                    color: Colors.blue.shade300,
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
                    color: Colors.blue.shade300,
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
              Icon(Icons.favorite_border, size: 32, color: Colors.blue.shade300)
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
              color: Colors.grey.shade200,
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
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
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
    if (_versionNumber.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            "v$_versionNumber",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 700.ms);
  }

  // MARK: - Upgrade Screen Components

  // Update animation illustration
  Widget _buildUpdateAnimation() {
    return Container(
      height: 220,
      width: 220,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle (pulsing effect)
          Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
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
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Update animation effects
          _buildUpdateEffects(),

          // Center icon
          Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                    size: 50,
                    color: Colors.white,
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
  Widget _buildUpdateEffects() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Top right dot
        Positioned(
          top: 30,
          right: 40,
          child: _buildFloatingElement(
            icon: Icons.auto_awesome,
            size: 16,
            delay: 600.ms,
          ),
        ),

        // Bottom left dot
        Positioned(
          bottom: 30,
          left: 40,
          child: _buildFloatingElement(
            icon: Icons.add_moderator,
            size: 16,
            delay: 800.ms,
          ),
        ),

        // Left side dot
        Positioned(
          left: 20,
          top: 100,
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
    return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: size, color: Theme.of(context).primaryColor),
        )
        .animate()
        .fadeIn(delay: delay, duration: 500.ms)
        .then()
        .slideY(begin: 0.05, end: -0.05, duration: 2000.ms)
        .then()
        .slideY(begin: -0.05, end: 0.05, duration: 2000.ms);
  }

  // Version comparison row
  Widget _buildVersionInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
              _buildFloatingLabel('CURRENT', Colors.grey.shade600),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.mobile_friendly,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentVersionString,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
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
              _buildFloatingLabel('NEW', Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.upgrade,
                    size: 18,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _latestVersionString,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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
        color: color.withOpacity(0.1),
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
    return SizedBox(
      width: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrow line
          Container(height: 2, color: Colors.grey.shade300),

          // Animated arrow head
          Icon(
                Icons.arrow_forward,
                color: Theme.of(context).primaryColor,
                size: 20,
              )
              .animate(onPlay: (controller) => controller.repeat())
              .moveX(begin: -5, end: 5, duration: 1200.ms)
              .then()
              .moveX(begin: 5, end: -5, duration: 1200.ms),
        ],
      ),
    );
  }

  // Features list for update screen
  Widget _buildFeaturesList() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            "What's New:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: features
                .map((feature) => _buildFeatureItem(feature))
                .toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  // Feature item with icon
  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
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
                      height: 54,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
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
