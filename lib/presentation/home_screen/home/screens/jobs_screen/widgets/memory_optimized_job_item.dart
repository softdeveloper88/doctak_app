import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

/// Memory-optimized job item widget with performance improvements
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
      child: InkWell(
        onTap: widget.onJobTap,
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildJobTitle(),
                  const SizedBox(height: 5),
                  _buildCompanyInfo(),
                  const SizedBox(height: 10),
                  _buildDatesSection(),
                  const SizedBox(height: 5),
                  _buildExperienceInfo(),
                  const SizedBox(height: 5),
                  _buildDescription(),
                  const SizedBox(height: 5),
                  _buildVisitSiteButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header with promoted badge, apply button and share option
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.jobData.promoted != 0)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.orangeAccent,
            ),
            child: const Text(
              'Sponsored',
              style: TextStyle(color: Colors.white),
            ),
          ),
        const SizedBox(width: 10),
        if (widget.jobData.user?.id != null)
          MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.blue,
            onPressed: () => widget.onApplyTap(widget.jobData.id.toString()),
            child: const Text(
              "Apply",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        const SizedBox(width: 20),
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: widget.onShareTap,
          child: Icon(
            Icons.share_sharp,
            size: 22,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ],
    );
  }

  // Job title section
  Widget _buildJobTitle() {
    return Text(
      widget.jobData.jobTitle ?? "",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  // Company name and location section
  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.jobData.companyName ?? 'N/A',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                widget.jobData.location ?? 'N/A',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Dates section with from and to dates
  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apply Date',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDateColumn(
              title: 'Date From',
              date: widget.jobData.createdAt,
            ),
            const SizedBox(width: 20),
            _buildDateColumn(
              title: 'Date To',
              date: widget.jobData.lastDate,
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build date column
  Widget _buildDateColumn({required String title, required String? date}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
        Row(
          children: [
            const Icon(Icons.date_range_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date))
                  : 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  // Experience and language info
  Widget _buildExperienceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience: ${widget.jobData.experience ?? 'N/A'}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          'Preferred Language: ${widget.jobData.preferredLanguage ?? 'N/A'}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // Description with expandable behavior
  Widget _buildDescription() {
    String description = widget.jobData.description ?? "";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _isDescriptionExpanded ? double.infinity : 100,
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: HtmlWidget(
              '<p>${description}</p>',
              textStyle: const TextStyle(fontSize: 14),
              customStylesBuilder: (element) {
                if (element.localName == 'p') {
                  return {'font-size': '14px'};
                }
                return null;
              },
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
            child: Text(
              _isDescriptionExpanded ? 'Show Less' : 'Show More',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
      ],
    );
  }

  // Visit site button
  Widget _buildVisitSiteButton() {
    return TextButton(
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
      child: const Text(
        'Visit Site',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
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