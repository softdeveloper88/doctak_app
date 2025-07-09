import 'dart:async';

import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/SVSearchFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_job_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';

import '../../../../../main.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import '../../../fragments/search_people/bloc/search_people_bloc.dart';
import '../../../fragments/search_people/bloc/search_people_event.dart';
import '../../../utils/SVCommon.dart';
import '../../components/SVPostComponent.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_event.dart';
import 'bloc/search_state.dart';
import 'screen_utils.dart';
import 'search_people.dart';

class SearchScreen extends StatefulWidget {
  Function? backPress;
  SearchScreen({this.backPress, super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  int selectIndex = 0;
  String searchQuery = '';
  Timer? _debounce;

  SearchBloc drugsBloc = SearchBloc();
  SearchPeopleBloc searchPeopleBloc = SearchPeopleBloc();
  HomeBloc homeBloc = HomeBloc();
  @override
  void initState() {
    searchPeopleBloc.add(
      SearchPeopleLoadPageEvent(
        page: 1,
        searchTerm: '',
      ),
    );
    homeBloc.add(LoadSearchPageEvent(page: 1, search: ''));
    drugsBloc.add(LoadPageEvent(
      page: 1,
      countryId: '',
      searchTerm: '',
    ));
    super.initState();
  }

  @override
  void dispose() {
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
  bool isSearchShow = true;
  // final BannerAdManager _bannerAdManager = BannerAdManager();
  Widget _individualTab(String tabName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (tabName == translation(context).lbl_jobs)
          Container(
            height: 30,
            width: 1,
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: svGetBodyColor(),
                        width: 1,
                        style: BorderStyle.solid))),
          ),
        Expanded(
          child: Tab(
            child: Text(
              tabName,
              // style:  TextStyle(color: svGetBodyColor(),fontSize:15,fontWeight:FontWeight.w500,),
            ),
          ),
        ),
        if (tabName == translation(context).lbl_jobs)
          Container(
            height: 30,
            width: 1,
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: svGetBodyColor(),
                        width: 1,
                        style: BorderStyle.solid))),
          ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        appBar: DoctakAppBar(
          title: translation(context).lbl_search,
          titleIcon: Icons.search_rounded,
          onBackPressed: () {
            widget.backPress!();
          },
          actions: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchShow ? Icons.close : Icons.search,
                  color: Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                setState(() {
                  isSearchShow = !isSearchShow;
                });
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Container(
          color: svGetScaffoldColor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSearchShow)
                searchDataWidget(),
              const SizedBox(height: 8),
              tabWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget jobWidgetList(){
    return  Column(
      children: [
        BlocBuilder<SplashBloc, SplashState>(
            builder: (context, state) {
              if (state is CountriesDataInitial) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue[600],
                      strokeWidth: 3,
                    ),
                  ),
                );
              } else if (state is CountriesDataLoaded) {
                for (var element
                in state.countriesModel.countries!) {
                  if (element.countryName ==
                      state.countryFlag) {
                    selectedValue = state.countriesModel
                        .countries?.first.countryName ??
                        element.countryName;
                  }
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: PopupMenuButton<Countries>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          offset: const Offset(0, 50),
                          tooltip: 'Select Country',
                          elevation: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.countryFlag != '' 
                                    ? state.countriesModel.countries!.firstWhere(
                                        (element) => element.id.toString() == state.countryFlag,
                                        orElse: () => state.countriesModel.countries!.first
                                      ).flag ?? ''
                                    : state.countriesModel.countries!.first.flag ?? '',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
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
                                          style: const TextStyle(
                                            color: Colors.black87,
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
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList() ?? [];
                          },
                          onSelected: (Countries newValue) {
                            BlocProvider.of<SplashBloc>(context).add(
                              LoadDropdownData(
                                newValue.id.toString(),
                                state.typeValue,
                                state.searchTerms ?? '',
                                ''
                              )
                            );
                            drugsBloc.add(LoadPageEvent(
                              page: 1,
                              countryId: newValue.id.toString(),
                              searchTerm: state.searchTerms ?? "",
                              type: state.typeValue
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is CountriesDataError) {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return const SizedBox();
              } else {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return const SizedBox();
              }
            }),
        BlocConsumer<SearchBloc, SearchState>(
          bloc: drugsBloc,
          // listenWhen: (previous, current) => current is SearchState,
          // buildWhen: (previous, current) => current is! SearchState,
          listener: (BuildContext context,
              SearchState state) {
            if (state is DataError) {
              // showDialog(
              //   context: context,
              //   builder: (context) => AlertDialog(
              //     content: Text(state.errorMessage),
              //   ),
              // );
            }
          },
          builder: (context, state) {
            print("state $state");
            if (state is PaginationLoadingState) {
              return const Expanded(
                  child: JobsShimmerLoader());
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              return SearchJobList(drugsBloc);
            } else if (state is DataError) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        translation(context).msg_something_went_wrong_retry,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          try {
                            searchPeopleBloc.add(
                              SearchPeopleLoadPageEvent(
                                page: 1,
                                searchTerm: '',
                              ),
                            );
                            homeBloc.add(LoadSearchPageEvent(page: 1, search: 'a'));
                            drugsBloc.add(LoadPageEvent(
                              page: 1,
                              countryId: '',
                              searchTerm: '',
                            ));
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                        ),
                        label: Text(
                          translation(context).lbl_try_again,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Expanded(
                  child: SizedBox());
            }
          },
        ),
      ],
    );
  }
 Widget searchDataWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearchShow ? 72 : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: isSearchShow
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: appStore.isDarkMode
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
                        textFieldType: TextFieldType.NAME,
                        textStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: appStore.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                        onChanged: (searchTxt) async {
                          if (_debounce?.isActive ?? false) _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500), () {
                            searchPeopleBloc.add(
                              SearchPeopleLoadPageEvent(
                                page: 1,
                                searchTerm: searchTxt,
                              ),
                            );
                            homeBloc.add(LoadSearchPageEvent(page: 1, search: searchTxt));
                            drugsBloc.add(LoadPageEvent(
                              page: 1,
                              countryId: '',
                              searchTerm: searchTxt,
                            ));
                          });
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: translation(context).lbl_search,
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: appStore.isDarkMode
                                ? Colors.white60
                                : Colors.black54,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(),
      ),
    );
  }
  Widget tabWidget() {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              dividerHeight: 0,
              onTap: (index) {
                setState(() {
                  selectIndex = index;
                });
              },
              indicator: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              unselectedLabelColor: Colors.black87,
              labelColor: Colors.white,
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              tabs: [
                Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectIndex == 0)
                        Container(
                          padding: const EdgeInsets.all(3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          translation(context).lbl_posts,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: selectIndex == 0 ? 13 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectIndex == 1)
                        Container(
                          padding: const EdgeInsets.all(3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          translation(context).lbl_jobs,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: selectIndex == 1 ? 13 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectIndex == 2)
                        Container(
                          padding: const EdgeInsets.all(3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people_outline,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          "People",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: selectIndex == 2 ? 13 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: svGetBgColor(),
              child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    /// Posts search Data Here
                    SVPostComponent(homeBloc),
                    /// Jobs Search Data Here
                    jobWidgetList(),
                    /// People search Data Here
                    SearchPeopleList(searchPeopleBloc: searchPeopleBloc,)
                  ]),
            ),
          ),
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );

  }
}


