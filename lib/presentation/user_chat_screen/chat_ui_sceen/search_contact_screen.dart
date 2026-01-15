import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
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
      appBar: DoctakAppBar(title: translation(context).lbl_search_contacts, titleIcon: Icons.person_search_rounded),
      body: Column(children: [_buildSearchField(theme), _buildContactsList(theme), if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()]),
    );
  }

  Widget _buildSearchField(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.cardBackground, theme.scaffoldBackground]),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.divider, width: 1),
          boxShadow: theme.isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(Icons.search_rounded, color: theme.textSecondary, size: 24),
            ),
            Expanded(
              child: AppTextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textFieldType: TextFieldType.NAME,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: translation(context).lbl_search,
                  hintStyle: TextStyle(color: theme.textTertiary, fontFamily: 'Poppins', fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                cursorColor: theme.primary,
                textStyle: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins', fontSize: 15),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.close_rounded, color: theme.textSecondary, size: 20),
                  ),
                ),
              ),
          ],
        ),
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
            builder: (context) => AlertDialog(content: Text(state.errorMessage)),
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
                padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  if (bloc.contactPageNumber <= bloc.contactNumberOfPage) {
                    if (index == bloc.searchContactsList.length - bloc.contactNextPageTrigger) {
                      bloc.add(CheckIfNeedMoreContactDataEvent(index: index));
                    }
                  }
                  if (bloc.contactNumberOfPage != bloc.contactPageNumber - 1 && index >= bloc.searchContactsList.length - 1) {
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
          return Center(child: Text(translation(context).msg_something_went_wrong));
        }
      },
    );
  }

  Widget _buildContactItem(OneUITheme theme, ChatBloc bloc, int index) {
    final contact = bloc.searchContactsList[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ChatRoomScreen(username: '${contact.firstName ?? ''} ${contact.lastName ?? ""}', profilePic: '${contact.profilePic}', id: '${contact.id}', roomId: '').launch(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.divider, width: 1),
              boxShadow: theme.isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Picture
                  _buildContactAvatar(theme, contact),
                  const SizedBox(width: 12),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${contact.firstName ?? ''} ${contact.lastName ?? ''}",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  // Message Button
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: theme.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(OneUITheme theme, dynamic contact) {
    return GestureDetector(
      onTap: () {
        SVProfileFragment(userId: contact.id).launch(context);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.1), theme.primary.withValues(alpha: 0.05)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: (contact.profilePic == null || contact.profilePic!.isEmpty)
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.8), theme.primary]),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                )
              : CachedNetworkImage(
                  imageUrl: '${AppData.imageUrl}${contact.profilePic!}',
                  height: 52,
                  width: 52,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.surfaceVariant),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.8), theme.primary]),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                ).cornerRadiusWithClipRRect(50),
        ),
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
              decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.search_off_rounded, size: 48, color: theme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).msg_no_user_found,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
