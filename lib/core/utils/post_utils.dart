import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PostUtils {
  // Function to parse hex color string
  static Color HexColor(String hexColorString) {
    hexColorString = hexColorString.replaceAll("#", "");
    if (hexColorString.length == 6) {
      hexColorString = "FF$hexColorString"; // Add FF for opacity
      return Color(int.parse(hexColorString, radix: 16));
    } else {
      return Color(int.parse('ffffff', radix: 16));
    }
  }

  // Function to launch URL with confirmation dialog - OneUI 8.5 Styled
  static Future<void> launchURL(BuildContext context, String urlString) async {
    Uri url = Uri.parse(urlString);
    final theme = OneUITheme.of(context);

    // Show a OneUI 8.5 styled bottom sheet before launching the URL
    bool shouldLaunch =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return _OneUILinkDialog(urlString: urlString, theme: theme);
          },
        ) ??
        false;

    if (shouldLaunch) {
      await launchUrl(url);
    } else {
      final snackTheme = OneUITheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leaving the app canceled.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: snackTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // Function to get a contrasting text color
  static Color contrastingTextColor(Color bgColor) {
    double luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// OneUI 8.5 Styled Link Dialog Widget
class _OneUILinkDialog extends StatelessWidget {
  final String urlString;
  final OneUITheme theme;

  const _OneUILinkDialog({required this.urlString, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Parse URL for display
    Uri? parsedUrl;
    try {
      parsedUrl = Uri.parse(urlString);
    } catch (_) {}

    final domain = parsedUrl?.host ?? urlString;
    final isSecure = parsedUrl?.scheme == 'https';

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                // Link icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primary.withValues(alpha: 0.15),
                        theme.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.link,
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
                        'Open External Link',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isSecure
                                ? CupertinoIcons.lock_fill
                                : CupertinoIcons.lock_open,
                            size: 12,
                            color: isSecure ? theme.success : theme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSecure ? 'Secure connection' : 'Not secure',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: isSecure ? theme.success : theme.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // URL Display Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          domain,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy button
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: urlString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Link copied to clipboard',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: theme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.iconButtonBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.doc_on_clipboard,
                          size: 18,
                          color: theme.iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Full URL
                Text(
                  urlString,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                    color: theme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Warning message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
                  color: theme.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are about to leave the app and open an external website.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: theme.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.buttonSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.border),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Open button
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primary,
                          theme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_up_right_square,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Open Link',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
