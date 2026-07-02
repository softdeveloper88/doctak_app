import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/cme_module/cme_hub_controller.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Compact white CME credits summary (web `CmeCreditMini` parity).
class CmeCreditSummaryCard extends StatelessWidget {
  const CmeCreditSummaryCard({
    super.key,
    required this.hub,
    this.onTap,
  });

  final CmeHubController hub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final dash = hub.dashboard;
    final total = _formatCredits(dash?.totalCredits);
    final year = _formatCredits(dash?.creditsThisYear);
    const yearGoal = 50.0;
    final yearNum = double.tryParse(year) ?? 0;
    final pct = (yearNum / yearGoal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AppSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: AppData.profilePicNotifier,
                  builder: (_, picUrl, __) {
                    final url =
                        picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
                    final resolved = url.isNotEmpty && url.toLowerCase() != 'null'
                        ? AppData.fullImageUrl(url)
                        : '';
                    return _circleAvatar(
                      theme: theme,
                      size: 40,
                      child: resolved.isNotEmpty
                          ? AppCachedNetworkImage(
                              imageUrl: resolved,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.person_outline, color: theme.primary, size: 20),
                            )
                          : Icon(Icons.person_outline, color: theme.primary, size: 20),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('CME credits', style: theme.caption),
                          const Spacer(),
                          Text(
                            '$total total',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: theme.divider,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$year of $yearGoal this year',
                        style: theme.caption,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20, color: theme.textTertiary),
                ],
              ],
            ),
      ),
    );
  }

  Widget _circleAvatar({
    required OneUITheme theme,
    required double size,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.border.withValues(alpha: 0.45)),
        color: theme.primary.withValues(alpha: 0.06),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  String _formatCredits(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      final n = value.toDouble();
      return n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(1);
    }
    return '$value';
  }
}
