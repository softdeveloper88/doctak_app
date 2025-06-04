import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class EnhancedDiscussionSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(CaseDiscussionFilters) onFiltersChanged;
  final List<SpecialtyFilter> specialties;
  final List<CountryFilter> countries;
  final CaseDiscussionFilters currentFilters;

  const EnhancedDiscussionSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    required this.onFiltersChanged,
    required this.specialties,
    required this.countries,
    required this.currentFilters,
  }) : super(key: key);

  @override
  State<EnhancedDiscussionSearchBar> createState() => _EnhancedDiscussionSearchBarState();
}

class _EnhancedDiscussionSearchBarState extends State<EnhancedDiscussionSearchBar> {
  bool _isFilterExpanded = false;
  late CaseDiscussionFilters _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = widget.currentFilters;
  }

  @override
  void didUpdateWidget(EnhancedDiscussionSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilters != widget.currentFilters) {
      _localFilters = widget.currentFilters;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar with filter toggle
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: 'Search case discussions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.controller.clear();
                              widget.onSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: widget.onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isFilterExpanded
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFilterExpanded
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _isFilterExpanded
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                ),
              ),
            ],
          ),

          // Filter section with proper sizing
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFilterExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      _buildFiltersSection(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Active filters chips
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            _buildActiveFiltersChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Specialty filter
          _buildSpecialtyFilter(),
          const SizedBox(height: 12),

          // Country filter
          _buildCountryFilter(),
          const SizedBox(height: 12),

          // Sort options
          _buildSortOptions(),
          const SizedBox(height: 12),

          // Status filter
          _buildStatusFilter(),
          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print('Applying filters: ${_localFilters.toQueryParameters()}');
                widget.onFiltersChanged(_localFilters);
                setState(() {
                  _isFilterExpanded = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Specialty',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: DropdownButtonFormField<SpecialtyFilter?>(
            value: _localFilters.selectedSpecialty,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: widget.specialties.isEmpty
                  ? 'Loading specialties...'
                  : 'Select specialty',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: Icon(
                Icons.medical_services_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
            items: [
              const DropdownMenuItem<SpecialtyFilter?>(
                value: null,
                child: Text('All Specialties'),
              ),
              ...widget.specialties
                  .where((specialty) => specialty.isActive)
                  .map((specialty) {
                return DropdownMenuItem<SpecialtyFilter?>(
                  value: specialty,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getSpecialtyColor(specialty.name),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(specialty.name)),
                    ],
                  ),
                );
              }),
            ],
            onChanged: widget.specialties.isEmpty
                ? null
                : (specialty) {
                    print(
                        'Specialty selected: ${specialty?.name} (ID: ${specialty?.id})');
                    setState(() {
                      _localFilters = _localFilters.copyWith(
                    selectedSpecialty: specialty,
                        clearSpecialty: specialty == null,
                      );
              });
            },
          ),
        ),
      ],
    );
  }

  Color _getSpecialtyColor(String specialtyName) {
    // This is a simple example; you might want to use a more sophisticated color mapping
    switch (specialtyName.toLowerCase()) {
      case 'cardiology':
        return Colors.red;
      case 'neurology':
        return Colors.blue;
      case 'oncology':
        return Colors.green;
      case 'pediatrics':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCountryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Country',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: DropdownButtonFormField<CountryFilter?>(
            value: _localFilters.selectedCountry,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: widget.countries.isEmpty
                  ? 'Loading countries...'
                  : 'Select country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: Icon(
                Icons.public,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
            items: [
              const DropdownMenuItem<CountryFilter?>(
                value: null,
                child: Text('All Countries'),
              ),
              ...widget.countries.map((country) {
                return DropdownMenuItem<CountryFilter?>(
                  value: country,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          country.flag.isNotEmpty ? country.flag : '🌍',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          country.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: widget.countries.isEmpty
                ? null
                : (country) {
                    print(
                        'Country selected: ${country?.name} (ID: ${country?.id})');
                    setState(() {
                _localFilters = _localFilters.copyWith(
                  selectedCountry: country,
                        clearCountry: country == null,
                      );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: DropdownButtonFormField<String?>(
                  value: _localFilters.sortBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Default'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'created_at',
                      child: Text('Date Created'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'likes',
                      child: Text('Likes'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'comments',
                      child: Text('Comments'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'views',
                      child: Text('Views'),
                    ),
                  ],
                  onChanged: (sortBy) {
                    setState(() {
                      _localFilters = _localFilters.copyWith(
                        sortBy: sortBy,
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 56,
                child: DropdownButtonFormField<String?>(
                  value: _localFilters.sortOrder,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Order',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'desc',
                      child: Text('Desc'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'asc',
                      child: Text('Asc'),
                    ),
                  ],
                  onChanged: (sortOrder) {
                    setState(() {
                      _localFilters = _localFilters.copyWith(
                        sortOrder: sortOrder,
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: DropdownButtonFormField<CaseStatus?>(
            value: _localFilters.status,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              const DropdownMenuItem<CaseStatus?>(
                value: null,
                child: Text('All Status'),
              ),
              ...CaseStatus.values.map((status) {
                return DropdownMenuItem<CaseStatus?>(
                  value: status,
                  child: Text(status.value.toUpperCase()),
                );
              }),
            ],
            onChanged: (status) {
              setState(() {
                _localFilters = _localFilters.copyWith(
                  status: status,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_localFilters.selectedSpecialty != null)
          Chip(
            label: Text(_localFilters.selectedSpecialty!.name),
            onDeleted: () {
              setState(() {
                _localFilters = _localFilters.copyWith(
                  selectedSpecialty: null,
                  clearSpecialty: true,
                );
              });
              widget.onFiltersChanged(_localFilters);
            },
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        if (_localFilters.selectedCountry != null)
          Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_localFilters.selectedCountry!.flag),
                const SizedBox(width: 4),
                Text(_localFilters.selectedCountry!.name),
              ],
            ),
            onDeleted: () {
              setState(() {
                _localFilters = _localFilters.copyWith(
                  selectedCountry: null,
                  clearCountry: true,
                );
              });
              widget.onFiltersChanged(_localFilters);
            },
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        if (_localFilters.status != null)
          Chip(
            label: Text(_localFilters.status!.value.toUpperCase()),
            onDeleted: () {
              setState(() {
                _localFilters = _localFilters.copyWith(
                  status: null,
                  clearStatus: true,
                );
              });
              widget.onFiltersChanged(_localFilters);
            },
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        if (_localFilters.sortBy != null)
          Chip(
            label: Text('Sort: ${_localFilters.sortBy}'),
            onDeleted: () {
              setState(() {
                _localFilters = _localFilters.copyWith(
                  sortBy: null,
                  sortOrder: null,
                  clearSort: true,
                );
              });
              widget.onFiltersChanged(_localFilters);
            },
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _localFilters.selectedSpecialty != null ||
        _localFilters.selectedCountry != null ||
        _localFilters.status != null ||
        _localFilters.sortBy != null;
  }

  void _clearAllFilters() {
    setState(() {
      _localFilters = const CaseDiscussionFilters();
    });
    widget.onFiltersChanged(_localFilters);
  }
}
