import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import '../../../fragments/search_people/bloc/search_people_bloc.dart';
import '../../../fragments/search_people/bloc/search_people_event.dart';
import '../../../fragments/search_people/bloc/search_people_state.dart';
import '../../../fragments/search_people/components/SVSearchCardComponent.dart';
import '../../../utils/SVCommon.dart';
import '../../components/SVPostComponent.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_state.dart';
import 'screen_utils.dart';
import 'bloc/search_event.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
    // drugsBloc.add(
    //   LoadPageEvent(
    //       page: 1,
    //       countryId: AppData.countryName,
    //       searchTerm: '',
    //       type: 'Brand'),
    // );
    super.initState();
    // _scrollController = ScrollController()..addListener(_onScroll);
  }
  var selectedValue;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sizedBox10,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 8.0),

                  decoration: BoxDecoration(
                      color: context.cardColor, borderRadius: radius(8)),
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
                        homeBloc.add(LoadSearchPageEvent(page: 1,search: searchTxt));
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
                            searchTerm: searchTxt,));
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
              ),
              sizedBox10,
              Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: gOffWhite,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 6),
                        child: TabBar(
                          onTap: (index) {
                            setState(() {
                              selectIndex = index;
                            });
                          },
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 05),
                          indicatorColor: gOffWhite,
                          tabs: [
                            selectIndex != 0
                                ? const Text(
                                    'Posts',
                                    style:
                                        TextStyle(color: gBlack, fontSize: 15),
                                  )
                                : Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      // color: const Color(0xffe9e9e9)),
                                      color: gWhite,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Posts',
                                        style: TextStyle(
                                            color: gBlack, fontSize: 15),
                                      ),
                                    ),
                                  ),
                            selectIndex != 1
                                ? const Text(
                                    'Jobs',
                                    style:
                                        TextStyle(color: gBlack, fontSize: 15),
                                  )
                                : Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      // color: const Color(0xffe9e9e9)),
                                      color: gWhite,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Jobs',
                                        style: TextStyle(
                                            color: gBlack, fontSize: 15),
                                      ),
                                    ),
                                  ),
                            selectIndex != 2
                                ? const Text(
                                    'Peoples',
                                    style:
                                        TextStyle(color: gBlack, fontSize: 15),
                                  )
                                : Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      // color: const Color(0xffe9e9e9)),
                                      color: gWhite,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Peoples',
                                        style: TextStyle(
                                            color: gBlack, fontSize: 18),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
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
                                    return const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Center(
                                            child: CircularProgressIndicator()),
                                      ],
                                    );
                                  } else if (state is CountriesDataLoaded) {
                                    for (var element
                                        in state.countriesModel.countries!) {
                                      if (element.flag == state.countryFlag) {
                                        selectedValue = state.countriesModel
                                                .countries?.first.flag ??
                                            element.flag;
                                      }
                                    }
                                    return Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CustomDropdownField(
                                            items: state
                                                    .countriesModel.countries ??
                                                [],
                                            value: state.countriesModel
                                                .countries!.first.flag,
                                            width: 50,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 0,
                                            ),
                                            onChanged: (String? newValue) {
                                              print("ddd ${state.countryFlag}");
                                              var index = state
                                                  .countriesModel.countries!
                                                  .indexWhere((element) =>
                                                      newValue == element.flag);
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

                                    return const Center(
                                        child: Text('Unknown state'));
                                  }
                                }),
                                BlocConsumer<SearchBloc, SearchState>(
                                  bloc: drugsBloc,
                                  // listenWhen: (previous, current) => current is SearchState,
                                  // buildWhen: (previous, current) => current is! SearchState,
                                  listener: (BuildContext context,
                                      SearchState state) {
                                    if (state is DataError) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          content: Text(state.errorMessage),
                                        ),
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    print("state $state");
                                    if (state is PaginationLoadingState) {
                                      return const Expanded(
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()));
                                    } else if (state is PaginationLoadedState) {
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
                                          child: Center(
                                              child: Text(
                                                  'Something went wrong')));
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
                              listener: (BuildContext context, SearchPeopleState state) {
                                if (state is SearchPeopleDataError) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: Text(state.errorMessage),
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                print("state $state");
                                if (state is SearchPeoplePaginationLoadingState) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (state is SearchPeoplePaginationLoadedState) {
                                  // print(state.drugsModel.length);
                                  // return _buildPostList(context);
                                  final bloc = searchPeopleBloc;
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    shrinkWrap: true,
                                    // physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      if (bloc.pageNumber <= bloc.numberOfPage) {
                                        if (index ==
                                            bloc.searchPeopleData.length -
                                                bloc.nextPageTrigger) {
                                          bloc.add(SearchPeopleCheckIfNeedMoreDataEvent(index: index));
                                        }
                                      }
                                      return bloc.numberOfPage != bloc.pageNumber - 1 &&
                                          index >= bloc.searchPeopleData.length - 1
                                          ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                          : SVSearchCardComponent(
                                           bloc:bloc,
                                          element: bloc.searchPeopleData[index],
                                          onTap: () {

                                            if (bloc.searchPeopleData[index]
                                                .isFollowedByCurrentUser ??
                                                false) {
                                              bloc.add(SetUserFollow(
                                                  bloc.searchPeopleData[index].id ?? '',
                                                  'unfollow'));

                                              bloc.searchPeopleData[index]
                                                  .isFollowedByCurrentUser = false;
                                            } else {
                                              bloc.add(SetUserFollow(
                                                  bloc.searchPeopleData[index].id ?? '',
                                                  'follow'));

                                              bloc.searchPeopleData[index]
                                                  .isFollowedByCurrentUser = true;
                                            }
                                          });
                                      // SVProfileFragment().launch(context);
                                    },
                                    // separatorBuilder: (BuildContext context, int index) {
                                    //   return const Divider(height: 20);
                                    // },
                                    itemCount: bloc.searchPeopleData.length,
                                  );
                                } else if (state is SearchPeopleDataError) {
                                  return Expanded(
                                    child: Center(
                                      child: Text(state.errorMessage),
                                    ),
                                  );
                                } else {
                                  return const Center(child: Text('Search Peoples'));
                                }
                              },
                            ),

                          ]),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPostList(BuildContext context) {
    final bloc = drugsBloc;
    print("bloc$bloc");
    print("len${bloc.drugsData.length}");
    return Expanded(
      child: ListView.builder(
        itemCount: bloc.drugsData.length,
        itemBuilder: (context, index) {
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
              bloc.add(CheckIfNeedMoreDataEvent(index: index));
            }
          }
          return bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= bloc.drugsData.length - 1
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bloc.drugsData[index].jobTitle ?? "",
                  style: secondaryTextStyle(
                      color: svGetBodyColor(), size: 18),
                ),
                const SizedBox(height: 5),
                Text(
                    'Company: ${bloc.drugsData[index].companyName ?? 'N/A'}',
                    style: secondaryTextStyle(color: svGetBodyColor())),
                const SizedBox(height: 10),
                Text(
                    'Experience: ${bloc.drugsData[index].experience ?? 'N/A'}',
                    style: secondaryTextStyle(color: svGetBodyColor())),
                const SizedBox(height: 5),
                Text(bloc.drugsData[index].description ?? 'N/A',
                    style: secondaryTextStyle(color: svGetBodyColor())),
                const SizedBox(height: 5),
                Text(
                    "Location: ${bloc.drugsData[index].location ?? 'N/A'}",
                    style: secondaryTextStyle(color: svGetBodyColor())),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply before: ${bloc.drugsData[index].lastDate != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(bloc.drugsData[index].lastDate!)) : 'N/A'}',
                        style: TextStyle(
                          color: bloc.drugsData[index].lastDate != null &&
                              DateTime.now().isAfter(DateTime.parse(
                                  bloc.drugsData[index].lastDate!))
                              ? Colors
                              .red // Change font color to red for expired jobs
                              : svGetBodyColor(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final Uri url = Uri.parse(bloc.drugsData[index]
                              .link!); // Assuming job.link is a non-null String
                          // Show dialog asking the user to confirm navigation
                          final shouldLeave = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Leave App'),
                              content: const Text(
                                  'Would you like to leave the app to view this content?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                          // If the user confirmed, launch the URL
                          if (shouldLeave == true) {
                            // await launchUrl(url);
                          } else if (shouldLeave == false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Leaving the app canceled.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Leaving the app canceled.')),
                            );
                          }
                        },
                        child: const Text(
                          'Apply ',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
        },
      ),
    );
  }
}