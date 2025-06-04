// // === CASE DISCUSSION MODULE INTEGRATION SNIPPET ===
// // Add this code to your main.dart file
//
// // 1. ADD THESE IMPORTS at the top of main.dart:
// import 'package:doctak_app/presentation/case_discussion/bloc/discussion_detail_bloc.dart';
// import 'package:doctak_app/presentation/case_discussion/bloc/create_discussion_bloc.dart';
// import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
// import 'package:doctak_app/presentation/case_discussion/screens/discussion_detail_screen.dart';
// import 'package:doctak_app/presentation/case_discussion/screens/create_discussion_screen.dart';
//
// // 2. IN YOUR MultiBlocProvider (around line 683), ADD THESE AFTER THE EXISTING DiscussionListBloc:
//
// // Note: You already have this one:
// // BlocProvider(
// //     create: (context) => DiscussionListBloc(
// //         repository: CaseDiscussionRepository(
// //             baseUrl: 'https://doctak.net',
// //             getAuthToken: () {
// //                 return AppData.userToken ?? "";
// //             }),
// //     )),
//
// // ADD THESE TWO:
// BlocProvider(
//     create: (context) => DiscussionDetailBloc(
//         repository: CaseDiscussionRepository(
//             baseUrl: 'https://doctak.net',
//             getAuthToken: () {
//                 return AppData.userToken ?? "";
//             }),
//     )),
// BlocProvider(
//     create: (context) => CreateDiscussionBloc(
//         repository: CaseDiscussionRepository(
//             baseUrl: 'https://doctak.net',
//             getAuthToken: () {
//                 return AppData.userToken ?? "";
//             }),
//     )),
//
// // 3. IN YOUR ROUTES MAP (around line 942), ADD THESE ROUTES:
//
// '/case_discussions': (context) => const DiscussionListScreen(),
// '/case_discussion_detail': (context) {
//   final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
//   return DiscussionDetailScreen(caseId: args['caseId']);
// },
// '/create_case_discussion': (context) => const CreateDiscussionScreen(),
//
// // 4. NAVIGATION EXAMPLES:
//
// // From your home drawer or any screen:
// // Navigate to case discussions list
// onTap: () {
//   Navigator.pushNamed(context, '/case_discussions');
// }
//
// // Navigate to specific case discussion
// onTap: () {
//   Navigator.pushNamed(
//     context,
//     '/case_discussion_detail',
//     arguments: {'caseId': 123}, // Replace with actual case ID
//   );
// }
//
// // Navigate to create new case discussion
// onTap: () {
//   Navigator.pushNamed(context, '/create_case_discussion');
// }
//
// // 5. ALTERNATIVE: Add to your drawer (in SVHomeDrawerComponent or similar):
//
// ListTile(
//   leading: Icon(Icons.forum, color: svGetBodyColor()),
//   title: Text('Case Discussions', style: primaryTextStyle(color: svGetBodyColor())),
//   onTap: () {
//     Navigator.pushNamed(context, '/case_discussions');
//   },
// ),
//
// // === END OF INTEGRATION SNIPPET ===