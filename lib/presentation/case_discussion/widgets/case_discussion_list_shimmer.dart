import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches DiscussionCard structure
class CaseDiscussionListShimmer extends StatelessWidget {
  const CaseDiscussionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) {
        final bool hasPatientInfo = index % 3 == 0; // Show patient info on some cards
        final bool hasSymptoms = index % 2 == 0; // Show symptoms on some cards

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: theme.divider,
            highlightColor: theme.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with author info
                  _buildHeader(context, theme),
                  const SizedBox(height: 12),

                  // Title
                  _buildTitle(context, theme),
                  const SizedBox(height: 8),

                  // Description preview
                  _buildDescription(context, theme),
                  const SizedBox(height: 12),

                  // Patient info if available
                  if (hasPatientInfo) ...[_buildPatientInfo(context, theme), const SizedBox(height: 12)],

                  // Symptoms if available
                  if (hasSymptoms) ...[_buildSymptoms(context, theme), const SizedBox(height: 12)],

                  // Footer with stats and actions
                  _buildFooter(context, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Header with author info matching DiscussionCard
  Widget _buildHeader(BuildContext context, OneUITheme theme) {
    return Row(
      children: [
        // CircleAvatar with radius 20 (40x40)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: theme.divider, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author name
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 4),
              // Author specialty
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
        // Specialty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ],
    );
  }

  // Title matching DiscussionCard (maxLines: 2)
  Widget _buildTitle(BuildContext context, OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 4),
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: 16,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }

  // Description preview matching DiscussionCard (maxLines: 3)
  Widget _buildDescription(BuildContext context, OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 4),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 14,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }

  // Patient info section matching DiscussionCard
  Widget _buildPatientInfo(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }

  // Symptoms section matching DiscussionCard
  Widget _buildSymptoms(BuildContext context, OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symptom tags (take 3)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 35,
                height: 10,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ),
        // "+X more symptoms" text
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }

  // Footer with stats and time matching DiscussionCard
  Widget _buildFooter(BuildContext context, OneUITheme theme) {
    return Row(
      children: [
        // Stats: likes, comments, views
        _buildStat(theme),
        const SizedBox(width: 16),
        _buildStat(theme),
        const SizedBox(width: 16),
        _buildStat(theme),

        const Spacer(),

        // Time
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }

  // Individual stat (icon + count) matching DiscussionCard._buildStat
  Widget _buildStat(OneUITheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }
}
