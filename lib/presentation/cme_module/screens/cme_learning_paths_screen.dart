import 'package:doctak_app/data/models/cme/cme_learning_path_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_learning_path_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_learning_path_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_learning_path_state.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeLearningPathsScreen extends StatelessWidget {
  const CmeLearningPathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeLearningPathBloc()
        ..add(CmeBrowseLearningPathsEvent(page: 1))
        ..add(CmeLoadMyEnrolledPathsEvent()),
      child: const _LearningPathsView(),
    );
  }
}

class _LearningPathsView extends StatefulWidget {
  const _LearningPathsView();

  @override
  State<_LearningPathsView> createState() => _LearningPathsViewState();
}

class _LearningPathsViewState extends State<_LearningPathsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final bloc = context.read<CmeLearningPathBloc>();
        switch (_tabController.index) {
          case 0:
            if (bloc.browsePaths.isEmpty) {
              bloc.add(CmeBrowseLearningPathsEvent(page: 1));
            }
          case 1:
            bloc.add(CmeLoadMyEnrolledPathsEvent());
          case 2:
            bloc.add(CmeLoadMyCompletedPathsEvent());
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('Learning Paths',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primary,
          unselectedLabelColor: theme.textTertiary,
          indicatorColor: theme.primary,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Paths'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(theme),
          _buildEnrolledTab(theme),
          _buildCompletedTab(theme),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(OneUITheme theme) {
    return BlocBuilder<CmeLearningPathBloc, CmeLearningPathState>(
      builder: (context, state) {
        final bloc = context.read<CmeLearningPathBloc>();

        if (state is CmeLearningPathLoadingState && bloc.browsePaths.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bloc.browsePaths.isEmpty) {
          return _buildEmpty(theme, 'No learning paths available',
              'New paths will appear here', Icons.route_outlined);
        }

        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(CmeBrowseLearningPathsEvent(page: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bloc.browsePaths.length,
            itemBuilder: (_, index) {
              if (bloc.pageNumber <= bloc.numberOfPage) {
                bloc.add(CmeCheckIfNeedMorePathsEvent(index: index));
              }
              return _buildPathCard(
                  context, theme, bloc.browsePaths[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEnrolledTab(OneUITheme theme) {
    return BlocBuilder<CmeLearningPathBloc, CmeLearningPathState>(
      builder: (context, state) {
        final bloc = context.read<CmeLearningPathBloc>();

        if (state is CmeLearningPathLoadingState &&
            bloc.enrolledPaths.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bloc.enrolledPaths.isEmpty) {
          return _buildEmpty(theme, 'No enrolled paths',
              'Enroll in a learning path to track your progress',
              Icons.school_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bloc.enrolledPaths.length,
          itemBuilder: (_, index) =>
              _buildPathCard(context, theme, bloc.enrolledPaths[index],
                  showProgress: true),
        );
      },
    );
  }

  Widget _buildCompletedTab(OneUITheme theme) {
    return BlocBuilder<CmeLearningPathBloc, CmeLearningPathState>(
      builder: (context, state) {
        final bloc = context.read<CmeLearningPathBloc>();

        if (state is CmeLearningPathLoadingState &&
            bloc.completedPaths.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bloc.completedPaths.isEmpty) {
          return _buildEmpty(theme, 'No completed paths',
              'Complete a learning path to see it here',
              Icons.check_circle_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bloc.completedPaths.length,
          itemBuilder: (_, index) =>
              _buildPathCard(context, theme, bloc.completedPaths[index],
                  showProgress: true),
        );
      },
    );
  }

  Widget _buildPathCard(
      BuildContext context, OneUITheme theme, CmeLearningPathData path,
      {bool showProgress = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: theme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: theme.radiusL,
          onTap: () {
            if (path.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CmeLearningPathDetailScreen(pathId: path.id!),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header
              if (path.imageUrl != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    path.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: theme.primary.withValues(alpha: 0.1),
                      child: Center(
                          child: Icon(Icons.route,
                              size: 32, color: theme.primary)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        if (path.difficulty != null)
                          _difficultyBadge(theme, path.difficulty!),
                        const SizedBox(width: 6),
                        if (path.creditType != null && path.totalCredits != null)
                          CmeCreditBadge(
                            creditType: path.creditType!,
                            creditAmount: path.totalCredits,
                            compact: true,
                          ),
                        const Spacer(),
                        if (path.enrolledCount != null)
                          Text(
                            '${path.enrolledCount} enrolled',
                            style: theme.caption,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      path.title ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (path.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        path.description!,
                        style: theme.bodySecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Meta row
                    Row(
                      children: [
                        if (path.totalEvents != null) ...[
                          Icon(Icons.event_outlined,
                              size: 14, color: theme.textTertiary),
                          const SizedBox(width: 3),
                          Text('${path.totalEvents} events',
                              style: theme.caption),
                          const SizedBox(width: 12),
                        ],
                        if (path.estimatedHours != null) ...[
                          Icon(Icons.access_time,
                              size: 14, color: theme.textTertiary),
                          const SizedBox(width: 3),
                          Text('${path.estimatedHours}h',
                              style: theme.caption),
                        ],
                      ],
                    ),
                    // Progress bar
                    if (showProgress && path.isEnrolled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: path.progressPercentage / 100,
                                backgroundColor: theme.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.primary),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${path.progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyBadge(OneUITheme theme, String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = const Color(0xFF34C759);
      case 'advanced':
        color = const Color(0xFFFF3B30);
      default:
        color = const Color(0xFFFF9500);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty[0].toUpperCase() + difficulty.substring(1),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmpty(
      OneUITheme theme, String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: theme.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: theme.bodySecondary),
          Text(subtitle, style: theme.caption),
        ],
      ),
    );
  }
}

// ─── Learning Path Detail Screen ─────────────────────────────────────────────

class CmeLearningPathDetailScreen extends StatelessWidget {
  final String pathId;

  const CmeLearningPathDetailScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeLearningPathBloc()
        ..add(CmeLoadPathDetailEvent(pathId: pathId)),
      child: _PathDetailView(pathId: pathId),
    );
  }
}

class _PathDetailView extends StatelessWidget {
  final String pathId;
  const _PathDetailView({required this.pathId});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: BlocConsumer<CmeLearningPathBloc, CmeLearningPathState>(
        listener: (context, state) {
          if (state is CmeLearningPathEnrolledState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF34C759),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context
                .read<CmeLearningPathBloc>()
                .add(CmeLoadPathDetailEvent(pathId: pathId));
          }
        },
        builder: (context, state) {
          final bloc = context.read<CmeLearningPathBloc>();

          if (state is CmeLearningPathLoadingState &&
              bloc.selectedPath == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: theme.cardBackground,
                foregroundColor: theme.textPrimary,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is CmeLearningPathErrorState &&
              bloc.selectedPath == null) {
            return _buildError(context, theme, state.message);
          }

          final path = bloc.selectedPath;
          if (path == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                expandedHeight: path.imageUrl != null ? 180 : 0,
                pinned: true,
                backgroundColor: theme.cardBackground,
                foregroundColor: theme.textPrimary,
                flexibleSpace: path.imageUrl != null
                    ? FlexibleSpaceBar(
                        background: Image.network(
                          path.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: theme.primary.withValues(alpha: 0.1)),
                        ),
                      )
                    : null,
                title: Text(
                  path.title ?? 'Learning Path',
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 16),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      _buildBadges(theme, path),
                      const SizedBox(height: 14),
                      // Description
                      if (path.description != null) ...[
                        Text(path.description!, style: theme.bodyMedium),
                        const SizedBox(height: 14),
                      ],
                      // Stats row
                      _buildStats(theme, path),
                      const SizedBox(height: 14),
                      // Progress (if enrolled)
                      if (path.isEnrolled)
                        _buildProgressCard(theme, path),
                      if (path.isEnrolled) const SizedBox(height: 14),
                      // Action button
                      _buildActionButton(context, theme, path),
                      const SizedBox(height: 20),
                      // Events list
                      if (path.events != null && path.events!.isNotEmpty) ...[
                        Text('Path Events', style: theme.titleSmall),
                        const SizedBox(height: 10),
                        ...path.events!.asMap().entries.map((entry) {
                          return _buildEventItem(
                              theme, entry.key + 1, entry.value);
                        }),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadges(OneUITheme theme, CmeLearningPathData path) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (path.difficulty != null)
          _badge(theme, path.displayDifficulty, _diffColor(path.difficulty!)),
        if (path.specialty != null)
          _badge(theme, path.specialty!, theme.primary),
        if (path.category != null)
          _badge(theme, path.category!, const Color(0xFF5856D6)),
      ],
    );
  }

  Widget _badge(OneUITheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF34C759);
      case 'advanced':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFFFF9500);
    }
  }

  Widget _buildStats(OneUITheme theme, CmeLearningPathData path) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(theme, Icons.event_outlined,
              '${path.totalEvents ?? 0}', 'Events'),
          _statItem(theme, Icons.school_outlined,
              '${path.totalCredits ?? 0}', 'Credits'),
          _statItem(theme, Icons.access_time,
              '${path.estimatedHours ?? 0}h', 'Duration'),
          _statItem(theme, Icons.people_outline,
              '${path.enrolledCount ?? 0}', 'Enrolled'),
        ],
      ),
    );
  }

  Widget _statItem(
      OneUITheme theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary)),
        Text(label, style: theme.caption),
      ],
    );
  }

  Widget _buildProgressCard(OneUITheme theme, CmeLearningPathData path) {
    final enrollment = path.enrollment!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your Progress', style: theme.titleSmall),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: enrollment.isActive
                      ? theme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFFF9500).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  enrollment.isActive
                      ? 'Active'
                      : enrollment.isPaused
                          ? 'Paused'
                          : 'Completed',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: enrollment.isActive
                        ? theme.primary
                        : const Color(0xFFFF9500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: path.progressPercentage / 100,
              backgroundColor: theme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${enrollment.completedEvents ?? 0}/${path.totalEvents ?? 0} events',
                  style: theme.caption),
              Text(
                '${path.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, OneUITheme theme, CmeLearningPathData path) {
    if (path.isEnrolled) {
      final enrollment = path.enrollment!;
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: enrollment.isActive
                  ? () => context
                      .read<CmeLearningPathBloc>()
                      .add(CmePausePathEvent(enrollmentId: enrollment.id!))
                  : () => context
                      .read<CmeLearningPathBloc>()
                      .add(CmeResumePathEvent(enrollmentId: enrollment.id!)),
              icon: Icon(
                  enrollment.isActive ? Icons.pause : Icons.play_arrow,
                  size: 18),
              label: Text(enrollment.isActive ? 'Pause' : 'Resume',
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonSecondary,
                foregroundColor: theme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context
                  .read<CmeLearningPathBloc>()
                  .add(CmeUnenrollFromPathEvent(
                      enrollmentId: enrollment.id!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF3B30),
                side: const BorderSide(color: Color(0xFFFF3B30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Unenroll',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context
            .read<CmeLearningPathBloc>()
            .add(CmeEnrollInPathEvent(pathId: path.id!)),
        icon: const Icon(Icons.school_outlined, size: 18),
        label: const Text('Enroll in Path',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildEventItem(
      OneUITheme theme, int index, CmePathEventItem event) {
    final isCompleted = event.isCompleted == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF34C759).withValues(alpha: 0.04)
            : theme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF34C759).withValues(alpha: 0.3)
              : theme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF34C759)
                  : theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$index',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title ?? 'Event $index',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Row(
                  children: [
                    if (event.type != null)
                      Text(event.type!, style: theme.caption),
                    if (event.credits != null) ...[
                      const SizedBox(width: 8),
                      Text('${event.credits} credits',
                          style: theme.caption),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (event.isRequired == true)
            Icon(Icons.star, size: 16, color: const Color(0xFFFF9500)),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, OneUITheme theme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('Learning Path',
            style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<CmeLearningPathBloc>()
                  .add(CmeLoadPathDetailEvent(pathId: pathId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
