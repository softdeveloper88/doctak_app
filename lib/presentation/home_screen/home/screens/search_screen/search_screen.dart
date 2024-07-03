import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import '../../../fragments/search_people/bloc/search_people_bloc.dart';
import '../../../fragments/search_people/bloc/search_people_event.dart';
import '../../../fragments/search_people/bloc/search_people_state.dart';
import '../../../fragments/search_people/components/SVSearchCardComponent.dart';
import '../../../utils/SVCommon.dart';
import '../../components/SVPostComponent.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_event.dart';
import 'bloc/search_state.dart';
import 'screen_utils.dart';

class SearchScreen extends StatefulWidget {
  Function? backPress;
   SearchScreen({this.backPress,super.key});

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
    homeBloc
        .add(LoadSearchPageEvent(page: 1, search: 'a'));
    // BlocProvider.of<SearchBloc>(context).add(
    //   GetPost(
    //       page: '1',
    //       countryId: "1",
    //       searchTerm: searchTxt,
    //       type: state.typeValue),
    // );
    // BlocProvider.of<SplashBloc>(context).add(
    //     LoadDropdownData(
    //         state.countryFlag,
    //         state.typeValue,
    //         state.searchTerms ?? '',
    //         ''));
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
  bool isSearchShow=true;
  // final BannerAdManager _bannerAdManager = BannerAdManager();
  Widget _individualTab(String tabName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (tabName == 'Jobs')
          Container(
            height: 20,
            width: 1,
            decoration:  BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: svGetBodyColor(),
                        width: 1,
                        style: BorderStyle.solid))),
          ),
         Expanded(
          child: Tab(
            child: Text(tabName,style: GoogleFonts.poppins(color: svGetBodyColor()),),
          ),
        ),
        if (tabName == 'Jobs')
          Container(
            height: 20,
            width: 1,
            decoration:  BoxDecoration(
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
        appBar:AppBar(
          backgroundColor:  svGetScaffoldColor(),
          surfaceTintColor:  svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),
          title: Text('Search',
                          style: boldTextStyle(size: 18)),

          leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_rounded,
                color: svGetBodyColor()),
            onPressed:(){widget.backPress!();}
          ),
          elevation: 0,
          centerTitle: true,
          actions: [
            InkWell(
              onTap: () {
                setState(() {});
                isSearchShow = !isSearchShow;
              },
              child: isSearchShow
                  ? Icon(Icons.cancel_outlined,
                  size: 25,
                  // height: 16,
                  // width: 16,
                  // fit: BoxFit.cover,
                  color: svGetBodyColor())
                  .paddingLeft(4):Image.asset(
                'assets/images/search.png',
                height: 20,
                width: 20,
                color: svGetBodyColor(),
              ),
            ).paddingRight(16)
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(thickness: 0.3,color: Colors.grey,endIndent: 20,indent: 20,),
           if(isSearchShow) Container(
              padding: const EdgeInsets.only(left: 8.0),
              margin: const EdgeInsets.only(
                left: 16,
                top: 0.0,
                bottom: 0.0,
                right: 16,
              ),
              decoration: BoxDecoration(
                  color: context.dividerColor.withOpacity(0.4),
                  borderRadius: radius(5),
                  border: Border.all(color: svGetBodyColor(), width: 0.3)),
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
                    homeBloc
                        .add(LoadSearchPageEvent(page: 1, search: searchTxt));
                    // BlocProvider.of<SearchBloc>(context).add(
                    //   GetPost(
                    //       page: '1',
                    //       countryId: "1",
                    //       searchTerm: searchTxt,
                    //       type: state.typeValue),
                    // );
                    // BlocProvider.of<SplashBloc>(context).add(
                    //     LoadDropdownData(
                    //         state.countryFlag,
                    //         state.typeValue,
                    //         state.searchTerms ?? '',
                    //         ''));
                    drugsBloc.add(LoadPageEvent(
                      page: 1,
                      countryId: '',
                      searchTerm: searchTxt,
                    ));
                  });
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search Here',
                  hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                  suffixIcon: Image.asset(
                          'images/socialv/icons/ic_Search.png',
                          height: 16,
                          width: 16,
                          fit: BoxFit.cover,
                          color: svGetBodyColor())
                      .paddingAll(16),
                ),
              ),
            ),
            sizedBox10,
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 8),
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
                      color: svGetScaffoldColor(),
                      child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            /// Posts search Data Here
                            SVPostComponent(homeBloc),
                            /// Jobs Search Data Here
                            Column(
                              children: [
                                BlocBuilder<SplashBloc, SplashState>(
                                    builder: (context, state) {
                                  if (state is CountriesDataInitial) {
                                    return  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Center(
                                            child:
                                                CircularProgressIndicator(color: svGetBodyColor(),)),
                                      ],
                                    );
                                  } else if (state is CountriesDataLoaded) {
                                    for (var element
                                        in state.countriesModel.countries!) {
                                      if (element.countryName == state.countryFlag) {
                                        selectedValue = state
                                                .countriesModel
                                                .countries
                                                ?.first
                                                .countryName ??
                                            element.countryName;
                                      }
                                    }
                                    return Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        // Expanded(
                                        //   child: Container(
                                        //     margin: const EdgeInsets.only(
                                        //         left: 16, top: 16.0, bottom: 16.0),
                                        //     decoration: BoxDecoration(
                                        //         color: context.cardColor, borderRadius: radius(8)),
                                        //     child: AppTextField(
                                        //       textFieldType: TextFieldType.NAME,
                                        //       onChanged: (searchTxt) async {
                                        //         if (_debounce?.isActive ?? false) _debounce?.cancel();
                                        //
                                        //         _debounce =
                                        //             Timer(const Duration(milliseconds: 500), () {
                                        //               // BlocProvider.of<SearchBloc>(context).add(
                                        //               //   GetPost(
                                        //               //       page: '1',
                                        //               //       countryId: "1",
                                        //               //       searchTerm: searchTxt,
                                        //               //       type: state.typeValue),
                                        //               // );
                                        //               BlocProvider.of<SplashBloc>(context).add(
                                        //                   LoadDropdownData(
                                        //                       state.countryFlag,
                                        //                       state.typeValue,
                                        //                       state.searchTerms ?? '',
                                        //                       ''));
                                        //               drugsBloc.add(LoadPageEvent(
                                        //                   page: 1,
                                        //                   countryId: state.countryFlag != ''
                                        //                       ? state.countryFlag
                                        //                       : '${state.countriesModel.countries?.first.id ?? 1}',
                                        //                   searchTerm: searchTxt,
                                        //                   type: state.typeValue));
                                        //             });
                                        //         // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                        //       },
                                        //       decoration: InputDecoration(
                                        //         border: InputBorder.none,
                                        //         hintText: 'Search Here',
                                        //         hintStyle:
                                        //         secondaryTextStyle(color: svGetBodyColor()),
                                        //         prefixIcon: Image.asset(
                                        //             'images/socialv/icons/ic_Search.png',
                                        //             height: 16,
                                        //             width: 16,
                                        //             fit: BoxFit.cover,
                                        //             color: svGetBodyColor())
                                        //             .paddingAll(16),
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CustomDropdownField(
                                              items: state.countriesModel
                                                      .countries ??
                                                  [],
                                              value: state.countriesModel
                                                  .countries!.first.countryName,
                                              width: 50,
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

                                    return Center(
                                        child: Text(
                                            'Error: ${state.errorMessage}'));
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
                                      return  Expanded(
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator(color: svGetBodyColor(),)));
                                    } else if (state
                                        is PaginationLoadedState) {
                                      // print(state.drugsModel.length);
                                      return _buildPostList(context);
                                    } else if (state is DataError) {
                                      return Expanded(
                                        child: Center(
                                          child: Text(state.errorMessage),
                                        ),
                                      );
                                    } else {
                                      return const Expanded(
                                          child: Center(child: Text('')));
                                    }
                                  },
                                ),
                              ],
                            ),

                            /// People search Data Here
                            BlocConsumer<SearchPeopleBloc, SearchPeopleState>(
                              bloc: searchPeopleBloc,
                              // listenWhen: (previous, current) => current is SearchPeopleState,
                              // buildWhen: (previous, current) => current is! SearchPeopleState,
                              listener: (BuildContext context,
                                  SearchPeopleState state) {
                                if (state is SearchPeopleDataError) {
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
                                if (state
                                    is SearchPeoplePaginationLoadingState) {
                                  return  Center(
                                      child: CircularProgressIndicator(color: svGetBodyColor(),));
                                } else if (state
                                    is SearchPeoplePaginationLoadedState) {
                                  // print(state.drugsModel.length);
                                  // return _buildPostList(context);
                                  final bloc = searchPeopleBloc;
                                  return bloc.searchPeopleData.isEmpty
                                      ? const Center(
                                          child: Text("No Result Found"),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          shrinkWrap: true,
                                          // physics: const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            if (bloc.pageNumber <=
                                                bloc.numberOfPage) {
                                              if (index ==
                                                  bloc.searchPeopleData
                                                          .length -
                                                      bloc.nextPageTrigger) {
                                                bloc.add(
                                                    SearchPeopleCheckIfNeedMoreDataEvent(
                                                        index: index));
                                              }
                                            }
                                            return bloc.numberOfPage !=
                                                        bloc.pageNumber - 1 &&
                                                    index >=
                                                        bloc.searchPeopleData
                                                                .length -
                                                            1
                                                ?  Center(
                                                    child:
                                                        CircularProgressIndicator(color: svGetBodyColor(),),
                                                  )
                                                : SVSearchCardComponent(
                                                    bloc: bloc,
                                                    element:
                                                        bloc.searchPeopleData[
                                                            index],
                                                    onTap: () {
                                                      if (bloc
                                                              .searchPeopleData[
                                                                  index]
                                                              .isFollowedByCurrentUser ??
                                                          false) {
                                                        bloc.add(SetUserFollow(
                                                            bloc
                                                                    .searchPeopleData[
                                                                        index]
                                                                    .id ??
                                                                '',
                                                            'unfollow'));

                                                        bloc
                                                            .searchPeopleData[
                                                                index]
                                                            .isFollowedByCurrentUser = false;
                                                      } else {
                                                        bloc.add(SetUserFollow(
                                                            bloc
                                                                    .searchPeopleData[
                                                                        index]
                                                                    .id ??
                                                                '',
                                                            'follow'));

                                                        bloc
                                                            .searchPeopleData[
                                                                index]
                                                            .isFollowedByCurrentUser = true;
                                                      }
                                                    });
                                            // SVProfileFragment().launch(context);
                                          },
                                          // separatorBuilder: (BuildContext context, int index) {
                                          //   return const Divider(height: 20);
                                          // },
                                          itemCount:
                                              bloc.searchPeopleData.length,
                                        );
                                } else if (state is SearchPeopleDataError) {
                                  return Expanded(
                                    child: Center(
                                      child: Text(state.errorMessage),
                                    ),
                                  );
                                } else {
                                  return const Center(
                                      child: Text('Search Peoples'));
                                }
                              },
                            ),
                          ]),
                    ),
                  ),
                  if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = drugsBloc;
    print("bloc$bloc");
    print("len${bloc.drugsData.length}");
    return Expanded(
      child: bloc.drugsData.isEmpty
          ? const Center(
              child: Text('No Jobs Result found'),
            )
          : ListView.builder(
              itemCount: bloc.drugsData.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
                    bloc.add(CheckIfNeedMoreDataEvent(index: index));
                  }
                }
                return bloc.numberOfPage != bloc.pageNumber - 1 &&
                        index >= bloc.drugsData.length - 1
                    ?  Center(
                        child: CircularProgressIndicator(color: svGetBodyColor(),),
                      )
                    :  Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Material(
                    color: context.cardColor,
                    elevation: 4,
                    borderRadius:
                    const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row(
                          //   mainAxisAlignment:
                          //   MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     // Text(
                          //     //   selectedIndex == 0 ? "New" : "Expired",
                          //     //   style: GoogleFonts.poppins(
                          //     //       color: Colors.red,
                          //     //       fontWeight: FontWeight.w500,
                          //     //       fontSize: kDefaultFontSize),
                          //     // ),
                          //     const Icon(Icons.bookmark_border),
                          //   ],
                          // ),
                          Text(
                            bloc.drugsData[index].jobTitle ?? "",
                            style: GoogleFonts.poppins(
                                color: svGetBodyColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          const SizedBox(height: 5),
                          Text(bloc.drugsData[index].companyName ?? 'N/A',
                              style: secondaryTextStyle(
                                  color: svGetBodyColor())),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(
                                    bloc.drugsData[index].location ??
                                        'N/A',
                                    style: secondaryTextStyle(
                                        color: svGetBodyColor())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Apply Date',
                              style: GoogleFonts.poppins(
                                  color: svGetBodyColor(),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14)),
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment:
                                MainAxisAlignment.start,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Date From',
                                      style: secondaryTextStyle(
                                          color: svGetBodyColor())),
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.date_range_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(DateTime.parse(bloc
                                              .drugsData[index]
                                              .createdAt ??
                                              'N/A'.toString())),
                                          style: secondaryTextStyle(
                                              color: svGetBodyColor())),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.start,
                                children: [
                                  Text('Date To',
                                      style: secondaryTextStyle(
                                          color: svGetBodyColor())),
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.date_range_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(DateTime.parse(bloc
                                              .drugsData[index]
                                              .lastDate ??
                                              'N/A'.toString())),
                                          style: secondaryTextStyle(
                                              color: svGetBodyColor())),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                              'Experience: ${bloc.drugsData[index].experience ?? 'N/A'}',
                              style: secondaryTextStyle(
                                  color: svGetBodyColor())),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  child: HtmlWidget(
                                    '<p>${bloc.drugsData[index].description}</p>',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    // final Uri url = Uri.parse(bloc
                                    //     .drugsData[index]
                                    //     .link!); // Assuming job.link is a non-null String
                                    // Show dialog asking the user to confirm navigation
                                    final shouldLeave =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Leave App'),
                                        content: const Text(
                                            'Would you like to leave the app to view this content?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(true),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                    // If the user confirmed, launch the URL
                                    if (shouldLeave == true) {
                                      // await launchUrl(url);
                                    } else if (shouldLeave == false) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Leaving the app canceled.')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Leaving the app canceled.')),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Apply ',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration:
                                      TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
              },
            ),
    );
  }
}
