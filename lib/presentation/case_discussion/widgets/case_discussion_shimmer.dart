import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader for case discussion detail screen
class CaseDiscussionShimmer extends StatelessWidget {
  const CaseDiscussionShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discussion header shimmer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                              width: 80,
                              height: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      // Follow button
                      Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Discussion title
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  
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
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats and actions
                  Row(
                    children: [
                      // Like button
                      Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Share button
                      Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const Spacer(),
                      // Views/likes count
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Comments header shimmer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100,
                    height: 18,
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Comments shimmer
            ...List.generate(3, (index) => _buildCommentShimmer(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              // Avatar
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
                    // Username
                    Container(
                      width: 100,
                      height: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    // Specialty
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              // Time
              Container(
                width: 60,
                height: 12,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Comment text
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
          
          // Action buttons
          Row(
            children: [
              Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}