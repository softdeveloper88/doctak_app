import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/components/SVSearchCardComponent.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../fragments/search_people/bloc/search_people_state.dart';
import '../../../utils/shimmer_widget.dart';

class SearchPeopleList extends StatelessWidget {
  const SearchPeopleList({required this.searchPeopleBloc, super.key});

  final SearchPeopleBloc searchPeopleBloc;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocConsumer<SearchPeopleBloc, SearchPeopleState>(
      bloc: searchPeopleBloc,
      listener: (BuildContext context, SearchPeopleState state) {
        if (state is SearchPeopleDataError) {
          // Handle error if needed
        }
      },
      builder: (context, state) {
        print("state $state");
        if (state is SearchPeoplePaginationLoadingState) {
          return Container(color: theme.scaffoldBackground, child: const ProfileListShimmer());
        } else if (state is SearchPeoplePaginationLoadedState) {
          final bloc = searchPeopleBloc;
          if (bloc.searchPeopleData.isNotEmpty) {
            return Container(
              color: theme.scaffoldBackground,
              child: ListView.builder(
                key: const PageStorageKey<String>('people_list'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const ClampingScrollPhysics(),
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  if (bloc.pageNumber <= bloc.numberOfPage) {
                    if (index == bloc.searchPeopleData.length - bloc.nextPageTrigger) {
                      bloc.add(SearchPeopleCheckIfNeedMoreDataEvent(index: index));
                    }
                  }
                  if (bloc.numberOfPage != bloc.pageNumber - 1 && index >= bloc.searchPeopleData.length - 1) {
                    return Container(padding: const EdgeInsets.symmetric(vertical: 8), child: const ProfileListShimmer());
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: theme.cardDecoration,
                    child: ClipRRect(
                      borderRadius: theme.radiusL,
                      child: SVSearchCardComponent(
                        bloc: bloc,
                        element: bloc.searchPeopleData[index],
                        onTap: () {
                          if (bloc.searchPeopleData[index].isFollowedByCurrentUser ?? false) {
                            bloc.add(SetUserFollow(bloc.searchPeopleData[index].id ?? '', 'unfollow'));

                            bloc.searchPeopleData[index].isFollowedByCurrentUser = false;
                          } else {
                            bloc.add(SetUserFollow(bloc.searchPeopleData[index].id ?? '', 'follow'));

                            bloc.searchPeopleData[index].isFollowedByCurrentUser = true;
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
            return _buildEmptyState(context, theme);
          }
        }
        if (state is SearchPeopleDataError) {
          return _buildErrorState(context, theme);
        } else {
          return _buildInitialState(context, theme);
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, OneUITheme theme) {
    return Container(
      color: theme.scaffoldBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.15), theme.secondary.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: theme.primary),
            ),
            const SizedBox(height: 16),
            Text(translation(context).lbl_no_search_results, style: theme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OneUITheme theme) {
    return Container(
      color: theme.scaffoldBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 48, color: theme.error),
            ),
            const SizedBox(height: 16),
            Text(translation(context).msg_something_went_wrong_retry, style: theme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                try {
                  searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: ''));
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                translation(context).lbl_try_again,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: theme.radiusXL),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, OneUITheme theme) {
    return Container(
      color: theme.scaffoldBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.15), theme.secondary.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 48, color: theme.primary),
            ),
            const SizedBox(height: 16),
            Text(translation(context).lbl_search_peoples, style: theme.titleMedium),
          ],
        ),
      ),
    );
  }
}
