import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Key used to persist the user's AI data consent decision.
const String kAiDataConsentKey = 'ai_data_consent_granted';

/// Returns true if the user has already granted consent to AI data processing.
Future<bool> hasAiDataConsent() async {
  final prefs = SecureStorageService.instance;
  final value = await prefs.getBool(kAiDataConsentKey);
  return value == true;
}

/// Persists the consent decision.
Future<void> setAiDataConsent(bool granted) async {
  final prefs = SecureStorageService.instance;
  await prefs.setBool(kAiDataConsentKey, granted);
}

/// Navigates to the AI data consent screen if the user has not yet consented.
///
/// Returns `true` if the user has already consented or presses "I Agree".
/// Returns `false` if the user declines — the caller should block access.
///
/// Usage:
/// ```dart
/// final ok = await showAiConsentIfNeeded(context);
/// if (!ok) return; // user declined
/// ```
Future<bool> showAiConsentIfNeeded(BuildContext context) async {
  if (await hasAiDataConsent()) return true;

  if (!context.mounted) return false;

  final bool? agreed =
      await AppNavigator.push<bool>(context, const AiDataConsentScreen());

  final granted = agreed == true;
  if (granted) {
    await setAiDataConsent(granted);
  }
  return granted;
}

// ─── Full-screen consent page ──────────────────────────────────────────────

class AiDataConsentScreen extends StatelessWidget {
  const AiDataConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero header ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Shield icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'AI Data Processing',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your privacy matters. Please review how\nwe handle your data before continuing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body content ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        children: [
                          // Section: What data is shared
                          _ConsentSection(
                            theme: theme,
                            icon: Icons.upload_rounded,
                            iconBg: const Color(0xFFFFF3E0),
                            iconColor: const Color(0xFFFF9800),
                            title: 'What data is shared',
                            items: const [
                              'Your text questions & clinical summaries',
                              'Medical images you upload for analysis',
                              'Your AI session identifier (anonymous)',
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Section: Who processes this data
                          _ConsentSection(
                            theme: theme,
                            icon: Icons.cloud_outlined,
                            iconBg: const Color(0xFFE3F2FD),
                            iconColor: const Color(0xFF2196F3),
                            title: 'Who processes this data',
                            items: const [
                              'DocTak servers (doctak.net) — your data is first sent securely to our backend',
                              'A trusted third-party AI service — our backend forwards your query to generate a response',
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Section: Purpose of sharing
                          _ConsentSection(
                            theme: theme,
                            icon: Icons.verified_outlined,
                            iconBg: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF4CAF50),
                            title: 'Purpose of sharing',
                            items: const [
                              'To provide AI-powered medical image analysis and clinical Q&A',
                              'Your data is NOT used to train AI models',
                              'Third-party AI services process data under their respective privacy policies and API usage terms',
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Section: Your rights
                          _ConsentSection(
                            theme: theme,
                            icon: Icons.gavel_rounded,
                            iconBg: const Color(0xFFF3E5F5),
                            iconColor: const Color(0xFF9C27B0),
                            title: 'Your rights',
                            items: const [
                              'You can withdraw consent anytime from Settings',
                              'You may request deletion of your AI session data',
                              'Declining will not affect access to other DocTak features',
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Warning notice ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFE082),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFE082,
                                    ).withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFF9A825),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Important',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                          color: const Color(0xFF4E342E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Do not include highly sensitive personal identifiers (e.g. full name, national ID) in your queries. Use clinical summaries only.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          color: const Color(0xFF5D4037),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Privacy Policy link ───────────────────────
                          InkWell(
                            onTap: () {
                              AppNavigator.push(
                                context,
                                const TermsAndConditionScreen(),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View Full Privacy Policy & Terms',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Poppins',
                                      color: theme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: theme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom action bar ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.textSecondary.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'I Agree & Continue',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can withdraw consent anytime from Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable section widget ───────────────────────────────────────────────

class _ConsentSection extends StatelessWidget {
  final OneUITheme theme;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _ConsentSection({
    required this.theme,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
