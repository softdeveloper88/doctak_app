import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/bloc/search_bloc.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
import '../jobs_screen/document_upload_dialog.dart';
import 'bloc/search_event.dart';

class SearchJobList extends StatefulWidget {
  SearchJobList(this.drugsBloc, {super.key});

  SearchBloc drugsBloc;
  @override
  State<SearchJobList> createState() => _SearchJobListState();
}

class _SearchJobListState extends State<SearchJobList> {
  // Track expanded state for each job item
  final Map<int, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    if (widget.drugsBloc.drugsData.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: appStore.isDarkMode ? Colors.black : Colors.grey[50],
        ),
        child: ListView.builder(
          key: const PageStorageKey<String>('jobs_list'),
          padding: EdgeInsets.only(
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          itemCount: widget.drugsBloc.drugsData.length,
          cacheExtent: 1000,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            if (widget.drugsBloc.pageNumber <=
                widget.drugsBloc.numberOfPage) {
              if (index ==
                  widget.drugsBloc.drugsData.length -
                      widget.drugsBloc.nextPageTrigger) {
                widget.drugsBloc.add(CheckIfNeedMoreDataEvent(index: index));
              }
            }
            if (widget.drugsBloc.numberOfPage !=
                    widget.drugsBloc.pageNumber - 1 &&
                index >= widget.drugsBloc.drugsData.length - 1) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const JobsShimmerLoader(),
              );
            } else {
              return _buildJobItem(context, index);
            }
          },
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: appStore.isDarkMode ? Colors.black : Colors.grey[50],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_off_rounded,
                  size: 48,
                  color: Colors.blue[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                translation(context).msg_no_jobs_found,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: appStore.isDarkMode
                      ? Colors.white70
                      : Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(
                  fontSize: 14,
                  color: appStore.isDarkMode
                      ? Colors.white54
                      : Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildJobItem(BuildContext context, int index) {
    final jobData = widget.drugsBloc.drugsData[index];

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          JobsDetailsScreen(jobId: '${jobData.id}').launch(context);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: appStore.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Header
                _buildJobHeader(context, jobData),

                // Job Content
                _buildJobContent(context, jobData),

                // Job Details
                _buildJobDetails(context, jobData),

                // Action Row
                _buildActionRow(context, jobData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Job header section with company logo and actions
  Widget _buildJobHeader(BuildContext context, dynamic jobData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company/Job Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.work_outline_rounded,
                color: Colors.blue[600],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Job Title and Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Title
                Text(
                  jobData.jobTitle ?? "",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Company Name
                Text(
                  jobData.companyName ?? 'N/A',
                  style: TextStyle(
                    color: appStore.isDarkMode
                        ? Colors.white70
                        : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),

                // Location and Sponsored Badge
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        jobData.location ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (jobData.promoted != null && jobData.promoted != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Sponsored',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 10,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Actions (Share)
          IconButton(
            onPressed: () {
              // createDynamicLink(
              //   '${jobData.jobTitle ?? ""} \n Apply Link: ${jobData.link ?? ''}',
              //   '${AppData.base}job/${jobData.id}',
              //   jobData.link ?? '',
              // );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_outlined,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Job content section with experience and language
  Widget _buildJobContent(BuildContext context, dynamic jobData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Experience Info
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Icon(
                  Icons.work_history_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Experience',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        jobData.experience ?? 'Not specified',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Language Info
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  Icons.language_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        jobData.preferredLanguage ?? 'Any',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Job details section with dates and description
  Widget _buildJobDetails(BuildContext context, dynamic jobData) {
    String description = jobData.description ?? "";
    final int jobId = jobData.id ?? 0;
    final bool isExpanded = _expandedStates[jobId] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application Dates
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  'Application Start',
                  jobData.createdAt,
                  Icons.calendar_today_outlined,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateInfo(
                  'Application End',
                  jobData.lastDate,
                  Icons.event_outlined,
                  Colors.red,
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Description
            Text(
              'Job Description',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Description Content with See More/Less functionality
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isExpanded ? double.infinity : 60,
                  ),
                  child: SingleChildScrollView(
                    physics: isExpanded
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: HtmlWidget(
                      '<p>$description</p>',
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: appStore.isDarkMode
                            ? Colors.white60
                            : Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                // See More/Less Button
                if (description.length >
                    100) // Show button only if description is long enough
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedStates[jobId] = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded ? 'See less' : 'See more',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build date info
  Widget _buildDateInfo(
    String title,
    String? date,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date != null
                ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date))
                : 'Not specified',
            style: TextStyle(
              color: appStore.isDarkMode ? Colors.white60 : Colors.grey[700],
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Action row section with apply and visit site buttons
  Widget _buildActionRow(BuildContext context, dynamic jobData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appStore.isDarkMode
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Apply Button
          if (jobData.user?.id != null)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return DocumentUploadDialog(jobData.id.toString());
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (jobData.user?.id != null) const SizedBox(width: 12),

          // Visit Site Button
          Expanded(
            flex: jobData.user?.id != null ? 2 : 1,
            child: OutlinedButton(
              onPressed: () async {
                final shouldLeave = await _showConfirmationDialog(context);
                if (shouldLeave == true) {
                  PostUtils.launchURL(context, jobData.link ?? '');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        translation(context).msg_leaving_app_canceled ??
                            'Leaving the app canceled.',
                      ),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_outlined, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Visit Site',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog
  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context).lbl_leave_app ?? 'Leave App'),
        content: Text(
          translation(context).msg_open_link_confirm ??
              'Would you like to leave the app to view this content?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(translation(context).lbl_no_answer ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(translation(context).lbl_yes ?? 'Yes'),
          ),
        ],
      ),
    );
  }
}
