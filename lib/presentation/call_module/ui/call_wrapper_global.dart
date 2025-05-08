import 'package:flutter/material.dart';
import 'package:doctak_app/presentation/call_module/call_service.dart';
import 'package:provider/provider.dart';

class CallWrapperGlobal extends StatefulWidget {
  final Widget child;

  const CallWrapperGlobal({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<CallWrapperGlobal> createState() => _CallWrapperGlobalState();
}

class _CallWrapperGlobalState extends State<CallWrapperGlobal> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize listen for navigation routes that are call related
    _setupRouteObserver();
  }

  void _setupRouteObserver() {
    // Listen for navigation events specifically for call screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callService = Provider.of<CallService>(context, listen: false);

      // Check current route if it's a call route
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null) {
        final routeName = currentRoute.settings.name;
        if (routeName == '/call' || routeName == '/incoming-call') {
          // We are already on a call route, initialize call if needed
          final arguments = currentRoute.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            // Handle route arguments for call
            _handleCallRoute(arguments);
          }
        }
      }
    });
  }

  void _handleCallRoute(Map<String, dynamic> arguments) {
    final callId = arguments['callId'] as String?;
    final contactId = arguments['contactId'] as String?;
    final contactName = arguments['contactName'] as String?;
    final contactAvatar = arguments['contactAvatar'] as String?;
    final isIncoming = arguments['isIncoming'] as bool?;
    final isVideoCall = arguments['isVideoCall'] as bool?;

    if (callId != null && contactId != null) {
      // Navigate to call screen
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => CallScreen(
      //       callId: callId,
      //       contactId: contactId,
      //       contactName: contactName ?? 'Unknown',
      //       contactAvatar: contactAvatar ?? '',
      //       isIncoming: isIncoming ?? true,
      //       isVideoCall: isVideoCall ?? false,
      //     ),
      //   ),
      // );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Forward lifecycle changes to the call service
    final callService = Provider.of<CallService>(context, listen: false);
    callService.handleAppLifecycleState(state);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallService>(
      builder: (context, callService, child) {
        // Return the child widget wrapped in a call context
        return widget.child;
      },
    );
  }
}