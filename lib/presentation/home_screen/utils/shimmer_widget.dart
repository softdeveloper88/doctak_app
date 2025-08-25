import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserShimmer extends StatelessWidget {
   const UserShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 10, // Number of shimmer items to show
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[200]!,
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
          title: Container(
            height: 10,
            width: double.infinity,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 10,
            width: double.infinity,
            color: Colors.white,
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        // Alternate between read/unread styles for realistic shimmer

        return Shimmer.fromColors(
          baseColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
          period: const Duration(milliseconds: 1500),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              // Match real notification background colors
              color:  Colors.blue.withOpacity(0.08),

              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:  Colors.blue.withOpacity(0.2),

                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  // Avatar with notification type indicator (matching real structure)
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      // Notification type indicator (bottom-right)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _getShimmerNotificationColor(index),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Content section (matching RichText structure)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main text (simulating RichText with name + action)
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Second line of text (shorter)
                        Container(
                          height: 14,
                          width: MediaQuery.of(context).size.width * 0.45,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Time row with icon (matching real structure)
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              height: 12,
                              width: 70 + (index % 3) * 15, // Variable width for realism
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow button (matching real structure)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey[300],
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

  // Helper method to get different indicator colors for variety
  Color _getShimmerNotificationColor(int index) {
    final colors = [
      Colors.green,
      Colors.red, 
      Colors.blue,
      Colors.purple,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }
}

class ProfileListShimmer extends StatelessWidget {
  const ProfileListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        // Alternate follow status for realism
        final isFollowed = index % 3 == 0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[900] 
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Shimmer
                Shimmer.fromColors(
                  baseColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[300]!,
                  highlightColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[100]!,
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name row with optional follow indicator
                      Row(
                        children: [
                          // Name shimmer
                          Shimmer.fromColors(
                            baseColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            highlightColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[100]!,
                            period: const Duration(milliseconds: 1500),
                            child: Container(
                              height: 16,
                              width: 120 + (index % 3) * 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          if (isFollowed) ...[
                            const SizedBox(width: 6),
                            // Follow indicator shimmer
                            Shimmer.fromColors(
                              baseColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              period: const Duration(milliseconds: 1500),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Specialty/Role shimmer
                      Shimmer.fromColors(
                        baseColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        highlightColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[100]!,
                        period: const Duration(milliseconds: 1500),
                        child: Container(
                          height: 14,
                          width: 90 + (index % 4) * 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Follow/Unfollow Button Shimmer
                Shimmer.fromColors(
                  baseColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[300]!,
                  highlightColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[100]!,
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
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

// class GuideLineShimmer extends StatelessWidget{
//   const GuideLineShimmer({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return ListView.builder(
//       itemCount: 10, // Number of shimmer items to show
//       itemBuilder: (context, index) =>
//           Shimmer.fromColors(
//             baseColor: Colors.grey[300]!,
//             highlightColor: Colors.grey[100]!,
//             child: ListTile(
//
//
//               title: Column(
//                 children: [
//                   _buildShimmerLine(),
//                   Container(
//                     height: 200,
//                     width: double.infinity,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//
//             ),
//           ),
//
//     );
//
//   }
//   Widget _buildShimmerLine() {
//     return Container(
//       width: double.infinity,
//       height: 16,
//       color: Colors.white,
//     );
//   }
// }
// class ChatShimmer extends StatelessWidget{
//   const ChatShimmer({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return ListView.builder(
//       itemCount: 10, // Number of shimmer items to show
//       itemBuilder: (context, index) =>
//           Shimmer.fromColors(
//             baseColor: Colors.grey[300]!,
//             highlightColor: Colors.grey[100]!,
//             child: Container(
//               margin: EdgeInsets.symmetric(vertical: 8),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color:  Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               height: 20,
//               width: double.infinity,
//               color: Colors.white,
//             ),
//           ),
//     );
//   }
//
// }
