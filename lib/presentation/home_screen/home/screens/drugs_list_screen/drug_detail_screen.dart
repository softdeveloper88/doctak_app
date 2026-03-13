import 'package:doctak_app/data/apiClient/drugs_v6_api_service.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_ai_sheet.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen drug detail view.
/// Navigated to with [Navigator.push] from the drug list or featured cards.
class DrugDetailScreen extends StatefulWidget {
  final DrugV6Item drug;
  final String currency;

  const DrugDetailScreen({
    super.key,
    required this.drug,
    this.currency = '',
  });

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  final _api = DrugsV6ApiService.instance;

  /// Starts as the list-provided drug, then potentially enriched via detail API.
  late DrugV6Item _drug;
  bool _loadingDetail = false;
  bool _isBookmarked = false;
  Box<dynamic>? _bookmarkBox;

  // Quick AI question suggestions
  static const _quickQuestions = [
    ('Side effects', Icons.warning_amber_rounded, 'What are the common and serious side effects?'),
    ('Dosage', Icons.medication_outlined, 'What is the standard dosage and how is it taken?'),
    ('Interactions', Icons.compare_arrows_rounded, 'What are the drug interactions I should know about?'),
    ('Pregnancy', Icons.pregnant_woman_rounded, 'Is it safe to use during pregnancy or breastfeeding?'),
    ('Contraindications', Icons.block_rounded, 'What are the contraindications and warnings?'),
  ];

  @override
  void initState() {
    super.initState();
    _drug = widget.drug;
    _initBookmarks();
    _fetchDetail();
  }

  @override
  void dispose() {
    _bookmarkBox?.close();
    super.dispose();
  }

  Future<void> _initBookmarks() async {
    try {
      _bookmarkBox = await Hive.openBox<dynamic>('drug_bookmarks');
      if (mounted) {
        setState(() => _isBookmarked = _bookmarkBox!.containsKey(_drug.id.toString()));
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    try {
      final key = _drug.id.toString();
      if (_isBookmarked) {
        await _bookmarkBox?.delete(key);
      } else {
        await _bookmarkBox?.put(key, {
          'id': _drug.id,
          'trade_name': _drug.tradeName,
          'generic_name': _drug.genericName,
          'strength': _drug.strength,
          'manufacturer_name': _drug.manufacturerName,
          'mrp': _drug.mrp,
          'currency': widget.currency,
        });
      }
      if (mounted) {
        setState(() => _isBookmarked = !_isBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isBookmarked ? 'Drug saved to bookmarks' : 'Removed from bookmarks'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _fetchDetail() async {
    if (_drug.id <= 0) return;
    setState(() => _loadingDetail = true);
    try {
      final detail = await _api.getDrugDetail(_drug.id);
      if (detail != null && mounted) {
        setState(() {
          _drug = detail;
          _loadingDetail = false;
        });
        return;
      }
    } catch (_) {/* fall through with list data */}
    if (mounted) setState(() => _loadingDetail = false);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _shareText {
    final buf = StringBuffer();
    buf.writeln('💊 ${_drug.displayName}');
    if (_drug.genericName?.isNotEmpty == true) buf.writeln('Generic: ${_drug.genericName}');
    if (_drug.strength?.isNotEmpty == true) buf.writeln('Strength: ${_drug.strength}');
    if (_drug.formulation?.isNotEmpty == true) buf.writeln('Formulation: ${_drug.formulation}');
    if (_drug.packageSize?.isNotEmpty == true) buf.writeln('Pack size: ${_drug.packageSize}');
    if (_drug.manufacturerName?.isNotEmpty == true) buf.writeln('Manufacturer: ${_drug.manufacturerName}');
    if (_drug.hasPrice) {
      final cur = widget.currency.isNotEmpty ? widget.currency : (_drug.currency ?? '');
      buf.writeln('Price (MRP): $cur ${_drug.mrp}');
    }
    if (_drug.hasIndications) {
      buf.writeln('\nIndications:\n${_drug.indications}');
    }
    buf.writeln('\nShared via DocTak');
    return buf.toString().trim();
  }

  void _copyInfo() {
    Clipboard.setData(ClipboardData(text: _shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drug info copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  void _shareInfo() {
    Share.share(_shareText, subject: _drug.displayName);
  }

  void _openAI([String? prefill]) {
    DrugAISheet.show(context, drug: _drug, initialQuestion: prefill);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(OneUITheme theme) {
    return DoctakAppBar(
      title: _drug.displayName,
      subtitle: _drug.subtitle.isNotEmpty ? _drug.subtitle : null,
      titleFontSize: 16,
      actions: [
        if (_loadingDetail)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary),
              ),
            ),
          ),
        // Bookmark
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isBookmarked ? theme.primary : theme.iconColor,
            size: 22,
          ),
          tooltip: _isBookmarked ? 'Remove bookmark' : 'Save drug',
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: Icon(Icons.copy_rounded, color: theme.iconColor, size: 22),
          tooltip: 'Copy info',
          onPressed: _copyInfo,
        ),
        IconButton(
          icon: Icon(Icons.share_rounded, color: theme.iconColor, size: 22),
          tooltip: 'Share',
          onPressed: _shareInfo,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(OneUITheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(theme),
          const SizedBox(height: 16),
          if (_drug.hasPrice) ...[
            _buildPriceCard(theme),
            const SizedBox(height: 16),
          ],
          _buildInfoSection(theme),
          const SizedBox(height: 16),
          if (_drug.hasIndications) ...[
            _buildIndicationsSection(theme),
            const SizedBox(height: 16),
          ],
          _buildQuickQuestionsSection(theme),
          const SizedBox(height: 16),
          _buildAIPromo(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(OneUITheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.12),
            theme.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.medication_rounded, size: 34, color: theme.primary),
          ),
          const SizedBox(width: 16),

          // Name + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _drug.displayName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (_drug.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _drug.subtitle,
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (_drug.strength?.isNotEmpty == true)
                      _chip(_drug.strength!, theme.primary.withValues(alpha: 0.12), theme.primary),
                    if (_drug.formulation?.isNotEmpty == true)
                      _chip(_drug.formulation!, theme.secondary.withValues(alpha: 0.12), theme.secondary),
                    if (_drug.source?.isNotEmpty == true)
                      _chip(
                        _drug.source == 'country_drugs' ? 'Local' : 'Global',
                        theme.surfaceVariant,
                        theme.textSecondary,
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

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      );

  // ── Price card ─────────────────────────────────────────────────────────────

  Widget _buildPriceCard(OneUITheme theme) {
    final cur = widget.currency.isNotEmpty ? widget.currency : (_drug.currency ?? '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.attach_money_rounded, color: theme.success, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MRP / Price',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Text(
                '${cur.isNotEmpty ? '$cur ' : ''}${_drug.mrp}',
                style: TextStyle(
                  color: theme.success,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info section (grid of detail tiles) ────────────────────────────────────

  Widget _buildInfoSection(OneUITheme theme) {
    final rows = <(IconData, String, String?)>[
      (Icons.science_outlined, 'Generic Name', _drug.genericName),
      (Icons.bar_chart_rounded, 'Strength', _drug.strength),
      (Icons.medication_liquid_outlined, 'Formulation', _drug.formulation),
      (Icons.inventory_2_outlined, 'Pack Size', _drug.packageSize),
      (Icons.factory_outlined, 'Manufacturer', _drug.manufacturerName),
    ].where((r) => r.$3 != null && r.$3!.isNotEmpty).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.$1, size: 18, color: theme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.$2,
                              style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'Poppins')),
                          const SizedBox(height: 2),
                          Text(row.$3!,
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: row.$3!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${row.$2} copied'), duration: const Duration(seconds: 1)),
                        );
                      },
                      child: Icon(Icons.copy_rounded, size: 15, color: theme.textTertiary),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1) Divider(height: 1, indent: 64, color: theme.divider),
            ],
          );
        }),
      ),
    );
  }

  // ── Indications section ────────────────────────────────────────────────────

  Widget _buildIndicationsSection(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.assignment_outlined, size: 16, color: theme.primary),
          const SizedBox(width: 6),
          Text('Indications & Uses',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: theme.cardShadow,
          ),
          child: Text(
            _drug.indications!,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick AI question chips ─────────────────────────────────────────────────

  Widget _buildQuickQuestionsSection(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.quiz_outlined, size: 16, color: theme.primary),
          const SizedBox(width: 6),
          Text('Ask AI',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Powered by AI',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickQuestions.map((q) {
            return GestureDetector(
              onTap: () => _openAI(q.$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                  boxShadow: theme.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(q.$2, size: 14, color: theme.primary),
                    const SizedBox(width: 6),
                    Text(
                      q.$1,
                      style: TextStyle(
                          color: theme.primary,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── AI promo banner ────────────────────────────────────────────────────────

  Widget _buildAIPromo(OneUITheme theme) {
    return GestureDetector(
      onTap: _openAI,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primary, theme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Ask AI about this drug',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                  SizedBox(height: 2),
                  Text('Side effects, dosage, interactions & more',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

}
