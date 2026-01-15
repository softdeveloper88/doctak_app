import 'dart:async';

import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_job_list.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import '../../../fragments/search_people/bloc/search_people_bloc.dart';
import '../../../fragments/search_people/bloc/search_people_event.dart';
import '../../components/SVPostComponent.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_event.dart';
import 'bloc/search_state.dart';
import 'search_people.dart';

class SearchScreen extends StatefulWidget {
  final Function? backPress;
  const SearchScreen({this.backPress, super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  int selectIndex = 0;
  String searchQuery = '';
  Timer? _debounce;
  TabController? _tabController;

  SearchBloc drugsBloc = SearchBloc();
  SearchPeopleBloc searchPeopleBloc = SearchPeopleBloc();
  HomeBloc homeBloc = HomeBloc();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabChange);
    searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: ''));
    homeBloc.add(LoadSearchPageEvent(page: 1, search: ''));
    drugsBloc.add(LoadPageEvent(page: 1, countryId: '', searchTerm: ''));
  }

  void _handleTabChange() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      setState(() {
        selectIndex = _tabController!.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  //
  // @override
  // void initState() {
  //   getBannerAds();
  //   super.initState();
  // }
  // bool isLoaded = false;
  // bool isActive = true;
  // BannerAd? _bannerAd;
  //
  // getBannerAds() {
  //   _bannerAd = BannerAd(
  //       size: AdSize.banner,
  //       adUnitId: AdmobSetting.bannerUnit,
  //       listener: BannerAdListener(onAdClosed: (Ad ad) {
  //         debugPrint("Ad Closed");
  //       }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //         setState(() {
  //           isLoaded = false;
  //         });
  //       }, onAdLoaded: (Ad ad) {
  //         setState(() {
  //           isLoaded = true;
  //         });
  //         debugPrint('Ad Loaded');
  //       }, onAdOpened: (Ad ad) {
  //         debugPrint('Ad opened');
  //       }),
  //       request: const AdRequest());
  //
  //   _bannerAd!.load();
  // }
  // Widget bannerAdLoaded() {
  //   if (isLoaded == true) {
  //     return Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: SizedBox(
  //         height: _bannerAd!.size.height.toDouble(),
  //         child: AdWidget(
  //           ad: _bannerAd!,
  //         ),
  //       ),
  //     );
  //   } else {
  //     return const SizedBox(
  //       height: 8,
  //     );
  //   }
  // }
  var selectedValue;
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    searchQuery = query;
    // Apply search to all tabs
    searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: query));
    homeBloc.add(LoadSearchPageEvent(page: 1, search: query));
    drugsBloc.add(LoadPageEvent(page: 1, countryId: selectedValue?.id?.toString() ?? '', searchTerm: query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakSearchableAppBar(
        title: translation(context).lbl_search,
        searchHint: translation(context).lbl_search,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        startWithSearch: false,
        showBackButton: false,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 8), _buildTabWidget(theme)]),
    );
  }

  Widget _buildJobWidgetList(OneUITheme theme) {
    return BlocConsumer<SearchBloc, SearchState>(
      bloc: drugsBloc,
      listener: (BuildContext context, SearchState state) {
        if (state is DataError) {
          // Handle error state
        }
      },
      builder: (context, state) {
        debugPrint("state $state");
        if (state is PaginationLoadingState) {
          return const JobsShimmerLoader();
        } else if (state is PaginationLoadedState) {
          return _buildJobListWithCountryFilter(theme);
        } else if (state is DataError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.error_outline_rounded, size: 48, color: theme.error),
                ),
                const SizedBox(height: 20),
                Text(
                  translation(context).msg_something_went_wrong_retry,
                  style: TextStyle(fontSize: 15, color: theme.textSecondary, fontFamily: 'Poppins'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                theme.buildAuthPrimaryButton(
                  label: translation(context).lbl_try_again,
                  onPressed: () {
                    try {
                      searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: ''));
                      homeBloc.add(LoadSearchPageEvent(page: 1, search: 'a'));
                      drugsBloc.add(LoadPageEvent(page: 1, countryId: '', searchTerm: ''));
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                ),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildJobListWithCountryFilter(OneUITheme theme) {
    return Column(
      children: [
        BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) {
            if (state is CountriesDataInitial) {
              return const SizedBox(height: 12);
            } else if (state is CountriesDataLoaded) {
              for (var element in state.countriesModel.countries!) {
                if (element.countryName == state.countryFlag) {
                  selectedValue = state.countriesModel.countries?.first.countryName ?? element.countryName;
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primary.withValues(alpha: 0.2), width: 1),
                      ),
                      child: PopupMenuButton<Countries>(
                        color: theme.cardBackground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        offset: const Offset(0, 50),
                        tooltip: 'Select Country',
                        elevation: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.countryFlag != ''
                                    ? state.countriesModel.countries!.firstWhere((element) => element.id.toString() == state.countryFlag, orElse: () => state.countriesModel.countries!.first).flag ??
                                          ''
                                    : state.countriesModel.countries!.first.flag ?? '',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down_rounded, color: theme.primary, size: 22),
                            ],
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return state.countriesModel.countries?.map((Countries item) {
                                return PopupMenuItem<Countries>(
                                  value: item,
                                  height: 48,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.countryName ?? '',
                                            style: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(item.flag ?? '', style: const TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList() ??
                              [];
                        },
                        onSelected: (Countries newValue) {
                          BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue.id.toString(), state.typeValue, state.searchTerms ?? '', ''));
                          drugsBloc.add(LoadPageEvent(page: 1, countryId: newValue.id.toString(), searchTerm: state.searchTerms ?? "", type: state.typeValue));
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is CountriesDataError) {
              BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '', '', ''));
              return const SizedBox();
            } else {
              BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '', '', ''));
              return const SizedBox();
            }
          },
        ),
        // Job list goes here
        Expanded(child: SearchJobList(drugsBloc)),
      ],
    );
  }

  Widget _buildTabWidget(OneUITheme theme) {
    if (_tabController == null) {
      return const Expanded(child: SizedBox());
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            height: 52,
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border, width: 0.5),
            ),
            child: TabBar(
              controller: _tabController!,
              dividerHeight: 0,
              indicator: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.85)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              unselectedLabelColor: theme.textSecondary,
              labelColor: Colors.white,
              unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
              labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              tabs: [
                _buildTabItem(icon: Icons.article_outlined, label: translation(context).lbl_posts, isSelected: selectIndex == 0, theme: theme),
                _buildTabItem(icon: Icons.work_outline_rounded, label: translation(context).lbl_jobs, isSelected: selectIndex == 1, theme: theme),
                _buildTabItem(icon: Icons.people_outline_rounded, label: 'People', isSelected: selectIndex == 2, theme: theme),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              physics: const BouncingScrollPhysics(),
              children: [
                /// Posts search Data Here
                SVPostComponent(homeBloc, isNestedScroll: false),

                /// Jobs Search Data Here
                _buildJobWidgetList(theme),

                /// People search Data Here
                SearchPeopleList(searchPeopleBloc: searchPeopleBloc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required bool isSelected, required OneUITheme theme}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: theme.primary),
            ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isSelected ? 13 : 12),
            ),
          ),
        ],
      ),
    );
  }
}
