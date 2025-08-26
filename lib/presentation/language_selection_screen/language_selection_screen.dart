import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/splash_screen/unified_splash_upgrade_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  String? selectedLanguageCode;
  
  final List<LanguageOption> languages = [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageOption(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    LanguageOption(
      code: 'fa',
      name: 'Persian',
      nativeName: 'فارسی',
      flag: '🇮🇷',
    ),
    LanguageOption(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageOption(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageOption(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
  }
  
  Future<void> _initializePreferences() async {
    // Initialize nb_utils SharedPreferences if not already done
    try {
      await initialize();
    } catch (e) {
      // Already initialized, ignore
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      selectedLanguageCode = languageCode;
    });
    
    // Save the selected language using the proper setLocale function
    await setLocale(languageCode);
    
    // Use SharedPreferences directly as fallback
    try {
      await setValue('is_first_time', false);
    } catch (e) {
      // Fallback to direct SharedPreferences if nb_utils fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);
    }
    
    // Set locale in the app
    final locale = Locale(languageCode);
    MyApp.setLocale(context, locale);
    
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Navigate to the main app flow
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UnifiedSplashUpgradeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Compact header section
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              
                              // App Logo or Icon
                              Container(
                                width: isSmallScreen ? 50 : 60,
                                height: isSmallScreen ? 50 : 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.language_rounded,
                                  size: isSmallScreen ? 24 : 28,
                                  color: Colors.white,
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              
                              // Welcome text
                              Text(
                                'Choose Your Language',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1D29),
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              
                              Text(
                                'Select your preferred language to continue',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  color: const Color(0xFF6B7280),
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              
                              // Language Options
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  itemCount: languages.length,
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  itemBuilder: (context, index) {
                                    LanguageOption language = languages[index];
                                    bool isSelected = selectedLanguageCode == language.code;
                                    bool isLast = index == languages.length - 1;
                                    
                                    return Container(
                                      margin: EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        bottom: isLast ? 0 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isSelected ? Border.all(
                                          color: const Color(0xFF4A90E2),
                                          width: 1.5,
                                        ) : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => _selectLanguage(language.code),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: isSmallScreen ? 8 : 10,
                                            ),
                                            child: Row(
                                              children: [
                                                // Flag
                                                Container(
                                                  width: isSmallScreen ? 28 : 32,
                                                  height: isSmallScreen ? 28 : 32,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      language.flag,
                                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                                    ),
                                                  ),
                                                ),
                                                
                                                const SizedBox(width: 10),
                                                
                                                // Language names
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        language.name,
                                                        style: TextStyle(
                                                          fontSize: isSmallScreen ? 12 : 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFF1A1D29),
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                      if (language.name != language.nativeName) ...[
                                                        const SizedBox(height: 1),
                                                        Text(
                                                          language.nativeName,
                                                          style: TextStyle(
                                                            fontSize: isSmallScreen ? 10 : 11,
                                                            color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.8) : const Color(0xFF6B7280),
                                                            fontFamily: 'Poppins',
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Selection indicator
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  width: isSmallScreen ? 16 : 18,
                                                  height: isSmallScreen ? 16 : 18,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
                                                    border: Border.all(
                                                      color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFFD1D5DB),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? Icon(
                                                          Icons.check,
                                                          size: isSmallScreen ? 8 : 10,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              // Bottom section
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              
                              // Skip button (optional)
                              TextButton(
                                onPressed: () => _selectLanguage('en'), // Default to English
                                child: Text(
                                  'Skip (Use English)',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 13,
                                    color: const Color(0xFF6B7280),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 12 : 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}