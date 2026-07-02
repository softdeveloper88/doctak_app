import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_shimmer.dart';
import 'package:flutter/material.dart';

class UserShimmer extends StatelessWidget {
  const UserShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;

    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) => OneUIShimmer(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: base),
          title: Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;
    final placeholder = theme.shimmerBase;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        return OneUIShimmer(
          period: const Duration(milliseconds: 1500),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.shimmerNotificationCardFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.shimmerNotificationCardBorder,
                width: 1,
              ),
              boxShadow: theme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: placeholder,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.shimmerNotificationCardBorder,
                            width: 2,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _shimmerBadgeColor(theme, index),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.cardBackground,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.cardBackground.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 14,
                          width: MediaQuery.of(context).size.width * 0.45,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: placeholder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              height: 12,
                              width: 70 + (index % 3) * 15,
                              decoration: BoxDecoration(
                                color: placeholder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: theme.isDark ? 0.14 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _shimmerBadgeColor(OneUITheme theme, int index) {
    final colors = [
      theme.success,
      theme.likeColor,
      theme.primary,
      theme.secondary,
      theme.warning,
    ];
    return colors[index % colors.length];
  }
}

class ProfileListShimmer extends StatelessWidget {
  const ProfileListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final base = theme.shimmerBase;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isFollowed = index % 3 == 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: theme.surfaceCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OneUIShimmer(
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: base,
                      border: Border.all(
                        color: theme.border,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: OneUIShimmer(
                              period: const Duration(milliseconds: 1500),
                              child: Container(
                                height: 16,
                                constraints: BoxConstraints(
                                  maxWidth: 120 + (index % 3) * 20,
                                ),
                                decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          if (isFollowed) ...[
                            const SizedBox(width: 6),
                            OneUIShimmer(
                              period: const Duration(milliseconds: 1500),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: base,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      OneUIShimmer(
                        period: const Duration(milliseconds: 1500),
                        child: Container(
                          height: 14,
                          width: 90 + (index % 4) * 20,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OneUIShimmer(
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.border,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}