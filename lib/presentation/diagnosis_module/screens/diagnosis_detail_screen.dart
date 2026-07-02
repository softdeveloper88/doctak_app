import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_bloc.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_event.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_state.dart';
import 'package:doctak_app/presentation/diagnosis_module/screens/diagnosis_create_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DiagnosisDetailScreen extends StatefulWidget {
  final int diagnosisId;

  const DiagnosisDetailScreen({super.key, required this.diagnosisId});

  @override
  State<DiagnosisDetailScreen> createState() => _DiagnosisDetailScreenState();
}

class _DiagnosisDetailScreenState extends State<DiagnosisDetailScreen> {
  late final DiagnosisBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = DiagnosisBloc();
    _bloc.add(LoadDiagnosisDetail(id: widget.diagnosisId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: 'Diagnosis Details',
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.textPrimary),
              color: theme.cardBackground,
              onSelected: (action) => _onMenuAction(action, context),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    Icon(Icons.share, size: 18, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Share', style: TextStyle(color: theme.textPrimary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Export PDF', style: TextStyle(color: theme.textPrimary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 18, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: theme.textPrimary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'reanalyze',
                  child: Row(children: [
                    Icon(Icons.auto_awesome, size: 18, color: theme.primary),
                    const SizedBox(width: 8),
                    Text('Re-analyze',
                        style: TextStyle(color: theme.textPrimary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: theme.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: theme.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: BlocConsumer<DiagnosisBloc, DiagnosisState>(
          listener: (context, state) {
            if (state is DiagnosisDeletedState) {
              Navigator.pop(context, true);
            } else if (state is DiagnosisDeleteErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.error),
              );
            } else if (state is DiagnosisAnalyzedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Analysis regenerated (${state.response.aiRemaining ?? 0} remaining today)'),
                  backgroundColor: theme.success,
                ),
              );
              _bloc.add(LoadDiagnosisDetail(id: widget.diagnosisId));
            } else if (state is DiagnosisAnalyzeErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.error),
              );
            }
          },
          builder: (context, state) {
            if (state is DiagnosisDetailLoadingState ||
                state is DiagnosisAnalyzingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DiagnosisDetailErrorState) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: theme.error, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message,
                        style: TextStyle(color: theme.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _bloc
                          .add(LoadDiagnosisDetail(id: widget.diagnosisId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is DiagnosisDetailLoadedState) {
              return _buildContent(theme, state.detail);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(OneUITheme theme, DiagnosisDetailResponse detail) {
    final d = detail.diagnosis;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info card
          _buildPatientInfoCard(theme, d),
          const SizedBox(height: 14),
          // AI Usage banner
          _buildUsageBanner(theme, detail.aiUsageInfo),
          const SizedBox(height: 14),
          // AI Analysis
          if (d.recommendationFromAi != null &&
              d.recommendationFromAi!.isNotEmpty)
            _buildAiAnalysisCard(theme, d),
          const SizedBox(height: 14),
          // Differentials
          if (detail.differentials.isNotEmpty)
            _buildDifferentialsCard(theme, detail.differentials),
          const SizedBox(height: 14),
          // Clinical data summary
          _buildClinicalDataCard(theme, d),
          const SizedBox(height: 14),
          // Related diagnoses
          if (detail.relatedDiagnoses.isNotEmpty)
            _buildRelatedCard(theme, detail.relatedDiagnoses),
          const SizedBox(height: 14),
          // Quick actions - new analysis from same patient
          _buildQuickActionsCard(theme, d),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(OneUITheme theme, DiagnosisModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: theme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.fullName ?? 'Patient',
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${d.age ?? "?"} years, ${_formatGender(d.gender)}',
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              _contentTypeBadge(theme, d.contentType ?? 'diagnoses'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chief Complaint',
                    style: TextStyle(
                        color: theme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  d.chiefComplaint ?? 'N/A',
                  style: TextStyle(color: theme.textPrimary, fontSize: 15),
                ),
              ],
            ),
          ),
          if (d.symptoms != null && d.symptoms!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symptoms',
                      style: TextStyle(
                          color: theme.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(d.symptoms!,
                      style:
                          TextStyle(color: theme.textPrimary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageBanner(OneUITheme theme, AiUsageInfo info) {
    final color = info.canAccess ? theme.primary : theme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            info.canAccess ? Icons.auto_awesome : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI Usage: ${info.dailyUsed}/${info.dailyLimit} today (${info.dailyRemaining} remaining)',
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisCard(OneUITheme theme, DiagnosisModel d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: d.recommendationFromAi!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary, height: 1.5),
              h1: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
              h2: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
              h3: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary),
              strong: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimary),
              listBullet: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
              code: TextStyle(fontFamily: 'monospace', fontSize: 13, backgroundColor: theme.isDark ? Colors.grey[800] : Colors.grey[200], color: theme.textPrimary),
              codeblockDecoration: BoxDecoration(
                color: theme.isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1),
              ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDifferentialsCard(
      OneUITheme theme, List<DifferentialItem> differentials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Differential Diagnoses',
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...differentials.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _probabilityColor(item.probability)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${item.probability}%',
                          style: TextStyle(
                            color: _probabilityColor(item.probability),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarkdownBody(
                            data: item.name,
                            shrinkWrap: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              strong: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          if (item.explanation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: MarkdownBody(
                                data: item.explanation,
                                shrinkWrap: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                      color: theme.textSecondary, fontSize: 13),
                                  strong: TextStyle(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  listBullet: TextStyle(
                                      color: theme.textSecondary, fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildClinicalDataCard(OneUITheme theme, DiagnosisModel d) {
    final sections = <_ClinicalSection>[];

    // Vitals
    final vitals = <String, String?>{
      'Temperature': d.temperature,
      'BP': d.bpSystolic != null ? '${d.bpSystolic}/${d.bpDiastolic}' : null,
      'Pulse': d.pulseRate,
      'Resp Rate': d.respiratoryRate,
      'O₂ Sat': d.o2Saturation != null ? '${d.o2Saturation}%' : null,
      'Pain': d.painScore,
      'Weight': d.weight != null ? '${d.weight} kg' : null,
      'Height': d.height != null ? '${d.height} cm' : null,
    }..removeWhere((_, v) => v == null || v.isEmpty);
    if (vitals.isNotEmpty) {
      sections.add(_ClinicalSection('Vital Signs', Icons.monitor_heart, vitals.cast()));
    }

    // History
    final history = <String, String?>{
      'Past Medical': d.pastMedicalConditions,
      'Medications': d.medicationName,
      'Allergies': d.allergen,
      'Family History': d.familyMedicalHistory,
      'Lifestyle': d.lifestyleHabits,
    }..removeWhere((_, v) => v == null || v.isEmpty);
    if (history.isNotEmpty) {
      sections.add(_ClinicalSection('Medical History', Icons.history, history.cast()));
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Data',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...sections.map((section) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(section.icon, size: 16, color: theme.textSecondary),
                      const SizedBox(width: 6),
                      Text(section.title,
                          style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: section.data.entries
                        .map((e) => Chip(
                              label: Text('${e.key}: ${e.value}',
                                  style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 12)),
                              backgroundColor: theme.surfaceVariant,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildRelatedCard(
      OneUITheme theme, List<DiagnosisModel> related) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Related Cases',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...related.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: theme.surfaceVariant,
                  radius: 18,
                  child: Text('${r.age}',
                      style: TextStyle(
                          color: theme.textSecondary, fontSize: 12)),
                ),
                title: Text(
                  r.chiefComplaint ?? 'N/A',
                  style: TextStyle(color: theme.textPrimary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_formatGender(r.gender)} • ${r.contentType ?? 'diagnosis'}',
                  style: TextStyle(color: theme.textTertiary, fontSize: 12),
                ),
                trailing:
                    Icon(Icons.chevron_right, color: theme.textTertiary),
                onTap: r.id != null
                    ? () => AppNavigator.push(
                          context,
                          DiagnosisDetailScreen(diagnosisId: r.id!),
                        )
                    : null,
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(OneUITheme theme, DiagnosisModel d) {
    final actions = [
      ('diagnoses', 'Differential Diagnosis', Icons.medical_services, const Color(0xFF0A84FF)),
      ('treatment', 'Treatment Plan', Icons.healing, const Color(0xFF34C759)),
      ('labs', 'Lab Recommendations', Icons.science, const Color(0xFFFF9500)),
      ('interactions', 'Drug Interactions', Icons.compare_arrows, const Color(0xFFFF3B30)),
      ('education', 'Patient Education', Icons.school, const Color(0xFF5AC8FA)),
      ('note', 'Clinical Note', Icons.note_alt, const Color(0xFF8E8E93)),
    ];
    // Filter out the current content type
    final filtered = actions.where((a) => a.$1 != d.contentType).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Generate a new analysis from this patient\'s data',
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((a) => ActionChip(
              avatar: Icon(a.$3, size: 16, color: a.$4),
              label: Text(a.$2,
                  style: TextStyle(color: theme.textPrimary, fontSize: 12)),
              backgroundColor: a.$4.withValues(alpha: 0.08),
              side: BorderSide(color: a.$4.withValues(alpha: 0.3)),
              onPressed: () {
                // Navigate to create screen with prefilled patient data and selected content type
                final prefilled = DiagnosisModel(
                  age: d.age,
                  gender: d.gender,
                  chiefComplaint: d.chiefComplaint,
                  symptoms: d.symptoms,
                  pastMedicalConditions: d.pastMedicalConditions,
                  medicationName: d.medicationName,
                  allergen: d.allergen,
                  familyMedicalHistory: d.familyMedicalHistory,
                  lifestyleHabits: d.lifestyleHabits,
                  temperature: d.temperature,
                  bpSystolic: d.bpSystolic,
                  bpDiastolic: d.bpDiastolic,
                  pulseRate: d.pulseRate,
                  respiratoryRate: d.respiratoryRate,
                  o2Saturation: d.o2Saturation,
                  painScore: d.painScore,
                  weight: d.weight,
                  height: d.height,
                  generalAppearance: d.generalAppearance,
                  heent: d.heent,
                  cardiovascular: d.cardiovascular,
                  respiratoryExam: d.respiratoryExam,
                  gastrointestinal: d.gastrointestinal,
                  neurological: d.neurological,
                  skin: d.skin,
                  musculoskeletal: d.musculoskeletal,
                  otherFindings: d.otherFindings,
                  cbcResults: d.cbcResults,
                  bmpResults: d.bmpResults,
                  lftResults: d.lftResults,
                  coagulationResults: d.coagulationResults,
                  otherLabResults: d.otherLabResults,
                  xrayResults: d.xrayResults,
                  ctResults: d.ctResults,
                  mriResults: d.mriResults,
                  ultrasoundResults: d.ultrasoundResults,
                  otherImaging: d.otherImaging,
                  contentType: a.$1,
                );
                AppNavigator.push(
                  context,
                  DiagnosisCreateScreen(
                    existingDiagnosis: prefilled,
                  ),
                ).then((result) {
                  if (result == true) {
                    _bloc.add(LoadDiagnosisDetail(id: widget.diagnosisId));
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _contentTypeBadge(OneUITheme theme, String type) {
    final info = _getContentTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.$1, size: 14, color: info.$2),
          const SizedBox(width: 4),
          Text(info.$3,
              style: TextStyle(
                  color: info.$2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _probabilityColor(int prob) {
    if (prob >= 70) return const Color(0xFFFF3B30);
    if (prob >= 40) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

  (IconData, Color, String) _getContentTypeInfo(String type) {
    switch (type) {
      case 'treatment':
        return (Icons.healing, const Color(0xFF34C759), 'Treatment');
      case 'labs':
        return (Icons.science, const Color(0xFFFF9500), 'Labs');
      case 'interactions':
        return (Icons.compare_arrows, const Color(0xFFFF3B30), 'Interactions');
      case 'education':
        return (Icons.school, const Color(0xFF5AC8FA), 'Education');
      case 'note':
        return (Icons.note_alt, const Color(0xFF8E8E93), 'Note');
      default:
        return (Icons.medical_services, const Color(0xFF0A84FF), 'Diagnosis');
    }
  }

  String _formatGender(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'non-binary':
        return 'Non-Binary';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Prefer Not to Say';
      default:
        return gender ?? 'Unknown';
    }
  }

  void _onMenuAction(String action, BuildContext context) {
    final state = _bloc.state;
    switch (action) {
      case 'share':
        if (state is DiagnosisDetailLoadedState) {
          _shareDiagnosis(state.detail, context);
        }
        break;
      case 'export':
        if (state is DiagnosisDetailLoadedState) {
          _exportPdf(state.detail, context);
        }
        break;
      case 'edit':
        if (state is DiagnosisDetailLoadedState) {
          AppNavigator.push(
            context,
            DiagnosisCreateScreen(
              existingDiagnosis: state.detail.diagnosis,
            ),
          ).then((result) {
            if (result == true) {
              _bloc.add(LoadDiagnosisDetail(id: widget.diagnosisId));
            }
          });
        }
        break;
      case 'reanalyze':
        _showReanalyzeSheet(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showReanalyzeSheet(BuildContext context) {
    final theme = OneUITheme.of(context);
    final types = [
      ('diagnoses', 'Differential Diagnosis', Icons.medical_services),
      ('treatment', 'Treatment Plan', Icons.healing),
      ('labs', 'Lab Recommendations', Icons.science),
      ('interactions', 'Drug Interactions', Icons.compare_arrows),
      ('education', 'Patient Education', Icons.school),
      ('note', 'Clinical Note (SOAP)', Icons.note_alt),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Regenerate Analysis',
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Select the type of AI analysis to regenerate:',
                style: TextStyle(color: theme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            ...types.map((t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(t.$3, color: theme.primary),
                  title: Text(t.$2,
                      style: TextStyle(color: theme.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _bloc.add(AnalyzeDiagnosis(
                        id: widget.diagnosisId, contentType: t.$1));
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text('Delete Diagnosis', style: TextStyle(color: theme.textPrimary)),
        content: Text('Are you sure you want to delete this diagnosis?',
            style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(DeleteDiagnosis(id: widget.diagnosisId));
            },
            style: FilledButton.styleFrom(backgroundColor: theme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _shareDiagnosis(DiagnosisDetailResponse detail, BuildContext context) {
    final theme = OneUITheme.of(context);
    final d = detail.diagnosis;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final shareText = _buildShareText(d, detail.differentials);
        final link = 'https://doctak.net/diagnosis/${d.id}';
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share Diagnosis',
                  style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link, color: theme.primary),
                title: Text('Copy Link',
                    style: TextStyle(color: theme.textPrimary)),
                subtitle: Text(link,
                    style: TextStyle(
                        color: theme.textTertiary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Link copied to clipboard'),
                      backgroundColor: theme.success,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.share, color: theme.primary),
                title: Text('Share Report',
                    style: TextStyle(color: theme.textPrimary)),
                subtitle: Text('Share diagnosis summary as text',
                    style: TextStyle(
                        color: theme.textTertiary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(shareText,
                      subject: 'Diagnosis Report - ${d.chiefComplaint ?? ""}');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _buildShareText(
      DiagnosisModel d, List<DifferentialItem> differentials) {
    final buf = StringBuffer();
    buf.writeln('=== Diagnosis Report ===');
    buf.writeln();
    buf.writeln('Patient: ${d.fullName ?? "N/A"}, ${d.age ?? "?"} years, ${_formatGender(d.gender)}');
    buf.writeln('Chief Complaint: ${d.chiefComplaint ?? "N/A"}');
    if (d.symptoms != null && d.symptoms!.isNotEmpty) {
      buf.writeln('Symptoms: ${d.symptoms}');
    }
    buf.writeln('Analysis Type: ${d.contentType ?? "diagnoses"}');
    buf.writeln();
    if (d.recommendationFromAi != null && d.recommendationFromAi!.isNotEmpty) {
      buf.writeln('--- AI Analysis ---');
      buf.writeln(d.recommendationFromAi);
      buf.writeln();
    }
    if (differentials.isNotEmpty) {
      buf.writeln('--- Differential Diagnoses ---');
      for (final item in differentials) {
        buf.writeln('• ${item.name} (${item.probability}%) - ${item.explanation}');
      }
      buf.writeln();
    }
    buf.writeln('Generated via DocTak');
    buf.writeln('https://doctak.net/diagnosis/${d.id}');
    return buf.toString();
  }

  void _exportPdf(DiagnosisDetailResponse detail, BuildContext context) {
    final d = detail.diagnosis;
    final shareText = _buildShareText(d, detail.differentials);
    // Share as text report (PDF generation requires server-side support)
    Share.share(shareText,
        subject: 'Diagnosis Report - ${d.chiefComplaint ?? ""}');
  }
}

class _ClinicalSection {
  final String title;
  final IconData icon;
  final Map<String, String> data;

  _ClinicalSection(this.title, this.icon, this.data);
}
