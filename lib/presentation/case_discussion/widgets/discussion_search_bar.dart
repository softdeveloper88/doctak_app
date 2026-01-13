import 'package:flutter/material.dart';
import '../../../theme/one_ui_theme.dart';

class DiscussionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String? selectedSpecialty;
  final String? selectedCountry;
  final Function(String?) onSpecialtyChanged;
  final Function(String?) onCountryChanged;

  const DiscussionSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    this.selectedSpecialty,
    this.selectedCountry,
    required this.onSpecialtyChanged,
    required this.onCountryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search discussions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.inputBackground,
            ),
            onChanged: onSearch,
          ),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSpecialty,
                  decoration: InputDecoration(
                    labelText: 'Specialty',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Specialties')),
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'cardiology', child: Text('Cardiology')),
                    DropdownMenuItem(value: 'neurology', child: Text('Neurology')),
                    DropdownMenuItem(value: 'orthopedics', child: Text('Orthopedics')),
                    DropdownMenuItem(value: 'pediatrics', child: Text('Pediatrics')),
                  ],
                  onChanged: onSpecialtyChanged,
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Countries')),
                    DropdownMenuItem(value: '1', child: Text('United States')),
                    DropdownMenuItem(value: '2', child: Text('United Kingdom')),
                    DropdownMenuItem(value: '3', child: Text('Canada')),
                    // Add more countries as needed
                  ],
                  onChanged: onCountryChanged,
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}