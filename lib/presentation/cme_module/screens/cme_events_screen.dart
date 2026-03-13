import 'package:doctak_app/presentation/cme_module/bloc/cme_events_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_events_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_events_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_card.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeEventsScreen extends StatefulWidget {
  const CmeEventsScreen({super.key});

  @override
  State<CmeEventsScreen> createState() => _CmeEventsScreenState();
}

class _CmeEventsScreenState extends State<CmeEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all';
  String _selectedSpecialty = 'all';

  CmeEventsBloc get _bloc => context.read<CmeEventsBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(CmeLoadEventsEvent(page: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    _bloc.add(CmeLoadEventsEvent(
      page: 1,
      search: _searchController.text.trim(),
      type: _selectedType,
      specialty: _selectedSpecialty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      children: [
        // Search bar
        _buildSearchBar(theme),

        // Filter chips
        _buildFilterChips(theme),

        // Events list
        Expanded(
          child: BlocBuilder<CmeEventsBloc, CmeEventsState>(
            builder: (context, state) {
              if (state is CmeEventsLoadingState) {
                return const CmeShimmerLoader();
              }

              if (state is CmeEventsErrorState) {
                return _buildErrorState(theme, state.errorMessage);
              }

              if (_bloc.eventsList.isEmpty) {
                return _buildEmptyState(theme);
              }

              return _buildEventsList(theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: theme.inputDecoration(
          hint: 'Search CME events...',
          prefixIcon: Icon(Icons.search, color: theme.textTertiary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch();
                  },
                )
              : null,
        ),
        style: theme.bodyMedium,
        onSubmitted: (_) => _onSearch(),
        onChanged: (value) {
          setState(() {}); // Update clear button visibility
        },
      ),
    );
  }

  Widget _buildFilterChips(OneUITheme theme) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(theme, 'All', 'all', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
          _buildFilterChip(theme, 'Workshop', 'workshop', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
          _buildFilterChip(theme, 'Conference', 'conference', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
          _buildFilterChip(theme, 'Webinar', 'webinar', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
          _buildFilterChip(theme, 'Course', 'course', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
          _buildFilterChip(theme, 'Lecture', 'lecture', _selectedType, (v) {
            setState(() => _selectedType = v);
            _onSearch();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    OneUITheme theme,
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == currentValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : theme.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        selectedColor: theme.primary,
        backgroundColor: theme.cardBackground,
        side: BorderSide(
          color: isSelected
              ? theme.primary
              : theme.textTertiary.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: theme.radiusS,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEventsList(OneUITheme theme) {
    final bloc = _bloc;

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(CmeLoadEventsEvent(
          page: 1,
          search: _searchController.text.trim(),
          type: _selectedType,
          specialty: _selectedSpecialty,
        ));
      },
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        itemCount: bloc.eventsList.length,
        cacheExtent: 1000,
        itemBuilder: (context, index) {
          // Pagination trigger
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.eventsList.length - bloc.nextPageTrigger) {
              bloc.add(CmeCheckIfNeedMoreDataEvent(index: index));
            }
          }

          // Bottom loading shimmer
          if (bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= bloc.eventsList.length - 1) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final event = bloc.eventsList[index];
          return CmeEventCard(
            event: event,
            onTap: () {
              if (event.id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CmeEventDetailScreen(eventId: event.id!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.school_outlined, size: 48, color: theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No CME events found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodySecondary,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _bloc.add(CmeLoadEventsEvent(page: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: theme.radiusS,
                ),
              ),
              child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}
