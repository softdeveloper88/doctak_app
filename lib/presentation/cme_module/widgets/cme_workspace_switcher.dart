import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/cme_module/cme_hub_controller.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// App-bar workspace chip — personal account or CME provider org with photo.
class CmeWorkspaceSwitcher extends StatelessWidget {
  const CmeWorkspaceSwitcher({
    super.key,
    required this.hub,
    required this.onTap,
  });

  final CmeHubController hub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final org = hub.activeOrg;
    final isProvider = hub.isProviderMode && org != null;
    final label = isProvider ? org.name : 'Personal';

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WorkspaceAvatar(
                  theme: theme,
                  isProvider: isProvider,
                  logoUrl: org?.logoUrl,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: theme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar({
    required this.theme,
    required this.isProvider,
    this.logoUrl,
  });

  final OneUITheme theme;
  final bool isProvider;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;

    if (isProvider) {
      final url = logoUrl != null && logoUrl!.isNotEmpty
          ? AppData.fullImageUrl(logoUrl!)
          : '';
      return _roundImage(size, url, fallback: _orgFallback(size));
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppData.profilePicNotifier,
      builder: (_, picUrl, __) {
        final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
        final resolved =
            url.isNotEmpty && url.toLowerCase() != 'null'
                ? AppData.fullImageUrl(url)
                : '';
        return _roundImage(size, resolved, fallback: _personFallback(size));
      },
    );
  }

  Widget _roundImage(double size, String url, {required Widget fallback}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? AppCachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _personFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: theme.primary.withValues(alpha: 0.12),
      child: Icon(Icons.person_outline, size: size * 0.55, color: theme.primary),
    );
  }

  Widget _orgFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: theme.primary.withValues(alpha: 0.12),
      child: Icon(Icons.business_outlined, size: size * 0.5, color: theme.primary),
    );
  }
}
