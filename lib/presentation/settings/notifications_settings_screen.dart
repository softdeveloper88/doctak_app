import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/data/apiClient/settings_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  PermissionStatus _osStatus = PermissionStatus.denied;
  Map<String, bool> _values = {};
  List<_NotifGroup> _groups = [];

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
      final osStatus = await Permission.notification.status;
      final settings = await SettingsApiService.getPreferences(full: false);
      final notifications = settings['notifications'];
      final valuesRaw = notifications is Map ? notifications['values'] : null;
      final groupsRaw = notifications is Map ? notifications['groups'] : null;

      final values = <String, bool>{};
      if (valuesRaw is Map) {
        valuesRaw.forEach((key, value) {
          values[key.toString()] = value == true;
        });
      }

      final groups = <_NotifGroup>[];
      if (groupsRaw is List) {
        for (final group in groupsRaw) {
          if (group is Map) {
            final parsed = _NotifGroup.fromJson(Map<String, dynamic>.from(group));
            if (parsed.fields.isNotEmpty) groups.add(parsed);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _osStatus = osStatus;
        _values = values;
        _groups = groups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestOsPermission() async {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      await NotificationService.getFcmTokenSafely();
    }
    if (!mounted) return;
    setState(() => _osStatus = result);
    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _toggle(String column, bool enabled) async {
    final previous = Map<String, bool>.from(_values);
    setState(() {
      _values[column] = enabled;
      _saving = true;
    });
    try {
      await SettingsApiService.updateNotifications({column: enabled});
    } catch (e) {
      if (!mounted) return;
      setState(() => _values = previous);
      toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final osGranted = _osStatus.isGranted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Notifications',
        titleIcon: Icons.notifications_active_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (_error != null)
                  AppSurfaceCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    borderColor: Colors.red.withValues(alpha: 0.3),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            osGranted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                            color: osGranted ? const Color(0xFF0F766E) : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              osGranted ? 'Push notifications enabled' : 'Push permission needed',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        osGranted
                            ? 'This phone can receive DocTak alerts. Tune which events you want below.'
                            : 'Allow notifications in system settings so DocTak can send call, message, and account alerts.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                      if (!osGranted) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requestOsPermission,
                            child: Text(
                              _osStatus.isPermanentlyDenied ? 'Open system settings' : 'Allow notifications',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_groups.isEmpty)
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Notification preferences are unavailable right now.',
                      style: TextStyle(color: theme.textSecondary, fontFamily: 'Poppins'),
                    ),
                  )
                else
                  ..._groups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              if (group.description.isNotEmpty)
                                Text(
                                  group.description,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    color: theme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...group.fields.map((field) {
                          final mobileKey = field.firebase ?? field.push;
                          if (mobileKey == null) return const SizedBox.shrink();
                          final enabled = _values[mobileKey] == true;
                          return AppSurfaceCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                field.label,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              subtitle: field.description.isEmpty
                                  ? null
                                  : Text(
                                      field.description,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                              value: enabled,
                              onChanged: (value) => _toggle(mobileKey, value),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
              ],
            ),
    );
  }
}

class _NotifGroup {
  _NotifGroup({
    required this.title,
    required this.description,
    required this.fields,
  });

  factory _NotifGroup.fromJson(Map<String, dynamic> json) {
    final fields = <_NotifField>[];
    final raw = json['fields'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          fields.add(_NotifField.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return _NotifGroup(
      title: json['title']?.toString() ?? 'Notifications',
      description: json['description']?.toString() ?? '',
      fields: fields,
    );
  }

  final String title;
  final String description;
  final List<_NotifField> fields;
}

class _NotifField {
  _NotifField({
    required this.label,
    required this.description,
    this.push,
    this.firebase,
  });

  factory _NotifField.fromJson(Map<String, dynamic> json) {
    return _NotifField(
      label: json['label']?.toString() ?? 'Alert',
      description: json['description']?.toString() ?? '',
      push: json['push']?.toString(),
      firebase: json['firebase']?.toString(),
    );
  }

  final String label;
  final String description;
  final String? push;
  final String? firebase;
}
