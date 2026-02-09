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

import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import '../../../../core/utils/image_constant.dart';
import '../../../../localization/app_localization.dart';
import '../../../notification_screen/bloc/notification_state.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  const SVHomeFragment({
    required this.homeBloc,
    required this.openDrawer,
    super.key,
  });
  final Function openDrawer;
  final HomeBloc homeBloc;

  @override
  State<SVHomeFragment> createState() => _SVHomeFragmentState();
}

class _SVHomeFragmentState extends State<SVHomeFragment> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  // HomeBloc widget.homeBloc = HomeBloc();
  final ScrollController _mainScrollController = ScrollController();
  // Use static notification bloc to prevent multiple instances
  static NotificationBloc? _notificationBloc;
  NotificationBloc get notificationBloc {
    _notificationBloc ??= NotificationBloc();
    return _notificationBloc!;
  }

  // Debounce timer to prevent too many scroll events
  Timer? _scrollDebounce;
  bool _isLoadingTriggered = false;

  /// Handle scroll to trigger pagination when near bottom
  void _onScroll() {
    // Don't process if already triggered loading
    if (_isLoadingTriggered) return;

    // Use hasClients check to avoid errors
    if (!_mainScrollController.hasClients) return;

    final maxScroll = _mainScrollController.position.maxScrollExtent;
    final currentScroll = _mainScrollController.offset;
    final threshold = 300.0; // pixels from bottom to trigger

    if (maxScroll - currentScroll <= threshold) {
      // Near bottom - check if we should load more
      if (widget.homeBloc.pageNumber <= widget.homeBloc.numberOfPage) {
        _isLoadingTriggered = true;

        // Debounce to prevent multiple rapid triggers
        _scrollDebounce?.cancel();
        _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
          widget.homeBloc.add(
            PostCheckIfNeedMoreDataEvent(
              index:
                  widget.homeBloc.postList.length -
                  widget.homeBloc.nextPageTrigger,
            ),
          );
          // Reset after a delay to allow next pagination
          Future.delayed(const Duration(milliseconds: 500), () {
            _isLoadingTriggered = false;
          });
        });
      }
    }
  }

  String? emailVerified = '';
  bool isInCompleteProfile = false;
  Future<void> getSharedPreferences() async {
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
    super.initState();

    // Add scroll listener for pagination
    _mainScrollController.addListener(_onScroll);

    // Load posts first for immediate display
    widget.homeBloc.add(PostLoadPageEvent(page: 1));

    // Defer heavy operations to let UI render smoothly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        startIsolate();
        getSharedPreferences();
      }
    });

    // Defer ads loading to reduce initial load
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.homeBloc.add(AdsSettingEvent());
      }
    });
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
    // Start a periodic timer in the isolate - set to 60 seconds to reduce jank
    Timer.periodic(const Duration(seconds: 60), (timer) {
      sendPort.send('notificationCounter');
    });
  }

  /// Your notificationCounter function
  void notificationCounter() {
    // Removed print statement to reduce debug overhead
    notificationBloc.add(NotificationCounter());
  }

  /// Dispose the isolate and ports
  @override
  void dispose() {
    // Cancel debounce timer
    _scrollDebounce?.cancel();
    // Remove scroll listener
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
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
      body: BlocListener<HomeBloc, HomeState>(
        bloc: widget.homeBloc,
        listener: (context, state) {
          if (state is PostDataError) {
            if (state.errorMessage.contains('Session expired')) {
              AppSharedPreferences().clearSharedPreferencesData(context);
              const LoginScreen().launch(context, isNewTask: true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage.replaceAll('An error occurred: ', ''),
                    style: const TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  margin: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight + 20,
                    left: 16,
                    right: 16,
                  ),
                ),
              );
            }
          }
        },
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: theme.primary,
            backgroundColor: theme.surfaceVariant,
            strokeWidth: 2.5,
            displacement: 40,
            child: ListView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              cacheExtent: 800, // Optimized cache extent for memory efficiency
              addAutomaticKeepAlives:
                  false, // Disable for better memory management
              addRepaintBoundaries: true, // Enable for paint isolation
              children: [
                const UserChatComponent(),
                if (showIncompleteProfile)
                  IncompleteProfileCard(
                    emailVerified == '',
                    isInCompleteProfile,
                  ),
                // Wrap posts in RepaintBoundary for isolation
                RepaintBoundary(child: SVPostComponent(widget.homeBloc)),
              ],
            ),
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
          title: Text(translation(context).lbl_home, style: theme.appBarTitle),
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
                BlocBuilder<NotificationBloc, NotificationState>(
                  bloc: notificationBloc,
                  buildWhen: (previous, current) =>
                      previous != current && current is PaginationLoadedState,
                  builder: (context, state) {
                    if (state is PaginationLoadedState &&
                        notificationBloc.totalNotifications > 0) {
                      return Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              notificationBloc.totalNotifications > 99
                                  ? '99+'
                                  : '${notificationBloc.totalNotifications}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
