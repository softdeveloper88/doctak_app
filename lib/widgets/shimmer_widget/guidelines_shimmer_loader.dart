import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedGuidelineItem structure
class GuidelinesShimmerLoader extends StatelessWidget {
  const GuidelinesShimmerLoader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final bool hasLongName = index % 2 == 0;
        final bool isExpanded = index % 3 == 0; // Some cards show expanded state
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guideline Header
                  _buildGuidelineHeader(context, hasLongName, isExpanded),
                  
                  // Guideline Action
                  _buildGuidelineAction(context, isExpanded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Guideline header section matching MemoryOptimizedGuidelineItem
  Widget _buildGuidelineHeader(BuildContext context, bool hasLongName, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical information icon (50x50 with blue background)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Disease name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disease name
                Container(
                  width: hasLongName 
                      ? double.infinity 
                      : MediaQuery.of(context).size.width * 0.6,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description (HtmlWidget content)
                _buildDescription(context, isExpanded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Description section with collapsed/expanded states
  Widget _buildDescription(BuildContext context, bool isExpanded) {
    if (isExpanded) {
      // Expanded description (more lines)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    } else {
      // Collapsed description (trimmed to ~100 words)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    }
  }

  // Guideline action section matching MemoryOptimizedGuidelineItem
  Widget _buildGuidelineAction(BuildContext context, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // TextButton.icon - matching the action button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon placeholder
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                // Text placeholder - different widths for "See More" vs "Download PDF"
                Container(
                  width: isExpanded ? 80 : 60, // "Download PDF" vs "See More"
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}