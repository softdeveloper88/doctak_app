import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../main.dart';

/// Memory-optimized guideline item widget with performance improvements
class MemoryOptimizedGuidelineItem extends StatefulWidget {
  final Data guideline;

  const MemoryOptimizedGuidelineItem({
    super.key,
    required this.guideline,
  });

  @override
  State<MemoryOptimizedGuidelineItem> createState() => _MemoryOptimizedGuidelineItemState();
}

class _MemoryOptimizedGuidelineItemState extends State<MemoryOptimizedGuidelineItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Process description text
    String description = widget.guideline.description!
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('\u0002', ' ');
    
    String trimmedDescription = _trimDescription(description, 100);
    
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guideline Header
              _buildGuidelineHeader(description, trimmedDescription),
              
              // Guideline Action
              _buildGuidelineAction(),
            ],
          ),
        ),
      ),
    );
  }

  // Guideline header section
  Widget _buildGuidelineHeader(String description, String trimmedDescription) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.medical_information_outlined,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.guideline.diseaseName ?? "",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Toggle expanded state
                      isExpanded = !isExpanded;
                    });
                  },
                  child: HtmlWidget(
                    isExpanded
                        ? "<p>$description</p>"
                        : "<p>$trimmedDescription</p>",
                    textStyle: TextStyle(
                      color: appStore.isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Guideline action section
  Widget _buildGuidelineAction() {
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              if (isExpanded) {
                // If description is expanded, download the file
                downloadAndOpenFile(
                    "${AppData.base}/guidelines/${widget.guideline.fileName!}");
              } else {
                // If description is not expanded, expand it
                setState(() {
                  isExpanded = true;
                });
              }
            },
            icon: Icon(
              isExpanded ? Icons.download_outlined : Icons.read_more,
              color: Colors.blue[600],
              size: 18,
            ),
            label: Text(
              isExpanded ? translation(context).lbl_download_pdf : translation(context).lbl_see_more,
              style: TextStyle(
                color: Colors.blue[600],
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to trim description
  String _trimDescription(String description, int wordLimit) {
    List<String> words = description.split(' ');
    if (words.length <= wordLimit) return description;
    return '${words.take(wordLimit).join(' ')}...';
  }

  // Function to download and open file
  Future<void> downloadAndOpenFile(String url) async {
    try {
      final Uri fileUri = Uri.parse(url);
      await launchUrl(fileUri);
    } catch (e) {
      // Handle errors or show an alert to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${translation(context).msg_error_occurred}: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}