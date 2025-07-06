import 'package:cached_network_image/cached_network_image.dart';
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info with enhanced styling
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage: discussion.author.profilePic != null
                      ? CachedNetworkImageProvider("${AppData.imageUrl}${discussion.author.profilePic!}")
                      : null,
                  child: discussion.author.profilePic == null
                      ? Text(
                          discussion.author.name.isNotEmpty
                              ? discussion.author.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                          ),
                        )
                      : null,
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
                        color: Colors.blue[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(discussion.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getSpecialtyColor(discussion.specialty).withOpacity(0.1),
                            _getSpecialtyColor(discussion.specialty).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getSpecialtyColor(discussion.specialty).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        discussion.specialty.toUpperCase(),
                        style: TextStyle(
                          color: _getSpecialtyColor(discussion.specialty).withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.3,
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
            const SizedBox(height: 20),

            // Combined Title and Description with better typography
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Text(
                    discussion.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description section
                  Text(
                    discussion.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient Information',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${discussion.patientInfo!.gender.toUpperCase()}, ${discussion.patientInfo!.age} years old',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (discussion.patientInfo!.medicalHistory.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Medical History: ${discussion.patientInfo!.medicalHistory}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tags/Symptoms Section with compact styling
            if (discussion.symptoms != null && discussion.symptoms!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          color: Colors.orange[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Tags',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: discussion.symptoms!.map((symptom) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.08),
                      Colors.purple.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attached Files',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.purple[800],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${discussion.attachments!.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.purple[800],
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
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
                                          color: Colors.purple[600],
                                          size: 20,
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.purple[600],
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.description_rounded,
                                      color: Colors.purple[600],
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
                                      color: Colors.purple[800],
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
                                      color: Colors.purple[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.purple[600],
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.withOpacity(0.08),
                      Colors.teal.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.teal[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient Demographics',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildPatientDemographics(discussion.caseMetadata!.parsedPatientDemographics!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Clinical Metadata from CaseMetadata
            if (discussion.caseMetadata != null && 
                (discussion.caseMetadata!.clinicalComplexity != null || 
                 discussion.caseMetadata!.teachingValue != null ||
                 discussion.caseMetadata!.isAnonymized != null)) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.withOpacity(0.08),
                      Colors.indigo.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: Colors.indigo[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Information',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.indigo[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildClinicalMetadataFromModel(discussion.caseMetadata!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Clinical Keywords from CaseMetadata
            if (discussion.caseMetadata?.parsedClinicalKeywords != null && discussion.caseMetadata!.parsedClinicalKeywords!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.withOpacity(0.08),
                      Colors.cyan.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.key_rounded,
                          color: Colors.cyan[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Keywords',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.cyan[800],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${discussion.caseMetadata!.parsedClinicalKeywords!.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.cyan[800],
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
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.15),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            keyword,
                            style: TextStyle(
                              color: Colors.cyan[800],
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

            // Diagnosis
            if (discussion.diagnosis != null && discussion.diagnosis!.isNotEmpty) ...[
              _buildInfoSection(
                'Working Diagnosis',
                discussion.diagnosis!,
                Colors.green,
                Icons.local_hospital,
              ),
              const SizedBox(height: 12),
            ],

            // Treatment Plan
            if (discussion.treatmentPlan != null && discussion.treatmentPlan!.isNotEmpty) ...[
              _buildInfoSection(
                'Treatment Plan',
                discussion.treatmentPlan!,
                Colors.purple,
                Icons.healing,
              ),
              const SizedBox(height: 12),
            ],

            // AI Summary with enhanced display
            if (discussion.aiSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.withOpacity(0.08),
                      Colors.indigo.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.1),
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
                          color: Colors.indigo[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI Clinical Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v${discussion.aiSummary!.version ?? 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: Colors.indigo[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      discussion.aiSummary!.summary,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
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
                          color: Colors.indigo[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Generated ${_formatTime(discussion.aiSummary!.generatedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.indigo[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Stats with enhanced styling
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.03),
                    Colors.blue.withOpacity(0.01),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLikeStat(Icons.thumb_up_outlined, discussion.stats.likes, 'Likes'),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStat(Icons.comment_outlined, discussion.stats.commentsCount, 'Comments'),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStat(Icons.visibility_outlined, discussion.stats.views, 'Views'),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStat(Icons.people_outlined, discussion.followersCount ?? discussion.stats.followersCount, 'Followers'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildInfoSection(String title, String content, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummary(AISummary aiSummary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.indigo[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Summary',
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(aiSummary.confidenceScore * 100).toInt()}% confidence',
                  style: TextStyle(
                    color: Colors.indigo[700],
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
            style: const TextStyle(fontSize: 14),
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
                      color: Colors.indigo[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildLikeStat(IconData icon, int count, String label) {
    return GestureDetector(
      onTap: onLike,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: onLike != null ? Colors.blue[600] : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: onLike != null ? Colors.blue[700] : Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: onLike != null ? Colors.blue[600] : Colors.grey[600],
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

  Widget _buildStat(IconData icon, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpecialtyColor(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return Colors.red;
      case 'neurology':
        return Colors.purple;
      case 'orthopedics':
        return Colors.blue;
      case 'pediatrics':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildPatientDemographics(dynamic demographics) {
    final List<Widget> widgets = [];
    
    if (demographics is Map<String, dynamic>) {
      if (demographics['age'] != null) {
        widgets.add(_buildDemographicItem('Age', '${demographics['age']} years', Icons.cake_rounded));
      }
      if (demographics['gender'] != null) {
        widgets.add(_buildDemographicItem('Gender', demographics['gender'].toString(), Icons.person_rounded));
      }
      if (demographics['ethnicity'] != null) {
        widgets.add(_buildDemographicItem('Ethnicity', demographics['ethnicity'].toString(), Icons.public_rounded));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildClinicalMetadata(Map<String, dynamic> metadata) {
    final List<Widget> widgets = [];
    
    if (metadata['clinical_complexity'] != null) {
      final complexity = metadata['clinical_complexity'].toString();
      widgets.add(_buildMetadataItem(
        'Clinical Complexity', 
        complexity.toUpperCase(), 
        _getComplexityColor(complexity),
        Icons.timeline_rounded
      ));
    }
    
    if (metadata['teaching_value'] != null) {
      final teachingValue = metadata['teaching_value'].toString();
      widgets.add(_buildMetadataItem(
        'Teaching Value', 
        teachingValue.toUpperCase(), 
        _getTeachingValueColor(teachingValue),
        Icons.school_rounded
      ));
    }
    
    if (metadata['is_anonymized'] != null) {
      final isAnonymized = metadata['is_anonymized'] == true || metadata['is_anonymized'] == '1';
      widgets.add(_buildMetadataItem(
        'Patient Privacy', 
        isAnonymized ? 'ANONYMIZED' : 'IDENTIFIED', 
        isAnonymized ? Colors.green : Colors.orange,
        isAnonymized ? Icons.security_rounded : Icons.visibility_rounded
      ));
    }
    
    return widgets;
  }

  List<Widget> _buildClinicalMetadataFromModel(CaseMetadata metadata) {
    final List<Widget> widgets = [];
    
    if (metadata.clinicalComplexity != null) {
      final complexity = metadata.clinicalComplexity!;
      widgets.add(_buildMetadataItem(
        'Clinical Complexity', 
        complexity.toUpperCase(), 
        _getComplexityColor(complexity),
        Icons.timeline_rounded
      ));
    }
    
    if (metadata.teachingValue != null) {
      final teachingValue = metadata.teachingValue!;
      widgets.add(_buildMetadataItem(
        'Teaching Value', 
        teachingValue.toUpperCase(), 
        _getTeachingValueColor(teachingValue),
        Icons.school_rounded
      ));
    }
    
    if (metadata.isAnonymized != null) {
      final isAnonymized = metadata.isAnonymized!;
      widgets.add(_buildMetadataItem(
        'Patient Privacy', 
        isAnonymized ? 'ANONYMIZED' : 'IDENTIFIED', 
        isAnonymized ? Colors.green : Colors.orange,
        isAnonymized ? Icons.security_rounded : Icons.visibility_rounded
      ));
    }
    
    if (metadata.evidenceLevel != null) {
      widgets.add(_buildMetadataItem(
        'Evidence Level', 
        metadata.evidenceLevel!.toUpperCase(), 
        Colors.purple,
        Icons.science_rounded
      ));
    }
    
    return widgets;
  }

  Widget _buildDemographicItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.teal.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.teal[600],
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Colors.teal[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTeachingValueColor(String teachingValue) {
    switch (teachingValue.toLowerCase()) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.purple;
      default:
        return Colors.grey;
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