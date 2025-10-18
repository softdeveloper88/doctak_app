import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

/// Memory-optimized conference item widget with performance improvements
class MemoryOptimizedConferenceItem extends StatefulWidget {
  final Data conference;
  final Function(BuildContext, Data)? onItemTap;

  const MemoryOptimizedConferenceItem({
    super.key,
    required this.conference,
    this.onItemTap,
  });

  @override
  State<MemoryOptimizedConferenceItem> createState() => _MemoryOptimizedConferenceItemState();
}

class _MemoryOptimizedConferenceItemState extends State<MemoryOptimizedConferenceItem> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (widget.onItemTap != null) {
            widget.onItemTap!(context, widget.conference);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conference image
                _buildConferenceImageOrPlaceholder(),
                
                // Conference header with title and dates
                _buildConferenceHeader(),
                
                // Conference description
                _buildConferenceDescription(),
                
                // Conference details (city, venue, etc.)
                _buildConferenceDetails(),
                
                // Register button and actions
                _buildActionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Conference image or placeholder
  Widget _buildConferenceImageOrPlaceholder() {
    if (widget.conference.thumbnail != null && widget.conference.thumbnail!.isNotEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: Image.network(
          widget.conference.thumbnail!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                translation(context).msg_image_not_available,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.blue,
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 100,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.event,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }

  // Conference header with title and organizer
  Widget _buildConferenceHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event,
              color: Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conference.title ?? translation(context).lbl_not_available,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.conference.startDate ?? ''} - ${widget.conference.endDate ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.conference.organizer != null && widget.conference.organizer!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.conference.organizer ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              _shareConference();
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_outlined,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Conference description
  Widget _buildConferenceDescription() {
    if (widget.conference.description == null || widget.conference.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translation(context).lbl_description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.conference.description ?? translation(context).msg_no_description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Conference details (location, credits, etc.)
  Widget _buildConferenceDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.location_on_outlined,
            Colors.green[700]!,
            '${widget.conference.city ?? ''}, ${widget.conference.country ?? ''}',
          ),
          if (widget.conference.venue != null && widget.conference.venue!.isNotEmpty)
            _buildDetailRow(
              Icons.meeting_room_outlined,
              Colors.orange[700]!,
              widget.conference.venue!,
            ),
          if (widget.conference.cmeCredits != null || widget.conference.mocCredits != null)
            _buildDetailRow(
              Icons.school_outlined,
              Colors.purple[700]!,
              'CME: ${widget.conference.cmeCredits ?? 'N/A'}, MOC: ${widget.conference.mocCredits ?? 'N/A'}',
            ),
          if (widget.conference.specialtiesTargeted != null && widget.conference.specialtiesTargeted!.isNotEmpty)
            _buildDetailRow(
              Icons.medical_services_outlined,
              Colors.blue[700]!,
              widget.conference.specialtiesTargeted!,
            ),
        ],
      ),
    );
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Register button and actions
  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: widget.conference.registrationLink != null && 
            widget.conference.registrationLink!.isNotEmpty
          ? ElevatedButton(
              onPressed: () => _launchRegistrationLink(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.app_registration, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    translation(context).lbl_register_now,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              translation(context).lbl_registration_unavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  // Share conference details
  void _shareConference() {
    // createDynamicLink(
    //   '${widget.conference.title ?? ""} \n  Register Link: ${widget.conference.conferenceAgendaLink ?? ''}',
    //   '${AppData.base}conference/${widget.conference.id}',
    //   widget.conference.thumbnail ?? '',
    // );
  }

  // Launch registration link
  void _launchRegistrationLink() {
    if (widget.conference.registrationLink != null && 
        widget.conference.registrationLink!.isNotEmpty) {
      Uri registrationUri = Uri.parse(widget.conference.registrationLink!);
      PostUtils.launchURL(context, registrationUri.toString());
    }
  }
}