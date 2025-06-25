import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedConferenceItem structure
class ConferencesShimmerLoader extends StatelessWidget {
  const ConferencesShimmerLoader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        final bool hasImage = index % 2 == 0;
        final bool hasLongTitle = index % 3 == 0;
        final bool hasDescription = index % 4 != 0;
        final bool hasRegistration = index % 5 != 0;
        
        return Container(
          margin: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conference image
                  _buildConferenceImageOrPlaceholder(hasImage),
                  
                  // Conference header with title and dates
                  _buildConferenceHeader(context, hasLongTitle),
                  
                  // Conference description
                  if (hasDescription) _buildConferenceDescription(context),
                  
                  // Conference details (city, venue, etc.)
                  _buildConferenceDetails(context, index),
                  
                  // Register button and actions
                  _buildActionRow(context, hasRegistration),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Conference image or placeholder matching MemoryOptimizedConferenceItem
  Widget _buildConferenceImageOrPlaceholder(bool hasImage) {
    if (hasImage) {
      // With image: 180px height
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      // Without image: 100px height with event icon
      return Container(
        height: 100,
        width: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  // Conference header matching MemoryOptimizedConferenceItem
  Widget _buildConferenceHeader(BuildContext context, bool hasLongTitle) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event icon container (padding: 15, borderRadius: 12)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title, dates, and organizer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conference title
                Container(
                  width: hasLongTitle 
                      ? double.infinity 
                      : MediaQuery.of(context).size.width * 0.6,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Start date - end date with calendar icon
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Organizer with person icon (conditional)
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Share button (circular with blue background)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Conference description matching MemoryOptimizedConferenceItem
  Widget _buildConferenceDescription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Description" label
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Description text (maxLines: 3)
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Conference details matching MemoryOptimizedConferenceItem
  Widget _buildConferenceDetails(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Location (always present)
          _buildDetailRow(
            Colors.green[700]!,
            MediaQuery.of(context).size.width * 0.4,
          ),
          // Venue (conditional)
          if (index % 3 != 0)
            _buildDetailRow(
              Colors.orange[700]!,
              MediaQuery.of(context).size.width * 0.3,
            ),
          // Credits (conditional)
          if (index % 2 == 0)
            _buildDetailRow(
              Colors.purple[700]!,
              MediaQuery.of(context).size.width * 0.5,
            ),
          // Specialties (conditional)
          if (index % 4 == 0)
            _buildDetailRow(
              Colors.blue[700]!,
              MediaQuery.of(context).size.width * 0.6,
            ),
        ],
      ),
    );
  }

  // Helper method to build a detail row matching MemoryOptimizedConferenceItem._buildDetailRow
  Widget _buildDetailRow(Color color, double textWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container with colored background (6px padding, 8px borderRadius)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Detail text
          Expanded(
            child: Container(
              height: 14,
              width: textWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Register button and actions matching MemoryOptimizedConferenceItem
  Widget _buildActionRow(BuildContext context, bool hasRegistration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: hasRegistration
          ? // ElevatedButton with icon and text
            Container(
              height: 40, // Height from padding vertical: 12
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Registration icon
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "Register Now" text
                  Container(
                    height: 14,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            )
          : // "Registration unavailable" text (centered)
            Center(
              child: Container(
                height: 14,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
    );
  }
}