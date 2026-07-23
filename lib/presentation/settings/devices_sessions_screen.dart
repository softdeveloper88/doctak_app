import 'package:doctak_app/data/apiClient/settings_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class DevicesSessionsScreen extends StatefulWidget {
  const DevicesSessionsScreen({super.key});

  @override
  State<DevicesSessionsScreen> createState() => _DevicesSessionsScreenState();
}

class _DevicesSessionsScreenState extends State<DevicesSessionsScreen> {
  bool _loading = true;
  String? _error;
  List<_SessionItem> _sessions = [];
  List<_ActivityItem> _activities = [];
  String? _removingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await SettingsApiService.getPreferences(full: true);
      final devices = settings['devices'];
      final sessionsRaw = devices is Map ? devices['sessions'] : null;
      final activitiesRaw = devices is Map ? devices['loginActivities'] : null;

      final sessions = <_SessionItem>[];
      if (sessionsRaw is List) {
        for (final row in sessionsRaw) {
          if (row is Map) {
            sessions.add(_SessionItem.fromJson(Map<String, dynamic>.from(row)));
          }
        }
      }

      final activities = <_ActivityItem>[];
      if (activitiesRaw is List) {
        for (final row in activitiesRaw) {
          if (row is Map) {
            activities.add(_ActivityItem.fromJson(Map<String, dynamic>.from(row)));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _activities = activities;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String id) async {
    setState(() => _removingId = id);
    try {
      await SettingsApiService.deleteSession(id);
      toast('Session signed out.');
      await _load();
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Devices & sessions',
        titleIcon: Icons.devices_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (_error != null)
                    AppSurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      borderColor: Colors.red.withValues(alpha: 0.3),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Text(
                    'Active sessions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign out any device you do not recognize.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_sessions.isEmpty)
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No active sessions found.',
                        style: TextStyle(color: theme.textSecondary, fontFamily: 'Poppins'),
                      ),
                    )
                  else
                    ..._sessions.map((session) {
                      final removing = _removingId == session.id;
                      return AppSurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                session.isMobile ? Icons.phone_iphone_rounded : Icons.laptop_mac_rounded,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          session.device,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.5,
                                            color: theme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (session.isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'This device',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (session.ipAddress != null && session.ipAddress!.isNotEmpty) session.ipAddress!,
                                      if (session.lastActivityAt != null) 'Last active ${_formatDate(session.lastActivityAt!)}',
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  if (!session.isCurrent) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: removing ? null : () => _remove(session.id),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: removing
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Sign out'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (_activities.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Recent sign-ins',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._activities.take(8).map((activity) {
                      return AppSurfaceCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.description,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                color: theme.textSecondary,
                              ),
                            ),
                            if (activity.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(activity.createdAt!),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SessionItem {
  _SessionItem({
    required this.id,
    required this.device,
    required this.isCurrent,
    this.ipAddress,
    this.lastActivityAt,
    this.deviceType,
  });

  factory _SessionItem.fromJson(Map<String, dynamic> json) {
    final deviceType = json['deviceType']?.toString().toLowerCase();
    return _SessionItem(
      id: json['id']?.toString() ?? '',
      device: json['device']?.toString() ?? 'Unknown device',
      isCurrent: json['isCurrent'] == true,
      ipAddress: json['ipAddress']?.toString(),
      lastActivityAt: json['lastActivityAt']?.toString(),
      deviceType: deviceType,
    );
  }

  final String id;
  final String device;
  final bool isCurrent;
  final String? ipAddress;
  final String? lastActivityAt;
  final String? deviceType;

  bool get isMobile {
    final type = deviceType ?? '';
    final label = device.toLowerCase();
    return type.contains('android') ||
        type.contains('ios') ||
        label.contains('android') ||
        label.contains('iphone') ||
        label.contains('ipad');
  }
}

class _ActivityItem {
  _ActivityItem({
    required this.title,
    required this.description,
    this.createdAt,
  });

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    return _ActivityItem(
      title: json['title']?.toString() ??
          json['activity_type']?.toString() ??
          'Sign-in',
      description: json['description']?.toString() ?? 'Activity recorded on your account.',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  final String title;
  final String description;
  final String? createdAt;
}
