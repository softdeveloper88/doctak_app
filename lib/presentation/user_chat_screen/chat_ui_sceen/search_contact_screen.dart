import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
// import 'package:sizer/sizer.dart'; // Not used

import '../../../main.dart';
import '../../home_screen/utils/SVColors.dart';
import '../../home_screen/utils/SVCommon.dart';
import '../../home_screen/utils/shimmer_widget.dart';
import 'chat_room_screen.dart';

class SearchContactScreen extends StatefulWidget {
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
      // Replace this with your actual search logic and API calls
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: DoctakAppBar(
        title: translation(context).lbl_search_contacts,
        titleIcon: Icons.person_search_rounded,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: appStore.isDarkMode
                    ? [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF0A0A0A),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF8F9FA),
                      ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: appStore.isDarkMode
                    ? const Color(0xFF262626)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: appStore.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appStore.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: appStore.isDarkMode
                          ? Colors.white54
                          : Colors.black45,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textFieldType: TextFieldType.NAME,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: translation(context).lbl_search,
                        hintStyle: TextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white54
                              : Colors.black45,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      cursorColor: SVAppColorPrimary,
                      textStyle: TextStyle(
                        color: appStore.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
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
                          child: Icon(
                            Icons.close_rounded,
                            color: appStore.isDarkMode
                                ? Colors.white54
                                : Colors.black45,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // TextField(
          //   controller: _searchController,
          //   decoration: InputDecoration(
          //     labelText: 'Search',
          //     hintText: 'Enter your search query...',
          //     prefixIcon: const Icon(Icons.search),
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10.0),
          //     ),
          //   ),
          //   onChanged: _onSearchChanged,
          // ),
          BlocConsumer<ChatBloc, ChatState>(
            bloc: chatBloc,
            // listenWhen: (previous, current) => current is SearchPeopleState,
            // buildWhen: (previous, current) => current is! SearchPeopleState,
            listener: (BuildContext context, ChatState state) {
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
              if (state is PaginationLoadingState) {
                return const Expanded(child: UserShimmer());
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                var bloc = chatBloc;
                if(bloc.searchContactsList.isNotEmpty) {
                  return Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      // physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (bloc.contactPageNumber <=
                            bloc.contactNumberOfPage) {
                          if (index ==
                              bloc.searchContactsList.length -
                                  bloc.contactNextPageTrigger) {
                            bloc.add(
                                CheckIfNeedMoreContactDataEvent(index: index));
                          }
                        }
                        if (bloc.contactNumberOfPage !=
                            bloc.contactPageNumber - 1 &&
                            index >= bloc.searchContactsList.length - 1) {
                          return const SizedBox(
                              height: 200,
                              child: UserShimmer());
                        } else {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ChatRoomScreen(
                                    username:
                                    '${bloc.searchContactsList[index].firstName ??
                                        ''} ${bloc.searchContactsList[index]
                                        .lastName ?? ""}',
                                    profilePic:
                                    '${bloc.searchContactsList[index]
                                        .profilePic}',
                                    id: '${bloc.searchContactsList[index].id}',
                                    roomId: '',
                                  ).launch(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: appStore.isDarkMode
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: appStore.isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: appStore.isDarkMode
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Profile Picture
                                        GestureDetector(
                                          onTap: () {
                                            SVProfileFragment(
                                                userId: bloc
                                                    .searchContactsList[
                                                index]
                                                    .id)
                                                .launch(context);
                                          },
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      SVAppColorPrimary.withOpacity(0.1),
                                                      SVAppColorPrimary.withOpacity(0.05),
                                                    ],
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(2),
                                                  child: bloc
                                                      .searchContactsList[
                                                  index]
                                                      .profilePic ==
                                                      ''
                                                      ? Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.blue.shade400,
                                                          Colors.blue.shade600,
                                                        ],
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 28,
                                                    ),
                                                  )
                                                      : CachedNetworkImage(
                                                    imageUrl:
                                                    '${AppData.imageUrl}${bloc
                                                        .searchContactsList[index]
                                                        .profilePic.validate()}',
                                                    height: 52,
                                                    width: 52,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: appStore.isDarkMode
                                                            ? Colors.white.withOpacity(0.1)
                                                            : Colors.grey.withOpacity(0.1),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.blue.shade400,
                                                            Colors.blue.shade600,
                                                          ],
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                    ),
                                                  ).cornerRadiusWithClipRRect(50),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // User Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "${bloc
                                                          .searchContactsList[index]
                                                          .firstName
                                                          .validate()} ${bloc
                                                          .searchContactsList[index]
                                                          .lastName.validate()}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: appStore.isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  // Verified badge can be added later if the model supports it
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              // Specialty can be shown if available in the model
                                            ],
                                          ),
                                        ),
                                        // Message Button
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                SVAppColorPrimary.withOpacity(0.1),
                                                SVAppColorPrimary.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: SVAppColorPrimary,
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        // SVProfileFragment().launch(context);
                      },
                      itemCount: bloc.searchContactsList.length,
                    ),
                  );
                }else{
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  SVAppColorPrimary.withOpacity(0.1),
                                  SVAppColorPrimary.withOpacity(0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: SVAppColorPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translation(context).msg_no_user_found,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: appStore.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: appStore.isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                    });
              } else {
                return Center(child: Text(translation(context).msg_something_went_wrong));
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()

          // Add your list or search results display here
        ],
      ),
    );
  }
}
