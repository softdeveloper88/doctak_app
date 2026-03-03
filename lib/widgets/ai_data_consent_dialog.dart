import 'package:doctak_app/core/utils/secure_storage_service.dart';
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

/// Shows the AI data consent dialog if the user has not yet consented.
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

  final bool? agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _AiDataConsentDialog(),
  );

  final granted = agreed == true;
  await setAiDataConsent(granted);
  return granted;
}

// ─── Internal dialog widget ────────────────────────────────────────────────

class _AiDataConsentDialog extends StatelessWidget {
  const _AiDataConsentDialog();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'AI Data Processing Notice',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please read before using AI features',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── What data is sent ─────────────────────────────────
                  _SectionCard(
                    theme: theme,
                    icon: Icons.upload_rounded,
                    iconColor: Colors.orange,
                    title: 'What data is shared',
                    items: const [
                      'Your text questions & clinical summaries',
                      'Medical images you upload for analysis',
                      'Your AI session identifier (anonymous)',
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Who receives it ───────────────────────────────────
                  _SectionCard(
                    theme: theme,
                    icon: Icons.cloud_outlined,
                    iconColor: Colors.blue,
                    title: 'Who processes this data',
                    items: const [
                      'DocTak servers (doctak.net) — your data is first sent securely to our backend',
                      'OpenAI (GPT-4o) — our backend forwards your query to OpenAI\'s AI model to generate a response',
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Why & purpose ─────────────────────────────────────
                  _SectionCard(
                    theme: theme,
                    icon: Icons.fact_check_outlined,
                    iconColor: Colors.green,
                    title: 'Purpose of sharing',
                    items: const [
                      'To provide AI-powered medical image analysis and clinical Q&A',
                      'Your data is NOT used to train AI models',
                      'OpenAI processes data under its Privacy Policy and API usage terms',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Important notice ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Do not include highly sensitive personal identifiers (e.g. full name, national ID) in your queries. Use clinical summaries only.',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Privacy Policy link ───────────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsAndConditionScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: theme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'View Full Privacy Policy & Terms',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text(
                            'I Agree & Continue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'You can withdraw consent anytime from Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
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

// ─── Reusable section card ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _SectionCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (theme as OneUITheme).inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (theme as OneUITheme).primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: (theme as OneUITheme).textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 5, color: (theme as OneUITheme).textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: (theme as OneUITheme).textPrimary,
                        height: 1.45,
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
