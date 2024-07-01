import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../ads_setting/ads_widget/banner_ads_widget.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/followers_bloc.dart';
import 'component/follower_widget.dart';

class FollowerScreen extends StatefulWidget {
  Function? backPress;
  bool isFollowersScreen;
  String userId;
  FollowerScreen({this.backPress,super.key, required  this.isFollowersScreen,required this.userId});

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  FollowersBloc followersBloc = FollowersBloc();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isSearchShow=false;
  @override
  void initState() {
    followersBloc.add(FollowersLoadPageEvent(
      page: 1,
      searchTerm: '',
      userId: widget.userId
    ));
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
          page: 1,
          searchTerm: query,
            userId: widget.userId

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
      appBar:AppBar(
        backgroundColor:  svGetScaffoldColor(),
        surfaceTintColor:  svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(widget.isFollowersScreen?'Followers':'Following',
            style: boldTextStyle(size: 18)),

        leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_rounded,
                color: svGetBodyColor()),
            onPressed:(){
              Navigator.pop(context);
            }
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () {
              setState(() {});
              isSearchShow = !isSearchShow;
            },
            child:  isSearchShow
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
        children: [
          const Divider(thickness: 0.3,color: Colors.grey,endIndent: 20,indent: 20,),
          if(isSearchShow) Container(
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
                border: Border.all(
                    color: Colors.black, width: 0.3)),
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
          ),
          BlocConsumer<FollowersBloc, FollowersState>(
            bloc: followersBloc,
            // listenWhen: (previous, current) => current is FollowersState,
            // buildWhen: (previous, current) => current is! FollowersState,
            listener: (BuildContext context, FollowersState state) {
              if (state is FollowersDataError) {
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
              if (state is FollowersPaginationLoadingState) {
                return  Expanded(
                    child: Center(child: CircularProgressIndicator(color: svGetBodyColor(),)));
              } else if (state is FollowersPaginationLoadedState) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                final bloc = followersBloc;
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      // if (bloc.pageNumber <= bloc.numberOfPage) {
                      //   if (index ==
                      //       bloc.searchPeopleData.length -
                      //           bloc.nextPageTrigger) {
                      //     bloc.add(FollowersCheckIfNeedMoreDataEvent(
                      //         index: index));
                      //   }
                      // }
                      return
                      //   bloc.numberOfPage != bloc.pageNumber - 1 &&
                      //     index >= bloc.searchPeopleData.length - 1
                      //     ?  Center(
                      //   child: CircularProgressIndicator(color: svGetBodyColor(),),
                      // )
                      //     :
                        FollowerWidget(
                          userId: widget.userId,
                          bloc: bloc,
                          element:widget.isFollowersScreen? bloc.followerDataModel!.followers![index]:bloc.followerDataModel!.following![index],
                          onTap: () {
                            if(widget.isFollowersScreen) {
                              if (bloc.followerDataModel?.followers![index]
                                  .isCurrentlyFollow ??
                                  false) {
                                bloc.add(SetUserFollow(
                                    followersBloc.followerDataModel?.followers?[index].id ?? '',
                                    'unfollow'));

                                bloc.followerDataModel?.followers![index]
                                    .isCurrentlyFollow = false;
                              } else {
                                bloc.add(SetUserFollow(
                                    bloc.followerDataModel?.followers![index].id ?? '',
                                    'follow'));

                                bloc.followerDataModel!.followers![index]
                                    .isCurrentlyFollow = true;
                              }
                            }else{

                              if (bloc.followerDataModel?.following![index]
                                  .isCurrentlyFollow ??
                                  false) {
                                bloc.add(SetUserFollow(
                                    followersBloc.followerDataModel?.following?[index].id ?? '',
                                    'unfollow'));

                                bloc.followerDataModel?.following![index]
                                    .isCurrentlyFollow = false;
                              } else {
                                bloc.add(SetUserFollow(
                                    bloc.followerDataModel?.following![index].id ?? '',
                                    'follow'));

                                bloc.followerDataModel!.following![index]
                                    .isCurrentlyFollow = true;
                              }
                            }
                          });
                      // SVProfileFragment().launch(context);
                    },
                    // separatorBuilder: (BuildContext context, int index) {
                    //   return const Divider(height: 20);
                    // },
                    itemCount:widget.isFollowersScreen? bloc.followerDataModel?.followers?.length:bloc.followerDataModel?.following?.length,
                  ),
                );
              } else if (state is FollowersDataError) {
                return const Expanded(
                  child: Center(
                    child: Text(''),
                  ),
                );
              } else {
                return Expanded(
                    child: Center(child: CircularProgressIndicator(color: svGetBodyColor(),)));
              }
            },
          ),
          if(AppData.isShowGoogleBannerAds??false)BannerAdWidget()
        ],
      ),
      // SingleChildScrollView(
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text('RECENT', style: boldTextStyle()).paddingAll(16),
      //       ListView.separated(
      //         padding: EdgeInsets.all(16),
      //         shrinkWrap: true,
      //         physics: NeverScrollableScrollPhysics(),
      //         itemBuilder: (context, index) {
      //           return SVSearchCardComponent(element: list[index]).onTap(() {
      //             // SVProfileFragment().launch(context);
      //           });
      //         },
      //         separatorBuilder: (BuildContext context, int index) {
      //           return Divider(height: 20);
      //         },
      //         itemCount: list.length,
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
