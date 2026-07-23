import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// LinkedIn-style pill shown when new feed posts arrive while scrolled down.
class FeedNewPostsPill extends StatelessWidget {
  final VoidCallback onTap;

  const FeedNewPostsPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Material(
      elevation: 4,
      shadowColor: theme.primary.withValues(alpha: 0.35),
      color: theme.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward_rounded, size: 16, color: theme.buttonPrimaryText),
              const SizedBox(width: 6),
              Text(
                'New posts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.buttonPrimaryText,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
