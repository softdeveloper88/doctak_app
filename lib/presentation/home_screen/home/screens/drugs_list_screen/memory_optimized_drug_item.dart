import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Memory-optimized drug item widget with performance improvements
class MemoryOptimizedDrugItem extends StatefulWidget {
  final Data drug;
  final Function(BuildContext, String, String) onShowBottomSheet;

  const MemoryOptimizedDrugItem({super.key, required this.drug, required this.onShowBottomSheet});

  @override
  State<MemoryOptimizedDrugItem> createState() => _MemoryOptimizedDrugItemState();
}

class _MemoryOptimizedDrugItemState extends State<MemoryOptimizedDrugItem> {
  /// Remove duplicate currency symbols (e.g., "4.5 AED AED" -> "4.5 AED")
  String _formatPrice(String price) {
    if (price.isEmpty) return '0';

    // Remove duplicate AED occurrences
    // Example: "4.5 AED AED" -> "4.5 AED"
    final regex = RegExp(r'(\s+AED)+$', caseSensitive: false);
    String formatted = price.replaceAll(regex, ' AED');

    // If no AED found after cleanup, return original
    if (!formatted.toUpperCase().contains('AED')) {
      formatted = price;
    }

    return formatted.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          _showDialog(context, widget.drug.genericName ?? '');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: theme.cardShadow),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drug Header
                _buildDrugHeader(theme),

                // Drug Info
                _buildDrugInfo(theme),

                // Action Row
                _buildActionRow(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drug header section
  Widget _buildDrugHeader(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardBackground),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(Icons.medication_rounded, size: 24, color: theme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.drug.genericName ?? "",
                  style: TextStyle(color: theme.primary, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.drug.tradeName ?? translation(context).lbl_not_available,
                  style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        widget.drug.strength ?? '',
                        style: TextStyle(color: theme.primary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        widget.drug.packageSize ?? '',
                        style: TextStyle(color: theme.success, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drug info section
  Widget _buildDrugInfo(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Row(
        children: [
          // Manufacturer Info
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Icon(Icons.business_outlined, size: 20, color: theme.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation(context).lbl_manufacturer_name,
                        style: TextStyle(color: theme.textTertiary, fontSize: 12, fontFamily: 'Poppins'),
                      ),
                      Text(
                        widget.drug.manufacturerName ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              _formatPrice(widget.drug.mrp ?? '0'),
              style: TextStyle(color: theme.primary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Action row section
  Widget _buildActionRow(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            translation(context).lbl_tap_for_details,
            style: TextStyle(color: theme.textTertiary, fontSize: 12, fontFamily: 'Poppins'),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.primary),
        ],
      ),
    );
  }

  // Show dialog for drug details
  void _showDialog(BuildContext context, String genericName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = OneUITheme.of(context);
        return _buildDialog(context, genericName, theme);
      },
    );
  }

  // Build dialog widget
  Widget _buildDialog(BuildContext context, String genericName, OneUITheme theme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(20), boxShadow: theme.cardShadow),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            _buildDialogHeader(context, genericName, theme),

            // Dialog Content
            _buildDialogContent(context, genericName, theme),

            // Dialog Footer
            _buildDialogFooter(context, theme),
          ],
        ),
      ),
    );
  }

  // Dialog header
  Widget _buildDialogHeader(BuildContext context, String genericName, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.cardBackground, shape: BoxShape.circle),
            child: Icon(Icons.medication_outlined, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              genericName,
              style: TextStyle(color: theme.cardBackground, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog content
  Widget _buildDialogContent(BuildContext context, String genericName, OneUITheme theme) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(
              translation(context).lbl_select_option_to_learn,
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: theme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildQuestion(context, translation(context).lbl_all_information, genericName, "icInfo", Icons.info_outline, Colors.blue[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_mechanism, genericName, "icMechanisam", Icons.settings_outlined, Colors.purple[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_indications, genericName, "icIndication", Icons.assignment_outlined, Colors.green[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_dosage, genericName, "icDosage", Icons.access_time_filled_outlined, Colors.orange[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_drug_interactions, genericName, "icDrug", Icons.compare_arrows_outlined, Colors.red[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_special_populations, genericName, "icSpecial", Icons.people_outline, Colors.teal[700]!, clickable: true),
            _buildQuestion(context, translation(context).lbl_side_effects, genericName, "icSideEffect", Icons.report_problem_outlined, Colors.amber[700]!, clickable: true),
          ],
        ),
      ),
    );
  }

  // Dialog footer
  Widget _buildDialogFooter(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.cardBackground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: 18, color: theme.cardBackground),
            const SizedBox(width: 8),
            Text(
              translation(context).lbl_close,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.cardBackground),
            ),
          ],
        ),
      ),
    );
  }

  // Question item widget
  Widget _buildQuestion(BuildContext context, String question, String genericName, String iconAsset, IconData iconData, Color iconColor, {bool clickable = false}) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: clickable
          ? () {
              widget.onShowBottomSheet(context, genericName, question);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: theme.cardShadow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: iconColor, width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(fontSize: 15, color: theme.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.arrow_forward_rounded, size: 16, color: iconColor),
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
