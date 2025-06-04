import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/widgets/job_card_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/bloc/search_bloc.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
import '../jobs_screen/document_upload_dialog.dart';
import 'bloc/search_event.dart';

class SearchJobList extends StatelessWidget {
  SearchJobList(this.drugsBloc, {super.key});

  SearchBloc drugsBloc;

  @override
  Widget build(BuildContext context) {
    if (drugsBloc.drugsData.isNotEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.black : Colors.grey[50],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: drugsBloc.drugsData.length,
            itemBuilder: (context, index) {
              if (drugsBloc.pageNumber <= drugsBloc.numberOfPage) {
                if (index ==
                    drugsBloc.drugsData.length - drugsBloc.nextPageTrigger) {
                  drugsBloc.add(CheckIfNeedMoreDataEvent(index: index));
                }
              }
              if (drugsBloc.numberOfPage != drugsBloc.pageNumber - 1 &&
                  index >= drugsBloc.drugsData.length - 1) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const JobsShimmerLoader(),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: JobCardWidget(
                      jobData: drugsBloc.drugsData[index],
                      selectedIndex: 0,
                      onJobTap: () {
                        JobsDetailsScreen(jobId: '${drugsBloc.drugsData[index].id}')
                            .launch(context);
                      },
                      onShareTap: () {
                        createDynamicLink(
                          '${drugsBloc.drugsData[index].jobTitle ?? ""} \n Apply Link: ${drugsBloc.drugsData[index].link ?? ''}',
                          'https://doctak.net/job/${drugsBloc.drugsData[index].id}',
                          drugsBloc.drugsData[index].link ?? '',
                        );
                      },
                      onApplyTap: (id) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DocumentUploadDialog(id);
                          },
                        );
                      },
                      onLaunchLink: (url) {
                        PostUtils.launchURL(context, url.toString());
                      },
                    ),
                  ),
                );
              // return Container(
              //   margin: const EdgeInsets.all(10),
              //   decoration: BoxDecoration(
              //     color: context.cardColor,
              //     borderRadius: BorderRadius.circular(5),
              //   ),
              //   child: Material(
              //     color: context.cardColor,
              //     elevation: 4,
              //     borderRadius:
              //     const BorderRadius.all(Radius.circular(10)),
              //     child: Container(
              //       padding: const EdgeInsets.all(10),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           // Row(
              //           //   mainAxisAlignment:
              //           //   MainAxisAlignment.spaceBetween,
              //           //   children: [
              //           //     // Text(
              //           //     //   selectedIndex == 0 ? "New" : "Expired",
              //           //     //   style: TextStyle(
              //           //     //       color: Colors.red,
              //           //     //       fontWeight: FontWeight.w500,
              //           //     //       fontSize: kDefaultFontSize),
              //           //     // ),
              //           //     const Icon(Icons.bookmark_border),
              //           //   ],
              //           // ),
              //           Text(
              //             drugsBloc.drugsData[index].jobTitle ?? "",
              //             style: TextStyle(fontFamily: 'Poppins',
              //                 color: svGetBodyColor(),
              //                 fontWeight: FontWeight.bold,
              //                 fontSize: 18),
              //           ),
              //           const SizedBox(height: 5),
              //           Text(drugsBloc.drugsData[index].companyName ?? 'N/A',
              //               style: secondaryTextStyle(
              //                   color: svGetBodyColor())),
              //           const SizedBox(height: 10),
              //           Row(
              //             children: <Widget>[
              //               const Icon(
              //                 Icons.location_on,
              //                 size: 20,
              //                 color: Colors.grey,
              //               ),
              //               const SizedBox(
              //                 width: 5,
              //               ),
              //               Expanded(
              //                 child: Text(
              //                     drugsBloc.drugsData[index].location ??
              //                         'N/A',
              //                     style: secondaryTextStyle(
              //                         color: svGetBodyColor())),
              //               ),
              //             ],
              //           ),
              //           const SizedBox(height: 20),
              //           Text('Apply Date',
              //               style: TextStyle(fontFamily: 'Poppins',
              //                   color: svGetBodyColor(),
              //                   fontWeight: FontWeight.w400,
              //                   fontSize: 14)),
              //           Row(
              //             children: [
              //               Column(
              //                 mainAxisAlignment:
              //                 MainAxisAlignment.start,
              //                 crossAxisAlignment:
              //                 CrossAxisAlignment.start,
              //                 children: [
              //                   Text('Date From',
              //                       style: secondaryTextStyle(
              //                           color: svGetBodyColor())),
              //                   Row(
              //                     children: <Widget>[
              //                       const Icon(
              //                         Icons.date_range_outlined,
              //                         size: 20,
              //                         color: Colors.grey,
              //                       ),
              //                       const SizedBox(
              //                         width: 5,
              //                       ),
              //                       Text(
              //                           DateFormat('MMM dd, yyyy')
              //                               .format(DateTime.parse(drugsBloc
              //                               .drugsData[index]
              //                               .createdAt ??
              //                               'N/A'.toString())),
              //                           style: secondaryTextStyle(
              //                               color: svGetBodyColor())),
              //                     ],
              //                   ),
              //                 ],
              //               ),
              //               const SizedBox(
              //                 width: 20,
              //               ),
              //               Column(
              //                 crossAxisAlignment:
              //                 CrossAxisAlignment.start,
              //                 mainAxisAlignment:
              //                 MainAxisAlignment.start,
              //                 children: [
              //                   Text('Date To',
              //                       style: secondaryTextStyle(
              //                           color: svGetBodyColor())),
              //                   Row(
              //                     children: <Widget>[
              //                       const Icon(
              //                         Icons.date_range_outlined,
              //                         size: 20,
              //                         color: Colors.grey,
              //                       ),
              //                       const SizedBox(
              //                         width: 5,
              //                       ),
              //                       Text(
              //                           DateFormat('MMM dd, yyyy')
              //                               .format(DateTime.parse(drugsBloc
              //                               .drugsData[index]
              //                               .lastDate ??
              //                               'N/A'.toString())),
              //                           style: secondaryTextStyle(
              //                               color: svGetBodyColor())),
              //                     ],
              //                   ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //           Text(
              //               'Experience: ${drugsBloc.drugsData[index]
              //                   .experience ??
              //                   'N/A'}',
              //               style: secondaryTextStyle(
              //                   color: svGetBodyColor())),
              //           Text(
              //               'Preferred Languages: ${drugsBloc.drugsData[index]
              //                   .preferredLanguage ??
              //                   'N/A'}',
              //               style: secondaryTextStyle(
              //                   color: svGetBodyColor())),
              //
              //           const SizedBox(height: 5),
              //           Row(
              //             children: [
              //               Expanded(
              //                 child: Container(
              //                   color: Colors.white,
              //                   child: HtmlWidget(
              //                     '<p>${drugsBloc.drugsData[index]
              //                         .description}</p>',
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //           const SizedBox(height: 5),
              //           Padding(
              //             padding: const EdgeInsets.only(top: 16),
              //             child: Column(
              //               crossAxisAlignment:
              //               CrossAxisAlignment.start,
              //               children: [
              //                 TextButton(
              //                   onPressed: () async {
              //                     // final Uri url = Uri.parse(bloc
              //                     //     .drugsData[index]
              //                     //     .link!); // Assuming job.link is a non-null String
              //                     // Show dialog asking the user to confirm navigation
              //                     final shouldLeave =
              //                     await showDialog<bool>(
              //                       context: context,
              //                       builder: (context) =>
              //                           AlertDialog(
              //                             title: const Text('Leave App'),
              //                             content: const Text(
              //                                 'Would you like to leave the app to view this content?'),
              //                             actions: <Widget>[
              //                               TextButton(
              //                                 onPressed: () =>
              //                                     Navigator.of(context)
              //                                         .pop(false),
              //                                 child: const Text('No'),
              //                               ),
              //                               TextButton(
              //                                 onPressed: () =>
              //                                     Navigator.of(context)
              //                                         .pop(true),
              //                                 child: const Text('Yes'),
              //                               ),
              //                             ],
              //                           ),
              //                     );
              //                     // If the user confirmed, launch the URL
              //                     if (shouldLeave == true) {
              //                       // await launchUrl(url);
              //                     } else if (shouldLeave == false) {
              //                       ScaffoldMessenger.of(context)
              //                           .showSnackBar(
              //                         const SnackBar(
              //                             content: Text(
              //                                 'Leaving the app canceled.')),
              //                       );
              //                     } else {
              //                       ScaffoldMessenger.of(context)
              //                           .showSnackBar(
              //                         const SnackBar(
              //                             content: Text(
              //                                 'Leaving the app canceled.')),
              //                       );
              //                     }
              //                   },
              //                   child: const Text(
              //                     'Apply ',
              //                     style: TextStyle(
              //                       color: Colors.blue,
              //                       decoration:
              //                       TextDecoration.underline,
              //                     ),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // );
            }
            // return PostItem(drugsBloc.drugsData[index].title, drugsBloc.posts[index].body);
          },
        ),
      ));
    } else {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_no_jobs_found,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
