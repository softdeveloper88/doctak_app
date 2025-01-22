import 'dart:async';
import 'dart:isolate';

import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/incomplete_profile_card.dart';
import 'package:doctak_app/presentation/home_screen/home/components/user_chat_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/notification_screen.dart';
import 'package:doctak_app/presentation/notification_screen/user_announcement_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/image_constant.dart';
import '../../../../localization/app_localization.dart';
import '../../../notification_screen/bloc/notification_state.dart';
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
  String? emailVerified = '';
  bool isInCompleteProfile = false;
  getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emailVerified = prefs.getString('email_verified_at') ?? '';
    String? specialty = prefs.getString('specialty') ?? '';
    String? countryName = prefs.getString('country') ?? '';
    String? city = prefs.getString('city') ?? '';
    isInCompleteProfile = specialty == '' || countryName == '' || city == '';
    setState(() {});
  }

  @override
  void initState() {
    startIsolate();
    getSharedPreferences();
    // PusherService(AppData.logInUserId);
    widget.homeBloc.add(PostLoadPageEvent(page: 1));
    widget.homeBloc.add(AdsSettingEvent());
    super.initState();
  }

  Isolate? _isolate;
  ReceivePort? _receivePort;

  /// Start the isolate and listen for messages
  void startIsolate() async {
    _receivePort = ReceivePort();

    // Spawn the isolate and pass the SendPort of the ReceivePort
    _isolate = await Isolate.spawn(
      isolateEntry,
      _receivePort!.sendPort,
    );

    // Listen to messages from the isolate
    _receivePort!.listen((message) {
      if (message == 'notificationCounter') {
        // Call your Bloc event here
        notificationCounter();
      }
    });
  }

  /// The entry point for the isolate
  static void isolateEntry(SendPort sendPort) {
    // Start a periodic timer in the isolate
    Timer.periodic(const Duration(seconds: 20), (timer) {
      sendPort.send('notificationCounter');
    });
  }

  /// Your notificationCounter function
  void notificationCounter() {
    print("Notification counter triggered!");
    // Add your Bloc event logic here
    notificationBloc.add(NotificationCounter());
  }

  /// Dispose the isolate and ports
  @override
  void dispose() {
    // Kill the isolate
    _isolate?.kill(priority: Isolate.immediate);
    // Close the ReceivePort
    _receivePort?.close();
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
      notificationBloc.add(AnnouncementEvent(),);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showIncompleteProfile =
        emailVerified == '' || isInCompleteProfile;

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
              style: boldTextStyle(
                size: 18,
                fontFamily: 'Poppins',
              )),
          actions: [
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
              icon: SvgPicture.asset(
                height: 25,
                width:25,
                icChat,
                // CupertinoIcons.chat_bubble_2,
                // size: 30,
                color: context.iconColor,
              ),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                UserChatScreen().launch(context);
              },
            ),
            const SizedBox(height: 16,)
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
                controller: _mainScrollController,
                physics: const ClampingScrollPhysics(),
                // More controlled scrolling
                children: [
                  UserChatComponent(),
                  const UserAnnouncementScreen(),
                  if (showIncompleteProfile)
                    IncompleteProfileCard(
                      emailVerified == '',
                      isInCompleteProfile,
                    ),
                  SVPostComponent(widget.homeBloc)
                ]),
          ),
        ));
  }
}
