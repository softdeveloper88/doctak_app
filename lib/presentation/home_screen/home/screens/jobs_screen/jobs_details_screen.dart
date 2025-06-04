import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/document_upload_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/job_applicant_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
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
  const JobsDetailsScreen({
    required this.jobId, 
    this.isFromSplash = false, 
    super.key
  });

  final String jobId;
  final bool isFromSplash;

  @override
  State<JobsDetailsScreen> createState() => _JobsDetailsScreenState();
}

class _JobsDetailsScreenState extends State<JobsDetailsScreen> {
  final JobsBloc jobsBloc = JobsBloc();
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
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
      (country) => country.countryName?.toLowerCase() == name.toLowerCase(), 
      orElse: () => defaultCountry, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () {
            if (widget.isFromSplash) {
              const SVDashboardScreen().launch(context, isNewTask: true);
            } else {
              Navigator.pop(context);
            }
          }
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline_rounded,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              translation(context).lbl_job_detail,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_outlined,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
              onPressed: () {
                if (jobsBloc.jobDetailModel.job != null) {
                  createDynamicLink(
                    '${jobsBloc.jobDetailModel.job?.jobTitle ?? ""}\n Apply Link  ${jobsBloc.jobDetailModel.job?.link ?? ''}',
                    'https://doctak.net/job/${jobsBloc.jobDetailModel.job?.id}',
                    jobsBloc.jobDetailModel.job?.link ?? '',
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<JobsBloc, JobsState>(
        bloc: jobsBloc,
        listener: (BuildContext context, JobsState state) {
          if (state is DataError) {
            // Error handling if needed
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return const ShimmerCardList();
          } else if (state is PaginationLoadedState) {
            return _buildJobDetails();
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

  Widget _buildJobDetails() {
    final job = jobsBloc.jobDetailModel.job;
    if (job == null) {
      return Center(child: Text(translation(context).msg_no_data_found));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action buttons
            _buildActionButtons(),
            
            // Card section with main details
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: context.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.jobTitle ?? "",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (job.promoted != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  translation(context).lbl_sponsored,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Company name
                    Text(
                      job.companyName ?? translation(context).lbl_not_available,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job.location ?? translation(context).lbl_not_available,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Dates section
                    Text(
                      translation(context).lbl_apply_date,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateInfo(
                            title: translation(context).lbl_date_from,
                            date: job.createdAt,
                            icon: Icons.date_range_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateInfo(
                            title: translation(context).lbl_date_to,
                            date: job.lastDate,
                            icon: Icons.date_range_outlined,
                            isExpired: job.lastDate != null 
                                ? DateTime.parse(job.lastDate??'').isBefore(DateTime.now())
                                : false,
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Additional details
                    _buildDetailRow(
                      icon: Icons.work_outline,
                      title: translation(context).lbl_experience,
                      value: job.experience ?? translation(context).lbl_not_available,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(
                      icon: Icons.language,
                      title: translation(context).lbl_preferred_language,
                      value: job.preferredLanguage ?? translation(context).lbl_not_available,
                    ),
                    
                    const Divider(height: 32),
                    
                    // Description
                    Text(
                      translation(context).lbl_description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description with expand/collapse
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      constraints: BoxConstraints(
                        maxHeight: _isDescriptionExpanded ? double.infinity : 200,
                      ),
                      child: SingleChildScrollView(
                        physics: _isDescriptionExpanded
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: HtmlWidget(
                          '<p>${job.description ?? ""}</p>',
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    // Show more/less button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isDescriptionExpanded
                                ? translation(context).lbl_show_less
                                : translation(context).lbl_show_more,
                            style: const TextStyle(color: Colors.blue),
                          ),
                          Icon(
                            _isDescriptionExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bottom action buttons
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: context.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation(context).lbl_actions,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Apply button
                        if ((jobsBloc.jobDetailModel.hasApplied ?? false) == false)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return DocumentUploadDialog(widget.jobId);
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit_document),
                              label: Text(translation(context).lbl_apply),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        
                        // Withdraw button  
                        if (jobsBloc.jobDetailModel.hasApplied ?? false)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CustomAlertDialog(
                                      mainTitle: translation(context).lbl_withdraw_application,
                                      yesButtonText: translation(context).lbl_withdraw,
                                      title: translation(context).msg_confirm_withdraw,
                                      callback: () {
                                        jobsBloc.add(WithDrawApplicant(jobId: widget.jobId));
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: Text(translation(context).lbl_withdraw),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        
                        if (job.link != null && job.link!.isNotEmpty) ...[
                          if ((jobsBloc.jobDetailModel.hasApplied ?? false) ||
                              job.user?.id == AppData.logInUserId)
                            const SizedBox(width: 8),
                          
                          // Visit site button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final shouldLeave = await _showConfirmDialog();
                                if (shouldLeave == true) {
                                  final Uri url = Uri.parse(job.link!);
                                  await _launchInBrowser(url);
                                }
                              },
                              icon: const Icon(Icons.link),
                              label: Text(translation(context).lbl_visit_site),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // View applicants button (for job creator)
                    if (job.user?.id == AppData.logInUserId)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              JobApplicantScreen(widget.jobId, jobsBloc).launch(context);
                            },
                            icon: const Icon(Icons.people),
                            label: Text(translation(context).lbl_view_applicants),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (jobsBloc.jobDetailModel.job == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (jobsBloc.jobDetailModel.hasApplied ?? false)
            Chip(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.green.withOpacity(0.1),
              side: const BorderSide(color: Colors.green),
              avatar: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 18,
              ),
              label: Text(
                translation(context).lbl_applied,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateInfo({
    required String title,
    required String? date,
    required IconData icon,
    bool isExpired = false,
  }) {
    String formattedDate = date != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date))
        : translation(context).lbl_not_available;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: isExpired ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isExpired ? Colors.red : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context).lbl_leave_app),
        content: Text(translation(context).msg_open_link_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(translation(context).lbl_no_answer),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(translation(context).lbl_yes),
          ),
        ],
      ),
    );
  }

  Future<void> _launchInBrowser(Uri url) async {
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${translation(context).lbl_error}: ${e.toString()}')),
        );
      }
    }
  }
}