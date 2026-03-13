import 'package:doctak_app/data/models/cme/cme_notification_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_notifications_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_notifications_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_notifications_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

class CmeNotificationsScreen extends StatefulWidget {
  const CmeNotificationsScreen({super.key});

  @override
  State<CmeNotificationsScreen> createState() =>
      _CmeNotificationsScreenState();
}

class _CmeNotificationsScreenState extends State<CmeNotificationsScreen> {
  CmeNotificationsBloc get _bloc => context.read<CmeNotificationsBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(CmeLoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('CME Notifications',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
        actions: [
          BlocBuilder<CmeNotificationsBloc, CmeNotificationsState>(
            builder: (context, state) {
              if (_bloc.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      _bloc.add(CmeMarkAllNotificationsReadEvent()),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: theme.primary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CmeNotificationsBloc, CmeNotificationsState>(
        builder: (context, state) {
          if (state is CmeNotificationsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CmeNotificationsErrorState) {
            return _buildError(theme, state.errorMessage);
          }

          if (_bloc.notificationsList.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _bloc.add(CmeLoadNotificationsEvent());
            },
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              itemCount: _bloc.notificationsList.length,
              itemBuilder: (context, index) {
                return _buildNotificationTile(
                    theme, _bloc.notificationsList[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
      OneUITheme theme, CmeNotificationData notification) {
    final isUnread = notification.unread;

    return Container(
      color: isUnread
          ? theme.primary.withValues(alpha: 0.04)
          : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (notification.id != null && isUnread) {
              _bloc.add(CmeMarkNotificationReadEvent(
                  notificationId: notification.id!));
            }
            if (notification.eventId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CmeEventDetailScreen(
                      eventId: notification.eventId!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.type)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(notification.type),
                    size: 20,
                    color: _getIconColor(notification.type),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? '',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w400,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.message ?? '',
                        style: theme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: theme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread dot
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'registration':
        return Icons.how_to_reg;
      case 'reminder':
        return Icons.notifications_active;
      case 'event_start':
        return Icons.play_circle;
      case 'certificate':
        return Icons.workspace_premium;
      case 'quiz':
        return Icons.quiz;
      case 'waitlist':
        return Icons.hourglass_bottom;
      default:
        return Icons.school;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'registration':
        return const Color(0xFF34C759);
      case 'reminder':
        return const Color(0xFFFF9500);
      case 'event_start':
        return const Color(0xFFFF3B30);
      case 'certificate':
        return const Color(0xFF6366F1);
      case 'quiz':
        return const Color(0xFF0A84FF);
      case 'waitlist':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF0A84FF);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return timeago.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.notifications_none,
                size: 48, color: theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _bloc.add(CmeLoadNotificationsEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
