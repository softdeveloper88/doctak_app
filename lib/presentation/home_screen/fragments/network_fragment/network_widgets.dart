import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_shimmer.dart';
import 'package:flutter/material.dart';

/// Reference tokens from `Network Screen - Standalone.html`.
abstract final class NetworkLayout {
  static const double personCardWidth = 158;
  static const double organizationCardWidth = 174;
  static const double personCoverHeight = 48;
  static const double personCardAvatarSize = 52;
  static const double personCardHeight = 218;
  static const double organizationCardHeight = 198;
  static const double organizationCoverHeight = 44;
  static const double organizationCardLogoSize = 46;
  static const double organizationButtonHeight = 30;
  static const double personButtonHeight = 32;
  static const double personAvatarSize = 66;
  static const double organizationLogoSize = 50;
  static const double connectionAvatarSize = 46;
  static const double horizontalListPadding = 16;
  static const double horizontalCardGap = 10;
  static const double sectionTopSpacing = 20;
  static const double firstSectionTopSpacing = 16;
  static const double connectionsHorizontalInset = 12;
}

/// Whether a network search/suggestion row represents a business page.
bool networkSearchItemIsOrganization(Map<String, dynamic> item) {
  final raw = item['entity_type'] ?? item['entityType'] ?? item['type'];
  final type = raw?.toString().toLowerCase() ?? '';
  return type == 'organization' || type == 'business';
}

String networkSearchItemName(Map<String, dynamic> item) {
  if (networkSearchItemIsOrganization(item)) {
    return (item['name'] ?? 'Organization').toString();
  }
  final fullName = (item['fullName'] ?? item['name'] ?? '').toString().trim();
  if (fullName.isNotEmpty && fullName.toLowerCase() != 'unknown') return fullName;
  final firstLast =
      '${item['first_name'] ?? item['firstName'] ?? ''} ${item['last_name'] ?? item['lastName'] ?? ''}'
          .trim();
  if (firstLast.isNotEmpty) return firstLast;
  return (item['username'] ?? '').toString();
}

/// Segmented filter for people / organizations / all in network search.
class NetworkEntityScopeBar extends StatelessWidget {
  final String selectedScope;
  final int peopleCount;
  final int organizationCount;
  final ValueChanged<String> onChanged;

  const NetworkEntityScopeBar({
    super.key,
    required this.selectedScope,
    required this.peopleCount,
    required this.organizationCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _ScopeChip(
            theme: theme,
            label: 'All',
            count: peopleCount + organizationCount,
            selected: selectedScope == 'all',
            onTap: () => onChanged('all'),
          ),
          const SizedBox(width: 8),
          _ScopeChip(
            theme: theme,
            label: 'People',
            count: peopleCount,
            selected: selectedScope == 'people',
            onTap: () => onChanged('people'),
          ),
          const SizedBox(width: 8),
          _ScopeChip(
            theme: theme,
            label: 'Organizations',
            count: organizationCount,
            selected: selectedScope == 'organizations',
            onTap: () => onChanged('organizations'),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final OneUITheme theme;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.theme,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showCount = count > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.primary : theme.border,
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.textSecondary,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : theme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : theme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared type scale for the Network tab (matches reference HTML).
abstract final class NetworkTypography {
  static const double screenTitle = 22;
  static const double tab = 14;
  static const double sectionTitle = 17;
  static const double sectionAction = 13.5;
  static const double badge = 12;
  static const double personCardTitle = 13.5;
  static const double personCardSubtitle = 12;
  static const double organizationCardTitle = 13;
  static const double organizationCardSubtitle = 11.5;
  static const double cardMeta = 11;
  static const double personButton = 13.5;
  static const double organizationButton = 13;
  static const double invitationTitle = 13;
  static const double invitationSubtitle = 11;
  static const double listName = 14;
  static const double listSubtitle = 12;
  static const double listAction = 10.5;
}

double networkPersonCardWidth(BuildContext context) =>
    NetworkLayout.personCardWidth;

double networkOrganizationCardWidth(BuildContext context) =>
    NetworkLayout.organizationCardWidth;

/// @deprecated Use [networkPersonCardWidth] or [networkOrganizationCardWidth].
double networkHorizontalCardWidth(BuildContext context) =>
    networkPersonCardWidth(context);

bool networkIsOrganizationFollowing(Map<String, dynamic> org) {
  final raw = org['is_following'] ?? org['isFollowing'];
  if (raw is bool) return raw;
  if (raw is num) return raw == 1;
  final text = raw?.toString().toLowerCase() ?? '';
  return text == '1' || text == 'true';
}

String networkFormatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    final compact = value / 1000;
    return compact >= 10
        ? '${compact.toStringAsFixed(0)}k'
        : '${compact.toStringAsFixed(1)}k';
  }
  return '$value';
}

String networkRequestId(Map<String, dynamic> request) {
  return request['requestId']?.toString() ??
      request['request_id']?.toString() ??
      request['friend_request_id']?.toString() ??
      request['friendRequestId']?.toString() ??
      '';
}

Map<String, dynamic> networkPersonFromRequest(Map<String, dynamic> request) {
  final sender = request['sender'];
  if (sender is Map) {
    return Map<String, dynamic>.from(sender);
  }
  return request;
}

String networkPersonName(Map<String, dynamic> person) {
  final full = person['fullName']?.toString().trim();
  if (full != null && full.isNotEmpty) return full;
  return '${person['first_name'] ?? person['name'] ?? ''} ${person['last_name'] ?? ''}'
      .trim();
}

String networkPersonHeadline(Map<String, dynamic> person) {
  final specialty = person['specialty']?.toString() ?? '';
  final country = person['country']?.toString() ??
      person['countryName']?.toString() ??
      person['city']?.toString() ??
      '';
  if (specialty.isNotEmpty && country.isNotEmpty) {
    return '${capitalizeWords(specialty)} · $country';
  }
  return specialty.isNotEmpty
      ? capitalizeWords(specialty)
      : capitalizeWords(country);
}

String? networkPersonAvatar(Map<String, dynamic> person) {
  final url = AppData.fullImageUrl(
    person['profilePicUrl']?.toString() ??
        person['profile_pic']?.toString() ??
        person['avatar']?.toString(),
  );
  return url.isEmpty ? null : url;
}

String? networkPersonCover(Map<String, dynamic> person) {
  final url = AppData.fullImageUrl(
    person['coverUrl']?.toString() ??
        person['cover_url']?.toString() ??
        person['cover_pic']?.toString() ??
        person['cover_picture']?.toString() ??
        person['coverPicture']?.toString() ??
        person['background']?.toString() ??
        person['backgroundUrl']?.toString() ??
        '',
  );
  return url.isEmpty ? null : url;
}

String networkPersonInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return '?';
  if (list.length == 1) {
    return list.first.length >= 2
        ? list.first.substring(0, 2).toUpperCase()
        : list.first[0].toUpperCase();
  }
  return '${list.first[0]}${list.last[0]}'.toUpperCase();
}

({Color background, Color foreground}) networkAvatarPaletteForName(String name) {
  const palettes = [
    (background: Color(0xFFDCEBFF), foreground: Color(0xFF0A84FF)),
    (background: Color(0xFFFADCE8), foreground: Color(0xFFE85D8F)),
    (background: Color(0xFFD8F3E5), foreground: Color(0xFF2E9E62)),
    (background: Color(0xFFFFF0D6), foreground: Color(0xFFE8A317)),
    (background: Color(0xFFE8E0FF), foreground: Color(0xFF7C5CFC)),
  ];
  final hash = name.isEmpty ? 0 : name.codeUnits.fold(0, (a, b) => a + b);
  final palette = palettes[hash % palettes.length];
  return (
    background: palette.background,
    foreground: palette.foreground,
  );
}

BoxDecoration networkSurfaceCard(OneUITheme theme) {
  return theme.surfaceCardDecoration();
}

/// Shared user avatar for network screens — matches reference design.
class NetworkUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const NetworkUserAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = networkAvatarPaletteForName(name);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? theme.avatarBackground : palette.background,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(palette, theme),
              errorWidget: (_, __, ___) => _placeholder(palette, theme),
            )
          : _placeholder(palette, theme),
    );
  }

  Widget _placeholder(
    ({Color background, Color foreground}) palette,
    OneUITheme theme,
  ) {
    return Container(
      color: palette.background,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: palette.foreground,
          size: size * 0.48,
        ),
      ),
    );
  }
}

class NetworkInvitationsBanner extends StatelessWidget {
  final int count;
  final String subtitle;
  final List<String> previewNames;
  final VoidCallback onReview;

  const NetworkInvitationsBanner({
    super.key,
    required this.count,
    required this.subtitle,
    required this.previewNames,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: theme.cardBackground,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onReview,
          child: Ink(
            decoration: networkSurfaceCard(theme),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _InvitationAvatarStack(names: previewNames),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count pending invitation${count == 1 ? '' : 's'}',
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.008,
                            color: theme.textPrimary,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySecondary.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onReview,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFDDEAFF),
                      foregroundColor: const Color(0xFF1043A8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationAvatarStack extends StatelessWidget {
  final List<String> names;

  const _InvitationAvatarStack({required this.names});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFE57373),
      Color(0xFF4DB6AC),
      Color(0xFF9575CD),
    ];
    final visible = names.take(3).toList();
    if (visible.isEmpty) {
      return CircleAvatar(
        radius: 15,
        backgroundColor: colors[0],
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 14),
      );
    }

    return SizedBox(
      width: 52,
      height: 30,
      child: Stack(
        children: List.generate(visible.length, (index) {
          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                networkPersonInitials(visible[index]),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

IconData networkOrganizationIcon(String? type) {
  switch (type) {
    case 'hospital':
      return Icons.local_hospital_rounded;
    case 'recruiter':
      return Icons.work_outline_rounded;
    case 'cme_provider':
      return Icons.school_outlined;
    case 'pharma':
      return Icons.medical_services_outlined;
    default:
      return Icons.business_rounded;
  }
}

Color networkOrganizationIconColor(String? type) {
  switch (type) {
    case 'hospital':
      return const Color(0xFF2E9E62);
    case 'recruiter':
      return const Color(0xFF3B82F6);
    case 'cme_provider':
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF0EA5E9);
  }
}

String? networkOrganizationCover(Map<String, dynamic> organization) {
  final raw = organization['cover_url']?.toString().trim() ??
      organization['coverUrl']?.toString().trim() ??
      organization['cover']?.toString().trim() ??
      organization['cover_pic']?.toString().trim() ??
      organization['banner']?.toString().trim() ??
      organization['banner_url']?.toString().trim() ??
      organization['background']?.toString().trim();
  if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  final url = AppData.fullImageUrl(raw);
  return url.isEmpty ? null : url;
}

String? networkOrganizationLogoUrl(Map<String, dynamic> organization) {
  final raw = organization['logo_url']?.toString().trim() ??
      organization['logoUrl']?.toString().trim() ??
      organization['logo']?.toString().trim();
  if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  final url = AppData.fullImageUrl(raw);
  return url.isEmpty ? null : url;
}

Widget networkOrganizationLogo({
  required Map<String, dynamic> organization,
  double size = NetworkLayout.organizationLogoSize,
}) {
  final type = organization['type']?.toString();
  final iconColor = networkOrganizationIconColor(type);
  final logoUrl = networkOrganizationLogoUrl(organization);
  final fallback = Icon(
    networkOrganizationIcon(type),
    color: iconColor,
    size: size * 0.5,
  );

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: iconColor.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: logoUrl != null
        ? AppCachedNetworkImage(
            imageUrl: logoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => fallback,
          )
        : fallback,
  );
}

class NetworkSectionHeaderShimmer extends StatelessWidget {
  const NetworkSectionHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: OneUIShimmer(
        child: Row(
          children: [
            Container(
              height: 14,
              width: 140,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Container(
              height: 12,
              width: 48,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NetworkHorizontalShimmerKind { person, organization }

class NetworkHorizontalCardsShimmer extends StatelessWidget {
  final double cardWidth;
  final double height;
  final NetworkHorizontalShimmerKind kind;

  const NetworkHorizontalCardsShimmer({
    super.key,
    required this.cardWidth,
    required this.height,
    this.kind = NetworkHorizontalShimmerKind.person,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(
          start: NetworkLayout.horizontalListPadding,
        ),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsetsDirectional.only(
            end: NetworkLayout.horizontalCardGap,
          ),
          child: OneUIShimmer(
            child: Container(
              width: cardWidth,
              height: height,
              decoration: networkSurfaceCard(theme),
              padding: EdgeInsets.fromLTRB(
                14,
                kind == NetworkHorizontalShimmerKind.person ? 18 : 16,
                14,
                15,
              ),
              child: Column(
                crossAxisAlignment: kind == NetworkHorizontalShimmerKind.person
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  if (kind == NetworkHorizontalShimmerKind.person) ...[
                    Container(
                      height: NetworkLayout.personCoverHeight,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        0,
                        -(NetworkLayout.personCardAvatarSize / 2),
                      ),
                      child: Align(
                        child: Container(
                          width: NetworkLayout.personCardAvatarSize,
                          height: NetworkLayout.personCardAvatarSize,
                          decoration: BoxDecoration(
                            color: base,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.cardBackground,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: NetworkLayout.personCardAvatarSize / 2 - 4),
                  ] else ...[
                    Container(
                      height: NetworkLayout.organizationCoverHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(
                        0,
                        -(NetworkLayout.organizationCardLogoSize / 2),
                      ),
                      child: Container(
                        width: NetworkLayout.organizationCardLogoSize,
                        height: NetworkLayout.organizationCardLogoSize,
                        decoration: BoxDecoration(
                          color: base,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardBackground,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: NetworkLayout.organizationCardLogoSize / 2 - 8,
                    ),
                  ],
                  Container(
                    height: 11,
                    width: cardWidth * 0.72,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 9,
                    width: cardWidth * 0.58,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: kind == NetworkHorizontalShimmerKind.person
                        ? NetworkLayout.personButtonHeight
                        : NetworkLayout.organizationButtonHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NetworkConnectionsListShimmer extends StatelessWidget {
  const NetworkConnectionsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NetworkLayout.connectionsHorizontalInset,
      ),
      child: Container(
        decoration: networkSurfaceCard(theme),
        child: Column(
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: OneUIShimmer(
                child: Row(
                  children: [
                    Container(
                      width: NetworkLayout.connectionAvatarSize,
                      height: NetworkLayout.connectionAvatarSize,
                      decoration: BoxDecoration(
                        color: base,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 120,
                            color: base,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 90,
                            color: base,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NetworkHomeShimmer extends StatelessWidget {
  const NetworkHomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: NetworkLayout.firstSectionTopSpacing),
        const NetworkSectionHeaderShimmer(),
        NetworkHorizontalCardsShimmer(
          cardWidth: networkPersonCardWidth(context),
          height: NetworkLayout.personCardHeight,
        ),
        const SizedBox(height: NetworkLayout.sectionTopSpacing),
        const NetworkSectionHeaderShimmer(),
        NetworkHorizontalCardsShimmer(
          cardWidth: networkOrganizationCardWidth(context),
          height: NetworkLayout.organizationCardHeight,
          kind: NetworkHorizontalShimmerKind.organization,
        ),
        const SizedBox(height: NetworkLayout.sectionTopSpacing),
        const NetworkSectionHeaderShimmer(),
        const NetworkConnectionsListShimmer(),
      ],
    );
  }
}

class NetworkViewToggleGroup extends StatelessWidget {
  final bool isGridView;
  final ValueChanged<bool> onChanged;

  const NetworkViewToggleGroup({
    super.key,
    required this.isGridView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.radiusS,
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NetworkViewToggleButton(
            icon: Icons.grid_view_rounded,
            isActive: isGridView,
            onTap: () => onChanged(true),
          ),
          _NetworkViewToggleButton(
            icon: Icons.format_list_bulleted_rounded,
            isActive: !isGridView,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _NetworkViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NetworkViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? theme.cardBackground : Colors.transparent,
          borderRadius: theme.radiusS,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? theme.primary : theme.textTertiary,
        ),
      ),
    );
  }
}

class NetworkOrganizationGridCard extends StatelessWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onFollowToggle;
  final VoidCallback? onOpen;

  const NetworkOrganizationGridCard({
    super.key,
    required this.organization,
    required this.onFollowToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final name = organization['name']?.toString() ?? 'Organization';
    final typeLabel = organization['type_label']?.toString() ?? 'Business';
    final city = organization['city']?.toString() ?? '';
    final followers = int.tryParse(
          organization['follower_count']?.toString() ?? '',
        ) ??
        0;
    final isFollowing = networkIsOrganizationFollowing(organization);

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: networkSurfaceCard(theme),
        clipBehavior: Clip.antiAlias,
        child: NetworkOrganizationCardBody(
          organization: organization,
          name: name,
          typeLabel: typeLabel,
          city: city,
          followers: followers,
          isFollowing: isFollowing,
          onFollowToggle: onFollowToggle,
        ),
      ),
    );
  }
}

class NetworkOrganizationListTile extends StatelessWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onFollowToggle;
  final VoidCallback? onOpen;

  const NetworkOrganizationListTile({
    super.key,
    required this.organization,
    required this.onFollowToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final name = organization['name']?.toString() ?? 'Organization';
    final typeLabel = organization['type_label']?.toString() ?? 'Business';
    final city = organization['city']?.toString() ?? '';
    final followers = int.tryParse(
          organization['follower_count']?.toString() ?? '',
        ) ??
        0;
    final isFollowing = networkIsOrganizationFollowing(organization);

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            networkOrganizationLogo(organization: organization, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.copyWith(
                      fontSize: NetworkTypography.listName,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    city.isNotEmpty ? '$typeLabel · $city' : typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySecondary.copyWith(
                      fontSize: NetworkTypography.listSubtitle,
                    ),
                  ),
                  Text(
                    '${networkFormatCount(followers)} followers',
                    style: theme.caption.copyWith(
                      fontSize: NetworkTypography.cardMeta,
                      color: theme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 108,
              child: NetworkFollowButton(
                isFollowing: isFollowing,
                onTap: onFollowToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkPersonCoverBand extends StatelessWidget {
  final String? coverUrl;
  final String name;
  final double height;

  const NetworkPersonCoverBand({
    super.key,
    required this.coverUrl,
    required this.name,
    this.height = NetworkLayout.personCoverHeight,
  });

  @override
  Widget build(BuildContext context) {
    final palette = networkAvatarPaletteForName(name);
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    if (hasCover) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallbackCover(palette),
        errorWidget: (_, __, ___) => _fallbackCover(palette),
      );
    }

    return _fallbackCover(palette);
  }

  Widget _fallbackCover(({Color background, Color foreground}) palette) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.background,
            palette.foreground.withValues(alpha: 0.28),
          ],
        ),
      ),
    );
  }
}

class NetworkPersonCardAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isVerified;

  const NetworkPersonCardAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final size = NetworkLayout.personCardAvatarSize;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.cardBackground,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0B1220),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: NetworkUserAvatar(
            imageUrl: imageUrl,
            name: name,
            size: size,
          ),
        ),
        if (isVerified)
          Positioned(
            right: -1,
            bottom: -1,
            child: theme.buildVerifiedBadge(size: 15),
          ),
      ],
    );
  }
}

class NetworkOrganizationCardLogo extends StatelessWidget {
  final Map<String, dynamic> organization;
  final double size;

  const NetworkOrganizationCardLogo({
    super.key,
    required this.organization,
    this.size = NetworkLayout.organizationCardLogoSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardBackground,
        border: Border.all(
          color: theme.cardBackground,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0B1220),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: networkOrganizationLogo(organization: organization, size: size),
    );
  }
}

class NetworkPersonSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final Widget action;
  final VoidCallback? onTap;
  final double? width;
  final bool fillWidth;
  final bool includeTrailingMargin;

  const NetworkPersonSuggestionCard({
    super.key,
    required this.person,
    required this.action,
    this.onTap,
    this.width,
    this.fillWidth = false,
    this.includeTrailingMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final name = networkPersonName(person);
    final headline = networkPersonHeadline(person);
    final mutualCount = int.tryParse(
          person['mutualCount']?.toString() ??
              person['mutual_count']?.toString() ??
              '0',
        ) ??
        0;
    final isVerified =
        person['is_verified'] == true || person['is_verified'] == 1;
    final cardWidth = width ?? networkPersonCardWidth(context);
    final headerHeight =
        NetworkLayout.personCoverHeight + (NetworkLayout.personCardAvatarSize / 2) + 6;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fillWidth ? null : cardWidth,
        height: fillWidth ? null : double.infinity,
        margin: includeTrailingMargin
            ? const EdgeInsetsDirectional.only(
                end: NetworkLayout.horizontalCardGap,
              )
            : EdgeInsets.zero,
        decoration: networkSurfaceCard(theme),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  NetworkPersonCoverBand(
                    coverUrl: networkPersonCover(person),
                    name: name,
                  ),
                  Positioned(
                    top: NetworkLayout.personCoverHeight -
                        (NetworkLayout.personCardAvatarSize / 2),
                    child: NetworkPersonCardAvatar(
                      imageUrl: networkPersonAvatar(person),
                      name: name,
                      isVerified: isVerified,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: NetworkTypography.personCardTitle,
                        letterSpacing: -0.01,
                        height: 1.2,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.bodySecondary.copyWith(
                          fontSize: NetworkTypography.personCardSubtitle,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (mutualCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 11,
                            color: theme.textTertiary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$mutualCount mutual',
                            style: theme.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: NetworkTypography.cardMeta,
                              height: 1.0,
                              color: theme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    action,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkPersonCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final VoidCallback onConnect;
  final VoidCallback? onTap;
  final double? width;

  const NetworkPersonCard({
    super.key,
    required this.person,
    required this.onConnect,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isRequestSent = person['friendRequestSent'] == true;

    return NetworkPersonSuggestionCard(
      person: person,
      onTap: onTap,
      width: width,
      action: NetworkActionButton(
        label: isRequestSent
            ? translation(context).lbl_cancel
            : translation(context).lbl_connect,
        muted: isRequestSent,
        onTap: onConnect,
      ),
    );
  }
}

class NetworkOrganizationCard extends StatelessWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onFollowToggle;
  final VoidCallback? onOpen;
  final double? width;

  const NetworkOrganizationCard({
    super.key,
    required this.organization,
    required this.onFollowToggle,
    this.onOpen,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final name = organization['name']?.toString() ?? 'Organization';
    final typeLabel = organization['type_label']?.toString() ?? 'Business';
    final city = organization['city']?.toString() ?? '';
    final followers = int.tryParse(
          organization['follower_count']?.toString() ?? '',
        ) ??
        0;
    final isFollowing = networkIsOrganizationFollowing(organization);
    final cardWidth = width ?? networkOrganizationCardWidth(context);

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsetsDirectional.only(
          end: NetworkLayout.horizontalCardGap,
        ),
        decoration: networkSurfaceCard(theme),
        clipBehavior: Clip.antiAlias,
        child: NetworkOrganizationCardBody(
          organization: organization,
          name: name,
          typeLabel: typeLabel,
          city: city,
          followers: followers,
          isFollowing: isFollowing,
          onFollowToggle: onFollowToggle,
        ),
      ),
    );
  }
}

/// LinkedIn-style organization card content: cover band, overlapping logo,
/// then name/meta/follow button. Shared by horizontal and grid cards.
class NetworkOrganizationCardBody extends StatelessWidget {
  final Map<String, dynamic> organization;
  final String name;
  final String typeLabel;
  final String city;
  final int followers;
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  const NetworkOrganizationCardBody({
    super.key,
    required this.organization,
    required this.name,
    required this.typeLabel,
    required this.city,
    required this.followers,
    required this.isFollowing,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    const coverHeight = NetworkLayout.organizationCoverHeight;
    const logoSize = NetworkLayout.organizationCardLogoSize;
    final headerHeight = coverHeight + (logoSize / 2) + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              NetworkPersonCoverBand(
                coverUrl: networkOrganizationCover(organization),
                name: name,
                height: coverHeight,
              ),
              PositionedDirectional(
                start: 12,
                top: coverHeight - (logoSize / 2),
                child: NetworkOrganizationCardLogo(
                  organization: organization,
                  size: logoSize,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    fontSize: NetworkTypography.organizationCardTitle,
                    letterSpacing: -0.01,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  city.isNotEmpty ? '$typeLabel · $city' : typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySecondary.copyWith(
                    fontSize: NetworkTypography.organizationCardSubtitle,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${networkFormatCount(followers)} followers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.caption.copyWith(
                    fontSize: NetworkTypography.cardMeta,
                    height: 1.0,
                    color: theme.textTertiary,
                  ),
                ),
                const Spacer(),
                NetworkFollowButton(
                  isFollowing: isFollowing,
                  onTap: onFollowToggle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NetworkFollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const NetworkFollowButton({
    super.key,
    required this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final borderColor = isFollowing ? theme.textTertiary : theme.primary;
    final labelColor = isFollowing ? theme.textTertiary : theme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: borderColor.withValues(alpha: 0.08),
        child: Container(
          height: NetworkLayout.organizationButtonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFollowing) ...[
                Icon(Icons.add_rounded, size: 11, color: labelColor),
                const SizedBox(width: 3),
              ] else ...[
                Icon(Icons.check_rounded, size: 11, color: labelColor),
                const SizedBox(width: 3),
              ],
              Text(
                isFollowing
                    ? translation(context).lbl_following
                    : translation(context).lbl_follow,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                  fontSize: NetworkTypography.organizationButton,
                  letterSpacing: -0.005,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NetworkActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool muted;

  const NetworkActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fullWidth = true,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final borderColor = muted ? theme.textTertiary : theme.primary;
    final labelColor = muted ? theme.textTertiary : theme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: borderColor.withValues(alpha: 0.08),
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: 32,
          padding: fullWidth
              ? const EdgeInsets.symmetric(horizontal: 8)
              : const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class NetworkSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? badgeCount;

  const NetworkSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: theme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: NetworkTypography.sectionTitle,
              letterSpacing: -0.014,
              color: theme.textPrimary,
            ),
          ),
          if (badgeCount != null && badgeCount! > 0) ...[
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: NetworkTypography.badge,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: theme.bodyMedium.copyWith(
                        fontSize: NetworkTypography.sectionAction,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                        letterSpacing: -0.005,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: theme.primary,
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
