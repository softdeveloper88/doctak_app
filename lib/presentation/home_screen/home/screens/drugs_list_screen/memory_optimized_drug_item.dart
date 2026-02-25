import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_ai_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Memory-optimized drug card for the v6 API.
/// Shows trade name, generic, strength, formulation, manufacturer & price.
/// Tapping opens DrugDetailSheet; the AI button opens DrugAISheet.
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: theme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                _buildTags(theme),
                _buildFooter(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.medication_rounded, size: 24, color: theme.primary),
          ),
          const SizedBox(width: 12),

          // Names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.tradeName?.isNotEmpty == true ? drug.tradeName! : drug.genericName ?? '',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (drug.genericName?.isNotEmpty == true && drug.tradeName?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      drug.genericName!,
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Price badge
          if (drug.hasPrice)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                drug.mrp ?? '',
                style: TextStyle(
                  color: theme.success,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tags row (strength / formulation) ───────────────────────────────────

  Widget _buildTags(OneUITheme theme) {
    final tags = <(String, Color)>[];
    if (drug.strength?.isNotEmpty == true) tags.add((drug.strength!, theme.primary));
    if (drug.formulation?.isNotEmpty == true) tags.add((drug.formulation!, theme.secondary));
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.$2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.$1,
              style: TextStyle(color: t.$2, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Footer (manufacturer + actions) ─────────────────────────────────────

  Widget _buildFooter(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        border: Border(top: BorderSide(color: theme.divider, width: 0.8)),
      ),
      child: Row(
        children: [
          if (drug.manufacturerName?.isNotEmpty == true) ...[
            Icon(Icons.factory_outlined, size: 14, color: theme.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                drug.manufacturerName!,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ] else
            const Spacer(),

          // AI button
          GestureDetector(
            onTap: () => DrugAISheet.show(context, drug: drug),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 18, color: theme.textTertiary),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DrugDetailScreen(drug: drug, currency: currency),
      ),
    );
  }
}


// Old class removed — replaced by the StatelessWidget above.
