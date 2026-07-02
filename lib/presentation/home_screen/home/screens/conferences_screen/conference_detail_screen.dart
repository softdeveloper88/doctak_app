import 'package:doctak_app/core/utils/conference_display.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class ConferenceDetailScreen extends StatefulWidget {
  const ConferenceDetailScreen({
    super.key,
    required this.conferenceId,
    this.initialConference,
  });

  final String conferenceId;
  final Data? initialConference;

  @override
  State<ConferenceDetailScreen> createState() => _ConferenceDetailScreenState();
}

class _ConferenceDetailScreenState extends State<ConferenceDetailScreen> {
  final _api = ApiServiceManager();
  Data? _conference;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _conference = widget.initialConference;
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getConferenceDetail(widget.conferenceId);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _conference = Data.fromJson(data);
      }
      _loading = false;
    });
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final conference = _conference;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_conference,
        titleIcon: Icons.event,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: _loading && conference == null
          ? const Center(child: CircularProgressIndicator())
          : conference == null
              ? Center(
                  child: Text(
                    translation(context).msg_something_went_wrong_retry,
                    style: TextStyle(color: theme.textSecondary),
                  ),
                )
              : _buildContent(theme, conference),
    );
  }

  Widget _buildContent(OneUITheme theme, Data c) {
    final hero = (c.image?.isNotEmpty == true) ? c.image : c.thumbnail;
    final location = conferenceLocationLabel(
      location: c.location,
      city: c.city,
      state: c.state,
      country: c.country,
      countryName: c.countryName,
    );
    final callForPapers = parseConferenceTopics(c.specialtiesTargeted);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 180,
              color: theme.primary.withValues(alpha: 0.08),
              child: hero != null && hero.isNotEmpty
                  ? Image.network(hero, fit: BoxFit.cover)
                  : Icon(Icons.event_rounded, size: 48, color: theme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (c.specialty?.isNotEmpty == true)
                _chip(c.specialty!, theme, filled: false),
              _chip(c.conferenceStatus ?? 'Upcoming', theme, filled: true),
              if (c.cmeCredits?.isNotEmpty == true) _chip('${c.cmeCredits} CME', theme, filled: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.title ?? '',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
              height: 1.2,
            ),
          ),
          if (c.organizer?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Hosted by ${c.organizer}',
              style: TextStyle(fontSize: 14, color: theme.textSecondary, fontFamily: 'Poppins'),
            ),
          ],
          const SizedBox(height: 16),
          _infoPanel(theme, c, location),
          const SizedBox(height: 16),
          _section(theme, 'About this conference', c.description),
          if (callForPapers.isNotEmpty)
            _topicsSection(theme, 'Call for papers', callForPapers),
          _section(theme, 'Speakers', c.speakers),
          _section(theme, 'Sponsors', c.sponsors),
          _section(theme, 'Accommodation', c.accommodationDetails),
          _section(theme, 'Additional notes', c.additianalNotes),
          const SizedBox(height: 8),
          _actionButtons(theme, c),
        ],
      ),
    );
  }

  Widget _infoPanel(OneUITheme theme, Data c, String location) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _factRow(theme, 'Dates', '${c.startDate ?? ''}${c.endDate != null && c.endDate != c.startDate ? ' — ${c.endDate}' : ''}'),
          if (location.isNotEmpty) _factRow(theme, 'Location', location),
          if (c.venue?.isNotEmpty == true) _factRow(theme, 'Venue', c.venue!),
          if (c.earlyBirdPrice?.isNotEmpty == true ||
              c.regularPrice?.isNotEmpty == true ||
              c.latePrice?.isNotEmpty == true)
            _factRow(
              theme,
              'Pricing',
              [
                if (c.earlyBirdPrice?.isNotEmpty == true) 'Early ${c.earlyBirdPrice}',
                if (c.regularPrice?.isNotEmpty == true) 'Regular ${c.regularPrice}',
                if (c.latePrice?.isNotEmpty == true) 'Late ${c.latePrice}',
              ].join(' · '),
            ),
          if (c.email?.isNotEmpty == true) _factRow(theme, 'Email', c.email!),
          if (c.phoneNo?.isNotEmpty == true) _factRow(theme, 'Phone', c.phoneNo!),
        ],
      ),
    );
  }

  Widget _factRow(OneUITheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: theme.textTertiary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: theme.textPrimary, fontFamily: 'Poppins', height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _section(OneUITheme theme, String title, String? body) {
    if (body == null || body.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _richBody(theme, body),
        ],
      ),
    );
  }

  Widget _topicsSection(OneUITheme theme, String title, List<String> topics) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in topics)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _richBody(OneUITheme theme, String body) {
    final textStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      fontFamily: 'Poppins',
      color: theme.textPrimary.withValues(alpha: 0.85),
    );

    if (conferenceIsHtmlContent(body)) {
      return HtmlWidget(
        body,
        textStyle: textStyle,
      );
    }

    return Text(body, style: textStyle);
  }

  Widget _actionButtons(OneUITheme theme, Data c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.registrationLink?.isNotEmpty == true)
          FilledButton(
            onPressed: () => _openUrl(c.registrationLink),
            style: FilledButton.styleFrom(
              backgroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Register now', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        if (c.website?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _openUrl(c.website),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Visit website', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
        if (c.conferenceAgendaLink?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _openUrl(c.conferenceAgendaLink),
            child: const Text('View agenda', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Widget _chip(String label, OneUITheme theme, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? theme.primary.withValues(alpha: 0.12) : theme.inputBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? theme.primary.withValues(alpha: 0.2) : theme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? theme.primary : theme.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
