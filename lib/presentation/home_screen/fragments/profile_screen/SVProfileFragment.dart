import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/followers_screen/follower_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/profile_shimmer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: svGetScaffoldColor(),
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
            return Center(child: ProfileShimmer());
          } else if (state is PaginationLoadedState) {
            return SVProfileHeaderComponent(
                userProfile: profileBloc.userProfile,
                profileBoc: profileBloc,
                isMe: widget.userId == null);
          } else if (state is DataError) {
            return RetryWidget(errorMessage: "Something went wrong please try again",onRetry: (){
              try {
                print(widget.userId);
                if (widget.userId == null) {
                  print('object1 ${AppData.logInUserId}');
                  profileBloc.add(LoadPageEvent(userId: AppData.logInUserId, page: 1));
                } else {
                  print('object ${widget.userId}');
                  profileBloc.add(LoadPageEvent(userId: widget.userId, page: 1));
                }
              } catch (e) {
                debugPrint(e.toString());
              }

            });
          } else {
            return Center(child: Text('Unknown state${state.toString()}'));
          }
        },
      ),
    );
  }
}
