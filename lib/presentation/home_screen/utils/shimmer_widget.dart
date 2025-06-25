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
      itemCount: 10,
      itemBuilder: (context, index) => Shimmer.fromColors(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
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
                // Avatar with notification indicator
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    // Notification type indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title line 1
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title line 2 (shorter)
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Timestamp
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileListShimmer extends StatelessWidget {
  const ProfileListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) => Shimmer.fromColors(
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Profile Picture with shadow
                Container(
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
                        color: Colors.blue.withOpacity(0.15),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row with verification badge
                      Row(
                        children: [
                          // Name
                          Container(
                            height: 16,
                            width: 120 + (index % 3) * 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Verification badge
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Specialty
                      Container(
                        height: 14,
                        width: 90 + (index % 4) * 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Follow Button with shadow
                Container(
                  width: 90,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
