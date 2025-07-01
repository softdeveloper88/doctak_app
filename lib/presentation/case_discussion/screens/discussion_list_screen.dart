import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import '../../home_screen/utils/SVColors.dart';
import '../../home_screen/utils/SVCommon.dart';
import '../bloc/create_discussion_bloc.dart';
import '../bloc/discussion_list_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/discussion_card.dart';
import '../widgets/enhanced_discussion_search_bar.dart';
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
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: DoctakAppBar(
        title: 'Case Discussions',
        titleIcon: Icons.medical_information_rounded,
        actions: [
          // Search icon button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchShow ? Icons.close : Icons.search,
                color: Colors.blue[600],
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
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.green[600],
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
            color: svGetScaffoldColor(),
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
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          decoration: BoxDecoration(
                            color: AppData.isShowGoogleBannerAds ?? false
                                ? Colors.blueGrey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: Colors.blue.withOpacity(0.6),
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
                                      color: AppData.isShowGoogleBannerAds ?? false
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onChanged: (searchTxt) async {
                                      if (_debounce?.isActive ?? false)
                                        _debounce?.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 500), () {
                                        _onSearch(searchTxt);
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Search case discussions...',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: AppData.isShowGoogleBannerAds ?? false
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
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
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      color: Colors.blue.withOpacity(0.6),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: PopupMenuButton<SpecialtyFilter>(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  offset: const Offset(0, 45),
                                  tooltip: 'Filter by Specialty',
                                  elevation: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_services_outlined,
                                          size: 16,
                                          color: Colors.blue[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            state.currentFilters.selectedSpecialty?.name ?? 'All Specialties',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: Colors.blue[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (BuildContext context) {
                                    final items = <PopupMenuEntry<SpecialtyFilter>>[];
                                    
                                    // Add "All" option
                                    items.add(
                                      PopupMenuItem<SpecialtyFilter>(
                                        value: SpecialtyFilter(id: 0, name: 'All Specialties', slug: 'all'),
                                        height: 35,
                                        child: Text(
                                          'All Specialties',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                            color: state.currentFilters.selectedSpecialty == null
                                                ? Colors.blue[800]
                                                : Colors.black87,
                                            fontWeight: state.currentFilters.selectedSpecialty == null
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
                                              color: state.currentFilters.selectedSpecialty?.id == specialty.id
                                                  ? Colors.blue[800]
                                                  : Colors.black87,
                                              fontWeight: state.currentFilters.selectedSpecialty?.id == specialty.id
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
                                  onSelected: (SpecialtyFilter? selectedSpecialty) {
                                    final updatedFilters = state.currentFilters.copyWith(
                                      selectedSpecialty: selectedSpecialty?.id == 0 ? null : selectedSpecialty,
                                      clearSpecialty: selectedSpecialty?.id == 0,
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
                            //       color: Colors.grey.withOpacity(0.1),
                            //       borderRadius: BorderRadius.circular(20),
                            //       border: Border.all(
                            //         color: Colors.blue.withOpacity(0.2),
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
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                offset: const Offset(0, 45),
                                tooltip: 'Sort Options',
                                elevation: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sort_rounded,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: Colors.blue[600],
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
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Newest First',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color: state.currentFilters.sortBy == 'newest'
                                                  ? Colors.blue[800]
                                                  : Colors.black87,
                                              fontWeight: state.currentFilters.sortBy == 'newest'
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
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Most Popular',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color: state.currentFilters.sortBy == 'popular'
                                                  ? Colors.blue[800]
                                                  : Colors.black87,
                                              fontWeight: state.currentFilters.sortBy == 'popular'
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
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Most Discussed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color: state.currentFilters.sortBy == 'comments'
                                                  ? Colors.blue[800]
                                                  : Colors.black87,
                                              fontWeight: state.currentFilters.sortBy == 'comments'
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
                                  final updatedFilters = state.currentFilters.copyWith(
                                    sortBy: sortBy,
                                  );
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
                          'Error loading discussions',
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
                          child: const Text('Retry'),
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
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No discussions found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _hasActiveFilters(state.currentFilters)
                                          ? 'Try adjusting your filters or search terms'
                                          : 'Be the first to start a discussion!',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_hasActiveFilters(state.currentFilters)) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<DiscussionListBloc>().add(
                                            UpdateFilters(const CaseDiscussionFilters()),
                                          );
                                        },
                                        child: const Text('Clear Filters'),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async => _onRefresh(),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.discussions.length + (state.hasReachedMax ? 0 : 1),
                                  itemBuilder: (context, index) {
                                    if (index >= state.discussions.length) {
                                      // Simple shimmer for load more
                                      return Container(
                                        margin: const EdgeInsets.all(16),
                                        height: 80,
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final discussion = state.discussions[index];
                                    return DiscussionCard(
                                      discussion: discussion,
                                      onTap: () => _navigateToDiscussionDetail(discussion),
                                      onLike: () => _likeDiscussion(discussion.id),
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

  void _navigateToDiscussionDetail(CaseDiscussion discussion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(caseId: discussion.id),
      ),
    );
  }

  void _navigateToCreateDiscussion() {
    BlocProvider(
      create: (context) => CreateDiscussionBloc(
        repository: CaseDiscussionRepository(baseUrl:AppData.base2,getAuthToken: (){return AppData.userToken??"";}),
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

  bool _hasActiveFilters(CaseDiscussionFilters filters) {
    return filters.selectedSpecialty != null ||
        filters.selectedCountry != null ||
        filters.status != null ||
        filters.sortBy != null ||
        (filters.searchQuery != null && filters.searchQuery!.isNotEmpty);
  }
}
