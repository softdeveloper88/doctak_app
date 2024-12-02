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
