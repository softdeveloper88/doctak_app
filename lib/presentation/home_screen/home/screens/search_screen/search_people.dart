import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/components/SVSearchCardComponent.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
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
          return Container(
            decoration: BoxDecoration(
              color: appStore.isDarkMode ? Colors.black : Colors.grey[50],
            ),
            child: const ProfileListShimmer(),
          );
        } else if (state is SearchPeoplePaginationLoadedState) {
          final bloc = searchPeopleBloc;
          if (bloc.searchPeopleData.isNotEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: appStore.isDarkMode ? Colors.black : Colors.grey[50],
              ),
              child: ListView.builder(
                key: const PageStorageKey<String>('people_list'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const ClampingScrollPhysics(),
                cacheExtent: 500,
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
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const ProfileListShimmer(),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SVSearchCardComponent(
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
                        },
                      ),
                    ),
                  );
                },
                itemCount: bloc.searchPeopleData.length,
              ),
            );
          } else {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      translation(context).lbl_no_search_results,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
          }
        }
        if (state is SearchPeopleDataError) {
          return Center(
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
            );
        } else {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    translation(context).lbl_search_peoples,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
