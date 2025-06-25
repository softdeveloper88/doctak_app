import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches DiscussionCard structure
class CaseDiscussionListShimmer extends StatelessWidget {
  const CaseDiscussionListShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final bool hasPatientInfo = index % 3 == 0; // Show patient info on some cards
        final bool hasSymptoms = index % 2 == 0; // Show symptoms on some cards
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with author info
                  _buildHeader(context),
                  const SizedBox(height: 12),

                  // Title
                  _buildTitle(context),
                  const SizedBox(height: 8),

                  // Description preview
                  _buildDescription(context),
                  const SizedBox(height: 12),

                  // Patient info if available
                  if (hasPatientInfo) ...[
                    _buildPatientInfo(context),
                    const SizedBox(height: 12),
                  ],

                  // Symptoms if available
                  if (hasSymptoms) ...[
                    _buildSymptoms(context),
                    const SizedBox(height: 12),
                  ],

                  // Footer with stats and actions
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Header with author info matching DiscussionCard
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // CircleAvatar with radius 20 (40x40)
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
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
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              // Author specialty
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        // Specialty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  // Title matching DiscussionCard (maxLines: 2)
  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Description preview matching DiscussionCard (maxLines: 3)
  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Patient info section matching DiscussionCard
  Widget _buildPatientInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Symptoms section matching DiscussionCard
  Widget _buildSymptoms(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symptom tags (take 3)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 35,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        // "+X more symptoms" text
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Footer with stats and time matching DiscussionCard
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Stats: likes, comments, views
        _buildStat(),
        const SizedBox(width: 16),
        _buildStat(),
        const SizedBox(width: 16),
        _buildStat(),

        const Spacer(),

        // Time
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Individual stat (icon + count) matching DiscussionCard._buildStat
  Widget _buildStat() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}