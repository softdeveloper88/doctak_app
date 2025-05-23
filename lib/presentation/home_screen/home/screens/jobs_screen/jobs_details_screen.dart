import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/document_upload_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/job_applicant_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
    print(widget.jobId);
    jobsBloc.add(
      JobDetailPageEvent(jobId: widget.jobId),
    );
    super.initState();
  }
  Countries findModelByNameOrDefault(
      List<Countries> countries,
      String name,
      Countries defaultCountry,
      ) {
    return countries.firstWhere(
          (country) => country.countryName?.toLowerCase() == name.toLowerCase(), // Case-insensitive match
      orElse: () => defaultCountry, // Return defaultCountry if not found
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(translation(context).lbl_job_detail, style: boldTextStyle(size: 18)),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: svGetBodyColor(),
            ),
            onPressed: () {
              if (widget.isFromSplash) {
                const SVDashboardScreen().launch(context, isNewTask: true);
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
            return ShimmerCardList();
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
                          mainAxisAlignment: MainAxisAlignment.end,
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
                              //&& jobsBloc.jobDetailModel.job?.user!.id != AppData.logInUserId
                              if((jobsBloc.jobDetailModel.hasApplied??false)==false)  MaterialButton(
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
                        const SizedBox(height: 10,),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              // border: Border.all(color: Colors.grey)
                            ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if(jobsBloc.jobDetailModel.hasApplied??false)  GestureDetector(
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
                             if(jobsBloc.jobDetailModel.job?.user!.id == AppData.logInUserId) TextButton(
                                onPressed: () {
                                  JobApplicantScreen(widget.jobId,jobsBloc).launch(context);
                                },
                                child: const Text(
                                  "Applicants",
                                  style: TextStyle(
                                      color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          jobsBloc.jobDetailModel.job?.jobTitle ?? "",
                          style: TextStyle(
                              color: svGetBodyColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(jobsBloc.jobDetailModel.job?.companyName ?? translation(context).lbl_not_available,
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
                        Text(translation(context).lbl_apply_date,
                            style: TextStyle(fontFamily: 'Poppins',
                                color: svGetBodyColor(),
                                fontWeight: FontWeight.w400,
                                fontSize: 14)),
                        Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(translation(context).lbl_date_from,
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
                                Text(translation(context).lbl_date_to,
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
                        Text(
                            'Preferred Language: ${jobsBloc.jobDetailModel.job?.preferredLanguage ?? 'N/A'}',
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
                              textStyle:  TextStyle(fontFamily: 'Poppins',
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
                                      title: Text(translation(context).lbl_leave_app),
                                      content: Text(
                                          translation(context).msg_open_link_confirm),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text(translation(context).lbl_no_answer),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                            final Uri url = Uri.parse(jobsBloc
                                                    .jobDetailModel.job?.link ??
                                                '');
                                            _launchInBrowser(url);
                                          },
                                          child: Text(translation(context).lbl_yes),
                                        ),
                                      ],
                                    ),
                                  );
                                  // If the user confirmed, launch the URL
                                  if (shouldLeave == true) {
                                    // await launchUrl(url);
                                  } else if (shouldLeave == false) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                          content: Text(
                                              translation(context).msg_leaving_app_canceled)),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                          content: Text(
                                              translation(context).msg_leaving_app_canceled)),
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
            return Center(child: Text(translation(context).msg_something_went_wrong));
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
