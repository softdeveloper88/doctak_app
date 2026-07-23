import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to switch the acting account between the personal profile
/// and business/organization pages — mirrors the website header dropdown
/// (Personal profile · Hospital/Recruiter/CME Provider pages · Current/Switch).
Future<void> showWorkspaceSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WorkspaceSwitcherSheet(),
  );
}

class _WorkspaceSwitcherSheet extends StatefulWidget {
  const _WorkspaceSwitcherSheet();

  @override
  State<_WorkspaceSwitcherSheet> createState() =>
      _WorkspaceSwitcherSheetState();
}

class _WorkspaceSwitcherSheetState extends State<_WorkspaceSwitcherSheet> {
  final _acting = ActingContextService.instance;
  String? _switchingId; // org id, 'personal', or null
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _acting.addListener(_onActingChanged);
    _refresh();
  }

  @override
  void dispose() {
    _acting.removeListener(_onActingChanged);
    super.dispose();
  }

  void _onActingChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _acting.initialize();
    await _acting.refreshOrganizations();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _switch({ActingOrganization? org}) async {
    if (_switchingId != null) return;
    setState(() => _switchingId = org?.id ?? 'personal');
    try {
      if (org == null) {
        await _acting.switchToPersonal();
      } else {
        await _acting.switchToOrganization(org.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            org == null
                ? 'Personal profile is active.'
                : '${org.name} workspace is active.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _switchingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isPersonal = !_acting.isBusinessMode;
    final orgs = _acting.organizations;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Switch account', style: theme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Post, comment and hire as yourself or as a business page.',
              style: theme.caption,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _AccountOption(
                    theme: theme,
                    label: _personalName,
                    subtitle: 'Personal profile',
                    usePersonalAvatar: true,
                    selected: isPersonal,
                    busy: _switchingId == 'personal',
                    enabled: _switchingId == null,
                    onTap: () => _switch(),
                  ),
                  ...orgs.map(
                    (org) => _AccountOption(
                      theme: theme,
                      label: org.name,
                      subtitle: org.roleDisplay.isEmpty
                          ? org.typeDisplay
                          : '${org.typeDisplay} · ${org.roleDisplay}',
                      logoUrl: (org.logoUrl != null && org.logoUrl!.isNotEmpty)
                          ? AppData.fullImageUrl(org.logoUrl!)
                          : null,
                      selected:
                          !isPersonal && _acting.organization?.id == org.id,
                      busy: _switchingId == org.id,
                      enabled: _switchingId == null,
                      onTap: () => _switch(org: org),
                    ),
                  ),
                  if (_refreshing && orgs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                  if (!_refreshing && orgs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No business pages yet. Create a hospital, recruiter or CME provider page on doctak.net to post jobs and courses.',
                        style: theme.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _personalName {
    final name = capitalizeWords(AppData.name);
    return AppData.userType == 'doctor' ? 'Dr. $name' : name;
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.theme,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.busy = false,
    this.enabled = true,
    this.logoUrl,
    this.usePersonalAvatar = false,
  });

  final OneUITheme theme;
  final String label;
  final String subtitle;
  final bool selected;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  final String? logoUrl;
  final bool usePersonalAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.08)
            : theme.scaffoldBackground,
        borderRadius: theme.radiusM,
        child: InkWell(
          onTap: (enabled && !selected) ? onTap : null,
          borderRadius: theme.radiusM,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: selected ? theme.primary : theme.textPrimary,
                        ),
                      ),
                      Text(subtitle, style: theme.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing() {
    if (busy) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary),
      );
    }
    if (selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Current',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: theme.primary,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        'Switch',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const size = 44.0;
    if (usePersonalAvatar) {
      return ValueListenableBuilder<String>(
        valueListenable: AppData.profilePicNotifier,
        builder: (_, picUrl, _) {
          final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
          final resolved = url.isNotEmpty && url.toLowerCase() != 'null'
              ? AppData.fullImageUrl(url)
              : '';
          return _avatarFrame(
            size: size,
            child: resolved.isNotEmpty
                ? AppCachedNetworkImage(
                    imageUrl: resolved,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.person_outline, color: theme.primary),
          );
        },
      );
    }

    if (logoUrl != null) {
      return _avatarFrame(
        size: size,
        child: AppCachedNetworkImage(
          imageUrl: logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return _avatarFrame(
      size: size,
      child: Icon(Icons.business_outlined, color: theme.primary),
    );
  }

  Widget _avatarFrame({required double size, required Widget child}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }
}
