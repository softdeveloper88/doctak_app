import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/widgets/virtualized_jobs_list.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../widgets/shimmer_widget/jobs_shimmer_loader.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import 'bloc/jobs_event.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  ProfileBloc profileBloc = ProfileBloc();
  JobsBloc jobsBloc = JobsBloc();
  final TextEditingController _controller = TextEditingController();
  List<_SearchSuggestion> _filteredSuggestions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.removeListener(_onSearchTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    profileBloc.close();
    jobsBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    jobsBloc.add(JobLoadPageEvent(page: 1, countryId: '', searchTerm: ''));
    profileBloc.add(UpdateSpecialtyDropdownValue1(''));
    _controller.addListener(_onSearchTextChanged);
    super.initState();
  }

  /// Fires on every keystroke (no debounce) for instant suggestion filtering.
  void _onSearchTextChanged() {
    if (_suppressSuggestionUpdate) return;
    final query = _controller.text;
    _filterSuggestions(query);
    setState(() {
      isShowingSuggestions = query.isNotEmpty && _filteredSuggestions.isNotEmpty;
    });
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = [];
      });
      return;
    }
    try {
      final lowerQuery = query.toLowerCase();
      final seen = <String>{};
      final suggestions = <_SearchSuggestion>[];

      // 1) Specialties from profile
      for (final s in (profileBloc.specialtyList ?? <String>[])) {
        if (s.toLowerCase().contains(lowerQuery) && seen.add(s.toLowerCase())) {
          suggestions.add(_SearchSuggestion(s, _SuggestionType.specialty));
        }
      }

      // 2) Fields from already-loaded jobs
      for (final job in jobsBloc.drugsData) {
        for (final entry in [
          MapEntry(job.jobTitle, _SuggestionType.jobTitle),
          MapEntry(job.companyName, _SuggestionType.company),
          MapEntry(job.location, _SuggestionType.location),
        ]) {
          final value = entry.key;
          if (value != null &&
              value.isNotEmpty &&
              value.toLowerCase().contains(lowerQuery) &&
              seen.add(value.toLowerCase())) {
            suggestions.add(_SearchSuggestion(value, entry.value));
          }
        }
        // Specialty names attached to the job
        for (final spec in (job.specialties ?? [])) {
          final name = spec.name;
          if (name != null &&
              name.isNotEmpty &&
              name.toLowerCase().contains(lowerQuery) &&
              seen.add(name.toLowerCase())) {
            suggestions.add(_SearchSuggestion(name, _SuggestionType.specialty));
          }
        }
      }

      setState(() {
        _filteredSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint('Error filtering suggestions: $e');
    }
  }

  String selectedValue = '';
  bool isShowingSuggestions = false;
  bool isSearchVisible = false;
  bool _suppressSuggestionUpdate = false;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          BlocBuilder<SplashBloc, SplashState>(
            builder: (context, state) {
              if (state is CountriesDataInitial) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Center(
                      child: Text(
                        translation(context).lbl_loading,
                        style: theme.bodyMedium,
                      ),
                    ),
                  ],
                );
              } else if (state is CountriesDataLoaded) {
                if (profileBloc.specialtyList?.isEmpty ?? true) {
                  profileBloc.add(UpdateSpecialtyDropdownValue1(''));
                }
                for (var element in state.countriesModel.countries!) {
                  if (element.countryName == state.countryFlag) {
                    selectedValue =
                        (state.countriesModel.countries?.first.countryName ??
                            '') +
                        (element.countryName ?? '');
                  }
                }
                return Column(
                  children: [
                    DoctakAppBar(
                      title: translation(context).lbl_jobs,
                      titleIcon: Icons.work_outline_rounded,
                      searchField: DoctakCollapsibleSearchField(
                        isVisible: isSearchVisible,
                        hintText: translation(context).lbl_search_by_specialty,
                        controller: _controller,
                        onChanged: (searchTxt) {
                          // Suggestions are handled instantly via _onSearchTextChanged listener.
                          // Only API search happens here (debounced by the search field).
                          jobsBloc.add(
                            JobLoadPageEvent(
                              page: 1,
                              countryId: state.countryFlag,
                              searchTerm: searchTxt,
                            ),
                          );
                        },
                        onClear: () {
                          setState(() {
                            isShowingSuggestions = false;
                            _filteredSuggestions.clear();
                          });
                          jobsBloc.add(
                            JobLoadPageEvent(
                              page: 1,
                              countryId: state.countryFlag,
                              searchTerm: '',
                            ),
                          );
                        },
                      ),
                      actions: [
                        // Search icon button
                        DoctakSearchToggleButton(
                          isSearching: isSearchVisible,
                          onTap: () {
                            setState(() {
                              isSearchVisible = !isSearchVisible;
                              if (!isSearchVisible) {
                                // Clear search when closing
                                _controller.clear();
                                isShowingSuggestions = false;
                                _filteredSuggestions.clear();
                                jobsBloc.add(
                                  JobLoadPageEvent(
                                    page: 1,
                                    countryId: state.countryFlag,
                                    searchTerm: '',
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        // Country dropdown with proper constraints
                        PopupMenuButton<Countries>(
                          shape: RoundedRectangleBorder(
                            borderRadius: theme.radiusL,
                          ),
                          offset: const Offset(0, 50),
                          tooltip: 'Select Country',
                          elevation: 8,
                          color: theme.cardBackground,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Center(
                              child: Text(
                                state.countryFlag != ''
                                    ? state.countriesModel.countries!
                                              .firstWhere(
                                                (element) =>
                                                    element.id.toString() ==
                                                    state.countryFlag,
                                                orElse: () => state
                                                    .countriesModel
                                                    .countries!
                                                    .first,
                                              )
                                              .flag ??
                                          ''
                                    : state
                                              .countriesModel
                                              .countries!
                                              .first
                                              .flag ??
                                          '',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return state.countriesModel.countries?.map((
                                  Countries item,
                                ) {
                                  return PopupMenuItem<Countries>(
                                    value: item,
                                    height: 48,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.countryName ?? '',
                                              style: TextStyle(
                                                color: theme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            item.flag ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList() ??
                                [];
                          },
                          onSelected: (Countries newValue) {
                            BlocProvider.of<SplashBloc>(context).add(
                              LoadDropdownData(
                                newValue.id.toString(),
                                state.typeValue,
                                state.searchTerms ?? '',
                                '',
                              ),
                            );
                            jobsBloc.add(
                              JobLoadPageEvent(
                                page: 1,
                                countryId: newValue.id.toString(),
                                searchTerm: state.searchTerms ?? "",
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    // Suggestions dropdown when searching
                    if (isShowingSuggestions)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate available height dynamically
                          final screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          final usedHeight =
                              MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              80 +
                              100; // Approximate used space
                          final availableHeight = screenHeight - usedHeight;
                          final maxHeight = (availableHeight * 0.4).clamp(
                            120.0,
                            300.0,
                          );
                          final itemHeight =
                              56.0; // Approximate ListTile height
                          final calculatedHeight =
                              (_filteredSuggestions.length * itemHeight).clamp(
                                0.0,
                                maxHeight,
                              );
                          final isScrollable =
                              _filteredSuggestions.length * itemHeight >
                              maxHeight;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            constraints: BoxConstraints(
                              maxHeight: calculatedHeight,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardBackground,
                              borderRadius: theme.radiusM,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: isScrollable
                                        ? const AlwaysScrollableScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion = _filteredSuggestions[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.surfaceVariant,
                                          borderRadius: theme.radiusM,
                                          border: Border.all(
                                            color: theme.divider,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: theme.radiusM,
                                            onTap: () {
                                              _suppressSuggestionUpdate = true;
                                              setState(() {
                                                isShowingSuggestions = false;
                                                _controller.text =
                                                    suggestion.text;
                                              });
                                              _suppressSuggestionUpdate = false;
                                              BlocProvider.of<SplashBloc>(
                                                context,
                                              ).add(
                                                LoadDropdownData(
                                                  state.countryFlag,
                                                  state.typeValue,
                                                  suggestion.text,
                                                  '',
                                                ),
                                              );
                                              jobsBloc.add(
                                                JobLoadPageEvent(
                                                  page: 1,
                                                  countryId: state.countryFlag,
                                                  searchTerm:
                                                      suggestion.text,
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 12.0,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    suggestion.type.icon,
                                                    size: 16,
                                                    color: theme.primary,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      suggestion.text,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            theme.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 12,
                                                    color: theme.textTertiary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Add scroll indicator when content is scrollable
                                if (isScrollable)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceVariant,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: theme.textSecondary,
                                        ),
                                        Text(
                                          'Scroll for more',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              } else if (state is CountriesDataError) {
                BlocProvider.of<SplashBloc>(
                  context,
                ).add(LoadDropdownData('', '', '', ''));

                return Center(
                  child: Text(
                    '${translation(context).lbl_error}: ${state.errorMessage}',
                    style: theme.bodyMedium,
                  ),
                );
              } else {
                BlocProvider.of<SplashBloc>(
                  context,
                ).add(LoadDropdownData('', '', '', ''));

                return Center(
                  child: Text(
                    translation(context).lbl_unknown_state,
                    style: theme.bodyMedium,
                  ),
                );
              }
            },
          ),
          BlocBuilder<JobsBloc, JobsState>(
            bloc: jobsBloc,
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return const Expanded(child: JobsShimmerLoader());
              } else if (state is PaginationLoadedState) {
                return Expanded(
                  child: VirtualizedJobsList(
                    jobsBloc: jobsBloc,
                    scrollController: _scrollController,
                  ),
                );
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Text(state.errorMessage, style: theme.bodyMedium),
                  ),
                );
              } else {
                return Expanded(
                  child: Center(
                    child: Text(
                      translation(context).msg_something_went_wrong,
                      style: theme.bodyMedium,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

enum _SuggestionType {
  specialty(Icons.medical_services_outlined),
  jobTitle(Icons.work_outline_rounded),
  company(Icons.business_outlined),
  location(Icons.location_on_outlined);

  const _SuggestionType(this.icon);
  final IconData icon;
}

class _SearchSuggestion {
  const _SearchSuggestion(this.text, this.type);
  final String text;
  final _SuggestionType type;
}
