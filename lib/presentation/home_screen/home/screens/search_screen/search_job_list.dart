import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/widgets/memory_optimized_job_item.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/bloc/search_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../jobs_screen/document_upload_dialog.dart';
import 'bloc/search_event.dart';

class SearchJobList extends StatefulWidget {
  const SearchJobList(this.drugsBloc, {super.key});

  final SearchBloc drugsBloc;

  @override
  State<SearchJobList> createState() => _SearchJobListState();
}

class _SearchJobListState extends State<SearchJobList> {
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
            } else {
              final jobData = widget.drugsBloc.drugsData[index];
              return MemoryOptimizedJobItem(
                jobData: jobData,
                onJobTap: () {
                  JobsDetailsScreen(jobId: '${jobData.id}').launch(context);
                },
                onShareTap: () {
                  // Share job
                  Share.share(
                    'Check out this job: ${jobData.jobTitle}\n${jobData.link ?? ''}',
                  );
                },
                onApplyTap: (jobId) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return DocumentUploadDialog(jobId);
                    },
                  );
                },
                onLaunchLink: (url) async {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              );
            }
          },
        ),
      );
    } else {
      return _buildEmptyState(context, theme);
    }
  }

  Widget _buildEmptyState(BuildContext context, OneUITheme theme) {
    return Container(
      color: theme.scaffoldBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withOpacity(0.15),
                    theme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_off_rounded,
                size: 48,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              translation(context).msg_no_jobs_found,
              style: theme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: theme.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}
