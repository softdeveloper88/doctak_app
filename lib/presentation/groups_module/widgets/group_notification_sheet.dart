import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-group notification mute preferences (local until dedicated API exists).
Future<void> showGroupNotificationSheet(
  BuildContext context, {
  required GroupDetailModel group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GroupNotificationSheet(group: group),
  );
}

class _GroupNotificationSheet extends StatefulWidget {
  final GroupDetailModel group;

  const _GroupNotificationSheet({required this.group});

  @override
  State<_GroupNotificationSheet> createState() => _GroupNotificationSheetState();
}

class _GroupNotificationSheetState extends State<_GroupNotificationSheet> {
  bool _muteAll = false;
  bool _mutePosts = false;
  bool _muteInvites = false;
  bool _loading = true;

  String get _prefix => 'group_notif_${widget.group.routeId}_';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _muteAll = prefs.getBool('${_prefix}mute_all') ?? false;
      _mutePosts = prefs.getBool('${_prefix}mute_posts') ?? false;
      _muteInvites = prefs.getBool('${_prefix}mute_invites') ?? false;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final canModerate = widget.group.capabilities.canModerate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: theme.cardBackground,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _loading
                  ? SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(color: theme.primary)),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Control alerts for ${widget.group.name}.',
                          style: TextStyle(fontSize: 13, color: theme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        _toggle(
                          theme,
                          title: 'Mute all group alerts',
                          subtitle: 'Pause every notification from this group',
                          value: _muteAll,
                          onChanged: (v) async {
                            setState(() => _muteAll = v);
                            await _save('mute_all', v);
                          },
                        ),
                        _toggle(
                          theme,
                          title: 'New posts',
                          subtitle: 'When someone publishes in this group',
                          value: _mutePosts,
                          enabled: !_muteAll,
                          onChanged: (v) async {
                            setState(() => _mutePosts = v);
                            await _save('mute_posts', v);
                          },
                        ),
                        if (canModerate)
                          _toggle(
                            theme,
                            title: 'Join & post requests',
                            subtitle: 'Pending member and post approvals',
                            value: _muteInvites,
                            enabled: !_muteAll,
                            onChanged: (v) async {
                              setState(() => _muteInvites = v);
                              await _save('mute_invites', v);
                            },
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    OneUITheme theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? theme.textPrimary : theme.textTertiary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: theme.textSecondary),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: theme.primary,
    );
  }
}
