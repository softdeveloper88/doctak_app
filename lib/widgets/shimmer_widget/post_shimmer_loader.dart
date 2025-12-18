import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostShimmerLoader extends StatelessWidget {
  final int itemCount;

  const PostShimmerLoader({
    super.key,
    this.itemCount = 3, // Default item count is 3
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: const Padding(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                  ),
                  title: _ShimmerBox(height: 10),
                  subtitle: _ShimmerBox(height: 10),
                ),
                SizedBox(height: 8.0),
                _ShimmerBox(height: 300),
                SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  
  const _ShimmerBox({required this.height});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
