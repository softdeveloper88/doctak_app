import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Web-parity provider rail card (`CmeProviderOrgRailCard`).
class CmeProviderOrgRailCard extends StatelessWidget {
  const CmeProviderOrgRailCard({
    super.key,
    required this.org,
  });

  final ActingOrganization org;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final logoUrl = org.logoUrl != null && org.logoUrl!.isNotEmpty
        ? AppData.fullImageUrl(org.logoUrl!)
        : '';
    final initial = org.name.trim().isNotEmpty
        ? org.name.trim().substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.border.withValues(alpha: 0.5)),
                  color: theme.primary.withValues(alpha: 0.06),
                ),
                clipBehavior: Clip.antiAlias,
                child: logoUrl.isNotEmpty
                    ? AppCachedNetworkImage(
                        imageUrl: logoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initial(initial, theme),
                      )
                    : _initial(initial, theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: theme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accredited provider',
                      style: theme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initial(String initial, OneUITheme theme) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.primary,
        ),
      ),
    );
  }
}
