import 'package:flutter/material.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import '../models/clinical_snapshot.dart';
import 'case_display_utils.dart';
import 'case_discussion_layout.dart';

/// Structured clinical case presentation matching the reference design.
class CaseClinicalDetail extends StatelessWidget {
  final ClinicalSnapshot snapshot;

  const CaseClinicalDetail({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CaseDiscussionLayout.cardInner,
        14,
        CaseDiscussionLayout.cardInner,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasPatientGrid) _PatientGrid(snapshot: snapshot, theme: theme),
          if (!snapshot.vitalSigns.isEmpty) ...[
            const SizedBox(height: 16),
            _VitalsRow(vitals: snapshot.vitalSigns, theme: theme),
          ],
          if (snapshot.labResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LabResultsList(labs: snapshot.labResults, theme: theme),
          ],
          if (snapshot.clinicalQuestion != null &&
              snapshot.clinicalQuestion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ClinicalQuestionBox(
              question: snapshot.clinicalQuestion!,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasPatientGrid =>
      snapshot.patientLabel != null ||
      (snapshot.chiefComplaint?.isNotEmpty ?? false) ||
      (snapshot.pastMedicalHistory?.isNotEmpty ?? false) ||
      (snapshot.medications?.isNotEmpty ?? false);
}

class _PatientGrid extends StatelessWidget {
  final ClinicalSnapshot snapshot;
  final OneUITheme theme;

  const _PatientGrid({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[];
    if (snapshot.patientLabel != null) {
      items.add((label: 'Patient', value: snapshot.patientLabel!));
    }
    if (snapshot.chiefComplaint?.isNotEmpty ?? false) {
      items.add((label: 'Chief Complaint', value: snapshot.chiefComplaint!));
    }
    if (snapshot.pastMedicalHistory?.isNotEmpty ?? false) {
      items.add((
        label: 'Past Medical HX',
        value: formatClinicalList(snapshot.pastMedicalHistory),
      ));
    }
    if (snapshot.medications?.isNotEmpty ?? false) {
      items.add((
        label: 'Medications',
        value: formatClinicalList(snapshot.medications),
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth > 360 && items.length > 1;
        if (!useTwoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < items.length - 1 ? 14 : 0),
                  child: _PatientGridItem(item: items[i], theme: theme),
                ),
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          final hasSecond = i + 1 < items.length;
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < items.length ? 14 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PatientGridItem(item: items[i], theme: theme)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: hasSecond
                        ? _PatientGridItem(item: items[i + 1], theme: theme)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}

class _PatientGridItem extends StatelessWidget {
  final ({String label, String value}) item;
  final OneUITheme theme;

  const _PatientGridItem({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontFamily: 'Poppins',
            color: theme.textTertiary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VitalsRow extends StatelessWidget {
  final VitalSignsMap vitals;
  final OneUITheme theme;

  const _VitalsRow({required this.vitals, required this.theme});

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, VitalSign sign})>[
      if (vitals.bp != null) (label: 'BP', sign: vitals.bp!),
      if (vitals.hr != null) (label: 'HR', sign: vitals.hr!),
      if (vitals.spo2 != null) (label: 'SPO2', sign: vitals.spo2!),
      if (vitals.temp != null) (label: 'TEMP', sign: vitals.temp!),
      if (vitals.rr != null) (label: 'RR', sign: vitals.rr!),
    ];

    return Row(
      children: entries.asMap().entries.map((indexed) {
        final entry = indexed.value;
        final isLast = indexed.key == entries.length - 1;
        final color = entry.sign.abnormal ? theme.error : theme.success;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.divider.withValues(alpha: 0.8)),
            ),
            child: Column(
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    fontFamily: 'Poppins',
                    color: theme.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.sign.value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LabResultsList extends StatelessWidget {
  final List<LabResult> labs;
  final OneUITheme theme;

  const _LabResultsList({required this.labs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: labs.asMap().entries.map((entry) {
        final lab = entry.value;
        final isLast = entry.key == labs.length - 1;
        final color = lab.abnormal ? theme.error : theme.success;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: theme.divider.withValues(alpha: 0.7),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lab.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${lab.value}${lab.abnormal ? ' ↑' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ClinicalQuestionBox extends StatelessWidget {
  final String question;
  final OneUITheme theme;

  const _ClinicalQuestionBox({required this.question, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(color: theme.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 15, color: theme.primary),
              const SizedBox(width: 6),
              Text(
                'CLINICAL QUESTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontFamily: 'Poppins',
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
