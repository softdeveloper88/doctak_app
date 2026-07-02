import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/survey_screen/survey_fill_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Browse available surveys (loaded from home feed pool).
class SurveysBrowseScreen extends StatefulWidget {
  const SurveysBrowseScreen({super.key});

  @override
  State<SurveysBrowseScreen> createState() => _SurveysBrowseScreenState();
}

class _SurveysBrowseScreenState extends State<SurveysBrowseScreen> {
  final SharedApiService _api = SharedApiService();
  List<FeedItem> _surveys = [];
  bool _loading = true;
  String? _error;

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
    final items = await _api.fetchSurveysForFeed(limit: 30);
    if (!mounted) return;
    setState(() {
      _surveys = items;
      _loading = false;
      if (items.isEmpty) _error = 'No surveys available right now.';
    });
  }

  Future<void> _openSurvey(FeedItem item) async {
    final completed = await SurveyFillScreen(surveyId: item.id).launch(context);
    if (completed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(title: 'Surveys', centerTitle: true),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: PostShimmerLoader(itemCount: 4),
            )
          : _error != null
              ? RetryWidget(errorMessage: _error!, onRetry: _load)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _surveys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _surveys[index];
                    final title = item.str('title') ?? 'Survey';
                    final org = item.str('organizationName') ?? 'Research';
                    final questions = item.intVal('questionCount');

                    return FeedCardShell(
                      child: InkWell(
                        onTap: () => _openSurvey(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FeedBadge(label: 'Survey', color: theme.primary),
                                  const Spacer(),
                                  if (questions > 0)
                                    Text('$questions questions', style: theme.caption),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(org, style: theme.caption),
                              const SizedBox(height: 4),
                              Text(title, style: theme.titleSmall),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FeedAccentButton(
                                  label: 'Respond',
                                  onTap: () => _openSurvey(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
