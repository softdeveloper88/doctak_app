import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;

class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key});

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_app_settings,
        titleIcon: Icons.settings_rounded,
      ),
      body: Container(
        color: theme.scaffoldBackground,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // Theme Setting Card
            Observer(
              builder: (_) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.isDark
                      ? theme.surfaceVariant
                      : Colors.transparent,
                ),
                boxShadow: theme.isDark ? [] : theme.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            appStore.isUsingSystemTheme
                                ? Icons.brightness_auto_rounded
                                : (appStore.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded),
                            color: theme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context).lbl_theme_appearance,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appStore.isUsingSystemTheme
                                    ? 'Using system theme'
                                    : (appStore.isDarkMode
                                        ? 'Dark mode'
                                        : 'Light mode'),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Theme Selection Options
                    Row(
                      children: [
                        // System Theme Option
                        Expanded(
                          child: _buildThemeOption(
                            context: context,
                            theme: theme,
                            icon: Icons.brightness_auto_rounded,
                            label: 'System',
                            isSelected: appStore.isUsingSystemTheme,
                            onTap: () {
                              appStore.useSystemTheme();
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Light Theme Option
                        Expanded(
                          child: _buildThemeOption(
                            context: context,
                            theme: theme,
                            icon: Icons.light_mode_rounded,
                            label: 'Light',
                            isSelected: !appStore.isUsingSystemTheme && !appStore.isDarkMode,
                            onTap: () {
                              appStore.toggleDarkMode(value: false);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dark Theme Option
                        Expanded(
                          child: _buildThemeOption(
                            context: context,
                            theme: theme,
                            icon: Icons.dark_mode_rounded,
                            label: 'Dark',
                            isSelected: !appStore.isUsingSystemTheme && appStore.isDarkMode,
                            onTap: () {
                              appStore.toggleDarkMode(value: true);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
            // Language Setting Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.isDark
                      ? theme.surfaceVariant
                      : Colors.transparent,
                ),
                boxShadow: theme.isDark ? [] : theme.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translation(context).lbl_app_language,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose your preferred language',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: theme.cardBackground,
                        elevation: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇺🇸',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_english_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ar',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇸🇦',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_arabic_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'fa',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇮🇷',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_farsi_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'fr',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇫🇷',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_french_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'es',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇪🇸',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_spanish_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'de',
                              child: Row(
                                children: [
                                  const Text(
                                    '🇩🇪',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_german_language,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                        onSelected: (value) async {
                          Locale newLocale = await setLocale(value);
                          MyApp.setLocale(context, newLocale);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Delete Account Card
            Container(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: theme.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.05),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: InkWell(
                onTap: () => _deleteAccount(context, theme),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation(context).lbl_delete_account,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Permanently delete your account',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
          ],
        ),
      ),
    );
  }

  void _deleteAccount(BuildContext context, OneUITheme theme) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translation(context).lbl_delete_account_confirmation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            translation(context).msg_delete_account_warning,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.surfaceVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      translation(context).lbl_cancel,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      var result = await _deleteUserAccount();
                      if (result) {
                        AppSharedPreferences().clearSharedPreferencesData(
                          context,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      translation(context).lbl_delete,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<bool> _deleteUserAccount() async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/delete-account');
    try {
      final response = await http.get(
        apiUrl,
        headers: <String, String>{
          'Authorization': 'Bearer ${AppData.userToken!}',
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required dynamic theme,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withOpacity(0.15)
              : theme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primary : theme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? theme.primary : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
