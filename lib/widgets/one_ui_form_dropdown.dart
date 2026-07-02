import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Unified OneUI-styled dropdown form field with label.
/// Use this across all form screens for consistent look & feel.
/// DO NOT use for login/signup screens or appbar filter fields.
///
/// For simple String dropdowns:
/// ```dart
/// OneUIFormDropdown<String>(
///   label: 'Country',
///   items: ['USA', 'UK'],
///   value: selectedCountry,
///   itemLabel: (item) => item,
///   onChanged: (val) => ...,
/// )
/// ```
///
/// For complex object dropdowns:
/// ```dart
/// OneUIFormDropdown<Countries>(
///   label: 'Country',
///   items: countriesList,
///   value: selectedCountry,
///   itemLabel: (item) => item.countryName ?? '',
///   itemBuilder: (item) => Row(children: [...]),
///   onChanged: (val) => ...,
/// )
/// ```
class OneUIFormDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String? hint;
  final bool required;
  final bool enabled;
  final ValueChanged<T?>? onChanged;

  /// Returns the display label for an item (used in selected item display).
  final String Function(T) itemLabel;

  /// Custom builder for dropdown menu items. If null, uses [itemLabel].
  final Widget Function(T)? itemBuilder;

  /// Custom builder for the selected item display. If null, uses [itemLabel].
  final Widget Function(T)? selectedItemWidgetBuilder;

  /// Trailing widget for each item (e.g. flag emoji).
  final Widget Function(T)? itemTrailing;

  /// Leading icon for each item (e.g. privacy icons).
  final Widget Function(T)? itemLeading;

  const OneUIFormDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.itemLabel,
    this.hint,
    this.required = false,
    this.enabled = true,
    this.onChanged,
    this.itemBuilder,
    this.selectedItemWidgetBuilder,
    this.itemTrailing,
    this.itemLeading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Ensure value is in items list
    final T? safeValue =
        (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row
        Row(
          children: [
            Text(
              label,
              style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Dropdown container
        Container(
          decoration: BoxDecoration(
            color: enabled ? theme.inputBackground : theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              // ignore: deprecated_member_use
              value: safeValue,
              isExpanded: true,
              dropdownColor: theme.cardBackground,
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? theme.textSecondary : theme.textTertiary,
              ),
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                overflow: TextOverflow.ellipsis,
              ),
              decoration: InputDecoration(
                hintText: hint ?? label,
                hintStyle: TextStyle(
                  color: theme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: true,
              ),
              selectedItemBuilder: (context) => items.map((item) {
                if (selectedItemWidgetBuilder != null) {
                  return selectedItemWidgetBuilder!(item);
                }
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (itemLeading != null) ...[
                        itemLeading!(item),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          itemLabel(item),
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (itemTrailing != null) itemTrailing!(item),
                    ],
                  ),
                );
              }).toList(),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: itemBuilder != null
                      ? itemBuilder!(item)
                      : Row(
                          children: [
                            if (itemLeading != null) ...[
                              itemLeading!(item),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                itemLabel(item),
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (itemTrailing != null) itemTrailing!(item),
                          ],
                        ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
