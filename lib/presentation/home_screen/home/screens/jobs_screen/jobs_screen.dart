import 'dart:async';

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
import 'package:nb_utils/nb_utils.dart';

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
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSpecialties = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    jobsBloc.add(JobLoadPageEvent(page: 1, countryId: '', searchTerm: ''));
    profileBloc.add(UpdateSpecialtyDropdownValue1(''));
    super.initState();
  }

  void _filterSpecialties(String query) {
    try {
      setState(() {
        _filteredSpecialties = profileBloc.specialtyList!
            .where(
              (specialty) =>
                  specialty.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      });
    } catch (e) {
      // Handle potential error when processing specialty list
      debugPrint('Error filtering specialties: $e');
    }
  }

  String selectedValue = '';
  bool isShowingSuggestions = false;
  bool isSearchVisible = false;

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
                                _filteredSpecialties.clear();
                                jobsBloc.add(
                                  JobLoadPageEvent(
                                    page: 1,
                                    countryId: state.countryFlag != ''
                                        ? state.countryFlag
                                        : '${state.countriesModel.countries?.first.id ?? 1}',
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
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: theme.iconButtonDecoration(),
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
                                style: const TextStyle(fontSize: 18),
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
                                                  fontFamily: 'Poppins',
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
                    Container(
                      color: theme.scaffoldBackground,
                      child: Column(
                        children: [
                          // Search field with animated visibility
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isSearchVisible ? 80 : 0,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: isSearchVisible
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 16.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.inputBackground,
                                        borderRadius: theme.radiusFull,
                                        border: Border.all(
                                          color: theme.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primary.withOpacity(
                                              0.05,
                                            ),
                                            offset: const Offset(0, 2),
                                            blurRadius: 6,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: theme.radiusFull,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12.0,
                                                  ),
                                              child: Icon(
                                                Icons.search_rounded,
                                                color: theme.primary
                                                    .withOpacity(0.6),
                                                size: 24,
                                              ),
                                            ),
                                            Expanded(
                                              child: AppTextField(
                                                controller: _controller,
                                                textFieldType:
                                                    TextFieldType.NAME,
                                                textStyle: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  color: theme.textPrimary,
                                                ),
                                                onChanged: (searchTxt) async {
                                                  if (_debounce?.isActive ??
                                                      false) {
                                                    _debounce?.cancel();
                                                  }
                                                  _debounce = Timer(
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    () {
                                                      _filterSpecialties(
                                                        searchTxt,
                                                      );
                                                      setState(() {
                                                        isShowingSuggestions =
                                                            searchTxt
                                                                .isNotEmpty &&
                                                            _filteredSpecialties
                                                                .isNotEmpty;
                                                      });
                                                      BlocProvider.of<
                                                            SplashBloc
                                                          >(context)
                                                          .add(
                                                            LoadDropdownData(
                                                              state.countryFlag,
                                                              state.typeValue,
                                                              searchTxt,
                                                              '',
                                                            ),
                                                          );
                                                      jobsBloc.add(
                                                        JobLoadPageEvent(
                                                          page: 1,
                                                          countryId:
                                                              state.countryFlag !=
                                                                  ''
                                                              ? state
                                                                    .countryFlag
                                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                                          searchTerm: searchTxt,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: translation(
                                                    context,
                                                  ).lbl_search_by_specialty,
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
                                                // Clear the search text but keep search field visible
                                                _controller.clear();
                                                setState(() {
                                                  isShowingSuggestions = false;
                                                  _filteredSpecialties.clear();
                                                });
                                                // Update search results
                                                jobsBloc.add(
                                                  JobLoadPageEvent(
                                                    page: 1,
                                                    countryId:
                                                        state.countryFlag != ''
                                                        ? state.countryFlag
                                                        : '${state.countriesModel.countries?.first.id ?? 1}',
                                                    searchTerm: '',
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      24,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(24),
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(24),
                                                        bottomRight:
                                                            Radius.circular(24),
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.clear,
                                                  color: theme.primary
                                                      .withOpacity(0.6),
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
                                final availableHeight =
                                    screenHeight - usedHeight;
                                final maxHeight = (availableHeight * 0.4).clamp(
                                  120.0,
                                  300.0,
                                );
                                final itemHeight =
                                    56.0; // Approximate ListTile height
                                final calculatedHeight =
                                    (_filteredSpecialties.length * itemHeight)
                                        .clamp(0.0, maxHeight);
                                final isScrollable =
                                    _filteredSpecialties.length * itemHeight >
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
                                        color: Colors.black.withOpacity(0.1),
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
                                          itemCount:
                                              _filteredSpecialties.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
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
                                                    setState(() {
                                                      isShowingSuggestions =
                                                          false;
                                                      _controller.text =
                                                          _filteredSpecialties[index];
                                                    });
                                                    BlocProvider.of<SplashBloc>(
                                                      context,
                                                    ).add(
                                                      LoadDropdownData(
                                                        state.countryFlag,
                                                        state.typeValue,
                                                        _filteredSpecialties[index],
                                                        '',
                                                      ),
                                                    );
                                                    jobsBloc.add(
                                                      JobLoadPageEvent(
                                                        page: 1,
                                                        countryId:
                                                            state.countryFlag !=
                                                                ''
                                                            ? state.countryFlag
                                                            : '${state.countriesModel.countries?.first.id ?? 1}',
                                                        searchTerm:
                                                            _filteredSpecialties[index],
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
                                                          Icons
                                                              .medical_services_outlined,
                                                          size: 16,
                                                          color: theme.primary,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            _filteredSpecialties[index],
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: theme
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 12,
                                                          color: theme
                                                              .textTertiary,
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
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    8,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    8,
                                                  ),
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
                                                  fontFamily: 'Poppins',
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
                      ),
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
