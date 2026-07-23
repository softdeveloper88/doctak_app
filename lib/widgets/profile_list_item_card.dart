import 'package:doctak_app/core/utils/display_identity.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/premium/premium_mark.dart';
import 'package:flutter/material.dart';

class ProfileListItemCard extends StatelessWidget {
  const ProfileListItemCard({
    super.key,
    required this.title,
    required this.onTap,
    this.avatarUrl,
    this.onAvatarTap,
    this.subtitle,
    this.metaText,
    this.trailing,
    this.titleSuffix,
    this.margin = AppCardLayout.listItemMargin,
  });

  final String title;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;
  final String? subtitle;
  final String? metaText;
  final Widget? trailing;
  final Widget? titleSuffix;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final normalizedTitle = formatDisplayName(title, 'Unknown');
    final normalizedSubtitle = subtitle == null || subtitle!.trim().isEmpty
        ? ''
        : formatDisplayName(subtitle);
    final normalizedMeta = metaText?.trim() ?? '';

    return AppSurfaceCard.listItem(
      margin: margin,
      onTap: onTap,
      child: Row(
        children: [
          ProfileAvatarView(
            imageUrl: avatarUrl,
            label: normalizedTitle,
            onTap: onAvatarTap ?? onTap,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        normalizedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium.copyWith(fontSize: 16),
                      ),
                    ),
                    if (titleSuffix != null) ...[
                      const SizedBox(width: 4),
                      titleSuffix!,
                    ],
                  ],
                ),
                if (normalizedSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    normalizedSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySecondary.copyWith(fontSize: 14),
                  ),
                ],
                if (normalizedMeta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    normalizedMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: normalizedMeta.startsWith('↩')
                        ? theme.caption.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : normalizedMeta.startsWith('✓')
                        ? theme.caption.copyWith(
                            color: const Color(0xFF34C759),
                            fontWeight: FontWeight.w600,
                          )
                        : theme.caption,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({
    super.key,
    required this.label,
    this.imageUrl,
    this.onTap,
    this.size = 56,
    this.gender,
    this.kind = DefaultAvatarKind.user,
    this.isPremium = false,
  });

  final String label;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double size;
  final String? gender;
  final DefaultAvatarKind kind;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _avatarPalette(label, theme);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isPremium ? PremiumStyle.gold : theme.avatarBorder,
          width: isPremium ? 2.5 : 2,
        ),
        boxShadow: [
          if (isPremium)
            BoxShadow(
              color: PremiumStyle.gold.withValues(alpha: 0.45),
              blurRadius: 0,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: palette.$1.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarContent(context, palette)),
    );

    if (onTap == null) return avatar;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: avatar,
    );
  }

  Widget _buildAvatarContent(BuildContext context, (Color, Color) palette) {
    final theme = OneUITheme.of(context);
    final safeUrl = imageUrl?.trim() ?? '';

    if (safeUrl.isNotEmpty &&
        safeUrl.toLowerCase() != 'null' &&
        !isDefaultAvatarUrl(safeUrl)) {
      return AppCachedNetworkImage(
        imageUrl: safeUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        errorWidget: (_, __, ___) => _buildFallback(theme, palette),
      );
    }

    return _buildFallback(theme, palette);
  }

  Widget _buildFallback(OneUITheme theme, (Color, Color) palette) {
    return buildDefaultAvatarWidget(size: size, kind: kind, gender: gender);
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  static (Color, Color) _avatarPalette(String seed, OneUITheme theme) {
    const palettes = [
      (Color(0xFF2D8CFF), Color(0xFF5AC8FA)),
      (Color(0xFF34C759), Color(0xFF8BD17C)),
      (Color(0xFFFF9500), Color(0xFFFFC15A)),
      (Color(0xFF00A6A6), Color(0xFF4FD1C5)),
      (Color(0xFF5856D6), Color(0xFF7B79F8)),
      (Color(0xFFFF6B00), Color(0xFFFFA24D)),
    ];

    if (seed.trim().isEmpty) return palettes.first;
    final index =
        seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
        palettes.length;
    return palettes[index];
  }
}

class ProfileListActionButton extends StatelessWidget {
  const ProfileListActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: filled ? null : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : color.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 14 : 15,
                  color: filled ? Colors.white : color,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileListIconAction extends StatelessWidget {
  const ProfileListIconAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final resolvedColor = color ?? theme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.radiusM,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: resolvedColor.withValues(alpha: 0.1),
            borderRadius: theme.radiusM,
          ),
          child: Icon(icon, color: resolvedColor, size: 22),
        ),
      ),
    );
  }
}

/// Verified badge shown next to a user's name.
/// Gold when [isPremium], otherwise DocTak blue.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 18, this.isPremium = false});

  final double size;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return DocTakVerifiedBadge(size: size, isPremium: isPremium);
  }
}
