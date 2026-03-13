import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_dashboard_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_events_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_notifications_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_notifications_event.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_analytics_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_certificates_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_creation_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_events_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_gamification_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_learning_paths_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_my_events_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_notifications_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_profile_screen.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeMainScreen extends StatefulWidget {
  const CmeMainScreen({super.key});

  @override
  State<CmeMainScreen> createState() => _CmeMainScreenState();
}

class _CmeMainScreenState extends State<CmeMainScreen> {
  int _currentIndex = 0;

  // Create BLoCs once
  late final CmeEventsBloc _eventsBloc;
  late final CmeDashboardBloc _dashboardBloc;
  late final CmeCertificatesBloc _certificatesBloc;
  late final CmeNotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _eventsBloc = CmeEventsBloc();
    _dashboardBloc = CmeDashboardBloc();
    _certificatesBloc = CmeCertificatesBloc();
    _notificationsBloc = CmeNotificationsBloc();
  }

  @override
  void dispose() {
    _eventsBloc.close();
    _dashboardBloc.close();
    _certificatesBloc.close();
    _notificationsBloc.close();
    super.dispose();
  }

  void _onCreateEvent(BuildContext context) {
    if (AppData.hasFeatureAccess('cme_credits')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CmeEventCreationScreen()),
      );
    } else {
      _showUpgradeDialog(context);
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: theme.radiusL),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: const Color(0xFFFFB800), size: 28),
            const SizedBox(width: 10),
            Text('Premium Feature',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary)),
          ],
        ),
        content: Text(
          'Creating CME events requires a premium subscription. '
          'Upgrade your plan to unlock this feature.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins', color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Upgrade',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _eventsBloc),
        BlocProvider.value(value: _dashboardBloc),
        BlocProvider.value(value: _certificatesBloc),
        BlocProvider.value(value: _notificationsBloc),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: _buildAppBar(theme),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            CmeEventsScreen(),
            CmeMyEventsScreen(),
            CmeLearningPathsScreen(),
            CmeCertificatesScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _onCreateEvent(context),
          backgroundColor: theme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: _buildBottomNav(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.cardBackground,
      foregroundColor: theme.textPrimary,
      elevation: 0,
      title: const Text(
        'CME',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.emoji_events_outlined, color: theme.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmeGamificationScreen(),
              ),
            );
          },
          tooltip: 'Achievements',
        ),
        IconButton(
          icon: Icon(Icons.analytics_outlined, color: theme.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmeAnalyticsScreen(),
              ),
            );
          },
          tooltip: 'Analytics',
        ),
        IconButton(
          icon: Icon(Icons.person_outline, color: theme.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmeProfileScreen(),
              ),
            );
          },
          tooltip: 'CME Profile',
        ),
        // Notifications bell
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: theme.textSecondary),
              onPressed: () {
                _notificationsBloc.add(CmeLoadNotificationsEvent());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: _notificationsBloc,
                      child: const CmeNotificationsScreen(),
                    ),
                  ),
                );
              },
            ),
            // Unread badge
            if (_notificationsBloc.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_notificationsBloc.unreadCount}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(OneUITheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(
            color: theme.textTertiary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(theme, 0, Icons.explore_outlined,
                  Icons.explore, 'Events'),
              _buildNavItem(theme, 1, Icons.school_outlined,
                  Icons.school, 'My CME'),
              _buildNavItem(theme, 2, Icons.route_outlined,
                  Icons.route, 'Paths'),
              _buildNavItem(theme, 3, Icons.workspace_premium_outlined,
                  Icons.workspace_premium, 'Certs'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    OneUITheme theme,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: theme.radiusL,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? theme.primary : theme.textTertiary,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
