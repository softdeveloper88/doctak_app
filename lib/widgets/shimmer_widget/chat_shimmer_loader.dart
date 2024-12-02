import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20, // Number of placeholders
      itemBuilder: (context, index) {
        // Alternate between sent and received messages
        bool isSent = index % 2 == 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isSent) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(width: 8),
              ],
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 30,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (isSent) SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
