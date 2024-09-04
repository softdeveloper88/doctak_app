import 'dart:async';

import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/components/SVSearchCardComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_people.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/SVCommon.dart';

class SVSearchFragment extends StatefulWidget {
  Function? backPress;

  SVSearchFragment({this.backPress, super.key});

  @override
  State<SVSearchFragment> createState() => _SVSearchFragmentState();
}

class _SVSearchFragmentState extends State<SVSearchFragment> {
  SearchPeopleBloc searchPeopleBloc = SearchPeopleBloc();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isSearchShow = true;

  @override
  void initState() {
    searchPeopleBloc.add(SearchPeopleLoadPageEvent(
      page: 1,
      searchTerm: '',
    ));
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPeopleBloc.add(
        SearchPeopleLoadPageEvent(
          page: 1,
          searchTerm: query,
        ),
      );
      print('Search query: $query');
      // Replace this with your actual search logic and API calls
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Search Peoples', style: boldTextStyle(size: 18)),
        leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
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
                ? Icon(Icons.cancel_outlined,
                        size: 25,
                        // height: 16,
                        // width: 16,
                        // fit: BoxFit.cover,
                        color: svGetBodyColor())
                    .paddingLeft(4)
                : Image.asset(
                    'assets/images/search.png',
                    height: 20,
                    width: 20,
                    color: svGetBodyColor(),
                  ),
          ).paddingRight(16)
        ],
      ),
      body: Column(
        children: [
          const Divider(
            thickness: 0.3,
            color: Colors.grey,
            endIndent: 20,
            indent: 20,
          ),
          if (isSearchShow) searchDataField(),
          SearchPeopleList(
            searchPeopleBloc: searchPeopleBloc,
          )
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  searchDataField() {
    return Container(
      padding: const EdgeInsets.only(left: 8.0),
      margin: const EdgeInsets.only(
        left: 16,
        top: 16.0,
        bottom: 16.0,
        right: 16,
      ),
      decoration: BoxDecoration(
          color: context.dividerColor.withOpacity(0.4),
          borderRadius: radius(5),
          border: Border.all(color: Colors.black, width: 0.3)),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: AppTextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textFieldType: TextFieldType.NAME,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search People ',
            hintStyle: secondaryTextStyle(color: svGetBodyColor()),
            suffixIcon: Image.asset('images/socialv/icons/ic_Search.png',
                    height: 16,
                    width: 16,
                    fit: BoxFit.cover,
                    color: svGetBodyColor())
                .paddingAll(16),
          ),
        ),
      ),
    );
  }
}

// class SearchPeopleList extends StatelessWidget {
//   SearchPeopleBloc searchPeopleBloc;
//   SearchPeopleList({required this.searchPeopleBloc, super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<SearchPeopleBloc, SearchPeopleState>(
//       bloc: searchPeopleBloc,
//       // listenWhen: (previous, current) => current is SearchPeopleState,
//       // buildWhen: (previous, current) => current is! SearchPeopleState,
//       listener: (BuildContext context, SearchPeopleState state) {
//         if (state is SearchPeopleDataError) {
//           // showDialog(
//           //   context: context,
//           //   builder: (context) => AlertDialog(
//           //     content: Text(state.errorMessage),
//           //   ),
//           // );
//         }
//       },
//
//       builder: (context, state) {
//         print("state $state");
//         if (state is SearchPeoplePaginationLoadingState) {
//           return Expanded(
//               child: Center(
//                   child: CircularProgressIndicator(
//             color: svGetBodyColor(),
//           )));
//         } else if (state is SearchPeoplePaginationLoadedState) {
//           // print(state.drugsModel.length);
//           // return _buildPostList(context);
//           final bloc = searchPeopleBloc;
//           return Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               // shrinkWrap: true,
//               // physics: const NeverScrollableScrollPhysics(),
//               itemBuilder: (context, index) {
//                 if (bloc.pageNumber <= bloc.numberOfPage) {
//                   if (index ==
//                       bloc.searchPeopleData.length - bloc.nextPageTrigger) {
//                     bloc.add(
//                         SearchPeopleCheckIfNeedMoreDataEvent(index: index));
//                   }
//                 }
//                 return bloc.numberOfPage != bloc.pageNumber - 1 &&
//                         index >= bloc.searchPeopleData.length - 1
//                     ? Center(
//                         child: CircularProgressIndicator(
//                           color: svGetBodyColor(),
//                         ),
//                       )
//                     : SVSearchCardComponent(
//                         bloc: bloc,
//                         element: bloc.searchPeopleData[index],
//                         onTap: () {
//                           if (bloc.searchPeopleData[index]
//                                   .isFollowedByCurrentUser ??
//                               false) {
//                             bloc.add(SetUserFollow(
//                                 bloc.searchPeopleData[index].id ?? '',
//                                 'unfollow'));
//
//                             bloc.searchPeopleData[index]
//                                 .isFollowedByCurrentUser = false;
//                           } else {
//                             bloc.add(SetUserFollow(
//                                 bloc.searchPeopleData[index].id ?? '',
//                                 'follow'));
//
//                             bloc.searchPeopleData[index]
//                                 .isFollowedByCurrentUser = true;
//                           }
//                         });
//                 // SVProfileFragment().launch(context);
//               },
//               // separatorBuilder: (BuildContext context, int index) {
//               //   return const Divider(height: 20);
//               // },
//               itemCount: bloc.searchPeopleData.length,
//             ),
//           );
//         } else if (state is SearchPeopleDataError) {
//           return Expanded(
//             child: Center(
//               child: Text(state.errorMessage),
//             ),
//           );
//         } else {
//           return const Expanded(
//               child: Center(child: Text('Something went wrong')));
//         }
//       },
//     );
//   }
// }
