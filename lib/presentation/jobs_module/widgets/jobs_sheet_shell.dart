import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared Jobs-module bottom sheet chrome — drag handle, title, optional
/// subtitle / trailing, and scrollable body. Used by filters, stage move, AI sheets.
class JobsSheetShell extends StatelessWidget {
  const JobsSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.maxHeightFactor = 0.88,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final double maxHeightFactor;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    // Color fills the full sheet including home-indicator area; SafeArea is
    // applied only as inner padding so no transparent gap shows under the sheet.
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: theme.cardBackground,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.titleSmall.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: theme.caption.copyWith(
                                  color: theme.textSecondary,
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null)
                        trailing!
                      else
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: padding,
                          child: child,
                        )
                      : Padding(
                          padding: padding,
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon badge used in sheet headers.
class JobsSheetLeadingIcon extends StatelessWidget {
  const JobsSheetLeadingIcon({
    super.key,
    required this.icon,
    this.color,
  });

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final c = color ?? theme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 21, color: c),
    );
  }
}
