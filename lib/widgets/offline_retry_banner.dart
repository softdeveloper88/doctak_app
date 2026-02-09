// offline_retry_banner.dart
// LinkedIn-style offline banner that shows at the bottom when API fails
// but cached data is available

import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// A LinkedIn-style banner that appears at the bottom of the screen
/// when the app is showing cached/offline data
class OfflineRetryBanner extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final bool showAnimation;

  const OfflineRetryBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.showAnimation = true,
  });

  @override
  State<OfflineRetryBanner> createState() => _OfflineRetryBannerState();
}

class _OfflineRetryBannerState extends State<OfflineRetryBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleRetry() {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    widget.onRetry();

    // Reset retry state after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF3CD),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade700 : const Color(0xFFFFECB5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Warning Icon
              Icon(
                Icons.wifi_off_rounded,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),

              // Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translation(context).lbl_showing_cached_data,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Retry Button
              _isRetrying
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? theme.primary : Colors.orange.shade700,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _handleRetry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: isDark
                            ? theme.primary.withValues(alpha: 0.2)
                            : Colors.orange.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: isDark ? theme.primary : Colors.orange.shade700,
                      ),
                      label: Text(
                        translation(context).lbl_retry,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? theme.primary
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact inline retry widget for use within lists
class OfflineRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OfflineRetryCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: isDark ? Colors.orange.shade300 : Colors.orange.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translation(context).lbl_tap_to_retry,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? theme.primary : Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              translation(context).lbl_retry,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
