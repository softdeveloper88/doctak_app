import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Ultra-realistic shimmer loader for conferences that precisely mirrors the actual conference card layout
class ConferencesShimmerLoader extends StatelessWidget {
  const ConferencesShimmerLoader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5, // Number of shimmer cards to show
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        // Create variations for each card to make it more realistic
        final bool hasLargeImage = index % 2 == 0;
        final bool hasLongTitle = index % 3 == 0;
        final bool hasNoVenue = index % 4 == 0;
        final bool hasAllCredits = index % 3 == 2;
        final bool hasRegisterButton = index % 5 != 0;
        final int numDetailsRows = hasNoVenue ? 2 : (hasAllCredits ? 4 : 3);
        
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conference image placeholder with realistic appearance
                  Container(
                    height: hasLargeImage ? 180 : 100,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          if (hasLargeImage) ...[  
                            const SizedBox(height: 10),
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Conference header with detailed icon and information
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container with inner details
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Conference title and dates with varying widths
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Container(
                                height: 16,
                                width: hasLongTitle ? 
                                  MediaQuery.of(context).size.width * 0.6 : 
                                  MediaQuery.of(context).size.width * 0.45,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Dates with calendar icon
                              Row(
                                children: [
                                  // Calendar icon
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Date text
                                  Container(
                                    height: 14,
                                    width: index % 2 == 0 ? 
                                      MediaQuery.of(context).size.width * 0.4 : 
                                      MediaQuery.of(context).size.width * 0.35,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Organizer with person icon
                              Row(
                                children: [
                                  // Person icon
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Organizer text with varying width
                                  Container(
                                    height: 14,
                                    width: index % 2 == 0 ? 
                                      MediaQuery.of(context).size.width * 0.3 : 
                                      MediaQuery.of(context).size.width * 0.25,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Share button with inner details
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 2,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Description section with realistic paragraph appearance
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description header
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description text - 3 lines with varying widths
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: index % 3 == 0 ? 
                            MediaQuery.of(context).size.width * 0.9 : 
                            MediaQuery.of(context).size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Conference details section with multiple detail rows
                  Container(
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
                      children: List.generate(
                        numDetailsRows,
                        (i) => Padding(
                          padding: EdgeInsets.only(bottom: i < numDetailsRows - 1 ? 8.0 : 0.0),
                          child: _buildDetailRowShimmer(context, i),
                        ),
                      ),
                    ),
                  ),
                  
                  // Register button with icon or unavailable text
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: hasRegisterButton ?
                      // Register button with icon
                      Container(
                        height: 46,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 14,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ) :
                      // Registration unavailable text
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 14,
                          width: 170,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
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
  
  // Helper method to build a detail row shimmer with different color for each type
  Widget _buildDetailRowShimmer(BuildContext context, int rowIndex) {
    // Different colors for different types of details
    Color iconBaseColor;
    switch (rowIndex) {
      case 0: // Location
        iconBaseColor = Colors.green.withOpacity(0.3);
        break;
      case 1: // Venue
        iconBaseColor = Colors.orange.withOpacity(0.3);
        break;
      case 2: // Credits
        iconBaseColor = Colors.purple.withOpacity(0.3);
        break;
      default: // Specialties
        iconBaseColor = Colors.blue.withOpacity(0.3);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container with background
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBaseColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Detail text with varying width
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}