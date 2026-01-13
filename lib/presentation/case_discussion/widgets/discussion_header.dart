import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/app/AppData.dart';
import '../models/case_discussion_models.dart';

class DiscussionHeader extends StatelessWidget {
  final CaseDiscussion discussion;
  final VoidCallback? onLike;

  const DiscussionHeader({
    Key? key,
    required this.discussion,
    this.onLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info with enhanced One UI styling
          Row(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primary,
                      theme.primary.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardBackground,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.avatarBackground,
                    backgroundImage: discussion.author.profilePic != null
                        ? CachedNetworkImageProvider("${AppData.imageUrl}${discussion.author.profilePic!}")
                        : null,
                    child: discussion.author.profilePic == null
                        ? Text(
                            discussion.author.name.isNotEmpty
                                ? discussion.author.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.author.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(discussion.createdAt),
                          style: TextStyle(
                            color: theme.textTertiary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Specialty badge - One UI pill style
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getSpecialtyColor(discussion.specialty, theme),
                            _getSpecialtyColor(discussion.specialty, theme).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discussion.specialty.toUpperCase(),
                        style: TextStyle(
                          color: theme.cardBackground,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Title and Description Card - One UI style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Text(
                  discussion.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description section
                  Text(
                    discussion.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient info if available
            if (discussion.patientInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: theme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient Information',
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${discussion.patientInfo!.gender.toUpperCase()}, ${discussion.patientInfo!.age} years old',
                      style: TextStyle(fontWeight: FontWeight.w500, color: theme.textPrimary),
                    ),
                    if (discussion.patientInfo!.medicalHistory.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Medical History: ${discussion.patientInfo!.medicalHistory}',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tags/Symptoms Section with One UI styling
            if (discussion.symptoms != null && discussion.symptoms!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: theme.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clinical Tags',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            fontFamily: 'Poppins',
                            color: theme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: discussion.symptoms!.map((symptom) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              color: theme.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attached Files Section
            if (discussion.attachments != null && discussion.attachments!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.secondary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: theme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attached Files',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: theme.secondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${discussion.attachments!.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: theme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...discussion.attachments!.map((attachment) {
                      final isImage = attachment.type.toLowerCase().contains('image') || 
                                     attachment.url.toLowerCase().contains('.jpg') || 
                                     attachment.url.toLowerCase().contains('.png') || 
                                     attachment.url.toLowerCase().contains('.jpeg');
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.secondary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: attachment.url.startsWith('http') 
                                            ? attachment.url 
                                            : "${AppData.imageUrl}${attachment.url}",
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Icon(
                                          Icons.image_rounded,
                                          color: theme.secondary,
                                          size: 20,
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.broken_image_rounded,
                                          color: theme.secondary,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.description_rounded,
                                      color: theme.secondary,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attachment.description.isNotEmpty 
                                        ? attachment.description 
                                        : 'Attachment ${attachment.id}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: theme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    attachment.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Poppins',
                                      color: theme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: theme.secondary,
                              size: 16,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Patient Demographics from CaseMetadata
            if (discussion.caseMetadata?.parsedPatientDemographics != null) ...[
              _buildPatientDemographicsSection(context, theme),
              const SizedBox(height: 16),
            ],

            // Clinical Metadata from CaseMetadata
            if (discussion.caseMetadata != null && 
                (discussion.caseMetadata!.clinicalComplexity != null || 
                 discussion.caseMetadata!.teachingValue != null ||
                 discussion.caseMetadata!.isAnonymized != null)) ...[
              _buildClinicalInfoSection(context, theme),
              const SizedBox(height: 16),
            ],

            // Clinical Keywords from CaseMetadata
            if (discussion.caseMetadata?.parsedClinicalKeywords != null && discussion.caseMetadata!.parsedClinicalKeywords!.isNotEmpty) ...[
              _buildClinicalKeywordsSection(context, theme),
              const SizedBox(height: 16),
            ],

            // Diagnosis
            if (discussion.diagnosis != null && discussion.diagnosis!.isNotEmpty) ...[
              _buildInfoSection(
                'Working Diagnosis',
                discussion.diagnosis!,
                theme.success,
                Icons.local_hospital_rounded,
                theme,
              ),
              const SizedBox(height: 12),
            ],

            // Treatment Plan
            if (discussion.treatmentPlan != null && discussion.treatmentPlan!.isNotEmpty) ...[
              _buildInfoSection(
                'Treatment Plan',
                discussion.treatmentPlan!,
                theme.secondary,
                Icons.healing_rounded,
                theme,
              ),
              const SizedBox(height: 12),
            ],

            // AI Summary with enhanced display
            if (discussion.aiSummary != null) ...[
              _buildAISummarySection(context, theme),
              const SizedBox(height: 16),
            ],

            // Stats with One UI 8.5 styling
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLikeStat(Icons.thumb_up_rounded, discussion.stats.likes, 'Likes', theme),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _buildStat(Icons.chat_bubble_rounded, discussion.stats.commentsCount, 'Comments', theme),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _buildStat(Icons.remove_red_eye_rounded, discussion.stats.views, 'Views', theme),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _buildStat(Icons.people_rounded, discussion.followersCount ?? discussion.stats.followersCount, 'Followers', theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildPatientDemographicsSection(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.success.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: theme.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Patient Demographics',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  fontFamily: 'Poppins',
                  color: theme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildPatientDemographics(discussion.caseMetadata!.parsedPatientDemographics!, theme),
        ],
      ),
    );
  }

  Widget _buildClinicalInfoSection(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Clinical Information',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Clinical metadata items as cards
          ..._buildClinicalMetadataFromModel(discussion.caseMetadata!, theme),
        ],
      ),
    );
  }

  Widget _buildClinicalKeywordsSection(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key_rounded,
                color: theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Keywords',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: theme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${discussion.caseMetadata!.parsedClinicalKeywords!.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: discussion.caseMetadata!.parsedClinicalKeywords!.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummarySection(BuildContext context, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: theme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Clinical Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v${discussion.aiSummary!.version ?? 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            discussion.aiSummary!.summary,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: theme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Generated ${_formatTime(discussion.aiSummary!.generatedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: theme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, Color color, IconData icon, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14, 
              color: theme.textPrimary,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummary(AISummary aiSummary, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Summary',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(aiSummary.confidenceScore * 100).toInt()}% confidence',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aiSummary.summary,
            style: TextStyle(fontSize: 14, color: theme.textPrimary),
          ),
          if (aiSummary.keyPoints != null && aiSummary.keyPoints!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...aiSummary.keyPoints!.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 12, color: theme.textSecondary),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildLikeStat(IconData icon, int count, String label, OneUITheme theme) {
    return GestureDetector(
      onTap: onLike,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: onLike != null ? theme.likeColor : theme.iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: onLike != null ? theme.likeColor : theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: onLike != null ? theme.likeColor : theme.textSecondary,
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count, String label, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.iconColor,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpecialtyColor(String specialty, OneUITheme theme) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return theme.error;
      case 'neurology':
        return theme.secondary;
      case 'orthopedics':
        return theme.primary;
      case 'pediatrics':
        return theme.success;
      default:
        return theme.textSecondary;
    }
  }

  List<Widget> _buildPatientDemographics(dynamic demographics, OneUITheme theme) {
    final List<Widget> widgets = [];
    
    if (demographics is Map<String, dynamic>) {
      if (demographics['age'] != null) {
        widgets.add(_buildDemographicItem('Age', '${demographics['age']} years', Icons.cake_rounded, theme));
      }
      if (demographics['gender'] != null) {
        widgets.add(_buildDemographicItem('Gender', demographics['gender'].toString(), Icons.person_rounded, theme));
      }
      if (demographics['ethnicity'] != null) {
        widgets.add(_buildDemographicItem('Ethnicity', demographics['ethnicity'].toString(), Icons.public_rounded, theme));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildClinicalMetadata(Map<String, dynamic> metadata, OneUITheme theme) {
    final List<Widget> widgets = [];
    
    if (metadata['clinical_complexity'] != null) {
      final complexity = metadata['clinical_complexity'].toString();
      widgets.add(_buildMetadataItem(
        'Clinical Complexity', 
        complexity.toUpperCase(), 
        _getComplexityColor(complexity, theme),
        Icons.timeline_rounded,
        theme
      ));
    }
    
    if (metadata['teaching_value'] != null) {
      final teachingValue = metadata['teaching_value'].toString();
      widgets.add(_buildMetadataItem(
        'Teaching Value', 
        teachingValue.toUpperCase(), 
        _getTeachingValueColor(teachingValue, theme),
        Icons.school_rounded,
        theme
      ));
    }
    
    if (metadata['is_anonymized'] != null) {
      final isAnonymized = metadata['is_anonymized'] == true || metadata['is_anonymized'] == '1';
      widgets.add(_buildMetadataItem(
        'Patient Privacy', 
        isAnonymized ? 'ANONYMIZED' : 'IDENTIFIED', 
        isAnonymized ? theme.success : theme.warning,
        isAnonymized ? Icons.security_rounded : Icons.visibility_rounded,
        theme
      ));
    }
    
    return widgets;
  }

  List<Widget> _buildClinicalMetadataFromModel(CaseMetadata metadata, OneUITheme theme) {
    final List<Widget> widgets = [];
    
    if (metadata.clinicalComplexity != null) {
      final complexity = metadata.clinicalComplexity!;
      widgets.add(_buildMetadataItem(
        'Clinical Complexity', 
        complexity.toUpperCase(), 
        _getComplexityColor(complexity, theme),
        Icons.timeline_rounded,
        theme
      ));
    }
    
    if (metadata.teachingValue != null) {
      final teachingValue = metadata.teachingValue!;
      widgets.add(_buildMetadataItem(
        'Teaching Value', 
        teachingValue.toUpperCase(), 
        _getTeachingValueColor(teachingValue, theme),
        Icons.school_rounded,
        theme
      ));
    }
    
    if (metadata.isAnonymized != null) {
      final isAnonymized = metadata.isAnonymized!;
      widgets.add(_buildMetadataItem(
        'Patient Privacy', 
        isAnonymized ? 'ANONYMIZED' : 'IDENTIFIED', 
        isAnonymized ? theme.success : theme.warning,
        isAnonymized ? Icons.security_rounded : Icons.visibility_rounded,
        theme
      ));
    }
    
    if (metadata.evidenceLevel != null) {
      widgets.add(_buildMetadataItem(
        'Evidence Level', 
        metadata.evidenceLevel!.toUpperCase(), 
        theme.secondary,
        Icons.science_rounded,
        theme
      ));
    }
    
    return widgets;
  }

  Widget _buildDemographicItem(String label, String value, IconData icon, OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.success.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value, Color color, IconData icon, OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container with color background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplexityColor(String complexity, OneUITheme theme) {
    switch (complexity.toLowerCase()) {
      case 'low':
        return theme.success;
      case 'medium':
        return theme.warning;
      case 'high':
        return theme.error;
      default:
        return theme.textSecondary;
    }
  }

  Color _getTeachingValueColor(String teachingValue, OneUITheme theme) {
    switch (teachingValue.toLowerCase()) {
      case 'low':
        return theme.textSecondary;
      case 'medium':
        return theme.primary;
      case 'high':
        return theme.secondary;
      default:
        return theme.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}