import 'package:doctak_app/core/app_export.dart';
import 'package:intl/intl.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/document_upload_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/job_applicant_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/shimmer_widget/job_details_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../SVDashboardScreen.dart';
import 'bloc/jobs_bloc.dart';
import 'bloc/jobs_state.dart';

class JobsDetailsScreen extends StatefulWidget {
  const JobsDetailsScreen({
    required this.jobId,
    this.isFromSplash = false,
    super.key,
  });

  final String jobId;
  final bool isFromSplash;

  @override
  State<JobsDetailsScreen> createState() => _JobsDetailsScreenState();
}

class _JobsDetailsScreenState extends State<JobsDetailsScreen> {
  final JobsBloc jobsBloc = JobsBloc();
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    // If jobId is empty, avoid making the API call and show a friendly message
    if (widget.jobId.trim().isEmpty) {
      // set a local flag so build() can show a proper message
      _invalidJobId = true;
    } else {
      jobsBloc.add(JobDetailPageEvent(jobId: widget.jobId));
    }

    super.initState();
  }

  bool _invalidJobId = false;

  /// Returns true when [v] has a meaningful non-empty value from the API.
  bool _hasValue(dynamic v) =>
      v != null && v.toString().trim().isNotEmpty;

  Countries findModelByNameOrDefault(
    List<Countries> countries,
    String name,
    Countries defaultCountry,
  ) {
    return countries.firstWhere(
      (country) => country.countryName?.toLowerCase() == name.toLowerCase(),
      orElse: () => defaultCountry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (_invalidJobId) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: translation(context).lbl_job_detail,
          titleIcon: Icons.work_outline_rounded,
          onBackPressed: () {
            if (widget.isFromSplash) {
              const SVDashboardScreen().launch(context, isNewTask: true);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        body: Center(
          child: Text(
            'This job is no longer available',
            style: TextStyle(color: theme.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_job_detail,
        titleIcon: Icons.work_outline_rounded,
        onBackPressed: () {
          if (widget.isFromSplash) {
            const SVDashboardScreen().launch(context, isNewTask: true);
          } else {
            Navigator.pop(context);
          }
        },
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_outlined,
                  color: theme.primary,
                  size: 16,
                ),
              ),
              onPressed: () {
                if (jobsBloc.jobDetailModel.job != null) {
                  final job = jobsBloc.jobDetailModel.job!;
                  DeepLinkService.shareJob(
                    jobId: job.id?.toString() ?? widget.jobId,
                    title: job.jobTitle,
                    company: job.companyName,
                    location: job.location,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<JobsBloc, JobsState>(
        bloc: jobsBloc,
        listener: (BuildContext context, JobsState state) {
          if (state is DataError) {
            // Error handling if needed
          }
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return const JobDetailsShimmer();
          } else if (state is PaginationLoadedState) {
            return _buildJobDetails();
          } else if (state is DataError) {
            return Center(child: Text(state.errorMessage));
          } else {
            return Center(
              child: Text(translation(context).msg_something_went_wrong),
            );
          }
        },
      ),
      bottomNavigationBar: BlocBuilder<JobsBloc, JobsState>(
        bloc: jobsBloc,
        builder: (context, state) {
          if (state is PaginationLoadedState &&
              jobsBloc.jobDetailModel.job != null) {
            return _buildStickyBottomBar(jobsBloc.jobDetailModel.job!);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildJobDetails() {
    final job = jobsBloc.jobDetailModel.job;
    if (job == null) {
      return Center(child: Text(translation(context).msg_no_data_found));
    }

    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    final hasRequirements = _hasValue(job.experience) ||
        _hasValue(job.preferredLanguage) ||
        _hasValue(job.noOfJobs);
    final hasDates = _hasValue(job.createdAt) || _hasValue(job.lastDate);
    final hasSpecialties = job.specialties?.isNotEmpty ?? false;
    final hasDescription = (job.description ?? '').trim().isNotEmpty;
    final hasUser = job.user != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          _buildHeroSection(job, isDark),
          const SizedBox(height: 16),

          // Stats Section
          _buildStatsGrid(job, jobsBloc.jobDetailModel.totalApplicants, isDark),

          // Requirements Section
          if (hasRequirements) ...[
            const SizedBox(height: 16),
            _buildRequirementsSection(job, isDark),
          ],

          // Application Window Section
          if (hasDates) ...[
            const SizedBox(height: 16),
            _buildApplicationWindowSection(job, isDark),
          ],

          // Medical Specialties Section
          if (hasSpecialties) ...[
            const SizedBox(height: 16),
            _buildSpecialtiesSection(job, isDark),
          ],

          // Job Description Section
          if (hasDescription) ...[
            const SizedBox(height: 16),
            _buildDescriptionSection(job, isDark),
          ],

          // Posted By Section
          if (hasUser) ...[
            const SizedBox(height: 16),
            _buildPostedBySection(job, isDark),
          ],

          // Extra bottom padding for the sticky bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeroSection(job, bool isDark) {
    const primary = Color(0xFF2563EB);
    final isPromoted = (job.promoted is bool && job.promoted == true) ||
        (job.promoted is int && job.promoted != 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: primary,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPromoted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Promoted',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        job.jobTitle ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.apartment_outlined,
                            size: 14,
                            color: Color(0xFFBFDBFE),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              job.companyName ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBFDBFE),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_hasValue(job.location)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                job.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_hasValue(job.salaryRange)) ...[
                        const SizedBox(height: 6),
                        Text(
                          job.salaryRange!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Decorative blob — top right
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Decorative blob — bottom left
          Positioned(
            left: -48,
            bottom: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(job, int? totalApplicants, bool isDark) {
    const primary = Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    Widget statCard(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        statCard('${job.views ?? 0}', 'Views'),
        const SizedBox(width: 12),
        statCard('${job.clicks ?? 0}', 'Clicks'),
        const SizedBox(width: 12),
        statCard('${totalApplicants ?? 0}', 'Applicants'),
      ],
    );
  }

  Widget _buildRequirementsSection(job, bool isDark) {
    const primary = Color(0xFF2563EB);
    final items = <({IconData icon, String label, String value})>[];
    if (_hasValue(job.experience))
      items.add((
        icon: Icons.work_history_outlined,
        label: 'Experience',
        value: job.experience.toString(),
      ));
    if (_hasValue(job.preferredLanguage))
      items.add((
        icon: Icons.translate_outlined,
        label: 'Preferred Language',
        value: job.preferredLanguage.toString(),
      ));
    if (_hasValue(job.noOfJobs))
      items.add((
        icon: Icons.groups_outlined,
        label: 'Positions Available',
        value: job.noOfJobs.toString(),
      ));

    if (items.isEmpty) return const SizedBox.shrink();

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final headerBg = isDark
        ? const Color(0xFF0F172A).withOpacity(0.6)
        : const Color(0xFFF8FAFC);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final divider =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: divider)),
            ),
            child: Text(
              'REQUIREMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...List.generate(items.length, (i) {
            return Column(
              children: [
                if (i > 0) Divider(height: 1, color: divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          items[i].icon,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                color: labelColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].value,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: valueColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection(job, bool isDark) {
    const primary = Color(0xFF2563EB);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'MEDICAL SPECIALTIES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (job.specialties ?? []).map<Widget>((specialty) {
            final name =
                (specialty.name ?? '').trim();
            final displayText = name.isEmpty
                ? 'Specialty ${specialty.id ?? ''}'.trim()
                : name;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 14,
                  color: primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplicationWindowSection(job, bool isDark) {
    const primary = Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final boxBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    String fmtDate(String? d) {
      if (d == null || d.trim().isEmpty) return 'N/A';
      try {
        return DateFormat('MMM dd, yyyy').format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    }

    Widget dateBox(String label, String? date, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmtDate(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLICATION WINDOW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              dateBox('Date From', job.createdAt, Icons.calendar_today_outlined),
              const SizedBox(width: 12),
              dateBox('Date To', job.lastDate, Icons.event_busy_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(job, bool isDark) {
    final desc = (job.description ?? '').trim();
    if (desc.isEmpty) return const SizedBox.shrink();

    const primary = Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bodyColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isDescriptionExpanded
                ? HtmlWidget(
                    desc,
                    textStyle: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: bodyColor,
                    ),
                  )
                : SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: HtmlWidget(
                        desc,
                        textStyle: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: bodyColor,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isDescriptionExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostedBySection(job, bool isDark) {
    if (job.user == null) return const SizedBox.shrink();
    const primary = Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final nameColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final btnBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final profilePic = job.user?.profilePic;
    final hasPhoto =
        profilePic != null && profilePic.toString().trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            backgroundImage:
                hasPhoto ? NetworkImage(profilePic.toString()) : null,
            child: !hasPhoto
                ? Icon(Icons.person_outline, color: primary, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.user?.name?.toString() ?? 'Job Poster',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Job Poster',
                  style:
                      TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: btnBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_outline, color: primary, size: 20),
          ),
        ],
      ),
    );
  }

  /// Sticky bottom action bar matching Stitch design
  Widget _buildStickyBottomBar(dynamic job) {
    final theme = OneUITheme.of(context);
    final bool hasApplied = jobsBloc.jobDetailModel.hasApplied ?? false;
    final bool hasLink = job.link != null && job.link!.isNotEmpty;
    final bool isJobOwner = job.user?.id == AppData.logInUserId;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isJobOwner
          ? _buildViewApplicantsButton()
          : Row(
              children: [
                // Visit Site button
                if (hasLink)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await PostUtils.launchURL(context, job.link!);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(
                          color: theme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            translation(context).lbl_visit_site,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasLink) const SizedBox(width: 12),
                // Apply Now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasApplied
                        ? () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomAlertDialog(
                                  mainTitle: translation(
                                    context,
                                  ).lbl_withdraw_application,
                                  yesButtonText: translation(
                                    context,
                                  ).lbl_withdraw,
                                  title: translation(
                                    context,
                                  ).msg_confirm_withdraw,
                                  callback: () {
                                    jobsBloc.add(
                                      WithDrawApplicant(jobId: widget.jobId),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          }
                        : () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return DocumentUploadDialog(widget.jobId);
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasApplied
                          ? Colors.green
                          : theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasApplied
                              ? Icons.check_circle_outline
                              : Icons.send_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasApplied
                              ? translation(context).lbl_applied
                              : translation(context).lbl_apply,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

  // View applicants button for Sticky Bar
  Widget _buildViewApplicantsButton() {
    final theme = OneUITheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          JobApplicantScreen(widget.jobId, jobsBloc).launch(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 12),
            Text(
              translation(context).lbl_view_applicants,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
