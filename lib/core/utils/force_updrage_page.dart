import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'app/app_shared_preferences.dart';
import 'app_transitions.dart';

class ForceUpgradePage extends StatefulWidget {
  ForceUpgradePage({Key? key}) : super(key: key);

  @override
  State<ForceUpgradePage> createState() => _ForceUpgradeState();
}

class _ForceUpgradeState extends State<ForceUpgradePage> {
  String latestVersionString = '';
  String currentVersionString = '';
  PackageInfo? packageInfo;

  // final featureFlagRepository = DoctakFirebaseRemoteConfig();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializePackageInfo();
    _checkAppVersion();
  }

  Future<void> _initializePackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<Map<String, dynamic>> fetchLatestVersion() async {
    try {
      var response;
      if (Platform.isAndroid) {
        response = await http.get(
          Uri.parse('${AppData.remoteUrl}/version/Android'),
        );
      } else {
        response = await http.get(
          Uri.parse('${AppData.remoteUrl}/version/iOS'),
        );
      }
      print(response.body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return <String, dynamic>{};
      }
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<void> _checkAppVersion() async {
    if (packageInfo != null) {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final latestVersionInfo = await fetchLatestVersion();
      var latestVersion;
      var latestVersionLocal;
      var mandatory;
      if (latestVersionInfo.isNotEmpty) {
        latestVersion = latestVersionInfo['data']['version'];
        await prefs.setString('latest_version', latestVersion);
        latestVersionLocal = await prefs.getString('latest_version');
        mandatory = latestVersionInfo['data']['mandatory'];
        setState(() {
          latestVersionString = latestVersionLocal ?? '';
          currentVersionString = packageInfo!.version;
        });
      } else {
        latestVersionLocal = await prefs.getString('latest_version') ?? '1.0.1';
        setState(() {
          latestVersionString = latestVersionLocal;
          currentVersionString = packageInfo!.version;
        });
      }
      print(latestVersionLocal);
      Version version1 = Version.parse(packageInfo!.version);
      Version version2 = Version.parse(latestVersionLocal);

      // final url = latestVersionInfo['url'];
      print(latestVersionInfo);
      print(latestVersion);
      print(version1);
      print(version2);

      if (version1 < version2 && mandatory == 1) {
        setState(() {
          isSkippible = false;
          isUpdateAvailable = true;
        });
      } else if (version1 < version2 && mandatory == 0) {
        setState(() {
          isSkippible = true;
          isUpdateAvailable = true;
        });
      } else {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            page: const SplashScreen(),
            transitionType: PageTransitionType.fade, // or any other type
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        CustomPageRoute(
          page: const SplashScreen(),
          transitionType: PageTransitionType.fade, // or any other type
        ),
      );
      // Handle the case where packageInfo is null
      // You can display a loading indicator or handle it in some other way
    }
  }

  void _launchAppOrPlayStore() {
    AppSharedPreferences().clearSharedPreferencesData(context);

    final appId = Platform.isAndroid ? packageInfo!.packageName : '6448684340';
    final url = Uri.parse(
      Platform.isAndroid
          ? "market://details?id=$appId"
          : "https://apps.apple.com/app/id$appId",
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  bool? isSkippible;
  bool? isUpdateAvailable;

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
                    isSkippible ?? false
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
                    currentVersionString,
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
                    latestVersionString,
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

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )
              .animate()
              .fadeIn(delay: (i * 200).ms, duration: 700.ms)
              .then(delay: 300.ms)
              .fadeOut(duration: 700.ms),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = isSkippible ?? false
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isUpdateAvailable ?? false
          ? Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
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
                        isSkippible ?? false
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
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Shimmer effect
                            if (isSkippible == false)
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
                                    isSkippible ?? false
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
                                    isSkippible ?? false
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
                      if (isSkippible ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const SplashScreen(),
                                ),
                              );
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
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.7),
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
            )
          : Container(
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
                alignment: Alignment.center,
                children: [
                  // Background animated patterns
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: _buildBackgroundPatterns(),
                    ),
                  ),
                  // Logo and animations
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with scale and fade animations
                      Center(
                        child:
                            Image.asset(
                                  'assets/logo/logo.png',
                                  width: 70.w,
                                  fit: BoxFit.contain,
                                )
                                .animate()
                                .fadeIn(
                                  duration: 800.ms,
                                  curve: Curves.easeOutQuad,
                                )
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 600.ms,
                                ),
                      ),
                      const SizedBox(height: 40),
                      // Loading indicator
                      _buildLoadingIndicator(),
                      const SizedBox(height: 20),
                      // Tagline or version text
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
                ],
              ),
            ),
    );
  }
}
