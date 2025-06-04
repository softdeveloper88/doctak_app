import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/document_upload_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/widgets/memory_optimized_job_item.dart';
import 'package:doctak_app/widgets/shimmer_widget/jobs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A virtualized list of jobs that only renders items when they're visible
class VirtualizedJobsList extends StatefulWidget {
  final JobsBloc jobsBloc;
  final ScrollController? scrollController;

  const VirtualizedJobsList({
    super.key,
    required this.jobsBloc,
    this.scrollController,
  });

  @override
  State<VirtualizedJobsList> createState() => _VirtualizedJobsListState();
}

class _VirtualizedJobsListState extends State<VirtualizedJobsList> {
  // Keep track of visible items for optimization
  final Set<int> _visibleJobIndices = {};
  
  @override
  void dispose() {
    _visibleJobIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.jobsBloc;

    if (bloc.drugsData.isEmpty) {
      return Center(
        child: Text(translation(context).msg_no_jobs_found),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(top: 10),
      itemCount: bloc.drugsData.length,
      // Using a larger cacheExtent for smooth scrolling
      cacheExtent: 800,
      itemBuilder: (context, index) {
        // Check for pagination trigger
        _triggerPaginationIfNeeded(bloc, index);

        // Return appropriate widget based on conditions
        if (_shouldShowShimmer(bloc, index)) {
          return SizedBox(height: 400, child: JobsShimmerLoader());
        } else if (_shouldShowNativeAd(index)) {
          return NativeAdWidget();
        } else {
          return _buildLazyLoadJobItem(index);
        }
      },
    );
  }

  // Build the job item with visibility detection
  Widget _buildLazyLoadJobItem(int index) {
    return VisibilityDetector(
      key: Key('job_visibility_${widget.jobsBloc.drugsData[index].id}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.1;
        _handleVisibilityChanged(index, isVisible);
      },
      child: MemoryOptimizedJobItem(
        jobData: widget.jobsBloc.drugsData[index],
        onJobTap: () => _openJobDetails(
          context, 
          widget.jobsBloc.drugsData[index].id.toString()
        ),
        onShareTap: () => _shareJob(widget.jobsBloc.drugsData[index]),
        onApplyTap: (id) => _showApplyDialog(context, id),
        onLaunchLink: (url) => PostUtils.launchURL(context, url.toString()),
      ),
    );
  }

  // Pagination logic
  void _triggerPaginationIfNeeded(JobsBloc bloc, int index) {
    if (bloc.pageNumber <= bloc.numberOfPage &&
        index == bloc.drugsData.length - bloc.nextPageTrigger) {
      bloc.add(JobCheckIfNeedMoreDataEvent(index: index));
    }
  }

  // Track which job items are visible
  void _handleVisibilityChanged(int index, bool isVisible) {
    if (isVisible) {
      _visibleJobIndices.add(index);
    } else {
      _visibleJobIndices.remove(index);
    }
    
    // Can be used for analytics or future optimizations
  }

  // Check if shimmer loader should be shown
  bool _shouldShowShimmer(JobsBloc bloc, int index) {
    return bloc.numberOfPage != bloc.pageNumber - 1 &&
        index >= bloc.drugsData.length - 1;
  }

  // Check if native ad should be shown
  bool _shouldShowNativeAd(int index) {
    return index % 5 == 0 && index != 0 && AppData.isShowGoogleNativeAds;
  }

  // Navigate to job details
  void _openJobDetails(BuildContext context, String jobId) {
    JobsDetailsScreen(jobId: jobId).launch(context);
  }

  // Share job via dynamic link
  void _shareJob(dynamic job) {
    final jobTitle = job.jobTitle ?? "";
    final jobLink = job.link ?? "";
    final jobId = job.id?.toString() ?? "";
    
    // Use the createDynamicLink function
    createDynamicLink(
      "$jobTitle\nApply Link: $jobLink",
      "https://doctak.net/job/$jobId",
      jobLink,
    );
  }

  // Show job application dialog
  void _showApplyDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DocumentUploadDialog(id),
    );
  }
}