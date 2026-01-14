import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Memory-optimized conference item widget with One UI 8.5 styling
class MemoryOptimizedConferenceItem extends StatefulWidget {
  final Data conference;
  final Function(BuildContext, Data)? onItemTap;

  const MemoryOptimizedConferenceItem({
    super.key,
    required this.conference,
    this.onItemTap,
  });

  @override
  State<MemoryOptimizedConferenceItem> createState() =>
      _MemoryOptimizedConferenceItemState();
}

class _MemoryOptimizedConferenceItemState
    extends State<MemoryOptimizedConferenceItem> {
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (widget.onItemTap != null) {
            widget.onItemTap!(context, widget.conference);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conference image
                _buildConferenceImageOrPlaceholder(theme),

                // Conference header with title and dates
                _buildConferenceHeader(theme),

                // Conference description
                _buildConferenceDescription(theme),

                // Conference details (city, venue, etc.)
                _buildConferenceDetails(theme),

                // Register button and actions
                _buildActionRow(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Conference image or placeholder
  Widget _buildConferenceImageOrPlaceholder(OneUITheme theme) {
    if (widget.conference.thumbnail != null &&
        widget.conference.thumbnail!.isNotEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: theme.surfaceVariant),
        child: Image.network(
          widget.conference.thumbnail!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    color: theme.textTertiary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translation(context).msg_image_not_available,
                    style: TextStyle(
                      color: theme.textTertiary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
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
                color: theme.primary,
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary.withOpacity(0.1),
              theme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.event_rounded, size: 36, color: theme.primary),
          ),
        ),
      );
    }
  }

  // Conference header with title and organizer
  Widget _buildConferenceHeader(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conference.title ??
                      translation(context).lbl_not_available,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Date row with chip style
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: theme.success,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${widget.conference.startDate ?? ''} - ${widget.conference.endDate ?? ''}',
                          style: TextStyle(
                            color: theme.success,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.conference.organizer != null &&
                    widget.conference.organizer!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: theme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.conference.organizer ?? '',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
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
          // Share button - One UI style
          Material(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                _shareConference();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.share_rounded,
                  color: theme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Conference description
  Widget _buildConferenceDescription(OneUITheme theme) {
    if (widget.conference.description == null ||
        widget.conference.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 14,
                  color: theme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                translation(context).lbl_description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.conference.description ??
                translation(context).msg_no_description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: theme.textSecondary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Conference details (location, credits, etc.)
  Widget _buildConferenceDetails(OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.location_on_rounded,
            theme.success,
            '${widget.conference.city ?? ''}, ${widget.conference.country ?? ''}',
            theme,
          ),
          if (widget.conference.venue != null &&
              widget.conference.venue!.isNotEmpty)
            _buildDetailRow(
              Icons.meeting_room_rounded,
              theme.warning,
              widget.conference.venue!,
              theme,
            ),
          if (widget.conference.cmeCredits != null ||
              widget.conference.mocCredits != null)
            _buildDetailRow(
              Icons.school_rounded,
              theme.secondary,
              'CME: ${widget.conference.cmeCredits ?? 'N/A'}, MOC: ${widget.conference.mocCredits ?? 'N/A'}',
              theme,
            ),
          if (widget.conference.specialtiesTargeted != null &&
              widget.conference.specialtiesTargeted!.isNotEmpty)
            _buildDetailRow(
              Icons.medical_services_rounded,
              theme.primary,
              widget.conference.specialtiesTargeted!,
              theme,
            ),
        ],
      ),
    );
  }

  // Helper method to build a detail row - One UI 8.5 style
  Widget _buildDetailRow(
    IconData icon,
    Color color,
    String text,
    OneUITheme theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Register button and actions - One UI 8.5 style
  Widget _buildActionRow(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child:
          widget.conference.registrationLink != null &&
              widget.conference.registrationLink!.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchRegistrationLink(),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.app_registration_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          translation(context).lbl_register_now,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translation(context).lbl_registration_unavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: theme.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Share conference details
  void _shareConference() {
    // Build location string from available fields
    final locationParts = <String>[
      if (widget.conference.venue != null && widget.conference.venue!.isNotEmpty) widget.conference.venue!,
      if (widget.conference.city != null && widget.conference.city!.isNotEmpty) widget.conference.city!,
      if (widget.conference.country != null && widget.conference.country!.isNotEmpty) widget.conference.country!,
    ];
    final location = locationParts.isNotEmpty ? locationParts.join(', ') : null;
    
    DeepLinkService.shareConference(
      conferenceId: widget.conference.id?.toString() ?? '',
      title: widget.conference.title,
      date: widget.conference.startDate,
      location: location,
    );
  }

  // Launch registration link
  void _launchRegistrationLink() async {
    if (widget.conference.registrationLink != null &&
        widget.conference.registrationLink!.isNotEmpty) {
      final Uri registrationUri = Uri.parse(
        widget.conference.registrationLink!,
      );
      if (await canLaunchUrl(registrationUri)) {
        await launchUrl(registrationUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
