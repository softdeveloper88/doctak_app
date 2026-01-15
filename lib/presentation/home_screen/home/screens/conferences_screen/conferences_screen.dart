import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/virtualized_conferences_list.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/conferences_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import 'bloc/conference_bloc.dart';
import 'bloc/conference_event.dart';
import 'bloc/conference_state.dart';

class ConferencesScreen extends StatefulWidget {
  const ConferencesScreen({this.isFromSplash = false, super.key});

  final bool isFromSplash;

  @override
  State<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends State<ConferencesScreen> {
  final ScrollController _scrollController = ScrollController();
  final ConferenceBloc conferenceBloc = ConferenceBloc();
  SplashBloc? _splashBloc;
  bool isSearchShow = true;
  TextEditingController searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _splashBloc = BlocProvider.of<SplashBloc>(context);
      _splashBloc?.add(LoadDropdownData1('', ''));
      conferenceBloc.add(LoadPageEvent(page: 1, countryName: 'all', searchTerm: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Return loading indicator if bloc is not yet initialized
    if (_splashBloc == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_conference,
        titleIcon: Icons.event,
        onBackPressed: () {
          if (widget.isFromSplash) {
            const SVDashboardScreen().launch(context, isNewTask: true);
          } else {
            Navigator.of(context).pop();
          }
        },
        actions: [
          // Country dropdown and search actions moved here
          BlocConsumer<SplashBloc, SplashState>(
            bloc: _splashBloc!,
            listener: (_, __) {},
            builder: (context, state) {
              if (state is CountriesDataLoaded1) {
                List<dynamic> list = state.countriesModelList;
                // Get the selected country name or default to "All"
                String selectedCountryName = state.countryName.isEmpty ? 'All' : state.countryName;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Country selector
                    Container(
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: PopupMenuButton<String>(
                        tooltip: translation(context).lbl_all_countries,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        offset: const Offset(0, 40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public_rounded, size: 16, color: theme.primary),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 80),
                                child: Text(
                                  selectedCountryName,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down_rounded, size: 18, color: theme.primary),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          // Add "All" option at the beginning
                          List<PopupMenuEntry<String>> items = [
                            PopupMenuItem<String>(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(Icons.public_rounded, size: 18, color: theme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    translation(context).lbl_all_countries,
                                    style: TextStyle(fontSize: 14, fontWeight: selectedCountryName == 'All' ? FontWeight.w600 : FontWeight.normal, color: theme.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                          ];
                          // Add country items - handle both Map and String formats
                          for (final item in list) {
                            String countryName;
                            if (item is Map) {
                              countryName = item['name']?.toString() ?? '';
                            } else {
                              countryName = item?.toString() ?? '';
                            }
                            if (countryName.isEmpty) continue;

                            final bool isSelected = countryName == selectedCountryName;
                            items.add(
                              PopupMenuItem<String>(
                                value: countryName,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 18, color: isSelected ? theme.primary : theme.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      countryName,
                                      style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: theme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return items;
                        },
                        onSelected: (String newValue) {
                          final String displayName = newValue == 'all' ? '' : newValue;
                          conferenceBloc.add(LoadPageEvent(page: 1, countryName: newValue, searchTerm: state.searchTerms ?? ''));
                          _splashBloc?.add(LoadDropdownData1(displayName, state.searchTerms ?? ''));
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Search button
                    DoctakSearchToggleButton(
                      isSearching: isSearchShow,
                      onTap: () {
                        setState(() {
                          isSearchShow = !isSearchShow;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              } else if (state is CountriesDataError) {
                // Still show search button even on error
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoctakSearchToggleButton(
                      isSearching: isSearchShow,
                      onTap: () {
                        setState(() {
                          isSearchShow = !isSearchShow;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              } else {
                // Loading state - show search button
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoctakSearchToggleButton(
                      isSearching: isSearchShow,
                      onTap: () {
                        setState(() {
                          isSearchShow = !isSearchShow;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(theme),
          _buildConferenceList(),
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  // Build search field
  Widget _buildSearchField(OneUITheme theme) {
    return BlocConsumer<SplashBloc, SplashState>(
      bloc: _splashBloc!,
      listener: (_, __) {},
      builder: (context, state) {
        if (state is CountriesDataLoaded1) {
          return DoctakCollapsibleSearchField(
            isVisible: isSearchShow,
            hintText: translation(context).lbl_search_conferences,
            controller: searchController,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            onChanged: (searchTxt) {
              conferenceBloc.add(LoadPageEvent(page: 1, countryName: state.countryName, searchTerm: searchTxt));
              _splashBloc?.add(LoadDropdownData1(state.countryName, searchTxt));
            },
            onClear: () {
              conferenceBloc.add(LoadPageEvent(page: 1, countryName: state.countryName, searchTerm: ''));
            },
          );
        } else if (state is DataError) {
          _splashBloc?.add(LoadDropdownData1('', ''));
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                conferenceBloc.add(LoadPageEvent(page: 1, countryName: 'all', searchTerm: ''));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          // Loading state - still show search field
          return DoctakCollapsibleSearchField(
            isVisible: isSearchShow,
            hintText: translation(context).lbl_search_conferences,
            controller: searchController,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            onChanged: (searchTxt) {
              conferenceBloc.add(LoadPageEvent(page: 1, countryName: 'all', searchTerm: searchTxt));
            },
            onClear: () {
              conferenceBloc.add(LoadPageEvent(page: 1, countryName: 'all', searchTerm: ''));
            },
          );
        }
      },
    );
  }

  // Build conference list
  Widget _buildConferenceList() {
    return BlocConsumer<ConferenceBloc, ConferenceState>(
      bloc: conferenceBloc,
      listener: (BuildContext context, ConferenceState state) {
        if (state is DataError) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadingState) {
          return Expanded(child: ConferencesShimmerLoader());
        } else if (state is PaginationLoadedState) {
          return Expanded(
            child: VirtualizedConferencesList(conferenceBloc: conferenceBloc, scrollController: _scrollController),
          );
        } else if (state is DataError) {
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                conferenceBloc.add(LoadPageEvent(page: 1, countryName: 'all', searchTerm: ''));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          return const Expanded(child: Center(child: Text('')));
        }
      },
    );
  }
}
