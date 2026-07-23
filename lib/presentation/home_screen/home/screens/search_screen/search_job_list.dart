import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/bloc/search_bloc.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'bloc/search_event.dart';

class SearchJobList extends StatefulWidget {
  const SearchJobList(this.drugsBloc, {super.key});

  final SearchBloc drugsBloc;

  @override
  State<SearchJobList> createState() => _SearchJobListState();
}

class _SearchJobListState extends State<SearchJobList> {
  JobCardDto _mapLegacy(dynamic jobData) {
    return JobCardDto(
      id: '${jobData.id ?? ''}',
      title: jobData.jobTitle?.toString() ?? 'Job',
      companyName: jobData.companyName?.toString(),
      location: jobData.location?.toString(),
      experience: jobData.experience?.toString(),
      specialty: jobData.specialty?.toString(),
      jobType: jobData.jobType?.toString(),
      salaryRange: jobData.salaryRange?.toString(),
      description: jobData.description?.toString(),
      image: jobData.jobImage?.toString(),
      lastDate: jobData.lastDate?.toString(),
      createdAt: jobData.createdAt?.toString() ?? jobData.postedAt?.toString(),
      promoted: jobData.promoted == true,
      stats: JobStatsDto(
        views: int.tryParse('${jobData.views ?? 0}') ?? 0,
        applicants: (jobData.applicants is List)
            ? (jobData.applicants as List).length
            : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (widget.drugsBloc.drugsData.isNotEmpty) {
      return Container(
        color: theme.scaffoldBackground,
        child: ListView.builder(
          key: const PageStorageKey<String>('jobs_list'),
          padding: EdgeInsets.only(
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          itemCount: widget.drugsBloc.drugsData.length,
          cacheExtent: 1000,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            if (widget.drugsBloc.pageNumber <= widget.drugsBloc.numberOfPage) {
              if (index ==
                  widget.drugsBloc.drugsData.length -
                      widget.drugsBloc.nextPageTrigger) {
                widget.drugsBloc.add(CheckIfNeedMoreDataEvent(index: index));
              }
            }
            if (widget.drugsBloc.numberOfPage !=
                    widget.drugsBloc.pageNumber - 1 &&
                index >= widget.drugsBloc.drugsData.length - 1) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const JobsShimmerLoader(),
              );
            }
            final jobData = widget.drugsBloc.drugsData[index];
            final job = _mapLegacy(jobData);
            return JobCard(
              job: job,
              showBookmark: false,
              onTap: () => JobsDetailsScreen(jobId: job.id).launch(context),
              trailing: IconButton(
                icon: Icon(Icons.share_outlined, color: theme.primary),
                onPressed: () => DeepLinkService.shareJob(
                  jobId: job.id,
                  title: job.title,
                  company: job.companyName,
                  location: job.location,
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildEmptyState(context, theme);
  }

  Widget _buildEmptyState(BuildContext context, OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: theme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: theme.titleSmall.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}
