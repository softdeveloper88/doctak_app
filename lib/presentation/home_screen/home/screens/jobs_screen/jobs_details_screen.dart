import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/document_upload_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/job_applicant_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../SVDashboardScreen.dart';
import 'bloc/jobs_bloc.dart';
import 'bloc/jobs_state.dart';

class JobsDetailsScreen extends StatefulWidget {
  JobsDetailsScreen(
      {required this.jobId, this.isFromSplash = false, super.key});

  String jobId;
  bool isFromSplash;

  @override
  State<JobsDetailsScreen> createState() => _JobsDetailsScreenState();
}

class _JobsDetailsScreenState extends State<JobsDetailsScreen> {
  JobsBloc jobsBloc = JobsBloc();

  @override
  void initState() {
    jobsBloc.add(
      JobDetailPageEvent(jobId: widget.jobId),
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
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: svGetBodyColor(),
            ),
            onPressed: () {
              if (widget.isFromSplash) {
                SVDashboardScreen().launch(context, isNewTask: true);
              } else {
                Navigator.pop(context);
              }
            }),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: BlocConsumer<JobsBloc, JobsState>(
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
            return Center(
                child: CircularProgressIndicator(
              color: svGetBodyColor(),
            ));
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
                  color: context.cardColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "New",
                              style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  fontSize: kDefaultFontSize),
                            ),
                            Row(
                              children: [
                            if(jobsBloc.jobDetailModel.job?.promoted !=0 )   Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.orangeAccent),
                                  child: const Text(
                                    'Sponsored',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                              if(jobsBloc.jobDetailModel.hasApplied !=false)  MaterialButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  color: Colors.blue,
                                  splashColor: Colors.blue,
                                  highlightColor: Colors.green,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return DocumentUploadDialog(widget
                                            .jobId); // Call the dialog from here
                                      },
                                    );
                                  },
                                  child: const Text(
                                    "Apply",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400),
                                    // 'images/socialv/icons/ic_share.png',
                                    // height: 22,
                                    // width: 22,
                                    // fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () {
                                    // _showBottomSheet(context,widget
                                    //     .homeBloc
                                    //     .postList[index]);
                                    createDynamicLink(
                                        '${jobsBloc.jobDetailModel.job?.jobTitle ?? ""}\n Apply Link  ${jobsBloc.jobDetailModel.job?.link ?? ''}',
                                        'https://doctak.net/job/${jobsBloc.jobDetailModel.job?.id}',
                                        jobsBloc.jobDetailModel.job?.link ??
                                            '');
                                    // Share.share("Job Title: ${jobsBloc.jobDetailModel.job?.jobTitle ?? ""}\n"
                                    //     "Company : ${jobsBloc.jobDetailModel.job?.companyName}\n"
                                    //     "Location: ${jobsBloc.jobDetailModel.job?.location ?? 'N/A'}\n"
                                    //     "Date From: ${ jobsBloc.jobDetailModel.job?.createdAt ??
                                    //     'N/A'}\n"
                                    //     "Date To: ${ jobsBloc.jobDetailModel.job?.lastDate ??
                                    //     'N/A'}\n"
                                    //     "Experience: ${ jobsBloc.jobDetailModel.job?.experience ??
                                    //     'N/A'}\n"
                                    //     "Job Apply Link: ${jobsBloc.jobDetailModel.job?.link ??
                                    //     'N/A'}\n" );
                                  },
                                  child: Icon(
                                    Icons.share_sharp,
                                    size: 22,
                                    // 'images/socialv/icons/ic_share.png',
                                    // height: 22,
                                    // width: 22,
                                    // fit: BoxFit.cover,
                                    color: context.iconColor,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              border: Border.all(color: Colors.grey)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if(jobsBloc.jobDetailModel.job?.userId != AppData.logInUserId)  GestureDetector(
                                onTap: (){
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CustomAlertDialog(
                                          mainTitle:"Withdraw Applicant",
                                           yesButtonText: 'Withdraw',
                                            title: 'Are you sure want to withdraw your application ?',
                                            callback: () {
                                              jobsBloc.add(WithDrawApplicant(jobId:widget.jobId));

                                              Navigator.of(context).pop();
                                            });
                                      });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.orangeAccent),
                                  child: const Text(
                                    'Withdraw Application',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                             if(jobsBloc.jobDetailModel.job?.userId ==AppData.logInUserId) TextButton(
                                onPressed: () {
                                  JobApplicantScreen(widget.jobId,jobsBloc).launch(context);
                                },
                                child: Text(
                                  "Applicants",
                                  style: GoogleFonts.poppins(
                                      color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
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
                            style: secondaryTextStyle(color: svGetBodyColor())),
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        DateFormat('MMM dd, yyyy').format(
                                            DateTime.parse(jobsBloc
                                                    .jobDetailModel
                                                    .job
                                                    ?.createdAt ??
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                        DateFormat('MMM dd, yyyy').format(
                                            DateTime.parse(jobsBloc
                                                    .jobDetailModel
                                                    .job
                                                    ?.lastDate ??
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
                              textStyle: GoogleFonts.poppins(
                                color: svGetBodyColor(),
                              ),
                              '<p>${jobsBloc.jobDetailModel.job?.description}</p>',
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  // final Uri url = Uri.parse(bloc
                                  //     .drugsData[index]
                                  //     .link!); // Assuming job.link is a non-null String
                                  // Show dialog asking the user to confirm navigation
                                  final shouldLeave = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Leave App'),
                                      content: const Text(
                                          'Would you like to leave the app to view this content?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                            final Uri url = Uri.parse(jobsBloc
                                                    .jobDetailModel.job?.link ??
                                                '');
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Leaving the app canceled.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Leaving the app canceled.')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Visit Site ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
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
