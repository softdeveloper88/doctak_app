import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostShimmerLoader extends StatelessWidget {
  final int itemCount;

  const PostShimmerLoader({
    Key? key,
    this.itemCount = 3, // Default item count is 3
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                  ),
                  title: Container(
                    width: double.infinity,
                    height: 10.0,
                    color: Colors.white,
                  ),
                  subtitle: Container(
                    width: double.infinity,
                    height: 10.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
