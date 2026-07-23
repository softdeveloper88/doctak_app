import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Legacy entry kept for feed / notifications / deep links.
/// Delegates to redesigned [JobDetailScreen].
class JobsDetailsScreen extends StatelessWidget {
  const JobsDetailsScreen({
    required this.jobId,
    this.isFromSplash = false,
    super.key,
  });

  final String jobId;
  final bool isFromSplash;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isFromSplash,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isFromSplash) {
          const SVDashboardScreen().launch(context, isNewTask: true);
        }
      },
      child: JobDetailScreen(jobId: jobId),
    );
  }
}
