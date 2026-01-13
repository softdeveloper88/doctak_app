import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared OneUI 8.5 components for profile screens
/// This eliminates code duplication across profile info screens

/// Info banner at the top of profile info screens
class OneUIInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? accentColor;

  const OneUIInfoBanner({
    super.key,
    required this.message,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = accentColor ?? theme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: theme.radiusL,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section card with header for profile info screens
class OneUIProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const OneUIProfileSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = iconColor ?? theme.primary;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(theme.radiusL.topLeft.x),
                topRight: Radius.circular(theme.radiusL.topRight.x),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: theme.radiusM,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Profile info row for displaying label-value pairs
class OneUIProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final bool showDivider;

  const OneUIProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = iconColor ?? theme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: theme.radiusM,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.bodyMedium,
                ),
              ),
              Flexible(
                child: Text(
                  value.isNotEmpty ? value : 'Not Specified',
                  style: TextStyle(
                    color: value.isNotEmpty
                        ? theme.textPrimary
                        : theme.textTertiary,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight:
                        value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    fontStyle:
                        value.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: theme.divider, thickness: 1, height: 1),
      ],
    );
  }
}

/// Empty state widget for profile sections
class OneUIProfileEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;

  const OneUIProfileEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = iconColor ?? theme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.5),
        borderRadius: theme.radiusL,
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.titleSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Edit/Save action button for app bar
class OneUIEditActionButton extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onPressed;

  const OneUIEditActionButton({
    super.key,
    required this.isEditMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEditMode
              ? theme.success.withOpacity(0.1)
              : theme.iconButtonBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEditMode ? Icons.check : Icons.edit,
          color: isEditMode ? theme.success : theme.primary,
          size: 16,
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// Add action button for app bar
class OneUIAddActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const OneUIAddActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.iconButtonBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          color: theme.primary,
          size: 16,
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// Primary action button for profile screens
class OneUIProfilePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;

  const OneUIProfilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final buttonColor = color ?? theme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: theme.radiusXL),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Privacy badge chip for privacy settings
class OneUIPrivacyBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const OneUIPrivacyBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: theme.radiusFull,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Work/Education card for professional experience screen
class OneUIWorkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<OneUIWorkCardDetail> details;
  final String? startDate;
  final String? endDate;
  final bool isCurrentRole;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const OneUIWorkCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    this.startDate,
    this.endDate,
    this.isCurrentRole = false,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title, subtitle, and actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.08),
                  theme.secondary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(theme.radiusL.topLeft.x),
                topRight: Radius.circular(theme.radiusL.topRight.x),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.bodySecondary),
                    ],
                  ),
                ),
                if (showActions) ...[
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, size: 16, color: theme.primary),
                      ),
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete, size: 16, color: theme.error),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: details
                  .map((detail) => _buildDetailRow(detail, theme))
                  .toList(),
            ),
          ),

          // Duration section
          if (startDate != null || endDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(theme.radiusL.bottomLeft.x),
                  bottomRight: Radius.circular(theme.radiusL.bottomRight.x),
                ),
                border: Border(
                  top: BorderSide(color: theme.divider),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: theme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Duration',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    startDate ?? '',
                    style: theme.bodyMedium,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'End Date',
                      style: theme.caption,
                    ),
                  ),
                  Text(
                    isCurrentRole ? 'Present' : (endDate ?? ''),
                    style: TextStyle(
                      color:
                          isCurrentRole ? theme.success : theme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(OneUIWorkCardDetail detail, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: detail.iconColor.withOpacity(0.1),
              borderRadius: theme.radiusM,
            ),
            child: Icon(detail.icon, size: 16, color: detail.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.label, style: theme.caption),
                if (detail.value.isNotEmpty)
                  Text(
                    detail.value,
                    style: theme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Work card detail model
class OneUIWorkCardDetail {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const OneUIWorkCardDetail({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}
