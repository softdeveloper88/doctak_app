import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/cme_module/cme_hub_controller.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

Future<void> showCmeWorkspaceSheet(
  BuildContext context, {
  required CmeHubController hub,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _CmeWorkspaceSheet(hub: hub),
  );
}

class _CmeWorkspaceSheet extends StatelessWidget {
  const _CmeWorkspaceSheet({required this.hub});

  final CmeHubController hub;

  Future<void> _switch(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not switch workspace: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final acting = ActingContextService.instance;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
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
          Text('Switch CME workspace', style: theme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose personal learning or a provider organization.',
            style: theme.caption,
          ),
          const SizedBox(height: 16),
          _WorkspaceOption(
            theme: theme,
            label: 'Personal',
            subtitle: 'Browse, register & earn credit',
            selected: !hub.isProviderMode,
            usePersonalAvatar: true,
            onTap: () => _switch(context, hub.switchToPersonal),
          ),
          ...acting.cmeProviders.map(
            (org) => _WorkspaceOption(
              theme: theme,
              label: org.name,
              subtitle: 'Provider workspace',
              logoUrl: org.logoUrl != null && org.logoUrl!.isNotEmpty
                  ? AppData.fullImageUrl(org.logoUrl!)
                  : null,
              selected: hub.isProviderMode && acting.organization?.id == org.id,
              onTap: () => _switch(context, () => hub.switchToProvider(org.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceOption extends StatelessWidget {
  const _WorkspaceOption({
    required this.theme,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.logoUrl,
    this.usePersonalAvatar = false,
  });

  final OneUITheme theme;
  final String label;
  final String subtitle;
  final bool selected;
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
          onTap: onTap,
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
                if (selected)
                  Icon(Icons.check_circle, color: theme.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const size = 44.0;
    if (usePersonalAvatar) {
      return ValueListenableBuilder<String>(
        valueListenable: AppData.profilePicNotifier,
        builder: (_, picUrl, __) {
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
