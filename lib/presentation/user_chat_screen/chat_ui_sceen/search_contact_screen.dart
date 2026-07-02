import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../home_screen/utils/SVCommon.dart';
import '../../home_screen/utils/shimmer_widget.dart';
import 'chat_room_screen.dart';

class SearchContactScreen extends StatefulWidget {
  const SearchContactScreen({super.key});

  @override
  _SearchContactScreenState createState() => _SearchContactScreenState();
}

class _SearchContactScreenState extends State<SearchContactScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    setStatusBarColor(svGetScaffoldColor());

    chatBloc.add(LoadContactsEvent(page: 1, keyword: ''));
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    chatBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      chatBloc.add(LoadContactsEvent(page: 1, keyword: query));
      print('Search query: $query');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_search_contacts,
        titleIcon: Icons.person_search_rounded,
        searchField: DoctakCollapsibleSearchField(
          isVisible: true,
          autofocus: false,
          hintText: translation(context).lbl_search,
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: () => _onSearchChanged(''),
        ),
      ),
      body: Column(
        children: [
          _buildContactsList(theme),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildContactsList(OneUITheme theme) {
    return BlocConsumer<ChatBloc, ChatState>(
      bloc: chatBloc,
      listener: (BuildContext context, ChatState state) {
        if (state is DataError) {
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadingState) {
          return const Expanded(child: UserShimmer());
        } else if (state is PaginationLoadedState) {
          var bloc = chatBloc;
          if (bloc.searchContactsList.isNotEmpty) {
            return Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  if (bloc.contactPageNumber <= bloc.contactNumberOfPage) {
                    if (index ==
                        bloc.searchContactsList.length -
                            bloc.contactNextPageTrigger) {
                      bloc.add(CheckIfNeedMoreContactDataEvent(index: index));
                    }
                  }
                  if (bloc.contactNumberOfPage != bloc.contactPageNumber - 1 &&
                      index >= bloc.searchContactsList.length - 1) {
                    return const SizedBox(height: 200, child: UserShimmer());
                  } else {
                    return _buildContactItem(theme, bloc, index);
                  }
                },
                itemCount: bloc.searchContactsList.length,
              ),
            );
          } else {
            return _buildEmptyState(theme);
          }
        } else if (state is DataError) {
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                chatBloc.add(LoadPageEvent(page: 1));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          return Center(
            child: Text(translation(context).msg_something_went_wrong),
          );
        }
      },
    );
  }

  Widget _buildContactItem(OneUITheme theme, ChatBloc bloc, int index) {
    final contact = bloc.searchContactsList[index];
    final fullName = '${contact.firstName ?? ''} ${contact.lastName ?? ''}'
        .trim();
    final profileUrl = AppData.fullImageUrl(contact.profilePic ?? '');

    return ProfileListItemCard(
      title: fullName,
      avatarUrl: profileUrl,
      titleSuffix: (contact.isVerified == true) ? const VerifiedBadge(size: 16) : null,
      onTap: () {
        ChatRoomScreen(
          username: fullName,
          profilePic: '${contact.profilePic}',
          id: '${contact.id}',
          conversationId: 0,
        ).launch(context);
      },
      onAvatarTap: () {
        ProfileNavigation.openUser(context, contact.id);
      },
      trailing: ProfileListIconAction(
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () {
          ChatRoomScreen(
            username: fullName,
            profilePic: '${contact.profilePic}',
            id: '${contact.id}',
            conversationId: 0,
          ).launch(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).msg_no_user_found,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
