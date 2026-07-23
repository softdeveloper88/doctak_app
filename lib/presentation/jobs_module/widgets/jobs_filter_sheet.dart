import 'dart:async';

import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class JobsFilterState {
  JobsFilterState({
    this.specialties = const [],
    this.locations = const [],
    this.jobTypes = const [],
    this.applyTypes = const [],
    this.postedWithin = 'all',
    this.sort = 'newest',
    this.locationQ = '',
  });

  List<String> specialties;
  List<String> locations;
  List<String> jobTypes;
  List<String> applyTypes;
  String postedWithin;
  String sort;
  String locationQ;

  JobsFilterState copy() => JobsFilterState(
        specialties: List.from(specialties),
        locations: List.from(locations),
        jobTypes: List.from(jobTypes),
        applyTypes: List.from(applyTypes),
        postedWithin: postedWithin,
        sort: sort,
        locationQ: locationQ,
      );

  int get activeCount =>
      specialties.length +
      locations.length +
      jobTypes.length +
      applyTypes.length +
      (postedWithin != 'all' ? 1 : 0) +
      (locationQ.trim().isNotEmpty ? 1 : 0);
}

Future<JobsFilterState?> showJobsFilterSheet({
  required BuildContext context,
  required JobsFilterState initial,
  JobFacetsDto? facets,
}) {
  return showModalBottomSheet<JobsFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _JobsFilterSheet(initial: initial, facets: facets),
  );
}

class _JobsFilterSheet extends StatefulWidget {
  const _JobsFilterSheet({required this.initial, this.facets});
  final JobsFilterState initial;
  final JobFacetsDto? facets;

  @override
  State<_JobsFilterSheet> createState() => _JobsFilterSheetState();
}

class _JobsFilterSheetState extends State<_JobsFilterSheet> {
  late JobsFilterState _state;
  late final TextEditingController _locationCtrl;
  final _locationFocus = FocusNode();
  Timer? _debounce;
  List<String> _locationSuggestions = [];
  int _suggestReqId = 0;
  bool _loadingSuggest = false;

  static const _jobTypes = [
    'full_time',
    'part_time',
    'contract',
    'locum',
    'internship',
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.initial.copy();
    _locationCtrl = TextEditingController(text: _state.locationQ);
    _locationFocus.addListener(() {
      if (!_locationFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _locationSuggestions = []);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationCtrl.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onLocationChanged(String value) {
    _state.locationQ = value;
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _loadingSuggest = false;
      });
      return;
    }
    setState(() => _loadingSuggest = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final reqId = ++_suggestReqId;
      try {
        final results = await JobsNodeApiService.autocomplete(
          q: q,
          type: 'location',
        );
        if (!mounted || reqId != _suggestReqId) return;
        setState(() {
          _locationSuggestions = results.take(8).toList();
          _loadingSuggest = false;
        });
      } catch (_) {
        if (!mounted || reqId != _suggestReqId) return;
        setState(() {
          _locationSuggestions = [];
          _loadingSuggest = false;
        });
      }
    });
  }

  void _selectLocationSuggestion(String value) {
    setState(() {
      if (!_state.locations.contains(value)) {
        _state.locations = [..._state.locations, value];
      }
      _state.locationQ = '';
      _locationCtrl.clear();
      _locationSuggestions = [];
    });
    _locationFocus.unfocus();
  }

  void _toggleLocation(String name, bool selected) {
    setState(() {
      if (selected) {
        _state.locations = [..._state.locations, name];
      } else {
        _state.locations =
            _state.locations.where((x) => x != name).toList();
      }
    });
  }

  BorderSide _chipBorder(OneUITheme theme, {required bool selected}) {
    return BorderSide(
      color: selected
          ? theme.primary.withValues(alpha: 0.28)
          : theme.border,
      width: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final facetLocations = widget.facets?.locations ?? const <JobFacetItem>[];
    final thinBorder = BorderSide(color: theme.border, width: 1);
    final focusBorder =
        BorderSide(color: theme.primary.withValues(alpha: 0.35), width: 1);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
        chipTheme: ChipThemeData(
          backgroundColor: theme.cardBackground,
          selectedColor: theme.accentSoft,
          disabledColor: theme.surfaceVariant,
          checkmarkColor: theme.primary,
          deleteIconColor: theme.textSecondary,
          labelStyle: theme.bodySecondary.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.textPrimary,
          ),
          secondaryLabelStyle: theme.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primary,
          ),
          side: thinBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: thinBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: theme.border, width: 1),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Filters',
                    style: theme.titleSmall.copyWith(fontSize: 17),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _state = JobsFilterState();
                        _locationCtrl.clear();
                        _locationSuggestions = [];
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primary,
                      textStyle: theme.bodySecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    _section(theme, 'Location / Remote'),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _locationCtrl,
                        focusNode: _locationFocus,
                        textInputAction: TextInputAction.search,
                        style: theme.bodyMedium,
                        cursorColor: theme.primary,
                        decoration: InputDecoration(
                          hintText: 'Search city, country, or Remote…',
                          hintStyle: theme.bodySecondary.copyWith(
                            color: theme.textTertiary,
                          ),
                          filled: true,
                          fillColor: theme.inputBackground,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: theme.textTertiary,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          suffixIcon: _loadingSuggest
                              ? Padding(
                                  padding: const EdgeInsets.all(11),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primary,
                                    ),
                                  ),
                                )
                              : (_locationCtrl.text.isNotEmpty
                                  ? IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: theme.textTertiary,
                                      ),
                                      onPressed: () {
                                        _locationCtrl.clear();
                                        _onLocationChanged('');
                                      },
                                    )
                                  : null),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: thinBorder,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: thinBorder,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: focusBorder,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _onLocationChanged(v);
                        },
                      ),
                    ),
                    if (_locationSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: theme.surfaceCardDecoration(),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              for (final suggestion in _locationSuggestions)
                                ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: theme.primary,
                                  ),
                                  title: Text(
                                    suggestion,
                                    style: theme.bodyMedium,
                                  ),
                                  trailing:
                                      _state.locations.contains(suggestion)
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: theme.primary,
                                              size: 18,
                                            )
                                          : null,
                                  onTap: () =>
                                      _selectLocationSuggestion(suggestion),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_state.locations.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final loc in _state.locations)
                            InputChip(
                              label: Text(
                                loc,
                                style: theme.caption.copyWith(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: true,
                              showCheckmark: false,
                              selectedColor: theme.accentSoft,
                              backgroundColor: theme.accentSoft,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: _chipBorder(theme, selected: true),
                              deleteIconColor: theme.primary,
                              onDeleted: () => _toggleLocation(loc, false),
                              onSelected: (_) => _toggleLocation(loc, false),
                            ),
                        ],
                      ),
                    ],
                    if (facetLocations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Popular locations',
                        style: theme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final loc in facetLocations.take(12))
                            _filterChip(
                              theme: theme,
                              label: '${loc.name} (${loc.count})',
                              selected: _state.locations.contains(loc.name),
                              onSelected: (sel) =>
                                  _toggleLocation(loc.name, sel),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _section(theme, 'Sort'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _choiceChip(
                          theme: theme,
                          label: 'Newest',
                          selected: _state.sort == 'newest',
                          onSelected: () =>
                              setState(() => _state.sort = 'newest'),
                        ),
                        _choiceChip(
                          theme: theme,
                          label: 'Oldest',
                          selected: _state.sort == 'oldest',
                          onSelected: () =>
                              setState(() => _state.sort = 'oldest'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _section(theme, 'Posted within'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in const [
                          ('all', 'Any time'),
                          ('1d', '24h'),
                          ('7d', '7 days'),
                          ('30d', '30 days'),
                        ])
                          _choiceChip(
                            theme: theme,
                            label: e.$2,
                            selected: _state.postedWithin == e.$1,
                            onSelected: () => setState(
                              () => _state.postedWithin = e.$1,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _section(theme, 'Job type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _jobTypes)
                          _filterChip(
                            theme: theme,
                            label: t.replaceAll('_', ' '),
                            selected: _state.jobTypes.contains(t),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _state.jobTypes = [..._state.jobTypes, t];
                              } else {
                                _state.jobTypes = _state.jobTypes
                                    .where((x) => x != t)
                                    .toList();
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _section(theme, 'Apply method'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(
                          theme: theme,
                          label: 'Easy Apply',
                          selected: _state.applyTypes.contains('easy_apply'),
                          onSelected: (sel) => setState(() {
                            _state.applyTypes = sel
                                ? [..._state.applyTypes, 'easy_apply']
                                : _state.applyTypes
                                    .where((x) => x != 'easy_apply')
                                    .toList();
                          }),
                        ),
                        _filterChip(
                          theme: theme,
                          label: 'External',
                          selected: _state.applyTypes.contains('external'),
                          onSelected: (sel) => setState(() {
                            _state.applyTypes = sel
                                ? [..._state.applyTypes, 'external']
                                : _state.applyTypes
                                    .where((x) => x != 'external')
                                    .toList();
                          }),
                        ),
                      ],
                    ),
                    if (widget.facets?.specialties.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _section(theme, 'Specialty'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in widget.facets!.specialties.take(16))
                            _filterChip(
                              theme: theme,
                              label: '${s.name} (${s.count})',
                              selected: _state.specialties.contains(s.name),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _state.specialties = [
                                    ..._state.specialties,
                                    s.name,
                                  ];
                                } else {
                                  _state.specialties = _state.specialties
                                      .where((x) => x != s.name)
                                      .toList();
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () {
                    _state.locationQ = _locationCtrl.text.trim();
                    Navigator.pop(context, _state);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    textStyle: theme.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceChip({
    required OneUITheme theme,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.accentSoft,
      backgroundColor: theme.cardBackground,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: theme.bodySecondary.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? theme.primary : theme.textPrimary,
      ),
      side: _chipBorder(theme, selected: selected),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: _chipBorder(theme, selected: selected),
      ),
    );
  }

  Widget _filterChip({
    required OneUITheme theme,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: theme.accentSoft,
      backgroundColor: theme.cardBackground,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: theme.bodySecondary.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? theme.primary : theme.textPrimary,
      ),
      side: _chipBorder(theme, selected: selected),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: _chipBorder(theme, selected: selected),
      ),
    );
  }

  Widget _section(OneUITheme theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.bodySecondary.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.textSecondary,
        ),
      ),
    );
  }
}
