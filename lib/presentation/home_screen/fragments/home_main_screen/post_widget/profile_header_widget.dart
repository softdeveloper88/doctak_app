import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String profilePicUrl;
  final String userName;
  final String? createdAt;
  final String? specialty;
  final VoidCallback onProfileTap;
  final VoidCallback onDeleteTap;
  final bool isCurrentUser;

  const ProfileHeaderWidget({
    super.key,
    required this.profilePicUrl,
    required this.userName,
    this.createdAt,
    this.specialty,
    required this.onProfileTap,
    required this.onDeleteTap,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onProfileTap(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // One UI 8.5 Profile Picture
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.avatarBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: theme.isDark ? 0.2 : 0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: profilePicUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePicUrl,
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.avatarBackground,
                                child: Center(child: CupertinoActivityIndicator(color: theme.primary)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.avatarBackground,
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: TextStyle(color: theme.avatarText, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: theme.avatarBackground,
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: TextStyle(color: theme.avatarText, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Info with One UI 8.5 styling
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name and Verification Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Poppins', color: theme.textPrimary, letterSpacing: -0.2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // One UI 8.5 Verification Badge
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [theme.verifiedBadge, theme.verifiedBadge.withValues(alpha: 0.8)]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: theme.verifiedBadge.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))],
                              ),
                              child: const Icon(CupertinoIcons.checkmark_alt, size: 10, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Specialty or Time Info
                        if (specialty != null)
                          Row(
                            children: [
                              Icon(CupertinoIcons.heart_circle, size: 14, color: theme.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  specialty!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textSecondary, fontFamily: 'Poppins'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(CupertinoIcons.time, size: 12, color: theme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                createdAt ?? '',
                                style: TextStyle(fontSize: 12, color: theme.textSecondary, fontFamily: 'Poppins'),
                              ),
                              if (createdAt != null && createdAt!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(color: theme.textSecondary, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Icon(CupertinoIcons.globe, size: 12, color: theme.textSecondary),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // One UI 8.5 More Options Button
          if (isCurrentUser)
            Container(
              decoration: BoxDecoration(color: theme.moreButtonBg, shape: BoxShape.circle),
              child: PopupMenuButton<String>(
                icon: Icon(CupertinoIcons.ellipsis_vertical, color: theme.iconColor, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: theme.cardBackground,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Delete',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.trash, color: theme.deleteRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: theme.deleteRed, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'Delete') {
                    onDeleteTap();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
