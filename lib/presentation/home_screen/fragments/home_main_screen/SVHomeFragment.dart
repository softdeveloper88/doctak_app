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
        appBar: _buildModernAppBar(context),
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

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: svGetScaffoldColor(),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
          // Subtle gradient overlay for premium feel
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    svGetScaffoldColor(),
                    svGetScaffoldColor().withOpacity(0.95),
                  ]
                : [
                    svGetScaffoldColor(),
                    svGetScaffoldColor().withOpacity(0.98),
                  ],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          leading: Container(
            margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: _buildModernIconButton(
              child: Image.asset(
                'images/socialv/icons/ic_More.png',
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                color: context.iconColor,
              ),
              onPressed: () {
                widget.openDrawer();
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              translation(context).lbl_home,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: context.iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          actions: [
            _buildNotificationButton(context),
            const SizedBox(width: 8),
            _buildModernIconButton(
              child: SvgPicture.asset(
                height: 24,
                width: 24,
                icChat,
                color: context.iconColor,
              ),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                UserChatScreen().launch(context);
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernIconButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4,vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationScreen(notificationBloc),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 24,
                  color: context.iconColor,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: BlocBuilder<NotificationBloc, NotificationState>(
                    bloc: notificationBloc,
                    builder: (context, state) {
                      if (state is PaginationLoadedState) {
                        return notificationBloc.totalNotifications > 0
                            ? Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red[400]!,
                                      Colors.red[600]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: svGetScaffoldColor(),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${notificationBloc.totalNotifications > 99 ? '99+' : notificationBloc.totalNotifications}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox();
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
