import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/jobs_event.dart';

class JobApplicantScreen extends StatefulWidget {
  String jobId;
  JobsBloc jobBloc;

  JobApplicantScreen(this.jobId, this.jobBloc, {super.key});

  @override
  State<JobApplicantScreen> createState() => _JobApplicantScreenState();
}

class _JobApplicantScreenState extends State<JobApplicantScreen> {
  // JobsBloc widget.jobBloc = JobsBloc();
  @override
  void initState() {
    setStatusBarColor(svGetScaffoldColor());
    // Data jobsModel = widget.jobBloc.drugsData.singleWhere((job)=>job.id.toString()==widget.jobId.toString());
    // applicantList=jobsModel.applicants!.toList();
    widget.jobBloc.add(ShowApplicantEvent(jobId: widget.jobId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        title: Text(
          'Applicants',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [],
      ),
      body: BlocConsumer<JobsBloc, JobsState>(
        bloc: widget.jobBloc,
        listener: (BuildContext context, JobsState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(state.errorMessage),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return Center(
                child: CircularProgressIndicator(
              color: svGetBodyColor(),
            ));
          } else if (state is PaginationLoadedState) {
            return ListView.builder(
              itemCount:
                  widget.jobBloc.jobApplicantsModel?.applicants?.length ?? 0,
              itemBuilder: (context, index) {
                var bloc = widget.jobBloc;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      // Add navigation logic or any other action on contact tap
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // SVProfileFragment(userId:bloc.contactsList[index].id).launch(context);
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child:
                                        // bloc
                                        //             .contactsList[
                                        //                 index]
                                        //             .profilePic ==
                                        //         ''
                                        //     ? Image.asset(
                                        //             'images/socialv/faces/face_5.png',
                                        //             height: 56,
                                        //             width: 56,
                                        //             fit: BoxFit
                                        //                 .cover)
                                        //         .cornerRadiusWithClipRRect(
                                        //             8)
                                        //         .cornerRadiusWithClipRRect(
                                        //             8)
                                        //     :
                                        CustomImageView(
                                                placeHolder:
                                                    'images/socialv/faces/face_5.png',
                                                imagePath:
                                                    '${AppData.imageUrl}${widget.jobBloc.jobApplicantsModel?.applicants![index].user?.profilePic.validate()}',
                                                height: 56,
                                                width: 56,
                                                fit: BoxFit.cover)
                                            .cornerRadiusWithClipRRect(30),
                                  ),
                                ),
                                10.width,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            width: 150,
                                            child: Text(
                                                "${widget.jobBloc.jobApplicantsModel?.applicants?[index].user?.name.validate()}",
                                                overflow: TextOverflow.clip,
                                                style: GoogleFonts.poppins(
                                                    color: svGetBodyColor(),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16))),
                                        6.width,
                                        // bloc.contactsList[index].isCurrentUser.validate()
                                        //     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
                                        //     : const Offstage(),
                                      ],
                                    ),
                                    Text(
                                        widget.jobBloc.jobApplicantsModel?.applicants?[index].user?.email ??
                                            "",
                                        style: secondaryTextStyle(
                                            color: svGetBodyColor())),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                              timeAgo.format(DateTime.parse(widget.jobBloc.jobApplicantsModel?.applicants?[index].createdAt ??
                                  "")),
                              style: secondaryTextStyle(
                                  color: svGetBodyColor(), size: 12)),
                          // isLoading ? const CircularProgressIndicator(color: svGetBodyColor(),):  AppButton(
                          //   shapeBorder: RoundedRectangleBorder(borderRadius: radius(10)),
                          //   text:widget.element.isFollowedByCurrentUser == true ? 'Unfollow':'Follow',
                          //   textStyle: boldTextStyle(color:  widget.element.isFollowedByCurrentUser != true ?SVAppColorPrimary:buttonUnSelectColor,size: 10),
                          //   onTap:  () async {
                          //     setState(() {
                          //       isLoading = true; // Set loading state to true when button is clicked
                          //     });
                          //
                          //     // Perform API call
                          //     widget.onTap();
                          //
                          //     setState(() {
                          //       isLoading = false; // Set loading state to false after API response
                          //     });
                          //   },
                          //   elevation: 0,
                          //   color: widget.element.isFollowedByCurrentUser == true ?SVAppColorPrimary:buttonUnSelectColor,
                          // ),
                          // ElevatedButton(
                          //   // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          //   onPressed: () async {
                          //     setState(() {
                          //       isLoading = true; // Set loading state to true when button is clicked
                          //     });
                          //
                          //     // Perform API call
                          //     await widget.onTap();
                          //
                          //     setState(() {
                          //       isLoading = false; // Set loading state to false after API response
                          //     });
                          //   },
                          //   child: isLoading
                          //       ? CircularProgressIndicator(color: svGetBodyColor(),) // Show progress indicator if loading
                          //       : Text(widget.element.isFollowedByCurrentUser == true ? 'Unfollow' : 'Follow', style: boldTextStyle(color: Colors.white, size: 10)),
                          //   style: ElevatedButton.styleFrom(
                          //     // primary: Colors.blue, // Change button color as needed
                          //     elevation: 0,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is DataError) {
            return Expanded(
              child: Center(
                child: Text(state.errorMessage),
              ),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     GroupViewScreen().launch(context);
      //     // Add functionality to start a new chat
      //   },
      //   child: const Icon(Icons.group),
      // ),
    );
  }
}
