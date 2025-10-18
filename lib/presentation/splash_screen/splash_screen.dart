import 'dart:async';
import 'dart:math';

// TODO: app_links temporarily disabled due to SDK compatibility
// import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sizer/sizer.dart';
import '../home_screen/SVDashboardScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
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

class _SplashScreenState extends State<SplashScreen> {
  String versionNumber = '';

  @override
  void initState() {
    _getVersionNumber();
    init();
    super.initState();
  }

  Future<void> _getVersionNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        versionNumber = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error getting version info: $e');
    }
  }

  // TODO: AppLinks temporarily disabled due to SDK compatibility
  // late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  Future<void> initDeepLinks(context) async {
    // TODO: Deep links temporarily disabled - app_links SDK incompatible
    // For now, just navigate to dashboard
    try {
      const SVDashboardScreen().launch(context, isNewTask: true);
    } catch (e) {
      print('error $e');
    }
  }

  Future<void> init() async {
    setStatusBarColor(Colors.transparent);
    await const Duration(seconds: 1).delay;
    finish(context);
    BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '', '', ''));
    BlocProvider.of<SplashBloc>(context).add(LoadDropdownData1('', ''));

    initializeAsync();
  }

  void initializeAsync() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    bool rememberMe = await prefs.getBool('rememberMe') ?? false;
    bool acceptTerms = await prefs.getBool('acceptTerms') ?? false;

    String? userToken = await prefs.getString('token');
    String? userId = await prefs.getString('userId');

    String? name = await prefs.getString('name');
    String? profile_pic = await prefs.getString('profile_pic');
    String? background = await prefs.getString('background');
    String? email = await prefs.getString('email');
    String? specialty = await prefs.getString('specialty');
    String? userType = await prefs.getString('user_type') ?? '';
    String? university = await prefs.getString('university') ?? '';
    String? countryName = await prefs.getString('country') ?? '';
    String? city = await prefs.getString('city') ?? '';
    String? currency = await prefs.getString('currency') ?? '';

    if (userToken != null) {
      AppData.deviceToken = await prefs.getString('device_token') ?? '';
      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = name ?? '';
      AppData.profile_pic = profile_pic ?? '';
      // AppData.background= background!;
      AppData.background = background ?? '';
      AppData.email = email ?? '';
      AppData.specialty = specialty ?? '';
      AppData.university = university;
      AppData.userType = userType;
      AppData.city = city;
      AppData.countryName = countryName;
      AppData.currency = currency;
    }
    if (rememberMe) {
      if (userToken != null) {
        //Future.delayed(const Duration(seconds: 1), () {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) =>  HomeScreen()), // Navigate to OnboardingScreen
        // );

        initDeepLinks(context);
        // const SVDashboardScreen().launch(context,isNewTask: true);
        // });
      } else {
        // Future.delayed(const Duration(seconds: 1), () {
        LoginScreen().launch(context, isNewTask: true);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const SignInScreen()), // Navigate to OnboardingScreen
        // );
        // });
      }
    } else {
      LoginScreen().launch(context, isNewTask: true);

      // TermsAndConditionScreen().launch(context, isNewTask: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                              width: 50.w,
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
              bottom: MediaQuery.of(context).padding.bottom + 60,
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
      ),
    );
  }

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

  Widget _buildVersionDisplay() {
    if (versionNumber.isEmpty) return const SizedBox.shrink();

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
            "v$versionNumber",
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
}
