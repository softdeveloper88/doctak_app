import 'dart:async';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import '../bloc/create_discussion_bloc.dart';
import '../bloc/discussion_list_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/discussion_card.dart';
import '../widgets/discussion_stats_bar.dart';
import '../widgets/case_discussion_list_shimmer.dart';
import 'discussion_detail_screen.dart';
import 'create_discussion_screen.dart';

class DiscussionListScreen extends StatefulWidget {
  const DiscussionListScreen({Key? key}) : super(key: key);

  @override
  State<DiscussionListScreen> createState() => _DiscussionListScreenState();
}

class _DiscussionListScreenState extends State<DiscussionListScreen> {
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool isSearchShow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    print('DiscussionListScreen: Initializing...');

    // Load filter data first to populate specialties and countries
    context.read<DiscussionListBloc>().add(LoadFilterData());

    // Then load discussions after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('DiscussionListScreen: Loading discussions...');
        context.read<DiscussionListBloc>().add(const LoadDiscussionList());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<DiscussionListBloc>().add(LoadMoreDiscussions());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearch(String query) {
    final bloc = context.read<DiscussionListBloc>();
    final currentState = bloc.state;

    if (currentState is DiscussionListLoaded) {
      final updatedFilters = currentState.currentFilters.copyWith(
        searchQuery: query.isEmpty ? null : query,
      );
      bloc.add(UpdateFilters(updatedFilters));
    }
  }

  void _onFiltersChanged(CaseDiscussionFilters filters) {
    context.read<DiscussionListBloc>().add(UpdateFilters(filters));
  }

  void _onRefresh() {
    context.read<DiscussionListBloc>().add(RefreshDiscussionList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_case_discussions,
        titleIcon: Icons.medical_information_rounded,
        actions: [
          // Search icon button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchShow ? Icons.close : Icons.search,
                color: theme.primary,
                size: 16,
              ),
            ),
            onPressed: () {
              setState(() {
                isSearchShow = !isSearchShow;
                if (!isSearchShow) {
                  _searchController.clear();
                  _onSearch('');
                }
              });
            },
          ),
          // Add new discussion button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.success,
                  size: 16,
                ),
              ),
              onPressed: _navigateToCreateDiscussion,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.cardBackground,
            child: Column(
              children: [
                // Search field with animated visibility
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isSearchShow ? 80 : 0,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: isSearchShow
                        ? Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: theme.inputBackground,
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(
                                color: theme.inputBorder,
                                width: 1.5,
                              ),
                              boxShadow: theme.cardShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24.0),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: theme.primary.withOpacity(0.6),
                                      size: 24,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _searchController,
                                      textFieldType: TextFieldType.NAME,
                                      textStyle: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: theme.textPrimary,
                                      ),
                                      onChanged: (searchTxt) async {
                                        if (_debounce?.isActive ?? false)
                                          _debounce?.cancel();
                                        _debounce = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                            _onSearch(searchTxt);
                                          },
                                        );
                                      },
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: translation(
                                          context,
                                        ).lbl_search_case_discussions,
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: theme.textTertiary,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 14.0,
                                            ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      _onSearch('');
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.1),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(24),
                                          bottomRight: Radius.circular(24),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.clear,
                                        color: theme.primary.withOpacity(0.6),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                // Filter options section
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: BlocBuilder<DiscussionListBloc, DiscussionListState>(
                    builder: (context, state) {
                      if (state is DiscussionListLoaded) {
                        return Row(
                          children: [
                            // Specialty Filter
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.border,
                                  ),
                                ),
                                child: PopupMenuButton<SpecialtyFilter>(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: theme.cardBackground,
                                  offset: const Offset(0, 45),
                                  tooltip: translation(
                                    context,
                                  ).lbl_filter_by_specialty,
                                  elevation: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_services_outlined,
                                          size: 16,
                                          color: theme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            state
                                                    .currentFilters
                                                    .selectedSpecialty
                                                    ?.name ??
                                                translation(
                                                  context,
                                                ).lbl_all_specialties,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              color: theme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: theme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (BuildContext context) {
                                    final items =
                                        <PopupMenuEntry<SpecialtyFilter>>[];

                                    // Add "All" option
                                    items.add(
                                      PopupMenuItem<SpecialtyFilter>(
                                        value: SpecialtyFilter(
                                          id: 0,
                                          name: translation(
                                            context,
                                          ).lbl_all_specialties,
                                          slug: 'all',
                                        ),
                                        height: 35,
                                        child: Text(
                                          translation(
                                            context,
                                          ).lbl_all_specialties,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                            color:
                                                state
                                                        .currentFilters
                                                        .selectedSpecialty ==
                                                    null
                                                ? theme.primary
                                                : theme.textPrimary,
                                            fontWeight:
                                                state
                                                        .currentFilters
                                                        .selectedSpecialty ==
                                                    null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    );

                                    // Add specialty options
                                    items.addAll(
                                      state.specialties.map((specialty) {
                                        return PopupMenuItem<SpecialtyFilter>(
                                          value: specialty,
                                          height: 35,
                                          child: Text(
                                            specialty.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color:
                                                  state
                                                          .currentFilters
                                                          .selectedSpecialty
                                                          ?.id ==
                                                      specialty.id
                                                  ? theme.primary
                                                  : theme.textPrimary,
                                              fontWeight:
                                                  state
                                                          .currentFilters
                                                          .selectedSpecialty
                                                          ?.id ==
                                                      specialty.id
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    );

                                    return items;
                                  },
                                  onSelected:
                                      (SpecialtyFilter? selectedSpecialty) {
                                        final updatedFilters = state
                                            .currentFilters
                                            .copyWith(
                                              selectedSpecialty:
                                                  selectedSpecialty?.id == 0
                                                  ? null
                                                  : selectedSpecialty,
                                              clearSpecialty:
                                                  selectedSpecialty?.id == 0,
                                            );
                                        _onFiltersChanged(updatedFilters);
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Country Filter
                            // Expanded(
                            //   child: Container(
                            //     height: 40,
                            //     decoration: BoxDecoration(
                            //       color: theme.surfaceVariant,
                            //       borderRadius: BorderRadius.circular(20),
                            //       border: Border.all(
                            //         color: theme.border,
                            //       ),
                            //     ),
                            //     child: PopupMenuButton<CountryFilter>(
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(16),
                            //       ),
                            //       offset: const Offset(0, 45),
                            //       tooltip: 'Filter by Country',
                            //       elevation: 8,
                            //       child: Container(
                            //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            //         child: Row(
                            //           mainAxisAlignment: MainAxisAlignment.center,
                            //           children: [
                            //             Icon(
                            //               Icons.location_on_outlined,
                            //               size: 16,
                            //               color: Colors.blue[600],
                            //             ),
                            //             const SizedBox(width: 6),
                            //             Expanded(
                            //               child: Text(
                            //                 state.currentFilters.selectedCountry?.name ?? 'All Countries',
                            //                 style: const TextStyle(
                            //                   fontSize: 12,
                            //                   fontFamily: 'Poppins',
                            //                   fontWeight: FontWeight.w500,
                            //                 ),
                            //                 overflow: TextOverflow.ellipsis,
                            //               ),
                            //             ),
                            //             Icon(
                            //               Icons.arrow_drop_down,
                            //               size: 16,
                            //               color: Colors.blue[600],
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //       itemBuilder: (BuildContext context) {
                            //         final items = <PopupMenuEntry<CountryFilter>>[];
                            //
                            //         // Add "All" option
                            //         items.add(
                            //           PopupMenuItem<CountryFilter>(
                            //             value: CountryFilter(id: 0, name: 'All Countries', code: 'all', flag: ''),
                            //             height: 35,
                            //             child: Text(
                            //               'All Countries',
                            //               style: TextStyle(
                            //                 fontSize: 12,
                            //                 fontFamily: 'Poppins',
                            //                 color: state.currentFilters.selectedCountry == null
                            //                     ? Colors.blue[800]
                            //                     : Colors.black87,
                            //                 fontWeight: state.currentFilters.selectedCountry == null
                            //                     ? FontWeight.w600
                            //                     : FontWeight.w400,
                            //               ),
                            //             ),
                            //           ),
                            //         );
                            //
                            //         // Add country options
                            //         items.addAll(
                            //           state.countries.map((country) {
                            //             return PopupMenuItem<CountryFilter>(
                            //               value: country,
                            //               height: 35,
                            //               child: Row(
                            //                 children: [
                            //                   if (country.flag.isNotEmpty) ...[
                            //                     Text(
                            //                       country.flag,
                            //                       style: const TextStyle(fontSize: 14),
                            //                     ),
                            //                     const SizedBox(width: 8),
                            //                   ],
                            //                   Expanded(
                            //                     child: Text(
                            //                       country.name,
                            //                       style: TextStyle(
                            //                         fontSize: 12,
                            //                         fontFamily: 'Poppins',
                            //                         color: state.currentFilters.selectedCountry?.id == country.id
                            //                             ? Colors.blue[800]
                            //                             : Colors.black87,
                            //                         fontWeight: state.currentFilters.selectedCountry?.id == country.id
                            //                             ? FontWeight.w600
                            //                             : FontWeight.w400,
                            //                       ),
                            //                       overflow: TextOverflow.ellipsis,
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             );
                            //           }).toList(),
                            //         );
                            //
                            //         return items;
                            //       },
                            //       onSelected: (CountryFilter? selectedCountry) {
                            //         final updatedFilters = state.currentFilters.copyWith(
                            //           selectedCountry: selectedCountry?.id == 0 ? null : selectedCountry,
                            //           clearCountry: selectedCountry?.id == 0,
                            //         );
                            //         _onFiltersChanged(updatedFilters);
                            //       },
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(width: 8),
                            // Sort Options
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.primary.withOpacity(0.2),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                offset: const Offset(0, 45),
                                tooltip: translation(context).lbl_sort_options,
                                elevation: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sort_rounded,
                                        size: 16,
                                        color: theme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: theme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem<String>(
                                      value: 'newest',
                                      height: 35,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: theme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            translation(
                                              context,
                                            ).lbl_newest_first,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color:
                                                  state.currentFilters.sortBy ==
                                                      'newest'
                                                  ? theme.primary
                                                  : theme.textPrimary,
                                              fontWeight:
                                                  state.currentFilters.sortBy ==
                                                      'newest'
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'popular',
                                      height: 35,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            size: 16,
                                            color: theme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            translation(
                                              context,
                                            ).lbl_most_popular,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color:
                                                  state.currentFilters.sortBy ==
                                                      'popular'
                                                  ? theme.primary
                                                  : theme.textPrimary,
                                              fontWeight:
                                                  state.currentFilters.sortBy ==
                                                      'popular'
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'comments',
                                      height: 35,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.comment_outlined,
                                            size: 16,
                                            color: theme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            translation(
                                              context,
                                            ).lbl_most_discussed,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color:
                                                  state.currentFilters.sortBy ==
                                                      'comments'
                                                  ? theme.primary
                                                  : theme.textPrimary,
                                              fontWeight:
                                                  state.currentFilters.sortBy ==
                                                      'comments'
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                onSelected: (String? sortBy) {
                                  final updatedFilters = state.currentFilters
                                      .copyWith(sortBy: sortBy);
                                  _onFiltersChanged(updatedFilters);
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DiscussionListBloc, DiscussionListState>(
              builder: (context, state) {
                if (state is DiscussionListLoading) {
                  return const CaseDiscussionListShimmer();
                }

                if (state is DiscussionListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          translation(context).msg_error_loading_discussions,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _onRefresh,
                          child: Text(translation(context).lbl_retry),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DiscussionListLoaded) {
                  // Show shimmer if specialties/countries are still loading
                  if (state.specialties.isEmpty &&
                      state.countries.isEmpty &&
                      state.discussions.isEmpty) {
                    return const CaseDiscussionListShimmer();
                  }

                  return Column(
                    children: [
                      // Stats bar
                      DiscussionStatsBar(
                        discussions: state.discussions,
                        currentFilters: state.currentFilters,
                        isLoading: state.isLoadingMore,
                      ),

                      // Content
                      Expanded(
                        child: state.discussions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: theme.textTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      translation(
                                        context,
                                      ).msg_no_discussions_found,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _hasActiveFilters(state.currentFilters)
                                          ? translation(
                                              context,
                                            ).msg_try_adjusting_filters
                                          : translation(
                                              context,
                                            ).msg_be_first_to_start_discussion,
                                      style: TextStyle(
                                        color: theme.textTertiary,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_hasActiveFilters(
                                      state.currentFilters,
                                    )) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context
                                              .read<DiscussionListBloc>()
                                              .add(
                                                UpdateFilters(
                                                  const CaseDiscussionFilters(),
                                                ),
                                              );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primary,
                                          foregroundColor: theme.buttonPrimaryText,
                                        ),
                                        child: Text(
                                          translation(
                                            context,
                                          ).lbl_clear_filters,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async => _onRefresh(),
                                color: theme.primary,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                    top: 8,
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                        16,
                                  ),
                                  itemCount:
                                      state.discussions.length +
                                      (state.hasReachedMax ? 0 : 1),
                                  itemBuilder: (context, index) {
                                    if (index >= state.discussions.length) {
                                      // Simple shimmer for load more
                                      return Container(
                                        margin: const EdgeInsets.all(16),
                                        height: 80,
                                        child: Shimmer.fromColors(
                                          baseColor: theme.divider,
                                          highlightColor: theme.cardBackground,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.cardBackground,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final discussion = state.discussions[index];
                                    return DiscussionCard(
                                      discussion: discussion,
                                      onTap: () => _navigateToDiscussionDetail(
                                        discussion.id,
                                      ),
                                      onLike: () =>
                                          _likeDiscussion(discussion.id),
                                      onDelete: () =>
                                          _deleteDiscussion(discussion.id),
                                      onEdit: () => _editDiscussion(discussion),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDiscussionDetail(int caseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(caseId: caseId),
      ),
    );
  }

  void _navigateToCreateDiscussion() {
    BlocProvider(
      create: (context) => CreateDiscussionBloc(
        repository: CaseDiscussionRepository(
          baseUrl: AppData.base2,
          getAuthToken: () {
            return AppData.userToken ?? "";
          },
        ),
      ),
      child: const CreateDiscussionScreen(),
    ).launch(context).then((created) {
      if (created == true) {
        _onRefresh();
      }
    });
  }

  void _likeDiscussion(int caseId) {
    context.read<DiscussionListBloc>().add(LikeDiscussion(caseId));
  }

  void _deleteDiscussion(int caseId) {
    context.read<DiscussionListBloc>().add(DeleteDiscussion(caseId));
  }

  void _editDiscussion(CaseDiscussionListItem discussion) async {
    print('🔄 Navigating to edit mode for case: ${discussion.id}');

    // For editing, we need to convert list item to full case discussion
    // For now, create a basic CaseDiscussion from the list item data
    final caseDiscussion = CaseDiscussion(
      id: discussion.id,
      title: discussion.title,
      description: discussion.title, // Use title as description for list items
      status: 'active',
      specialty: discussion.author.specialty,
      createdAt: discussion.createdAt,
      updatedAt: discussion.createdAt,
      author: discussion.author,
      stats: discussion.stats,
      symptoms: discussion.parsedTags,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => CreateDiscussionBloc(
            repository: CaseDiscussionRepository(
              baseUrl: AppData.base2,
              getAuthToken: () => AppData.userToken ?? "",
            ),
          ),
          child: CreateDiscussionScreen(existingCase: caseDiscussion),
        ),
      ),
    );

    // Refresh the list if the case was updated
    if (result == true) {
      print('✅ Case updated successfully, refreshing list');
      context.read<DiscussionListBloc>().add(LoadDiscussionList(refresh: true));
    }
  }

  bool _hasActiveFilters(CaseDiscussionFilters filters) {
    return filters.selectedSpecialty != null ||
        filters.selectedCountry != null ||
        filters.status != null ||
        filters.sortBy != null ||
        (filters.searchQuery != null && filters.searchQuery!.isNotEmpty);
  }
}
