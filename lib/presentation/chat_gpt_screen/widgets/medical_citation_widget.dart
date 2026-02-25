import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Grok-style inline citation links displayed below AI responses.
/// Always visible (no expansion needed). Each source is a tappable chip
/// showing the site name/favicon + title, linking directly to the source URL.
///
/// Required for Apple App Store Guideline 1.4.1 (Safety - Physical Harm).
class MedicalCitationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sources;

  const MedicalCitationWidget({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 14, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                'Sources',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Grok-style source chips — always visible, horizontally wrapping
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sources.asMap().entries.map((entry) {
              final index = entry.key;
              final source = entry.value;
              final url = source['url'] as String? ?? '';
              final title = source['title'] as String? ?? _domain(url);
              final domain = _domain(url);

              return _SourceChip(
                index: index + 1,
                title: title,
                domain: domain,
                url: url,
                theme: theme,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _domain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

/// A single Grok-style source chip: numbered badge + site name, tappable.
class _SourceChip extends StatelessWidget {
  final int index;
  final String title;
  final String domain;
  final String url;
  final OneUITheme theme;

  const _SourceChip({
    required this.index,
    required this.title,
    required this.domain,
    required this.url,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: url.isEmpty ? null : () => _launch(context, url),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Numbered badge
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Title + domain
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      domain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'Poppins',
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded, size: 11, color: Colors.blue[600]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}

/// Inline disclaimer banner shown below every AI analysis.
/// Required for Apple App Store Guideline 1.4.1.
class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.warning.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 14, color: theme.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'For qualified healthcare professionals only. This AI analysis does not constitute a medical diagnosis. Always consult clinical guidelines and a licensed physician.',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
