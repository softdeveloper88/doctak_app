import 'dart:async';

import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../home_screen/utils/SVCommon.dart';
import '../../main.dart';
import 'bloc/followers_bloc.dart';
import 'component/follower_widget.dart';

class FollowerScreen extends StatefulWidget {
  final Function? backPress;
  final bool isFollowersScreen;
  final String userId;
  
  const FollowerScreen({
    this.backPress,
    super.key,
    required this.isFollowersScreen,
    required this.userId,
  });

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  FollowersBloc followersBloc = FollowersBloc();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isSearchShow = false;
  
  @override
  void initState() {
    followersBloc.add(
        FollowersLoadPageEvent(page: 1, searchTerm: '', userId: widget.userId));
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
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
      followersBloc.add(
        FollowersLoadPageEvent(
            page: 1, searchTerm: query, userId: widget.userId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: Column(
        children: [
          // Custom AppBar with DoctakAppBar
          DoctakAppBar(
            title: widget.isFollowersScreen 
              ? translation(context).lbl_followers 
              : translation(context).lbl_following,
            titleIcon: widget.isFollowersScreen 
              ? Icons.people_rounded
              : Icons.person_add_rounded,
            actions: [
              // Search icon button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSearchShow ? Icons.close : Icons.search,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    isSearchShow = !isSearchShow;
                    if (!isSearchShow) {
                      _searchController.clear();
                      followersBloc.add(
                        FollowersLoadPageEvent(
                          page: 1, 
                          searchTerm: '', 
                          userId: widget.userId
                        ),
                      );
                    }
                  });
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          // Search field with animated visibility
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isSearchShow ? 72 : 0,
            color: svGetScaffoldColor(),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: isSearchShow
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: appStore.isDarkMode
                          ? Colors.blueGrey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.blue.withAlpha(51),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(13),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.blue.withAlpha(153),
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: AppTextField(
                              controller: _searchController,
                              textFieldType: TextFieldType.NAME,
                              textStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: appStore.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: translation(context).lbl_search_people,
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: appStore.isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              followersBloc.add(
                                FollowersLoadPageEvent(
                                  page: 1,
                                  searchTerm: '',
                                  userId: widget.userId
                                ),
                              );
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(26),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Icon(
                                Icons.clear,
                                color: Colors.blue.withAlpha(153),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
            ),
          ),
          
          // List content
          BlocConsumer<FollowersBloc, FollowersState>(
            bloc: followersBloc,
            listener: (BuildContext context, FollowersState state) {
              if (state is FollowersDataError) {
                // Handle error
              }
            },
            builder: (context, state) {
              if (state is FollowersPaginationLoadingState) {
                return const Expanded(
                  child: ProfileListShimmer()
                );
              } else if (state is FollowersPaginationLoadedState) {
                final bloc = followersBloc;
                final itemCount = widget.isFollowersScreen
                    ? bloc.followerDataModel?.followers?.length ?? 0
                    : bloc.followerDataModel?.following?.length ?? 0;
                
                if (itemCount == 0) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isFollowersScreen 
                                ? Icons.people_outline_rounded
                                : Icons.person_add_disabled_rounded,
                              size: 48,
                              color: Colors.blue[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isFollowersScreen
                              ? 'No followers yet'
                              : 'Not following anyone yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isFollowersScreen
                              ? 'When people follow you, they\'ll appear here'
                              : 'Start following people to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 16,
                      left: 0,
                      right: 0,
                    ),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return FollowerWidget(
                        userId: widget.userId,
                        bloc: bloc,
                        element: widget.isFollowersScreen
                            ? bloc.followerDataModel!.followers![index]
                            : bloc.followerDataModel!.following![index],
                        onTap: () async {
                          if (widget.isFollowersScreen) {
                            if (bloc.followerDataModel?.followers![index]
                                    .isCurrentlyFollow ??
                                false) {
                              bloc.add(SetUserFollow(
                                  followersBloc.followerDataModel
                                          ?.followers?[index].id ??
                                      '',
                                  'unfollow'));

                              bloc.followerDataModel?.followers![index]
                                  .isCurrentlyFollow = false;
                            } else {
                              bloc.add(SetUserFollow(
                                  bloc.followerDataModel
                                          ?.followers![index].id ??
                                      '',
                                  'follow'));

                              bloc.followerDataModel!.followers![index]
                                  .isCurrentlyFollow = true;
                            }
                          } else {
                            if (bloc.followerDataModel?.following![index]
                                    .isCurrentlyFollow ??
                                false) {
                              bloc.add(SetUserFollow(
                                  followersBloc.followerDataModel
                                          ?.following?[index].id ??
                                      '',
                                  'unfollow'));

                              bloc.followerDataModel?.following![index]
                                  .isCurrentlyFollow = false;
                            } else {
                              bloc.add(SetUserFollow(
                                  bloc.followerDataModel
                                          ?.following![index].id ??
                                      '',
                                  'follow'));

                              bloc.followerDataModel!.following![index]
                                  .isCurrentlyFollow = true;
                            }
                          }
                        },
                      );
                    },
                    itemCount: itemCount,
                  ),
                );
              } else if (state is FollowersDataError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            followersBloc.add(
                              FollowersLoadPageEvent(
                                page: 1, 
                                searchTerm: '', 
                                userId: widget.userId
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Expanded(
                  child: ProfileListShimmer()
                );
              }
            },
          ),
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }
}