// import 'package:doctak_app/core/utils/dynamic_link.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_state.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
// import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ConferenceDetailsScreen extends StatefulWidget {
//   ConferenceDetailsScreen({required this.conferenceId,super.key});
//   int conferenceId;
//   @override
//   State<ConferenceDetailsScreen> createState() => _ConferenceDetailsScreenState();
// }
//
// class _ConferenceDetailsScreenState extends State<ConferenceDetailsScreen> {
//   ConferenceBloc conferenceBloc = ConferenceBloc();
//   @override
//   void initState() {
//     // conferenceBloc.add(
//     //   JobDetailPageEvent(
//     //       conferenceId: widget.conferenceId),
//     // );
//     super.initState();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: svGetScaffoldColor(),
//       appBar: AppBar(
//         backgroundColor: svGetScaffoldColor(),
//         iconTheme: IconThemeData(color: context.iconColor),
//         title: Text('Conference Details', style: boldTextStyle(size: 20)),
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//             icon:  Icon(Icons.arrow_back_ios_new_rounded,
//               color:svGetBodyColor(),),
//             onPressed:(){Navigator.pop(context);}
//         ),
//         actions: const [
//           // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
//         ],
//       ),
//       body:  BlocConsumer<ConferenceBloc, ConferenceState>(
//         bloc: conferenceBloc,
//         // listenWhen: (previous, current) => current is PaginationLoadedState,
//         // buildWhen: (previous, current) => current is! PaginationLoadedState,
//         listener: (BuildContext context, ConferenceState state) {
//           if (state is DataError) {
//             // showDialog(
//             //   context: context,
//             //   builder: (context) => AlertDialog(
//             //     content: Text(state.errorMessage),
//             //   ),
//             // );
//           }
//         },
//         builder: (context, state) {
//           if (state is PaginationLoadingState) {
//             return  Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
//           } else if (state is PaginationLoadedState) {
//             // print(state.drugsModel.length);
//             return SingleChildScrollView(
//               child: Container(
//                 margin: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: context.cardColor,
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//                 child: Material(
//                   elevation: 4,
//                   color:context.cardColor,
//                   borderRadius:
//                   const BorderRadius.all(Radius.circular(10)),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildConferenceImageOrPlaceholder(),
//                       const SizedBox(height: 8),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 conference.title ?? 'No Title Available',
//                                 style: const TextStyle(
//                                   fontFamily: 'Robotic',
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18.0,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: InkWell(
//                                 splashColor: Colors.transparent,
//                                 highlightColor: Colors.transparent,
//                                 onTap: () {
//                                   // _showBottomSheet(context,widget
//                                   //     .homeBloc
//                                   //     .postList[index]);
//                                   createDynamicLink(
//                                       '${ conference.title ?? ""} \n  Register Link: ${ conference.conferenceAgendaLink ??''}',
//                                       'https://doctak.net/conference/${conference.id}',
//                                       conference.thumbnail??'');
//                                   // Share.share("Job Title: ${bloc.drugsData[index].jobTitle ?? ""}\n"
//                                   //     "Company : ${bloc.drugsData[index].companyName}\n"
//                                   //     "Location: ${bloc.drugsData[index].location ?? 'N/A'}\n"
//                                   //     "Date From: ${ bloc.drugsData[index]
//                                   //     .createdAt ??
//                                   //     'N/A'}\n"
//                                   //     "Date To: ${ bloc.drugsData[index]
//                                   //     .lastDate ??
//                                   //     'N/A'}\n"
//                                   //     "Experience: ${ bloc.drugsData[index]
//                                   //     .experience ??
//                                   //     'N/A'}\n"
//                                   //     "Job Apply Link: ${ bloc.drugsData[index]
//                                   //     .link ??
//                                   //     'N/A'}\n" );
//
//                                 },
//                                 child: Icon(Icons.share_sharp,
//                                   size: 22,
//                                   // 'images/socialv/icons/ic_share.png',
//                                   // height: 22,
//                                   // width: 22,
//                                   // fit: BoxFit.cover,
//                                   color: context.iconColor,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Conference Dates
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(
//                           '${conference.startDate ?? ''} - ${conference.endDate ?? ''}',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//
//                       const SizedBox(height: 4),
//
//                       // Action button (Register Now)
//
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: svAppButton(
//                           width: 30.w,
//                           // color: svGetBodyColor(),
//                           onTap: () {
//                             Uri registrationUri = Uri.parse(conference.registrationLink!);
//                             _launchInBrowser(registrationUri);
//                           },
//                           text: 'Register Now', context: context,
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       // Conference Description
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(conference.description ?? 'No Description Available'),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       // Other Conference Information (City, Venue, Organizer, etc.)
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8),
//                         child: Text('City: ${conference.city ?? 'N/A'}\n'
//                             'Venue: ${conference.venue ?? 'N/A'}\n'
//                             'Organizer: ${conference.organizer ?? 'N/A'}\n'
//                             'Country: ${conference.country ?? 'N/A'}\n'
//                             'CME Credits: ${conference.cmeCredits ?? 'N/A'}\n'
//                             'MOC Credits: ${conference.mocCredits ?? 'N/A'}\n'
//                           // 'Specialties Targeted: ${conference.specialties_targeted ?? 'N/A'}',
//                         ),
//                       ),
//
//                     ],
//                   ),
//                   // child: Container(
//                   //   padding: const EdgeInsets.all(10),
//                   //   child: Column(
//                   //     crossAxisAlignment: CrossAxisAlignment.start,
//                   //     children: [
//                   //       Row(
//                   //         mainAxisAlignment:
//                   //         MainAxisAlignment.spaceBetween,
//                   //         children: [
//                   //           Text(
//                   //             "New" ,
//                   //             style: GoogleFonts.poppins(
//                   //                 color: Colors.red,
//                   //                 fontWeight: FontWeight.w500,
//                   //                 fontSize: kDefaultFontSize),
//                   //           ),
//                   //           InkWell(
//                   //             splashColor: Colors.transparent,
//                   //             highlightColor: Colors.transparent,
//                   //             onTap: () {
//                   //               // _showBottomSheet(context,widget
//                   //               //     .homeBloc
//                   //               //     .postList[index]);
//                   //               createDynamicLink(
//                   //                   '${conferenceBloc.jobDetailModel.job?.jobTitle ?? "" }\n Apply Link  ${conferenceBloc.jobDetailModel.job?.link ??''}',
//                   //                   'https://doctak.net/job/${conferenceBloc.jobDetailModel.job?.id}',
//                   //                   conferenceBloc.jobDetailModel.job?.link ??'');
//                   //               // Share.share("Job Title: ${conferenceBloc.jobDetailModel.job?.jobTitle ?? ""}\n"
//                   //               //     "Company : ${conferenceBloc.jobDetailModel.job?.companyName}\n"
//                   //               //     "Location: ${conferenceBloc.jobDetailModel.job?.location ?? 'N/A'}\n"
//                   //               //     "Date From: ${ conferenceBloc.jobDetailModel.job?.createdAt ??
//                   //               //     'N/A'}\n"
//                   //               //     "Date To: ${ conferenceBloc.jobDetailModel.job?.lastDate ??
//                   //               //     'N/A'}\n"
//                   //               //     "Experience: ${ conferenceBloc.jobDetailModel.job?.experience ??
//                   //               //     'N/A'}\n"
//                   //               //     "Job Apply Link: ${conferenceBloc.jobDetailModel.job?.link ??
//                   //               //     'N/A'}\n" );
//                   //
//                   //
//                   //             },
//                   //             child: Icon(Icons.share_sharp,
//                   //               size: 22,
//                   //               // 'images/socialv/icons/ic_share.png',
//                   //               // height: 22,
//                   //               // width: 22,
//                   //               // fit: BoxFit.cover,
//                   //               color: context.iconColor,
//                   //             ),
//                   //           ),
//                   //         ],
//                   //       ),
//                   //       Text(
//                   //         conferenceBloc.jobDetailModel.job?.jobTitle ?? "",
//                   //         style: GoogleFonts.poppins(
//                   //             color: svGetBodyColor(),
//                   //             fontWeight: FontWeight.bold,
//                   //             fontSize: 18),
//                   //       ),
//                   //       const SizedBox(height: 5),
//                   //       Text(conferenceBloc.jobDetailModel.job?.companyName ?? 'N/A',
//                   //           style: secondaryTextStyle(
//                   //               color: svGetBodyColor())),
//                   //       const SizedBox(height: 10),
//                   //       Row(
//                   //         children: <Widget>[
//                   //           Icon(
//                   //             Icons.location_on,
//                   //             size: 20,
//                   //             color: svGetBodyColor(),
//                   //           ),
//                   //           const SizedBox(
//                   //             width: 5,
//                   //           ),
//                   //           Expanded(
//                   //             child: Text(
//                   //                 conferenceBloc.jobDetailModel.job?.location ??
//                   //                     'N/A',
//                   //                 style: secondaryTextStyle(
//                   //                     color: svGetBodyColor())),
//                   //           ),
//                   //         ],
//                   //       ),
//                   //       const SizedBox(height: 20),
//                   //       Text('Apply Date',
//                   //           style: GoogleFonts.poppins(
//                   //               color: svGetBodyColor(),
//                   //               fontWeight: FontWeight.w400,
//                   //               fontSize: 14)),
//                   //       Row(
//                   //         children: [
//                   //           Column(
//                   //             mainAxisAlignment:
//                   //             MainAxisAlignment.start,
//                   //             crossAxisAlignment:
//                   //             CrossAxisAlignment.start,
//                   //             children: [
//                   //               Text('Date From',
//                   //                   style: secondaryTextStyle(
//                   //                       color: svGetBodyColor())),
//                   //               Row(
//                   //                 children: <Widget>[
//                   //                   Icon(
//                   //                     Icons.date_range_outlined,
//                   //                     size: 20,
//                   //                     color: svGetBodyColor(),
//                   //                   ),
//                   //                   const SizedBox(
//                   //                     width: 5,
//                   //                   ),
//                   //                   Text(
//                   //                       DateFormat('MMM dd, yyyy')
//                   //                           .format(DateTime.parse(conferenceBloc.jobDetailModel.job?.createdAt ??
//                   //                           'N/A'.toString())),
//                   //                       style: secondaryTextStyle(
//                   //                           color: svGetBodyColor())),
//                   //                 ],
//                   //               ),
//                   //             ],
//                   //           ),
//                   //           const SizedBox(
//                   //             width: 20,
//                   //           ),
//                   //           Column(
//                   //             crossAxisAlignment:
//                   //             CrossAxisAlignment.start,
//                   //             mainAxisAlignment:
//                   //             MainAxisAlignment.start,
//                   //             children: [
//                   //               Text('Date To',
//                   //                   style: secondaryTextStyle(
//                   //                     color: svGetBodyColor(),
//                   //                   )),
//                   //               Row(
//                   //                 children: <Widget>[
//                   //                   Icon(
//                   //                     Icons.date_range_outlined,
//                   //                     size: 20,
//                   //                     color: svGetBodyColor(),
//                   //                   ),
//                   //                   const SizedBox(
//                   //                     width: 5,
//                   //                   ),
//                   //                   Text(
//                   //                       DateFormat('MMM dd, yyyy')
//                   //                           .format(DateTime.parse(conferenceBloc.jobDetailModel.job?.lastDate ??
//                   //                           'N/A'.toString())),
//                   //                       style: secondaryTextStyle(
//                   //                           color: svGetBodyColor())),
//                   //                 ],
//                   //               ),
//                   //             ],
//                   //           ),
//                   //         ],
//                   //       ),
//                   //       Text(
//                   //           'Experience: ${conferenceBloc.jobDetailModel.job?.experience ?? 'N/A'}',
//                   //           style: secondaryTextStyle(
//                   //             color: svGetBodyColor(),
//                   //           )),
//                   //       const SizedBox(height: 5),
//                   //       SingleChildScrollView(
//                   //         scrollDirection: Axis.horizontal,
//                   //         clipBehavior: Clip.hardEdge,
//                   //         child: Container(
//                   //           color: Colors.white,
//                   //           child: HtmlWidget(
//                   //             textStyle: GoogleFonts.poppins(color: svGetBodyColor(),),
//                   //             '<p>${conferenceBloc.jobDetailModel.job?.description}</p>',
//                   //           ),
//                   //         ),
//                   //       ),
//                   //       const SizedBox(height: 5),
//                   //       Padding(
//                   //         padding: const EdgeInsets.only(top: 16),
//                   //         child: Column(
//                   //           crossAxisAlignment:
//                   //           CrossAxisAlignment.start,
//                   //           children: [
//                   //             TextButton(
//                   //               onPressed: () async {
//                   //                 // final Uri url = Uri.parse(bloc
//                   //                 //     .drugsData[index]
//                   //                 //     .link!); // Assuming job.link is a non-null String
//                   //                 // Show dialog asking the user to confirm navigation
//                   //                 final shouldLeave =
//                   //                 await showDialog<bool>(
//                   //                   context: context,
//                   //                   builder: (context) => AlertDialog(
//                   //                     title: const Text('Leave App'),
//                   //                     content: const Text(
//                   //                         'Would you like to leave the app to view this content?'),
//                   //                     actions: <Widget>[
//                   //                       TextButton(
//                   //                         onPressed: () =>
//                   //                             Navigator.of(context)
//                   //                                 .pop(false),
//                   //                         child: const Text('No'),
//                   //                       ),
//                   //                       TextButton(
//                   //                         onPressed: () {
//                   //                           Navigator.of(context)
//                   //                               .pop(true);
//                   //                           final Uri url = Uri.parse(
//                   //                               conferenceBloc.jobDetailModel.job?.link??'');
//                   //                           _launchInBrowser(url);
//                   //                         },
//                   //                         child: const Text('Yes'),
//                   //                       ),
//                   //                     ],
//                   //                   ),
//                   //                 );
//                   //                 // If the user confirmed, launch the URL
//                   //                 if (shouldLeave == true) {
//                   //                   // await launchUrl(url);
//                   //                 } else if (shouldLeave == false) {
//                   //                   ScaffoldMessenger.of(context)
//                   //                       .showSnackBar(
//                   //                     const SnackBar(
//                   //                         content: Text(
//                   //                             'Leaving the app canceled.')),
//                   //                   );
//                   //                 } else {
//                   //                   ScaffoldMessenger.of(context)
//                   //                       .showSnackBar(
//                   //                     const SnackBar(
//                   //                         content: Text(
//                   //                             'Leaving the app canceled.')),
//                   //                   );
//                   //                 }
//                   //               },
//                   //               child: const Text(
//                   //                 'Apply ',
//                   //                 style: TextStyle(
//                   //                   color: Colors.blue,
//                   //                   decoration:
//                   //                   TextDecoration.underline,
//                   //                 ),
//                   //               ),
//                   //             ),
//                   //           ],
//                   //         ),
//                   //       ),
//                   //     ],
//                   //   ),
//                   // ),
//                 ),
//               ),
//             );
//           } else if (state is DataError) {
//             return Center(
//               child: Text(state.errorMessage),
//             );
//           } else {
//             return const Center(child: Text('Something went wrong'));
//           }
//         },
//       ),
//
//     );
//   }
//
//   Future<void> _launchInBrowser(Uri url) async {
//     if (!await launchUrl(
//       url,
//       mode: LaunchMode.externalApplication,
//     )) {
//       throw Exception('Could not launch $url');
//     }
//   }
//   Widget _buildConferenceImageOrPlaceholder() {
//     if (conference.thumbnail != null && conference.thumbnail!.isNotEmpty) {
//       return Container(
//         margin: const EdgeInsets.all(8.0), // Add margin to the container
//         child: Image.network(
//           conference.thumbnail!,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: 300,
//           errorBuilder: (context, error, stackTrace) {
//             return const Center(child: Text('Image not available'));
//           },
//         ),
//       );
//     } else {
//       return Container(
//         margin: const EdgeInsets.all(8.0), // Add margin to the container
//         // child: DecoratedBox(
//         //   decoration: BoxDecoration(
//         //     color: Colors.lightBlueAccent,
//         //     borderRadius: BorderRadius.circular(10.0),
//         //   ),
//         //   child: const SizedBox(
//         //     width: double.infinity,
//         //     height: 300,
//         //     child: Padding(
//         //       padding: EdgeInsets.all(16.0),
//         //       child: Center(
//         //         child: Text(
//         //           'No Image Available',
//         //           textAlign: TextAlign.center,
//         //           style: TextStyle(
//         //             fontSize: 18.0,
//         //             color: Colors.white,
//         //             fontWeight: FontWeight.bold,
//         //           ),
//         //         ),
//         //       ),
//         //     ),
//         //   ),
//         // ),
//       );
//     }
//   }
//
// }
