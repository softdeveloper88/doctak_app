import 'dart:async';
import 'dart:isolate';

import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/incomplete_profile_card.dart';
import 'package:doctak_app/presentation/home_screen/home/components/user_chat_component.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/notification_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

import '../../../../core/utils/image_constant.dart';
import '../../../../localization/app_localization.dart';
import '../../../notification_screen/bloc/notification_state.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  const SVHomeFragment({
    required this.homeBloc,
    required this.openDrawer,
    Key? key,
  }) : super(key: key);
  final Function openDrawer;
  final HomeBloc homeBloc;

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
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    emailVerified = await prefs.getString('email_verified_at') ?? '';
    String? specialty = await prefs.getString('specialty') ?? '';
    String? countryName = await prefs.getString('country') ?? '';
    String? city = await prefs.getString('city') ?? '';
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
    _isolate = await Isolate.spawn(isolateEntry, _receivePort!.sendPort);

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bool showIncompleteProfile =
        emailVerified == '' || isInCompleteProfile;

    return Scaffold(
      // resizeToAvoidBottomInset: false,
      key: scaffoldKey,
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildModernAppBar(context),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 1000, // Pre-render items for smoother scrolling
            children: [
              const UserChatComponent(),
              if (showIncompleteProfile)
                IncompleteProfileCard(emailVerified == '', isInCompleteProfile),
              SVPostComponent(widget.homeBloc),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final theme = OneUITheme.of(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: theme.appBarDecoration,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          leading: Container(
            margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: theme.buildIconButton(
              child: Image.asset(
                'images/socialv/icons/ic_More.png',
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                color: theme.iconColor,
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
              style: theme.appBarTitle,
            ),
          ),
          actions: [
            _buildNotificationButton(context, theme),
            const SizedBox(width: 8),
            theme.buildIconButton(
              child: SvgPicture.asset(
                height: 24,
                width: 24,
                icChat,
                color: theme.iconColor,
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

  Widget _buildNotificationButton(BuildContext context, OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationScreen(notificationBloc),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: theme.iconButtonDecoration(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(CupertinoIcons.bell, size: 22, color: theme.iconColor),
                Positioned(
                  right: 6,
                  top: 6,
                  child: BlocBuilder<NotificationBloc, NotificationState>(
                    bloc: notificationBloc,
                    buildWhen: (previous, current) =>
                        previous != current && current is PaginationLoadedState,
                    builder: (context, state) {
                      if (state is PaginationLoadedState) {
                        return notificationBloc.totalNotifications > 0
                            ? theme.buildBadge(
                                notificationBloc.totalNotifications,
                              )
                            : const SizedBox.shrink();
                      } else {
                        return const SizedBox.shrink();
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
