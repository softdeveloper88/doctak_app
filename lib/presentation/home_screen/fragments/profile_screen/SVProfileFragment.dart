import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/followers_screen/follower_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import '../../profile/components/SVProfileHeaderComponent.dart';
import '../../profile/components/SVProfilePostsComponent.dart';
import '../../utils/SVColors.dart';
import '../../utils/SVCommon.dart';
import 'bloc/profile_state.dart';

class SVProfileFragment extends StatefulWidget {
  SVProfileFragment({this.userId, Key? key}) : super(key: key);
  String? userId = '';

  @override
  State<SVProfileFragment> createState() => _SVProfileFragmentState();
}

class _SVProfileFragmentState extends State<SVProfileFragment> {
  ProfileBloc profileBloc = ProfileBloc();

  @override
  void initState() {
    print(widget.userId);
    if (widget.userId == null) {
      print('object1 ${AppData.logInUserId}');
      profileBloc.add(LoadPageEvent(userId: AppData.logInUserId, page: 1));
    } else {
      print('object ${widget.userId}');
      profileBloc.add(LoadPageEvent(userId: widget.userId, page: 1));
    }
    // profileBloc.add(LoadPageEvent1());
    setStatusBarColor(Colors.transparent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:svGetScaffoldColor(),
      // appBar: AppBar(
      //   backgroundColor: svGetScaffoldColor(),
      //   // title: Text('Profile', style: boldTextStyle(size: 20)),
      //   elevation: 0,
      //   centerTitle: true,
      //   iconTheme: IconThemeData(color: context.iconColor),
      //   // actions: [
      //   //   Switch(
      //   //     onChanged: (val) {
      //   //       appStore.toggleDarkMode(value: val);
      //   //     },
      //   //     value: appStore.isDarkMode,
      //   //     activeColor: SVAppColorPrimary,
      //   //   ),
      //   //   //IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
      //   // ],
      // ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (BuildContext context, ProfileState state) {},
        bloc: profileBloc,
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return  Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
          } else if (state is PaginationLoadedState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SVProfileHeaderComponent(
                      userProfile: profileBloc.userProfile,
                      profileBoc: profileBloc,
                      isMe: widget.userId == null),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          '${profileBloc.userProfile?.user?.firstName ?? ''} ${profileBloc.userProfile?.user?.lastName ?? ''}',
                          style:GoogleFonts.poppins(color: svGetBodyColor(),fontSize: 12.sp)),
                      4.width,
                      Image.asset('images/socialv/icons/ic_TickSquare.png',
                          height: 14, width: 14, fit: BoxFit.cover),
                    ],
                  ),
                  Text(profileBloc.userProfile?.user?.specialty ?? '',
                      style: secondaryTextStyle(color: svGetBodyColor())),
                  // 24.height,
                  if (widget.userId != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MaterialButton(
                          height: 30.0,
                          minWidth: 100,
                          onPressed: () {
                            ChatRoomScreen(username: '${profileBloc.userProfile?.user?.firstName} ${profileBloc.userProfile?.user?.lastName}',profilePic: '${profileBloc.userProfile?.profilePicture?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',id: '${profileBloc.userProfile?.user?.id}',roomId: '',).launch(context);
                          },
                          elevation: 0,
                          color: SVAppColorPrimary,
                          child: Text('Chat',style: boldTextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 10,),
                        MaterialButton(
                          height: 30.0,
                          minWidth: 100,
                          onPressed: () {
                            if (profileBloc.userProfile!.isFollowing?? false) {
                              profileBloc.add(SetUserFollow(
                                  profileBloc.userProfile?.user?.id ?? '',
                                  'unfollow'));

                              profileBloc.userProfile!.isFollowing= false;
                            } else {
                              profileBloc.add(SetUserFollow(
                                  profileBloc.userProfile?.user?.id?? '',
                                  'follow'));

                              profileBloc.userProfile!.isFollowing = true;
                            }
                            setState(() {});
                          },
                          elevation: 0,
                          color: SVAppColorPrimary,
                          child: Text(profileBloc.userProfile?.isFollowing??false?'Following':"Follow",style: boldTextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  24.height,
                  if(AppData.isShowGoogleBannerAds??false)BannerAdWidget(),
                  8.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: (){

                        },
                        child: Column(
                          children: [
                            Text('Posts',
                                style: secondaryTextStyle(
                                    color: svGetBodyColor(), size: 12)),
                            4.height,
                            Text('${profileBloc.userProfile?.totalPosts ?? ''}',
                                style: boldTextStyle(size: 18)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                          if(widget.userId != null) {
                            FollowerScreen(isFollowersScreen: true,userId: widget.userId.toString(),).launch(
                                context);
                          }else{
                            FollowerScreen(isFollowersScreen: true,userId: AppData.logInUserId,).launch(
                                context);
                          }
                        },
                        child: Column(
                          children: [
                            Text('Followers',
                                style: secondaryTextStyle(
                                    color: svGetBodyColor(), size: 12)),
                            4.height,
                            Text(
                                profileBloc.userProfile?.totalFollows
                                        ?.totalFollowings ??
                                    '',
                                style: boldTextStyle(size: 18)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                          if(widget.userId != null) {
                            FollowerScreen(isFollowersScreen: false,userId: widget.userId.toString(),).launch(
                                context);
                          }else{
                            FollowerScreen(isFollowersScreen: false,userId: AppData.logInUserId,).launch(
                                context);
                          }
                        },
                        child: Column(
                          children: [
                            Text('Followings',
                                style: secondaryTextStyle(
                                    color: svGetBodyColor(), size: 12)),
                            4.height,
                            Text(
                                profileBloc.userProfile?.totalFollows
                                        ?.totalFollowers ??
                                    '',
                                style: boldTextStyle(size: 18)),
                          ],
                        ),
                      )
                    ],
                  ),
                  4.height,
                   Divider(color: Colors.grey[200],endIndent: 16,indent: 16,),
                  SVProfilePostsComponent(profileBloc,),
                  16.height,
                ],
              ),
            );
          } else if (state is DataError) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          } else {
            return Center(child: Text('Unknown state${state.toString()}'));
          }
        },
      ),
    );
  }
}
