import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/presentation/complete_profile/complete_profile_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/incomplete_profile_card.dart';
import 'package:doctak_app/presentation/home_screen/home/components/user_chat_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/notification_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../localization/app_localization.dart';
import '../../../../widgets/show_loading_dialog.dart';
import '../../../notification_screen/bloc/notification_state.dart';
import '../../home/components/email_verification_widget.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  SVHomeFragment({required this.homeBloc, required this.openDrawer, Key? key})
      : super(key: key);
  Function openDrawer;
  HomeBloc homeBloc;

  @override
  State<SVHomeFragment> createState() => _SVHomeFragmentState();
}

class _SVHomeFragmentState extends State<SVHomeFragment> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  // HomeBloc widget.homeBloc = HomeBloc();
  final ScrollController _mainScrollController = ScrollController();
  NotificationBloc notificationBloc = NotificationBloc();
  String? emailVerified='';
  bool isInCompleteProfile=false;
  getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emailVerified=prefs.getString('email_verified_at')??'';
    String? specialty = prefs.getString('specialty') ?? '';
    String? countryName = prefs.getString('country') ?? '';
    String? city = prefs.getString('city') ?? '';
    isInCompleteProfile=specialty=='' || countryName =='' || city=='';
    setState(() {});
  }
  @override
  void initState() {
    _startTimer();
    getSharedPreferences();
    // PusherService(AppData.logInUserId);
    widget.homeBloc.add(PostLoadPageEvent(page: 1));
    widget.homeBloc.add(AdsSettingEvent());
    super.initState();
  }

  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      notificationCounter();
    });
  }

  void notificationCounter() {
    // Add your Bloc event here
    notificationBloc.add(NotificationCounter());

  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _refresh() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      getSharedPreferences();
      widget.homeBloc.add(PostLoadPageEvent(page: 1));
      widget.homeBloc.add(AdsSettingEvent());
      notificationBloc.add(NotificationCounter());
    });
  }

  @override
  Widget build(BuildContext context) {
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
    return Scaffold(
        // resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        backgroundColor: svGetBgColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          elevation: 0,
          leading: IconButton(
              icon: Image.asset(
                'images/socialv/icons/ic_More.png',
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                color: context.iconColor,
              ),
              onPressed: () {
                widget.openDrawer();
                FocusManager.instance.primaryFocus?.unfocus();
              }),
          title: Text(translation(context).lbl_home,
              style: boldTextStyle(size: 18,fontFamily: 'Poppins',)),
          actions: [
            // IconButton(
            //   icon: Image.asset(
            //     'assets/images/docktak_ai_light.png',
            //     width: 30,
            //     height: 30,
            //     fit: BoxFit.contain,
            //     // color: context.iconColor,
            //   ),
            //   onPressed: () {
            //     ChatDetailScreen(isFromMainScreen: true).launch(context);
            //
            //   },
            // ),
            // MaterialButton(
            //   textColor: Colors.black,
            //   // shapeBorder: RoundedRectangleBorder(borderRadius: radius(4),side: BorderSide()),
            //   // text: ' Artificial Intelligence ',
            //   // textStyle: secondaryTextStyle(color: Colors.white, size: 10),
            //   onPressed: () {
            //     ChatDetailScreen(isFromMainScreen: true).launch(context);
            //   },
            //   elevation: 6,
            //   color: Colors.white,
            //   minWidth: 80,
            //   shape: RoundedRectangleBorder(
            //       borderRadius: radius(4),
            //       side: const BorderSide(color: Colors.blue)),
            //   animationDuration: const Duration(milliseconds: 300),
            //   focusColor: SVAppColorPrimary,
            //   hoverColor: SVAppColorPrimary,
            //   splashColor: SVAppColorPrimary,
            //   height: 25,
            //   padding: const EdgeInsets.all(0),
            //   child: Text(
            //     " Artificial Intelligence ",
            //     style: TextStyle(
            //       color: Colors.black,
            //       fontSize: 10.sp,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
            IconButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(notificationBloc),
                  ),
                );
              },
              icon: Stack(
                children: [
                  IconButton(
                    color: context.cardColor,
                    icon: Icon(
                      CupertinoIcons.bell,
                      size: 28,
                      color: context.iconColor,
                    ),
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      NotificationScreen(notificationBloc).launch(context);
                    },
                  ),
                  Positioned(
                      right: 4,
                      top: 0,
                      child: BlocBuilder<NotificationBloc, NotificationState>(
                          bloc: notificationBloc,
                          builder: (context, state) {
                            int unreadCount = 0;

                            if (state is PaginationLoadedState) {
                              // unreadCount = state.unreadCount;
                              return notificationBloc.totalNotifications > 0
                                  ? Container(
                                      height: 20,
                                      width: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        border: Border.all(
                                          color: Colors.red,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${notificationBloc.totalNotifications ?? ''}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox();
                            } else {
                              return const SizedBox();
                            }
                          })),
                ],
              ),
            ),
            IconButton(
              color: context.cardColor,
              icon: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 30,
                color: context.iconColor,
              ),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                UserChatScreen().launch(context);
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                shrinkWrap: false,
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        RepaintBoundary(child: UserChatComponent()),
                        // if(emailVerified==null)const RepaintBoundary(child: VerifyEmailCard()),
                        // if(AppData.specialty=='' && AppData.countryName=='' && AppData.city=='')
                          RepaintBoundary(child: IncompleteProfileCard(emailVerified=='',isInCompleteProfile)),
                        RepaintBoundary(child: SVPostComponent(widget.homeBloc)),
                      ],
                    ),
                  ),
                ],
              ),),
        ));
  }
}
