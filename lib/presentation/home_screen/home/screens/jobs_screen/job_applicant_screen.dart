import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/jobs_event.dart';

class JobApplicantScreen extends StatefulWidget {
  final String jobId;
  final JobsBloc jobBloc;

  const JobApplicantScreen(this.jobId, this.jobBloc, {super.key});

  @override
  State<JobApplicantScreen> createState() => _JobApplicantScreenState();
}

class _JobApplicantScreenState extends State<JobApplicantScreen> {
  @override
  void initState() {
    widget.jobBloc.add(ShowApplicantEvent(jobId: widget.jobId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(title: translation(context).lbl_applicants, titleIcon: Icons.people),
      body: BlocConsumer<JobsBloc, JobsState>(
        bloc: widget.jobBloc,
        listener: (BuildContext context, JobsState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return const ShimmerCardList();
          } else if (state is PaginationLoadedState) {
            final applicants = widget.jobBloc.jobApplicantsModel?.applicants;

            if (applicants == null || applicants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(translation(context).msg_no_applicants, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final applicant = applicants[index];
                final user = applicant.user;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (user?.id != null) {
                        SVProfileFragment(userId: user!.id.toString()).launch(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Profile Image
                          Hero(
                            tag: 'profile-${user?.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.3), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
                              ),
                              child: CustomImageView(
                                placeHolder: 'images/socialv/faces/face_5.png',
                                imagePath: '${AppData.imageUrl}${user?.profilePic.validate()}',
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                                radius: BorderRadius.circular(30),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.name ?? translation(context).lbl_unknown,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildAppliedTimeChip(applicant.createdAt),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user?.email ?? "",
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // Resume or CV indicator (if applicable)
                                if (applicant.cv != null && applicant.cv!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.description_outlined, size: 14, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          translation(context).lbl_resume_attached,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is DataError) {
            return Center(child: Text(state.errorMessage));
          } else {
            return Center(child: Text(translation(context).msg_something_went_wrong));
          }
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Implement any additional action if needed
      //     // Perhaps open a filter dialog or export applicants list
      //   },
      //   icon: const Icon(Icons.people_outline),
      //   label: Text(translation(context).lbl_total_applicants +
      //       ": ${widget.jobBloc.jobApplicantsModel?.applicants?.length ?? 0}"),
      //   backgroundColor: Colors.blue,
      // ),
    );
  }

  Widget _buildAppliedTimeChip(String? createdAt) {
    if (createdAt == null) return const SizedBox.shrink();

    final timeAgoString = timeAgo.format(DateTime.parse(createdAt));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        timeAgoString,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
      ),
    );
  }
}
