import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bloc/jobs_bloc.dart';
import 'bloc/jobs_state.dart';

class JobsDetailsScreen extends StatefulWidget {
  JobsDetailsScreen({required this.jobId,super.key});
  int jobId;
  @override
  State<JobsDetailsScreen> createState() => _JobsDetailsScreenState();
}

class _JobsDetailsScreenState extends State<JobsDetailsScreen> {
  JobsBloc jobsBloc = JobsBloc();
  @override
  void initState() {
    jobsBloc.add(
      JobDetailPageEvent(
          jobId: widget.jobId),
    );
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Job Details', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_rounded,
                color:svGetBodyColor(),),
            onPressed:(){Navigator.pop(context);}
        ),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body:  BlocConsumer<JobsBloc, JobsState>(
        bloc: jobsBloc,
        // listenWhen: (previous, current) => current is PaginationLoadedState,
        // buildWhen: (previous, current) => current is! PaginationLoadedState,
        listener: (BuildContext context, JobsState state) {
          if (state is DataError) {
            // showDialog(
            //   context: context,
            //   builder: (context) => AlertDialog(
            //     content: Text(state.errorMessage),
            //   ),
            // );
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return  Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
          } else if (state is PaginationLoadedState) {
            // print(state.drugsModel.length);
            return SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Material(
                  elevation: 4,
                  color:context.cardColor,
                  borderRadius:
                  const BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "New" ,
                              style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  fontSize: kDefaultFontSize),
                            ),
                            const Icon(Icons.bookmark_border),
                          ],
                        ),
                        Text(
                          jobsBloc.jobDetailModel.job?.jobTitle ?? "",
                          style: GoogleFonts.poppins(
                              color: svGetBodyColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(jobsBloc.jobDetailModel.job?.companyName ?? 'N/A',
                            style: secondaryTextStyle(
                                color: svGetBodyColor())),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                             Icon(
                              Icons.location_on,
                              size: 20,
                              color: svGetBodyColor(),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: Text(
                                  jobsBloc.jobDetailModel.job?.location ??
                                      'N/A',
                                  style: secondaryTextStyle(
                                      color: svGetBodyColor())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Apply Date',
                            style: GoogleFonts.poppins(
                                color: svGetBodyColor(),
                                fontWeight: FontWeight.w400,
                                fontSize: 14)),
                        Row(
                          children: [
                            Column(
                              mainAxisAlignment:
                              MainAxisAlignment.start,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text('Date From',
                                    style: secondaryTextStyle(
                                        color: svGetBodyColor())),
                                Row(
                                  children: <Widget>[
                                     Icon(
                                      Icons.date_range_outlined,
                                      size: 20,
                                      color: svGetBodyColor(),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(DateTime.parse(jobsBloc.jobDetailModel.job?.createdAt ??
                                            'N/A'.toString())),
                                        style: secondaryTextStyle(
                                            color: svGetBodyColor())),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              mainAxisAlignment:
                              MainAxisAlignment.start,
                              children: [
                                Text('Date To',
                                    style: secondaryTextStyle(
                                      color: svGetBodyColor(),
                                    )),
                                Row(
                                  children: <Widget>[
                                     Icon(
                                      Icons.date_range_outlined,
                                      size: 20,
                                      color: svGetBodyColor(),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(DateTime.parse(jobsBloc.jobDetailModel.job?.lastDate ??
                                            'N/A'.toString())),
                                        style: secondaryTextStyle(
                                            color: svGetBodyColor())),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                            'Experience: ${jobsBloc.jobDetailModel.job?.experience ?? 'N/A'}',
                            style: secondaryTextStyle(
                              color: svGetBodyColor(),
                            )),
                        const SizedBox(height: 5),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.hardEdge,
                          child: Container(
                            color: Colors.white,
                            child: HtmlWidget(
                              textStyle: GoogleFonts.poppins(color: svGetBodyColor(),),
                              '<p>${jobsBloc.jobDetailModel.job?.description}</p>',
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  // final Uri url = Uri.parse(bloc
                                  //     .drugsData[index]
                                  //     .link!); // Assuming job.link is a non-null String
                                  // Show dialog asking the user to confirm navigation
                                  final shouldLeave =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Leave App'),
                                      content: const Text(
                                          'Would you like to leave the app to view this content?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context)
                                                  .pop(false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(true);
                                            final Uri url = Uri.parse(
                                                jobsBloc.jobDetailModel.job?.link??'');
                                            _launchInBrowser(url);
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  );
                                  // If the user confirmed, launch the URL
                                  if (shouldLeave == true) {
                                    // await launchUrl(url);
                                  } else if (shouldLeave == false) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Leaving the app canceled.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Leaving the app canceled.')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Apply ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration:
                                    TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (state is DataError) {
            return Center(
              child: Text(state.errorMessage),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),

    );
  }
  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
