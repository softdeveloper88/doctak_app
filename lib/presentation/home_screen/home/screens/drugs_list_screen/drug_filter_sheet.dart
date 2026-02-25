import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for applying drug list filters.
/// Shows categories, manufacturers, formulations, strengths, price ranges, and sort order.
class DrugFilterSheet extends StatefulWidget {
  final DrugV6Filters filters;
  final DrugActiveFilters activeFilters;
  final ValueChanged<DrugActiveFilters> onApply;

  const DrugFilterSheet({
    super.key,
    required this.filters,
    required this.activeFilters,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required DrugV6Filters filters,
    required DrugActiveFilters activeFilters,
    required ValueChanged<DrugActiveFilters> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrugFilterSheet(
        filters: filters,
        activeFilters: activeFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DrugFilterSheet> createState() => _DrugFilterSheetState();
}

class _DrugFilterSheetState extends State<DrugFilterSheet> {
  late DrugActiveFilters _draft;

  static const _sortOptions = [
    ('name_asc', 'Name A → Z'),
    ('name_desc', 'Name Z → A'),
    ('price_asc', 'Price: Low → High'),
    ('price_desc', 'Price: High → Low'),
    ('manufacturer', 'Manufacturer'),
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.activeFilters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
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
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  children: [
                    Text(
                      'Filter Drugs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    if (_draft.hasActiveFilters)
                      TextButton(
                        onPressed: () => setState(() => _draft = _draft.clearAll()),
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: theme.error, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // Sort
                    _sectionTitle(theme, 'Sort Order'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sortOptions.map((opt) {
                        final selected = _draft.sort == opt.$1;
                        return _chip(theme, opt.$2, selected, () => setState(() => _draft = _draft.copyWith(sort: opt.$1)));
                      }).toList(),
                    ),

                    // Formulations
                    if (widget.filters.formulations.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(theme, 'Formulation'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.filters.formulations.map((f) {
                          final selected = _draft.formulation == f;
                          return _chip(
                            theme,
                            f,
                            selected,
                            () => setState(() => _draft = selected ? _draft.copyWith(clearFormulation: true) : _draft.copyWith(formulation: f)),
                          );
                        }).toList(),
                      ),
                    ],

                    // Price ranges
                    if (widget.filters.priceRanges.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(theme, 'Price Range'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.filters.priceRanges.map((r) {
                          final selected = _draft.priceRange == r.value;
                          return _chip(
                            theme,
                            r.label,
                            selected,
                            () => setState(() => _draft = selected ? _draft.copyWith(clearPriceRange: true) : _draft.copyWith(priceRange: r.value)),
                          );
                        }).toList(),
                      ),
                    ],

                    // Manufacturers
                    if (widget.filters.manufacturers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(theme, 'Manufacturer'),
                      const SizedBox(height: 8),
                      ...widget.filters.manufacturers.take(10).map((m) {
                        final selected = _draft.manufacturer == m.manufacturerName;
                        return _listTile(
                          theme,
                          m.manufacturerName,
                          '${m.totalDrugs} drugs',
                          selected,
                          () => setState(() =>
                              _draft = selected
                                  ? _draft.copyWith(clearManufacturer: true)
                                  : _draft.copyWith(manufacturer: m.manufacturerName)),
                        );
                      }),
                    ],

                    // Categories
                    if (widget.filters.categories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(theme, 'Category (Generic Name)'),
                      const SizedBox(height: 8),
                      ...widget.filters.categories.take(10).map((c) {
                        final selected = _draft.category == c.genericName;
                        return _listTile(
                          theme,
                          c.genericName,
                          '${c.totalDrugs} drugs',
                          selected,
                          () => setState(() =>
                              _draft = selected
                                  ? _draft.copyWith(clearCategory: true)
                                  : _draft.copyWith(category: c.genericName)),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(_draft);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _draft.activeFilterCount > 0
                          ? 'Apply ${_draft.activeFilterCount} Filter${_draft.activeFilterCount > 1 ? 's' : ''}'
                          : 'Apply Filters',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(OneUITheme theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.textSecondary,
        fontFamily: 'Poppins',
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _chip(OneUITheme theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : theme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _listTile(OneUITheme theme, String title, String subtitle, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primary.withValues(alpha: 0.08) : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primary.withValues(alpha: 0.4) : Colors.transparent,
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
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? theme.primary : theme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: theme.textTertiary),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
