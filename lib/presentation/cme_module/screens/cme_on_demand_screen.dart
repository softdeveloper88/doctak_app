import 'package:doctak_app/data/models/cme/cme_gamification_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_on_demand_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_on_demand_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_on_demand_state.dart';import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class CmeOnDemandScreen extends StatelessWidget {
  final String eventId;

  const CmeOnDemandScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeOnDemandBloc()
        ..add(CmeLoadOnDemandModulesEvent(eventId: eventId)),
      child: const _OnDemandView(),
    );
  }
}

class _OnDemandView extends StatelessWidget {
  const _OnDemandView();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('On-Demand Content',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: BlocBuilder<CmeOnDemandBloc, CmeOnDemandState>(
        builder: (context, state) {
          if (state is CmeOnDemandLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CmeOnDemandErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.textTertiary),
                  const SizedBox(height: 12),
                  Text(state.message, style: theme.bodySecondary),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      // Retry not easily possible without eventId; show message
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final bloc = context.read<CmeOnDemandBloc>();

          // If viewing module detail
          if (state is CmeOnDemandDetailLoadedState ||
              state is CmeOnDemandSectionCompletedState) {
            final module = bloc.currentModule;
            if (module != null) {
              return _buildModuleDetail(context, theme, module);
            }
          }

          final modules = bloc.modules;

          if (modules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 64, color: theme.textTertiary),
                  const SizedBox(height: 12),
                  Text('No on-demand content', style: theme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Content will appear here when available',
                      style: theme.bodySecondary),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              return _buildModuleCard(context, theme, modules[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildModuleCard(
      BuildContext context, OneUITheme theme, CmeOnDemandModule module) {
    final isCompleted = module.isCompleted ?? false;

    return GestureDetector(
      onTap: () {
        if (module.id != null) {
          context.read<CmeOnDemandBloc>().add(
              CmeLoadOnDemandModuleDetailEvent(moduleId: module.id!));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (module.thumbnailUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        module.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.primary.withOpacity(0.1),
                          child: Icon(
                            _getTypeIcon(module.type),
                            size: 48,
                            color: theme.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      // Play overlay for video
                      if (module.type == 'video')
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.6),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      // Completion badge
                      if (isCompleted)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & difficulty row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTypeIcon(module.type),
                                size: 12, color: theme.primary),
                            const SizedBox(width: 4),
                            Text(
                              (module.type ?? 'Module').toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (module.difficulty != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(module.difficulty)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            module.difficulty!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  _getDifficultyColor(module.difficulty),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (module.averageRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              module.averageRating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    module.title ?? 'Untitled Module',
                    style: theme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (module.authorName != null) ...[
                    const SizedBox(height: 4),
                    Text('By ${module.authorName}', style: theme.caption),
                  ],
                  const SizedBox(height: 8),
                  // Meta row
                  Row(
                    children: [
                      if (module.durationMinutes != null) ...[
                        Icon(Icons.access_time,
                            size: 14, color: theme.textTertiary),
                        const SizedBox(width: 4),
                        Text('${module.durationMinutes} min',
                            style: theme.caption),
                        const SizedBox(width: 16),
                      ],
                      if (module.credits != null) ...[
                        Icon(Icons.school,
                            size: 14, color: theme.textTertiary),
                        const SizedBox(width: 4),
                        Text('${module.credits} credits',
                            style: theme.caption),
                      ],
                    ],
                  ),
                  // Progress bar
                  if (!isCompleted &&
                      (module.progressPercentage ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value:
                                  (module.progressPercentage ?? 0) / 100,
                              backgroundColor: theme.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primary),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${module.progressPercentage?.toInt() ?? 0}%',
                          style: theme.caption,
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
    );
  }

  Widget _buildModuleDetail(
      BuildContext context, OneUITheme theme, CmeOnDemandModule module) {
    return WillPopScope(
      onWillPop: () async {
        context.read<CmeOnDemandBloc>().add(CmeBackToModulesEvent());
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back to modules
            TextButton.icon(
              onPressed: () {
                context.read<CmeOnDemandBloc>().add(CmeBackToModulesEvent());
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to modules'),
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            // Module header
            Container(
              decoration: theme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(module.title ?? 'Module', style: theme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetaChip(theme, Icons.access_time,
                          '${module.durationMinutes ?? 0} min'),
                      const SizedBox(width: 8),
                      _buildMetaChip(theme, Icons.school,
                          '${module.credits ?? 0} credits'),
                      if (module.difficulty != null) ...[
                        const SizedBox(width: 8),
                        _buildMetaChip(
                            theme, Icons.signal_cellular_alt, module.difficulty!,
                            color: _getDifficultyColor(module.difficulty)),
                      ],
                    ],
                  ),
                  if (module.authorName != null) ...[
                    const SizedBox(height: 8),
                    Text('By ${module.authorName}', style: theme.bodySecondary),
                  ],
                  if (module.progressPercentage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Progress', style: theme.bodySecondary),
                        const Spacer(),
                        Text(
                          '${module.progressPercentage?.toInt() ?? 0}%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (module.progressPercentage ?? 0) / 100,
                        backgroundColor: theme.divider,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sections
            Text('Sections', style: theme.titleSmall),
            const SizedBox(height: 8),
            if (module.sections == null || module.sections!.isEmpty)
              Container(
                decoration: theme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('No sections available',
                      style: theme.bodySecondary),
                ),
              )
            else
              ...module.sections!.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return _buildSectionItem(
                    context, theme, section, module, index);
              }),
            // Open content URL
            if (module.contentUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(module.contentUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(_getTypeIcon(module.type)),
                  label: Text(module.type == 'video'
                      ? 'Watch Content'
                      : 'Open Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(BuildContext context, OneUITheme theme,
      CmeOnDemandSection section, CmeOnDemandModule module, int index) {
    final isCompleted = section.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: theme.cardDecoration,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF34C759).withOpacity(0.1)
                : theme.scaffoldBackground,
            border: Border.all(
              color: isCompleted ? const Color(0xFF34C759) : theme.divider,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check,
                    color: Color(0xFF34C759), size: 18)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
          ),
        ),
        title: Text(
          section.title ?? 'Section ${index + 1}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: theme.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(_getSectionTypeIcon(section.type),
                size: 12, color: theme.textTertiary),
            const SizedBox(width: 4),
            Text(section.type ?? 'Content', style: theme.caption),
            if (section.durationMinutes != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 12, color: theme.textTertiary),
              const SizedBox(width: 4),
              Text('${section.durationMinutes} min', style: theme.caption),
            ],
          ],
        ),
        trailing: !isCompleted
            ? IconButton(
                icon: Icon(Icons.play_circle_outline,
                    color: theme.primary),
                onPressed: () {
                  _openSectionContent(context, theme, section, module);
                },
              )
            : Icon(Icons.check_circle,
                color: const Color(0xFF34C759), size: 24),
        onTap: () {
          _openSectionContent(context, theme, section, module);
        },
      ),
    );
  }

  void _openSectionContent(BuildContext context, OneUITheme theme,
      CmeOnDemandSection section, CmeOnDemandModule module) {
    if (section.contentUrl != null) {
      final uri = Uri.tryParse(section.contentUrl!);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (section.htmlContent != null) {
      // Show HTML content in bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.title ?? 'Content',
                        style: theme.titleMedium,
                      ),
                    ),
                    // Mark complete button
                    TextButton(
                      onPressed: () {
                        if (module.id != null && section.id != null) {
                          context.read<CmeOnDemandBloc>().add(
                              CmeCompleteSectionEvent(
                                  moduleId: module.id!,
                                  sectionId: section.id!));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Mark Complete'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content - simple text rendering
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _stripHtml(section.htmlContent ?? ''),
                    style: theme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMetaChip(OneUITheme theme, IconData icon, String label,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? theme.textTertiary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? theme.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color ?? theme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return Icons.play_circle_filled;
      case 'article':
        return Icons.article;
      case 'interactive':
        return Icons.touch_app;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.play_circle_outline;
    }
  }

  IconData _getSectionTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'text':
        return Icons.description;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.article;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF34C759);
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
