import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_bloc.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_event.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_state.dart';
import 'package:doctak_app/presentation/diagnosis_module/screens/diagnosis_create_screen.dart';
import 'package:doctak_app/presentation/diagnosis_module/screens/diagnosis_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/diagnosis_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiagnosisMainScreen extends StatefulWidget {
  const DiagnosisMainScreen({super.key});

  @override
  State<DiagnosisMainScreen> createState() => _DiagnosisMainScreenState();
}

class _DiagnosisMainScreenState extends State<DiagnosisMainScreen> {
  late final DiagnosisBloc _bloc;
  final _searchController = TextEditingController();
  String? _selectedContentType;
  bool _isSearchVisible = false;

  static const List<Map<String, String?>> _contentTypes = [
    {'key': null, 'label': 'All'},
    {'key': 'diagnoses', 'label': 'Diagnoses'},
    {'key': 'treatment', 'label': 'Treatment'},
    {'key': 'labs', 'label': 'Labs'},
    {'key': 'interactions', 'label': 'Interactions'},
    {'key': 'education', 'label': 'Education'},
    {'key': 'note', 'label': 'Notes'},
  ];

  @override
  void initState() {
    super.initState();
    _bloc = DiagnosisBloc();
    _bloc.add(const LoadDiagnosisList(refresh: true));
  }

  @override
  void dispose() {
    _bloc.close();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _bloc.add(
      LoadDiagnosisList(
        refresh: true,
        search: value,
        contentType: _selectedContentType,
      ),
    );
  }

  void _onFilterChanged(String? contentType) {
    setState(() => _selectedContentType = contentType);
    _bloc.add(
      LoadDiagnosisList(
        refresh: true,
        search: _searchController.text,
        contentType: contentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        body: Column(
          children: [
            DoctakAppBar(
              title: 'Differential Diagnosis',
              automaticallyImplyLeading: true,
              searchField: DoctakCollapsibleSearchField(
                isVisible: _isSearchVisible,
                hintText: 'Search diagnoses...',
                controller: _searchController,
                onChanged: (value) => _onSearch(value),
                onClear: () {
                  _onSearch('');
                },
              ),
              actions: [
                DoctakSearchToggleButton(
                  isSearching: _isSearchVisible,
                  onTap: () {
                    setState(() {
                      _isSearchVisible = !_isSearchVisible;
                      if (!_isSearchVisible) {
                        _searchController.clear();
                        _onSearch('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: theme.primary),
                  onPressed: () => _navigateToCreate(context),
                ),
              ],
            ),
            _buildFilterChips(theme),
            _buildOverviewCards(theme),
            Expanded(child: _buildDiagnosisList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(OneUITheme theme) {
    final selectedIndex = _contentTypes.indexWhere(
      (type) => type['key'] == _selectedContentType,
    );

    return Container(
      color: theme.cardBackground,
      child: OneUISegmentedTabBar(
        tabs: _contentTypes.map((type) => type['label'] ?? '').toList(),
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (index) => _onFilterChanged(_contentTypes[index]['key']),
      ),
    );
  }

  Widget _buildOverviewCards(OneUITheme theme) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      bloc: _bloc,
      buildWhen: (_, state) =>
          state is DiagnosisListLoadedState ||
          state is DiagnosisListLoadingState,
      builder: (context, state) {
        final overview = _bloc.overview;
        if (overview == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _overviewCard(
                theme,
                'Total',
                '${overview.total}',
                Icons.assignment,
                theme.primary,
              ),
              const SizedBox(width: 8),
              _overviewCard(
                theme,
                'This Week',
                '${overview.thisWeek}',
                Icons.calendar_today,
                theme.success,
              ),
              const SizedBox(width: 8),
              _overviewCard(
                theme,
                'Dx',
                '${overview.differentials}',
                Icons.medical_services,
                theme.warning,
              ),
              const SizedBox(width: 8),
              _overviewCard(
                theme,
                'Tx',
                '${overview.treatments}',
                Icons.healing,
                theme.secondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _overviewCard(
    OneUITheme theme,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: theme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisList(OneUITheme theme) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is DiagnosisListLoadingState && _bloc.diagnosisList.isEmpty) {
          return const DiagnosisShimmerLoader();
        }
        if (state is DiagnosisListErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: theme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: TextStyle(color: theme.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _bloc.add(const LoadDiagnosisList(refresh: true)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final items = _bloc.diagnosisList;
        if (items.isEmpty && state is! DiagnosisListLoadingState) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: theme.textTertiary,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  'No diagnoses yet',
                  style: TextStyle(color: theme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _navigateToCreate(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Diagnosis'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        final hasMore = _bloc.hasMorePages;
        final itemCount = items.length + (hasMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async {
            _bloc.add(const LoadDiagnosisList(refresh: true));
            // Wait for loading to finish
            await _bloc.stream.firstWhere(
              (s) =>
                  s is DiagnosisListLoadedState || s is DiagnosisListErrorState,
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= items.length) {
                // Loading indicator at bottom
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Trigger pagination when near the end
              _bloc.add(LoadMoreDiagnoses(index: index));
              return _buildDiagnosisCard(theme, items[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildDiagnosisCard(OneUITheme theme, DiagnosisModel diagnosis) {
    final contentType = diagnosis.contentType ?? 'diagnoses';
    final typeInfo = _getContentTypeInfo(contentType);

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => _navigateToDetail(context, diagnosis.id!),
      padding: const EdgeInsets.all(14),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeInfo.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeInfo.$1, size: 14, color: typeInfo.$2),
                        const SizedBox(width: 4),
                        Text(
                          typeInfo.$3,
                          style: TextStyle(
                            color: typeInfo.$2,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (diagnosis.age != null || diagnosis.gender != null)
                    Text(
                      '${diagnosis.age ?? ''}${diagnosis.gender != null ? ', ${diagnosis.gender}' : ''}',
                      style: TextStyle(color: theme.textTertiary, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Chief complaint
              Text(
                diagnosis.chiefComplaint ?? 'No complaint',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (diagnosis.symptoms != null &&
                  diagnosis.symptoms!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  diagnosis.symptoms!,
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: theme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(diagnosis.createdAt),
                    style: TextStyle(color: theme.textTertiary, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.textTertiary,
                  ),
                ],
              ),
            ],
      ),
    );
  }

  (IconData, Color, String) _getContentTypeInfo(String type) {
    switch (type) {
      case 'treatment':
        return (Icons.healing, const Color(0xFF34C759), 'Treatment');
      case 'labs':
        return (Icons.science, const Color(0xFFFF9500), 'Labs');
      case 'interactions':
        return (Icons.compare_arrows, const Color(0xFFFF3B30), 'Interactions');
      case 'education':
        return (Icons.school, const Color(0xFF5AC8FA), 'Education');
      case 'note':
        return (Icons.note_alt, const Color(0xFF8E8E93), 'Note');
      default:
        return (Icons.medical_services, const Color(0xFF0A84FF), 'Diagnosis');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _navigateToCreate(BuildContext context) async {
    final result = await AppNavigator.push(
      context,
      const DiagnosisCreateScreen(),
    );
    if (result == true) {
      _bloc.add(const LoadDiagnosisList(refresh: true));
    }
  }

  void _navigateToDetail(BuildContext context, int id) {
    AppNavigator.push(
      context,
      DiagnosisDetailScreen(diagnosisId: id),
    );
  }
}
