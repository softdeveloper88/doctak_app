import 'package:doctak_app/presentation/jobs_module/jobs_hub_screen.dart';
import 'package:flutter/material.dart';

/// Entry point kept for existing navigators (drawer, feed “See all”).
/// Delegates to the redesigned [JobsHubScreen].
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key, this.manageJobId});

  final String? manageJobId;

  @override
  Widget build(BuildContext context) {
    return JobsHubScreen(manageJobId: manageJobId);
  }
}
