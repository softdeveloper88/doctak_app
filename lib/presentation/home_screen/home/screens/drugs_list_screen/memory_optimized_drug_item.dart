import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_ai_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Memory-optimized drug card for the v6 API — Stitch "Drug List Optimized" design.
/// Shows trade name, generic, strength/formulation badges, manufacturer & price.
/// Tapping opens DrugDetailScreen; the AI button opens DrugAISheet.
class MemoryOptimizedDrugItem extends StatelessWidget {
  final DrugV6Item drug;
  final String currency;

  const MemoryOptimizedDrugItem({
    super.key,
    required this.drug,
    this.currency = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.isDark ? theme.border : Colors.grey.shade200,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.isDark ? 0.15 : 0.04,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildTopSection(theme), _buildFooter(context, theme)],
          ),
        ),
      ),
    );
  }

  // ── Top Section (icon + name/badges + price) ─────────────────────────────

  Widget _buildTopSection(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug thumbnail icon
          _buildDrugIcon(theme),
          const SizedBox(width: 14),
          // Name + badges
          Expanded(child: _buildNameAndBadges(theme)),
          const SizedBox(width: 10),
          // Price column
          if (drug.hasPrice) _buildPriceColumn(theme),
        ],
      ),
    );
  }

  Widget _buildDrugIcon(OneUITheme theme) {
    // Pick an icon color based on formulation type
    final iconColor = _formulationColor(theme);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.isDark ? theme.surfaceVariant : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.isDark ? theme.border : Colors.grey.shade50,
          width: 0.5,
        ),
      ),
      child: Icon(_formulationIcon(), size: 28, color: iconColor),
    );
  }

  Widget _buildNameAndBadges(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trade name
        Text(
          drug.tradeName?.isNotEmpty == true
              ? drug.tradeName!
              : drug.genericName ?? '',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Generic name subtitle
        if (drug.genericName?.isNotEmpty == true &&
            drug.tradeName?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              drug.genericName!,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 6),
        // Badges row
        _buildBadgeRow(theme),
      ],
    );
  }

  Widget _buildBadgeRow(OneUITheme theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Formulation badge (Prescription / OTC style)
        if (drug.formulation?.isNotEmpty == true)
          _badge(
            theme,
            drug.formulation!,
            theme.primary.withValues(alpha: 0.1),
            theme.primary,
          ),
        // Strength badge
        if (drug.strength?.isNotEmpty == true)
          _badge(
            theme,
            drug.strength!,
            theme.isDark ? theme.surfaceVariant : Colors.grey.shade100,
            theme.textSecondary,
          ),
      ],
    );
  }

  Widget _badge(OneUITheme theme, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPriceColumn(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          drug.mrp ?? '',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        if (drug.packageSize?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              drug.packageSize!,
              style: TextStyle(
                color: theme.textTertiary,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  // ── Footer (manufacturer + AI Insight) ───────────────────────────────────

  Widget _buildFooter(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.isDark ? theme.border : Colors.grey.shade100,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          if (drug.manufacturerName?.isNotEmpty == true) ...[
            Icon(Icons.factory_outlined, size: 14, color: theme.textTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                drug.manufacturerName!,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ] else
            const Spacer(),

          // AI Insight button
          GestureDetector(
            onTap: () => DrugAISheet.show(context, drug: drug),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI INSIGHT',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DrugDetailScreen(drug: drug, currency: currency),
      ),
    );
  }

  /// Pick an icon based on formulation text.
  IconData _formulationIcon() {
    final f = (drug.formulation ?? '').toLowerCase();
    if (f.contains('tablet') || f.contains('capsule')) {
      return Icons.medication_rounded;
    } else if (f.contains('syrup') ||
        f.contains('liquid') ||
        f.contains('solution')) {
      return Icons.local_drink_rounded;
    } else if (f.contains('inject') || f.contains('vial')) {
      return Icons.vaccines_rounded;
    } else if (f.contains('cream') ||
        f.contains('ointment') ||
        f.contains('gel')) {
      return Icons.spa_rounded;
    } else if (f.contains('drop')) {
      return Icons.water_drop_rounded;
    } else if (f.contains('inhaler') || f.contains('spray')) {
      return Icons.air_rounded;
    }
    return Icons.medication_rounded;
  }

  /// Pick a color for the icon based on formulation.
  Color _formulationColor(OneUITheme theme) {
    final f = (drug.formulation ?? '').toLowerCase();
    if (f.contains('syrup') || f.contains('liquid') || f.contains('solution')) {
      return Colors.teal;
    } else if (f.contains('inject') || f.contains('vial')) {
      return Colors.red.shade400;
    } else if (f.contains('cream') ||
        f.contains('ointment') ||
        f.contains('gel')) {
      return Colors.purple.shade400;
    } else if (f.contains('drop')) {
      return Colors.cyan;
    } else if (f.contains('inhaler') || f.contains('spray')) {
      return Colors.orange;
    }
    return theme.primary;
  }
}
