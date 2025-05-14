import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/components/SVSearchCardComponent.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../fragments/search_people/bloc/search_people_state.dart';
import '../../../utils/shimmer_widget.dart';

class SearchPeopleList extends StatelessWidget {
  SearchPeopleList({required this.searchPeopleBloc, super.key});

  SearchPeopleBloc searchPeopleBloc;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchPeopleBloc, SearchPeopleState>(
      bloc: searchPeopleBloc,
      // listenWhen: (previous, current) => current is SearchPeopleState,
      // buildWhen: (previous, current) => current is! SearchPeopleState,
      listener: (BuildContext context, SearchPeopleState state) {
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
        if (state is SearchPeoplePaginationLoadingState) {
          return const Expanded(child: UserShimmer());
        } else if (state is SearchPeoplePaginationLoadedState) {
          // print(state.drugsModel.length);
          // return _buildPostList(context);
          final bloc = searchPeopleBloc;
          if (bloc.searchPeopleData.isNotEmpty) {
            return ListView.builder(
              shrinkWrap: true,
              // physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index ==
                      bloc.searchPeopleData.length - bloc.nextPageTrigger) {
                    bloc.add(
                        SearchPeopleCheckIfNeedMoreDataEvent(index: index));
                  }
                }
                 if(bloc.numberOfPage != bloc.pageNumber - 1 &&
                        index >= bloc.searchPeopleData.length - 1
                ) {
                   return const UserShimmer();
                }
                   return SVSearchCardComponent(
                       bloc: bloc,
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
          } else {
            Center(
              child: Text(translation(context).lbl_no_search_results),
            );
          }
        }
        if (state is SearchPeopleDataError) {
          return RetryWidget(
              errorMessage: translation(context).msg_something_went_wrong_retry,
              onRetry: () {
                try {
                  searchPeopleBloc.add(
                    SearchPeopleLoadPageEvent(
                      page: 1,
                      searchTerm: '',
                    ),
                  );
                } catch (e) {
                  debugPrint(e.toString());
                }
              });
        } else {
          return Center(child: Text(translation(context).lbl_search_peoples));
        }
      },
    );
  }
}
