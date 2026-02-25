import 'package:doctak_app/data/apiClient/drugs_v6_api_service.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-detail bottom sheet for a single drug.
/// Shows all fields (name, generic, strength, formulation, indications, MRP, manufacturer)
/// plus an "Ask AI" button that launches [onAskAI].
class DrugDetailSheet extends StatefulWidget {
  final DrugV6Item drug;
  final String currency;
  final VoidCallback onAskAI;

  const DrugDetailSheet({
    super.key,
    required this.drug,
    this.currency = '',
    required this.onAskAI,
  });

  static Future<void> show(
    BuildContext context, {
    required DrugV6Item drug,
    String currency = '',
    required VoidCallback onAskAI,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrugDetailSheet(drug: drug, currency: currency, onAskAI: onAskAI),
    );
  }

  @override
  State<DrugDetailSheet> createState() => _DrugDetailSheetState();
}

class _DrugDetailSheetState extends State<DrugDetailSheet> {
  DrugV6Item? _detail;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final d = await DrugsV6ApiService.instance.getDrugDetail(widget.drug.id);
      if (mounted) setState(() => _detail = d ?? widget.drug);
    } catch (_) {
      if (mounted) setState(() => _detail = widget.drug);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final drug = _detail ?? widget.drug;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              _buildHeader(theme, drug),

              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          if (drug.formulation?.isNotEmpty == true)
                            _infoRow(theme, Icons.science_outlined, 'Formulation', drug.formulation!),
                          if (drug.strength?.isNotEmpty == true)
                            _infoRow(theme, Icons.bar_chart_rounded, 'Strength', drug.strength!),
                          if (drug.packageSize?.isNotEmpty == true)
                            _infoRow(theme, Icons.inventory_2_outlined, 'Pack Size', drug.packageSize!),
                          if (drug.manufacturerName?.isNotEmpty == true)
                            _infoRow(theme, Icons.factory_outlined, 'Manufacturer', drug.manufacturerName!),
                          if (drug.hasPrice)
                            _infoRow(
                              theme,
                              Icons.attach_money_rounded,
                              'Price (MRP)',
                              '${drug.mrp} ${widget.currency}',
                              highlight: true,
                            ),
                          if (drug.hasIndications) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Indications',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                drug.indications!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textPrimary,
                                  fontFamily: 'Poppins',
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // AI Ask button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                              label: const Text(
                                'Ask AI about this drug',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onAskAI();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Copy info button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.copy_rounded, size: 18, color: theme.textSecondary),
                              label: Text(
                                'Copy Drug Info',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: theme.textSecondary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.textTertiary.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _copyInfo(drug),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OneUITheme theme, DrugV6Item drug) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.medication_rounded, color: theme.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.tradeName?.isNotEmpty == true ? drug.tradeName! : drug.genericName ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (drug.genericName?.isNotEmpty == true && drug.tradeName?.isNotEmpty == true)
                  Text(
                    drug.genericName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(OneUITheme theme, IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: highlight
                  ? theme.success.withValues(alpha: 0.12)
                  : theme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: highlight ? theme.success : theme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTertiary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: highlight ? theme.success : theme.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyInfo(DrugV6Item drug) {
    final lines = <String>[
      if (drug.tradeName?.isNotEmpty == true) 'Trade Name: ${drug.tradeName}',
      if (drug.genericName?.isNotEmpty == true) 'Generic: ${drug.genericName}',
      if (drug.strength?.isNotEmpty == true) 'Strength: ${drug.strength}',
      if (drug.formulation?.isNotEmpty == true) 'Form: ${drug.formulation}',
      if (drug.manufacturerName?.isNotEmpty == true) 'Manufacturer: ${drug.manufacturerName}',
      if (drug.hasPrice) 'MRP: ${drug.mrp} ${widget.currency}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drug info copied'), duration: Duration(seconds: 2)),
      );
    }
  }
}
