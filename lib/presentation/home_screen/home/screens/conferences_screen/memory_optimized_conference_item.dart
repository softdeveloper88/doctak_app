import 'package:doctak_app/core/utils/conference_display.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conference_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value.split(' ').first);
  }

  String _formatLongDate(String? value) {
    final parsed = _parseDate(value);
    if (parsed == null) return value ?? 'Date TBA';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[parsed.weekday - 1]}, ${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  String _locationLabel() {
    return conferenceLocationLabel(
      city: widget.conference.city,
      state: widget.conference.state,
      country: widget.conference.country,
      countryName: widget.conference.countryName,
    );
  }

  String _excerpt() {
    return conferenceExcerpt(widget.conference.description);
  }

  String _topicsPreview() {
    final source = widget.conference.specialtiesTargeted?.trim().isNotEmpty == true
        ? widget.conference.specialtiesTargeted
        : widget.conference.keywords;
    return conferenceTopicsPreview(source);
  }

  String _organizerInitials() {
    final name = widget.conference.organizer?.trim();
    if (name == null || name.isEmpty) return 'CF';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final startDate = _parseDate(widget.conference.startDate);
    const shortMonths = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final day = startDate != null
        ? startDate.day.toString().padLeft(2, '0')
        : '--';
    final month = startDate != null ? shortMonths[startDate.month - 1] : '---';
    final location = _locationLabel();
    final excerpt = _excerpt();
    final topics = _topicsPreview();
    final metaParts = [
      if (widget.conference.specialty?.trim().isNotEmpty == true)
        widget.conference.specialty!.trim(),
      if (location.isNotEmpty) location,
    ];

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: theme.cardDecoration,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConferenceDateColumn(day: day, month: month, theme: theme),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (widget.conference.specialty?.trim().isNotEmpty == true)
                            _Badge(
                              label: widget.conference.specialty!.trim(),
                              theme: theme,
                              style: _BadgeStyle.spec,
                            ),
                          _Badge(
                            label: 'Upcoming',
                            theme: theme,
                            style: _BadgeStyle.upcoming,
                          ),
                          if (widget.conference.cmeCredits?.trim().isNotEmpty == true)
                            _Badge(
                              label: '${widget.conference.cmeCredits} CME',
                              theme: theme,
                              style: _BadgeStyle.cme,
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: _hasWebsite ? _launchWebsite : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          widget.conference.title ??
                              translation(context).lbl_not_available,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _hasWebsite ? theme.primary : theme.textPrimary,
                            height: 1.3,
                            decoration: _hasWebsite ? TextDecoration.underline : null,
                            decorationColor: theme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          metaParts.join(' · '),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontFamily: 'Poppins',
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                      if (excerpt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: theme.textPrimary.withValues(alpha: 0.82),
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: theme.textSecondary,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: 'Call for papers: ',
                                style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                              TextSpan(text: topics),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _organizerInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.conference.organizer ??
                                      'Conference organizer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: theme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _formatLongDate(widget.conference.startDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      FilledButton(
                          onPressed: _openDetailScreen,
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                translation(context).lbl_view_details,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: _shareConference,
                            icon: Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasWebsite {
    final website = widget.conference.website?.trim();
    return website != null && website.isNotEmpty;
  }

  Future<void> _launchWebsite() async {
    final website = widget.conference.website?.trim();
    if (website == null || website.isEmpty) return;
    final uri = Uri.tryParse(website);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDetailScreen() {
    final id = widget.conference.id?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConferenceDetailScreen(
          conferenceId: id,
          initialConference: widget.conference,
        ),
      ),
    );
  }

  void _shareConference() {
    DeepLinkService.shareConference(
      conferenceId: widget.conference.id?.toString() ?? '',
      title: widget.conference.title ?? '',
    );
  }
}

class _ConferenceDateColumn extends StatelessWidget {
  const _ConferenceDateColumn({
    required this.day,
    required this.month,
    required this.theme,
  });

  final String day;
  final String month;
  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        border: Border(
          right: BorderSide(color: theme.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textSecondary,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeStyle { spec, upcoming, cme }

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.theme,
    required this.style,
  });

  final String label;
  final OneUITheme theme;
  final _BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (style) {
      case _BadgeStyle.spec:
        bg = theme.inputBackground;
        fg = theme.textPrimary;
        border = Border.all(color: theme.border);
      case _BadgeStyle.upcoming:
        bg = theme.primary.withValues(alpha: 0.1);
        fg = theme.primary;
      case _BadgeStyle.cme:
        bg = const Color(0xFFFEFCE8);
        fg = const Color(0xFF854D0E);
        border = Border.all(color: const Color(0xFFFDE68A));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          color: fg,
        ),
      ),
    );
  }
}
