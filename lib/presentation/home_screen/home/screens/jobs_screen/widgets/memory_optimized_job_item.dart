import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

/// Enhanced memory-optimized job item widget with modern design
class MemoryOptimizedJobItem extends StatefulWidget {
  final dynamic jobData; // Replace with your specific job model type
  final VoidCallback onJobTap;
  final VoidCallback onShareTap;
  final Function(String) onApplyTap;
  final Function(Uri) onLaunchLink;

  const MemoryOptimizedJobItem({
    super.key,
    required this.jobData,
    required this.onJobTap,
    required this.onShareTap,
    required this.onApplyTap,
    required this.onLaunchLink,
  });

  @override
  State<MemoryOptimizedJobItem> createState() => _MemoryOptimizedJobItemState();
}

class _MemoryOptimizedJobItemState extends State<MemoryOptimizedJobItem> {
  bool _isDescriptionExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onJobTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                _buildJobHeader(),
                
                // Job Content
                _buildJobContent(),
                
                // Job Details
                _buildJobDetails(),
                
                // Action Row
                _buildActionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Job header section with company logo and actions
  Widget _buildJobHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  widget.jobData.jobTitle ?? "",
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
                  widget.jobData.companyName ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.black87,
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
                        widget.jobData.location ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (widget.jobData.promoted != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            onPressed: widget.onShareTap,
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
  Widget _buildJobContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
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
                        widget.jobData.experience ?? 'Not specified',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
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
                        widget.jobData.preferredLanguage ?? 'Any',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
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
  Widget _buildJobDetails() {
    String description = widget.jobData.description ?? "";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
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
                  widget.jobData.createdAt,
                  Icons.calendar_today_outlined,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateInfo(
                  'Application End',
                  widget.jobData.lastDate,
                  Icons.event_outlined,
                  Colors.red,
                ),
              ),
            ],
          ),
          
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
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _isDescriptionExpanded ? double.infinity : 60,
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: HtmlWidget(
                '<p>${description}</p>',
                textStyle: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (description.length > 100)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              ),
              child: Text(
                _isDescriptionExpanded ? 'Show Less' : 'Show More',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build date info
  Widget _buildDateInfo(String title, String? date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
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
              color: Colors.grey[700],
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
  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Apply Button
          if (widget.jobData.user?.id != null)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => widget.onApplyTap(widget.jobData.id.toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
          
          if (widget.jobData.user?.id != null) const SizedBox(width: 12),
          
          // Visit Site Button
          Expanded(
            flex: widget.jobData.user?.id != null ? 2 : 1,
            child: OutlinedButton(
              onPressed: () async {
                final Uri url = Uri.parse(widget.jobData.link ?? '');
                final BuildContext currentContext = context;
                final shouldLeave = await _showConfirmationDialog(currentContext);
                if (!mounted) return;
                
                if (shouldLeave == true) {
                  widget.onLaunchLink(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(translation(context).msg_leaving_app_canceled),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
}