import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader for case discussion list screen
class CaseDiscussionListShimmer extends StatelessWidget {
  const CaseDiscussionListShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Author info row
                  Row(
                    children: [
                      // Author avatar
                      Container(
                        width: 48,
                        height: 48,
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
                              height: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            // Author specialty
                            Container(
                              width: 90,
                              height: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      // Time stamp
                      Container(
                        width: 60,
                        height: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Discussion title
                  Container(
                    width: double.infinity,
                    height: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  
                  // Discussion description
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats row
                  Row(
                    children: [
                      // Like count
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 20,
                            height: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Comment count
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 20,
                            height: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // View count
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 20,
                            height: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Trending indicator
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}