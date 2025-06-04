import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader for specialty dropdown loading in create discussion screen
class SpecialtyLoadingShimmer extends StatelessWidget {
  const SpecialtyLoadingShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Loading icon
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Loading text
            Expanded(
              child: Container(
                height: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            // Spinner placeholder
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}