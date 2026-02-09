import 'package:doctak_app/data/apiClient/services/moderation_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Report Content Bottom Sheet
/// Allows users to report objectionable content (posts, comments, users)
/// Apple App Store Guideline 1.2 Compliance
class ReportContentBottomSheet extends StatefulWidget {
  final int contentId;
  final String contentType; // 'post', 'comment', 'user'
  final String? contentOwnerName;
  final VoidCallback? onReportSubmitted;

  const ReportContentBottomSheet({
    super.key,
    required this.contentId,
    required this.contentType,
    this.contentOwnerName,
    this.onReportSubmitted,
  });

  /// Show the report bottom sheet
  static Future<void> show({
    required BuildContext context,
    required int contentId,
    required String contentType,
    String? contentOwnerName,
    VoidCallback? onReportSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportContentBottomSheet(
        contentId: contentId,
        contentType: contentType,
        contentOwnerName: contentOwnerName,
        onReportSubmitted: onReportSubmitted,
      ),
    );
  }

  @override
  State<ReportContentBottomSheet> createState() => _ReportContentBottomSheetState();
}

class _ReportContentBottomSheetState extends State<ReportContentBottomSheet> {
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String get _contentTypeDisplayName {
    switch (widget.contentType) {
      case 'post':
        return 'post';
      case 'comment':
        return 'comment';
      case 'user':
        return 'user';
      default:
        return 'content';
    }
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      toast('Please select a reason for reporting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final moderationService = ModerationApiService();
      
      switch (widget.contentType) {
        case 'post':
          await moderationService.reportPost(
            postId: widget.contentId,
            reason: _selectedReason!.value,
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          );
          break;
        case 'comment':
          await moderationService.reportComment(
            commentId: widget.contentId,
            reason: _selectedReason!.value,
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          );
          break;
        case 'user':
          await moderationService.reportUser(
            userId: widget.contentId,
            reason: _selectedReason!.value,
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        toast('Report submitted successfully. Our team will review it within 24 hours.');
        widget.onReportSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        toast('Failed to submit report. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.flag_fill,
                        color: theme.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report ${_contentTypeDisplayName}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                          ),
                          if (widget.contentOwnerName != null)
                            Text(
                              'by ${widget.contentOwnerName}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                color: theme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: theme.divider, height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle_fill,
                              color: theme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'We review all reports within 24 hours. False reports may result in action against your account.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: theme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'Why are you reporting this ${_contentTypeDisplayName}?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Report Reasons
                      ...ReportReason.values.map((reason) => _buildReasonTile(theme, reason)),
                      
                      const SizedBox(height: 20),
                      
                      // Additional Details
                      Text(
                        'Additional details (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.border),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          maxLength: 500,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Provide additional context about this report...',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: theme.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            counterStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
              
              // Submit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  border: Border(
                    top: BorderSide(color: theme.divider),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _selectedReason == null 
                          ? null 
                          : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.warning,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.warning.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReasonTile(OneUITheme theme, ReportReason reason) {
    final isSelected = _selectedReason == reason;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.warning.withValues(alpha: 0.1)
              : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.warning 
                : theme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.warning : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.warning : theme.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: isSelected ? theme.warning : theme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
