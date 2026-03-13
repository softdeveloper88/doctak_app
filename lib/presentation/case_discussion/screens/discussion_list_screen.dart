import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/discussion_list_bloc.dart';
import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/discussion_card.dart';
import '../widgets/shimmer_widgets.dart';
import 'create_discussion_screen.dart';
import 'discussion_detail_screen.dart';

/// The main case discussion listing screen.
/// Features tab bar (All / My Cases / Saved / Following),
/// search, specialty/country/sort filters, active filter chips,
/// paginated list with pull-to-refresh, and a FAB to create new cases.
class DiscussionListScreen extends StatefulWidget {
  const DiscussionListScreen({super.key});

  @override
  State<DiscussionListScreen> createState() => _DiscussionListScreenState();
}

class _DiscussionListScreenState extends State<DiscussionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  static const _tabs = [
    _TabItem('All Cases', null),
    _TabItem('My Cases', 'my'),
    _TabItem('Saved', 'saved'),
    _TabItem('Following', 'following'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _scrollController.addListener(_onScroll);

    // Initial load
    final bloc = context.read<DiscussionListBloc>();
    bloc.add(LoadFilterData());
    bloc.add(const LoadDiscussionList());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscussionListBloc>().add(LoadMoreDiscussions());
    }
  }

  void _onSearch(String query) {
    final bloc = context.read<DiscussionListBloc>();
    final state = bloc.state;
    final currentFilters = state is DiscussionListLoaded
        ? state.currentFilters
        : const CaseDiscussionFilters();
    bloc.add(UpdateFilters(
      currentFilters.copyWith(
        searchQuery: query.isEmpty ? null : query,
        clearSearch: query.isEmpty,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.isDark
          ? theme.scaffoldBackground
          : const Color(0xFFF6F6F8),
      body: Column(
        children: [
          // ── Unified header: AppBar + search + tab strip ──
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: theme.isDark ? theme.border : Colors.grey.shade200,
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoctakAppBar(
                  title: 'Case Discussions',
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: theme.textPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                            _onSearch('');
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.inputBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search cases...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: theme.textTertiary,
                          ),
                          prefixIcon: Icon(Icons.search,
                              size: 20, color: theme.textTertiary),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: _onSearch,
                        onChanged: (value) {
                          Future.delayed(
                              const Duration(milliseconds: 500), () {
                            if (_searchController.text == value) {
                              _onSearch(value);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                // ── Tab strip ──
                _buildTabStrip(theme),
              ],
            ),
          ),

          // ── Filter Chips ──
          BlocBuilder<DiscussionListBloc, DiscussionListState>(
            buildWhen: (prev, curr) {
              if (prev is DiscussionListLoaded && curr is DiscussionListLoaded) {
                return prev.currentFilters != curr.currentFilters ||
                    prev.specialties != curr.specialties;
              }
              return true;
            },
            builder: (context, state) {
              if (state is DiscussionListLoaded) {
                return _FilterBar(
                  specialties: state.specialties,
                  countries: state.countries,
                  currentFilters: state.currentFilters,
                  theme: theme,
                  onFilterChanged: (filters) {
                    context.read<DiscussionListBloc>().add(
                          UpdateFilters(filters),
                        );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ── Content ──
          Expanded(
            child:
                BlocBuilder<DiscussionListBloc, DiscussionListState>(
              builder: (context, state) {
                if (state is DiscussionListLoading) {
                  return const CaseDiscussionListShimmer();
                }

                if (state is DiscussionListError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () {
                      context
                          .read<DiscussionListBloc>()
                          .add(const LoadDiscussionList());
                    },
                    theme: theme,
                  );
                }

                if (state is DiscussionListLoaded) {
                  if (state.discussions.isEmpty) {
                    return _EmptyView(theme: theme);
                  }

                  return RefreshIndicator(
                    color: theme.primary,
                    onRefresh: () async {
                      context
                          .read<DiscussionListBloc>()
                          .add(RefreshDiscussionList());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: state.discussions.length +
                          (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.discussions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        }

                        final item = state.discussions[index];
                        return DiscussionCard(
                          item: item,
                          onTap: () => _openDetail(item.id),
                          onLike: () {
                            context.read<DiscussionListBloc>().add(
                                  ToggleLikeDiscussion(item.id),
                                );
                          },
                          onBookmark: () {
                            context.read<DiscussionListBloc>().add(
                                  ToggleBookmarkDiscussion(item.id),
                                );
                          },
                          onDelete: item.isOwner
                              ? () => _confirmDelete(item.id)
                              : null,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Case',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ── Drugs-style tab strip ──────────────────────────────────────────────────

  Widget _buildTabStrip(OneUITheme theme) {
    return Row(
      children: _tabs.asMap().entries.map((entry) {
        return _caseTab(theme, entry.value.label, entry.key);
      }).toList(),
    );
  }

  Widget _caseTab(OneUITheme theme, String label, int index) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController.index == index) return;
          setState(() {});
          _tabController.animateTo(index);
          final tab = _tabs[index].filterValue;
          final bloc = context.read<DiscussionListBloc>();
          final state = bloc.state;
          final currentFilters = state is DiscussionListLoaded
              ? state.currentFilters
              : const CaseDiscussionFilters();
          bloc.add(UpdateFilters(
              currentFilters.copyWith(tab: tab, clearTab: tab == null)));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? theme.primary : theme.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openDetail(int caseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionDetailScreen(caseId: caseId),
      ),
    );
  }

  void _openCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => CreateDiscussionBloc(
            repository: CaseDiscussionRepository(
              baseUrl: AppData.base2,
              getAuthToken: () => AppData.userToken ?? '',
            ),
          ),
          child: const CreateDiscussionScreen(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        context.read<DiscussionListBloc>().add(RefreshDiscussionList());
      }
    });
  }

  void _confirmDelete(int caseId) {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Case'),
        content: const Text(
            'Are you sure you want to delete this case discussion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<DiscussionListBloc>()
                  .add(DeleteDiscussion(caseId));
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Tab Item ──

class _TabItem {
  final String label;
  final String? filterValue;
  const _TabItem(this.label, this.filterValue);
}

// ── Filter Bar ──

class _FilterBar extends StatelessWidget {
  final List<SpecialtyFilter> specialties;
  final List<CountryFilter> countries;
  final CaseDiscussionFilters currentFilters;
  final OneUITheme theme;
  final Function(CaseDiscussionFilters) onFilterChanged;

  const _FilterBar({
    required this.specialties,
    required this.countries,
    required this.currentFilters,
    required this.theme,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = currentFilters.selectedSpecialty != null ||
        currentFilters.selectedCountry != null ||
        (currentFilters.sortBy != null && currentFilters.sortBy != 'latest');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          bottom: BorderSide(color: theme.divider, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Specialty dropdown
            _FilterDropdown(
              label: _getSpecialtyLabel(),
              icon: Icons.medical_services_outlined,
              isActive: currentFilters.selectedSpecialty != null,
              theme: theme,
              onTap: () => _showSpecialtyPicker(context),
            ),
            const SizedBox(width: 8),

            // Country dropdown
            _FilterDropdown(
              label: _getCountryLabel(),
              icon: Icons.public,
              isActive: currentFilters.selectedCountry != null,
              theme: theme,
              onTap: () => _showCountryPicker(context),
            ),
            const SizedBox(width: 8),

            // Sort dropdown
            _FilterDropdown(
              label: _getSortLabel(),
              icon: Icons.sort,
              isActive: currentFilters.sortBy != null &&
                  currentFilters.sortBy != 'latest',
              theme: theme,
              onTap: () => _showSortPicker(context),
            ),

            // Clear filters button
            if (hasActiveFilter) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  onFilterChanged(CaseDiscussionFilters(
                    tab: currentFilters.tab,
                  ));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear, size: 14, color: theme.error),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: theme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSpecialtyLabel() {
    if (currentFilters.selectedSpecialty == null) return 'Specialty';
    return currentFilters.selectedSpecialty!.name;
  }

  String _getCountryLabel() {
    if (currentFilters.selectedCountry == null) return 'Country';
    return currentFilters.selectedCountry!.name;
  }

  String _getSortLabel() {
    switch (currentFilters.sortBy) {
      case 'most_liked':
        return 'Most Liked';
      case 'most_commented':
        return 'Most Commented';
      case 'most_viewed':
        return 'Most Viewed';
      case 'oldest':
        return 'Oldest';
      default:
        return 'Sort';
    }
  }

  void _showSpecialtyPicker(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Select Specialty',
      items: [
        _FilterItem(null, 'All Specialties'),
        ...specialties.map((s) => _FilterItem(s.id, s.name)),
      ],
      selectedId: currentFilters.selectedSpecialty?.id,
      onSelect: (id) {
        final specialty = id == null
            ? null
            : specialties.firstWhere((s) => s.id == id);
        onFilterChanged(currentFilters.copyWith(
          selectedSpecialty: specialty,
          clearSpecialty: id == null,
        ));
      },
    );
  }

  void _showCountryPicker(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Select Country',
      items: [
        _FilterItem(null, 'All Countries'),
        ...countries.map((c) => _FilterItem(c.id, c.name)),
      ],
      selectedId: currentFilters.selectedCountry?.id,
      onSelect: (id) {
        final country = id == null
            ? null
            : countries.firstWhere((c) => c.id == id);
        onFilterChanged(currentFilters.copyWith(
          selectedCountry: country,
          clearCountry: id == null,
        ));
      },
    );
  }

  void _showSortPicker(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Sort By',
      items: [
        _FilterItem(null, 'Latest'),
        _FilterItem('most_liked', 'Most Liked'),
        _FilterItem('most_commented', 'Most Commented'),
        _FilterItem('most_viewed', 'Most Viewed'),
        _FilterItem('oldest', 'Oldest First'),
      ],
      selectedId: currentFilters.sortBy,
      onSelect: (id) {
        onFilterChanged(currentFilters.copyWith(
          sortBy: id?.toString(),
          clearSort: id == null,
        ));
      },
    );
  }

  void _showFilterBottomSheet({
    required BuildContext context,
    required String title,
    required List<_FilterItem> items,
    dynamic selectedId,
    required Function(dynamic) onSelect,
  }) {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Divider(color: theme.divider),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final isSelected =
                          item.id?.toString() == selectedId?.toString();
                      return ListTile(
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? theme.primary
                                : theme.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: theme.primary, size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelect(item.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterItem {
  final dynamic id;
  final String label;
  const _FilterItem(this.id, this.label);
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final OneUITheme theme;
  final VoidCallback onTap;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primary.withValues(alpha: 0.1)
              : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? theme.primary.withValues(alpha: 0.3)
                : theme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? theme.primary : theme.textTertiary,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? theme.primary : theme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? theme.primary : theme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ──

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final OneUITheme theme;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty View ──

class _EmptyView extends StatelessWidget {
  final OneUITheme theme;
  const _EmptyView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No case discussions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new case discussion to share your clinical experience with the community.',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: theme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
