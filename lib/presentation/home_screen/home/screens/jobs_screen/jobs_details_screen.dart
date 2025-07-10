import 'package:doctak_app/core/app_export.dart';
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
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/job_details_shimmer.dart';
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
      appBar: DoctakAppBar(
        title: translation(context).lbl_job_detail,
        titleIcon: Icons.work_outline_rounded,
        onBackPressed: () {
          if (widget.isFromSplash) {
            const SVDashboardScreen().launch(context, isNewTask: true);
          } else {
            Navigator.pop(context);
          }
        },
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
            return const JobDetailsShimmer();
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
            
            // Hero Card - Job Header
            _buildJobHeaderCard(job),
            
            const SizedBox(height: 16),
            
            // Job Details Cards
            _buildJobInfoCard(job),
            
            const SizedBox(height: 16),
            
            // Job Statistics Card
            _buildJobStatsCard(job),
            
            const SizedBox(height: 16),
            
            // Specialties Card
            if (job.specialties?.isNotEmpty ?? false) ...[
              _buildSpecialtiesCard(job),
              const SizedBox(height: 16),
            ],
            
            // Description Card
            _buildDescriptionCard(job),
            
            const SizedBox(height: 16),
            
            // User Info Card (Job Poster)
            if (job.user != null)
              _buildUserInfoCard(job.user!),
            
            const SizedBox(height: 16),
            
            // Bottom action buttons - Redesigned to match job list pattern
            _buildActionButtonsCard(job),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Column(
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
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

  // New Card Building Methods
  Widget _buildJobHeaderCard(job) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.jobTitle ?? "",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if ((job.promoted is bool && job.promoted == true) || 
                    (job.promoted is int && job.promoted != 0))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          translation(context).lbl_sponsored,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job.companyName ?? translation(context).lbl_not_available,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job.location ?? translation(context).lbl_not_available,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (job.salaryRange != null && job.salaryRange!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.attach_money, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      job.salaryRange!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard(job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translation(context).lbl_job_detail,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.work_outline,
              title: translation(context).lbl_experience,
              value: job.experience ?? translation(context).lbl_not_available,
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.language,
              title: translation(context).lbl_preferred_language,
              value: job.preferredLanguage ?? translation(context).lbl_not_available,
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.numbers,
              title: "Number of Jobs",
              value: job.noOfJobs ?? translation(context).lbl_not_available,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              translation(context).lbl_apply_date,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildJobStatsCard(job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Job Statistics",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.visibility,
                    label: "Views",
                    value: "${job.views ?? 0}",
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.mouse,
                    label: "Clicks",
                    value: "${job.clicks ?? 0}",
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: "Applicants",
                    value: "${jobsBloc.jobDetailModel.totalApplicants ?? 0}",
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesCard(job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Medical Specialties",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (job.specialties ?? []).map<Widget>((specialty) {
                String displayText = specialty.name ?? "Specialty ${specialty.id ?? 'Unknown'}";
                if (displayText.trim().isEmpty) {
                  displayText = "Specialty ${specialty.id ?? 'Unknown'}";
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  translation(context).lbl_description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: BoxConstraints(
                maxHeight: _isDescriptionExpanded ? 1000 : 200,
              ),
              child: SingleChildScrollView(
                physics: _isDescriptionExpanded
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: HtmlWidget(
                  job.description ?? "",
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              icon: Icon(
                _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.teal,
              ),
              label: Text(
                _isDescriptionExpanded
                    ? translation(context).lbl_show_less
                    : translation(context).lbl_show_more,
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Posted By",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: user.profilePic != null && user.profilePic!.isNotEmpty
                        ? CustomImageView(
                           imagePath: '${AppData.imageUrl}${user.profilePic!}',
                            fit: BoxFit.cover,
                            // errorBuilder: (context, error, stackTrace) => Container(
                            //   color: Colors.indigo.withOpacity(0.1),
                            //   child: const Icon(Icons.person, color: Colors.indigo, size: 30),
                            // ),
                          )
                        : Container(
                            color: Colors.indigo.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.indigo, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? "Anonymous User",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Job Poster",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action buttons card matching job list item design
  Widget _buildActionButtonsCard(job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.cardColor,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  translation(context).lbl_actions,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Main action buttons row
            _buildMainActionRow(job),
            
            // View applicants button (for job creator)
            if (job.user?.id == AppData.logInUserId) ...[
              const SizedBox(height: 16),
              _buildViewApplicantsButton(),
            ],
          ],
        ),
      ),
    );
  }

  // Main action row with proper flex handling
  Widget _buildMainActionRow(job) {
    bool hasApplied = jobsBloc.jobDetailModel.hasApplied ?? false;
    bool hasLink = job.link != null && job.link!.isNotEmpty;
    bool isJobOwner = job.user?.id == AppData.logInUserId;

    return Row(
      children: [
        // Apply/Withdraw button
        if (!hasApplied && !isJobOwner)
          Expanded(
            flex: hasLink ? 1 : 1,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DocumentUploadDialog(widget.jobId);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    translation(context).lbl_apply,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (hasApplied && !isJobOwner)
          Expanded(
            flex: hasLink ? 1 : 1,
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    translation(context).lbl_withdraw,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Spacing between buttons
        if ((hasApplied || !isJobOwner) && hasLink) const SizedBox(width: 12),
        
        // Visit site button
        if (hasLink)
          Expanded(
            flex: (hasApplied || !isJobOwner) ? 1 : 1,
            child: OutlinedButton(
              onPressed: () async {
                final shouldLeave = await _showConfirmDialog();
                if (shouldLeave == true) {
                  final Uri url = Uri.parse(job.link!);
                  await _launchInBrowser(url);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_new_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    translation(context).lbl_visit_site,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // View applicants button
  Widget _buildViewApplicantsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          JobApplicantScreen(widget.jobId, jobsBloc).launch(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 12),
            Text(
              translation(context).lbl_view_applicants,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}