import 'dart:async';

import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/SVSearchFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_job_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

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

  // @override
  // void dispose() {
  //   _bannerAd!.dispose();
  //   super.dispose();
  // }
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
        if (tabName == 'Jobs')
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
        if (tabName == 'Jobs')
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
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          surfaceTintColor: svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),
          title: Text('Search', style: boldTextStyle(size: 17,weight: FontWeight.w500)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: svGetBodyColor()),
              onPressed: () {
                widget.backPress!();
              }),
          elevation: 0,
          centerTitle: true,
          actions: [
            InkWell(
              onTap: () {
                setState(() {});
                isSearchShow = !isSearchShow;
              },
              child: isSearchShow
                  ? Icon(Icons.close,
                          size: 25,
                          // height: 16,
                          // width: 16,
                          // fit: BoxFit.cover,
                          color: svGetBodyColor())
                      .paddingLeft(4)
                  : Image.asset(
                      'assets/images/search.png',
                      height: 17,
                      width: 17,
                      color: svGetBodyColor(),
                    ),
            ).paddingRight(16)
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Divider(
            //   thickness: 0.3,
            //   color: Colors.grey,
            //   endIndent: 20,
            //   indent: 20,
            // ),
            if (isSearchShow)
              searchDataWidget(),
            sizedBox5,
            tabWidget(),
          ],
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
                return Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Center(
                        child: CircularProgressIndicator(
                          color: svGetBodyColor(),
                        )),
                  ],
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
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding:  const EdgeInsets.only(left: 8.0,right: 8.0),
                        child: CustomDropdownField(
                          items: state.countriesModel
                              .countries ??
                              [],
                          value: state.countriesModel
                              .countries!.first.countryName,
                          width: 30,
                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          onChanged: (String? newValue) {
                            var index = state
                                .countriesModel.countries!
                                .indexWhere((element) =>
                            newValue ==
                                element.countryName);
                            var countryId = state
                                .countriesModel
                                .countries![index]
                                .id;
                            // BlocProvider.of<SearchBloc>(context).add(
                            //   GetPost(
                            //       page: '1',
                            //       countryId: countryId.toString(),
                            //       searchTerm: '',
                            //       type: state.typeValue),
                            // );
                            // countryId = countryIds.toString();
                            BlocProvider.of<SplashBloc>(
                                context)
                                .add(LoadDropdownData(
                                countryId.toString(),
                                state.typeValue,
                                state.searchTerms ?? '',
                                ''));
                            drugsBloc.add(LoadPageEvent(
                                page: 1,
                                countryId:
                                countryId.toString(),
                                searchTerm:
                                state.searchTerms ?? "",
                                type: state.typeValue));

                            // BlocProvider.of<SearchBloc>(context)
                            //     .add(UpdateFirstDropdownValue(newValue!));
                          },
                        ),
                      ),
                    ),
                  ],
                );
              } else if (state is CountriesDataError) {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return const Center(
                    child: Text(''));
              } else {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return const Center(child: Text(''));
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
              return Expanded(
                  child: ShimmerCardList());
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              return SearchJobList(drugsBloc);
            } else if (state is DataError) {
              return RetryWidget(errorMessage: "Something went wrong please try again",onRetry: (){
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

              });

            } else {
              return const Expanded(
                  child: Center(child: Text('')));
            }
          },
        ),
      ],
    );
  }
 Widget searchDataWidget() {
    return  Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: const EdgeInsets.only(left: 8.0),
        decoration: BoxDecoration(
            color: context.dividerColor.withOpacity(0.4),
            borderRadius: radius(5),
            border: Border.all(color: svGetBodyColor(), width: 0.5)),
        child: AppTextField(
          textFieldType: TextFieldType.NAME,
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
            hintText: 'Search ',
            hintStyle: secondaryTextStyle(color: svGetBodyColor()),
            suffixIcon: Image.asset(
                'images/socialv/icons/ic_Search.png',
                height: 17,
                width: 17,
                fit: BoxFit.cover,
                color: svGetBodyColor())
                .paddingAll(16),
          ),
        ),
      ),
    );
  }
  Widget tabWidget() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TabBar(
              dividerHeight: 1,
              dividerColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  selectIndex = index;
                });
              },
              indicatorWeight: 4,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              unselectedLabelStyle: const TextStyle(color: Colors.grey,fontSize: 15,fontWeight: FontWeight.w500),
              labelPadding: const EdgeInsets.all(4),
              indicatorColor: SVAppColorPrimary,
              tabs: [
                _individualTab('Posts'),
                _individualTab('Jobs'),
                _individualTab('Peoples'),
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


