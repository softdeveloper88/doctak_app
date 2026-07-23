import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class JobsSavedTab extends StatefulWidget {
  const JobsSavedTab({super.key});

  @override
  State<JobsSavedTab> createState() => _JobsSavedTabState();
}

class _JobsSavedTabState extends State<JobsSavedTab>
    with AutomaticKeepAliveClientMixin {
  List<JobCardDto> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await JobsNodeApiService.getBookmarks();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _unsave(JobCardDto job) async {
    try {
      await JobsNodeApiService.toggleBookmark(job.id);
      if (!mounted) return;
      setState(() => _items = _items.where((j) => j.id != job.id).toList());
    } catch (e) {
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OneUITheme.of(context);
    if (_loading) return const JobCardShimmerList();
    if (_error != null) {
      return JobsEmptyState(
        title: 'Couldn’t load saved jobs',
        subtitle: _error,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return const JobsEmptyState(
        title: 'No saved jobs yet',
        subtitle: 'Bookmark roles from Browse to revisit them here.',
        icon: Icons.bookmark_border_rounded,
      );
    }
    return ColoredBox(
      color: theme.scaffoldBackground,
      child: RefreshIndicator(
        color: theme.primary,
        onRefresh: _load,
        child: ListView.builder(
          padding: JobsTheme.listPadding(context, top: 12),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final job = _items[index];
            return JobCard(
              job: job.copyWith(isBookmarked: true),
              onTap: () => JobDetailScreen(jobId: job.id).launch(context),
              onBookmark: () => _unsave(job),
            );
          },
        ),
      ),
    );
  }
}
