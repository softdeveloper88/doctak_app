import 'dart:io';

import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

Future<bool?> showApplyWizard({
  required BuildContext context,
  required JobDetailDto job,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ApplyWizardSheet(job: job),
  );
}

class ApplyWizardSheet extends StatefulWidget {
  const ApplyWizardSheet({super.key, required this.job});
  final JobDetailDto job;

  @override
  State<ApplyWizardSheet> createState() => _ApplyWizardSheetState();
}

class _ApplyWizardSheetState extends State<ApplyWizardSheet> {
  int _step = 0;
  File? _cvFile;
  JobSavedCvDto? _selectedSaved;
  final _cvTextCtrl = TextEditingController();
  final _fieldCtrls = <String, TextEditingController>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.job.applicationFields) {
      _fieldCtrls[f.fieldKey] = TextEditingController();
    }
    if (widget.job.savedCvs.isNotEmpty) {
      _selectedSaved = widget.job.savedCvs.firstWhere(
        (c) => c.isDefault,
        orElse: () => widget.job.savedCvs.first,
      );
    }
  }

  @override
  void dispose() {
    _cvTextCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final file = File(path);
      if (await file.length() > 5 * 1024 * 1024) {
        toast('CV must be 5MB or smaller');
        return;
      }
      setState(() {
        _cvFile = file;
        _selectedSaved = null;
      });
    } catch (e) {
      toast('Couldn’t pick file: $e');
    }
  }

  bool get _cvReady =>
      _cvFile != null ||
      _selectedSaved != null ||
      _cvTextCtrl.text.trim().length >= 40;

  Map<String, dynamic> get _extraFields {
    final map = <String, dynamic>{};
    for (final f in widget.job.applicationFields) {
      final v = _fieldCtrls[f.fieldKey]?.text.trim() ?? '';
      if (v.isNotEmpty) map[f.fieldKey] = v;
    }
    return map;
  }

  String? _validateFields() {
    for (final f in widget.job.applicationFields) {
      if (!f.required) continue;
      final v = _fieldCtrls[f.fieldKey]?.text.trim() ?? '';
      if (v.isEmpty) return '${f.label ?? f.fieldKey} is required';
    }
    return null;
  }

  Future<void> _submit() async {
    final fieldErr = _validateFields();
    if (fieldErr != null) {
      toast(fieldErr);
      return;
    }
    if (!_cvReady) {
      toast('Add a CV or paste resume text');
      return;
    }
    setState(() => _submitting = true);
    try {
      await JobsNodeApiService.applyToJob(
        jobId: widget.job.id,
        cvFile: _cvFile,
        existingCvPath: _selectedSaved?.path,
        cvText: _cvFile == null && _selectedSaved == null
            ? _cvTextCtrl.text.trim()
            : null,
        extraFields: _extraFields,
      );
      if (!mounted) return;
      toast('Application submitted');
      Navigator.pop(context, true);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final fields = widget.job.applicationFields;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('Easy Apply', style: theme.titleMedium),
          Text(
            widget.job.title,
            style: theme.caption.copyWith(color: theme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepDot(theme, 0, 'CV'),
              Expanded(child: Divider(color: theme.surfaceVariant)),
              _stepDot(theme, 1, 'Details'),
              Expanded(child: Divider(color: theme.surfaceVariant)),
              _stepDot(theme, 2, 'Review'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _cvStep(theme),
                _fieldsStep(theme, fields),
                _reviewStep(theme, fields),
              ],
            ),
          ),
          Row(
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _step -= 1),
                  child: const Text('Back'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () {
                        if (_step == 0) {
                          if (!_cvReady) {
                            toast('Add a CV first');
                            return;
                          }
                          setState(() => _step = fields.isEmpty ? 2 : 1);
                          return;
                        }
                        if (_step == 1) {
                          final err = _validateFields();
                          if (err != null) {
                            toast(err);
                            return;
                          }
                          setState(() => _step = 2);
                          return;
                        }
                        _submit();
                      },
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 2 ? 'Submit' : 'Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(OneUITheme theme, int index, String label) {
    final active = _step >= index;
    final done = _step > index;
    return Column(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: active ? theme.primary : theme.surfaceVariant,
          child: done
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? Colors.white : theme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.caption.copyWith(
            color: active ? theme.primary : theme.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _cvOptionCard({
    required OneUITheme theme,
    required bool selected,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.primary.withValues(alpha: 0.08)
              : theme.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primary : theme.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _cvStep(OneUITheme theme) {
    return ListView(
      children: [
        if (widget.job.savedCvs.isNotEmpty) ...[
          Text(
            'Saved CVs',
            style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...widget.job.savedCvs.map((cv) {
            final selected = _selectedSaved?.id == cv.id && _cvFile == null;
            return _cvOptionCard(
              theme: theme,
              selected: selected,
              onTap: () => setState(() {
                _selectedSaved = cv;
                _cvFile = null;
              }),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: selected ? theme.primary : theme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cv.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (cv.isDefault)
                          Text(
                            'Default',
                            style: theme.caption
                                .copyWith(color: theme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? theme.primary : theme.textSecondary,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
        _cvOptionCard(
          theme: theme,
          selected: _cvFile != null,
          onTap: _pickCv,
          child: Row(
            children: [
              Icon(
                Icons.upload_file_outlined,
                color: _cvFile != null ? theme.primary : theme.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cvFile == null
                      ? 'Upload CV (PDF / Word)'
                      : _cvFile!.path.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _cvFile != null ? theme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: theme.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR PASTE RESUME TEXT',
                style: theme.caption.copyWith(
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.divider)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cvTextCtrl,
          maxLines: 8,
          onChanged: (_) => setState(() {
            if (_cvTextCtrl.text.trim().isNotEmpty) {
              _cvFile = null;
              _selectedSaved = null;
            }
          }),
          decoration: InputDecoration(
            hintText: 'Paste your CV text here (min. 40 characters)…',
            filled: true,
            fillColor: theme.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _fieldsStep(OneUITheme theme, List<JobApplicationFieldDto> fields) {
    if (fields.isEmpty) {
      return Center(
        child: Text(
          'No extra questions for this role.',
          style: theme.bodyMedium.copyWith(color: theme.textSecondary),
        ),
      );
    }
    return ListView(
      children: [
        for (final f in fields) ...[
          Text(
            '${f.label ?? f.fieldKey}${f.required ? ' *' : ''}',
            style: theme.bodySecondary,
          ),
          const SizedBox(height: 6),
          if (f.type == 'select' && f.options.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _fieldCtrls[f.fieldKey]!.text.isEmpty
                  ? null
                  : _fieldCtrls[f.fieldKey]!.text,
              items: f.options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _fieldCtrls[f.fieldKey]!.text = v ?? ''),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            TextField(
              controller: _fieldCtrls[f.fieldKey],
              maxLines: f.type == 'textarea' ? 4 : 1,
              keyboardType:
                  f.type == 'number' ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: f.placeholder,
                filled: true,
                fillColor: theme.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _reviewStep(OneUITheme theme, List<JobApplicationFieldDto> fields) {
    final answered = fields
        .where((f) => (_fieldCtrls[f.fieldKey]?.text.trim() ?? '').isNotEmpty)
        .toList();
    return ListView(
      children: [
        Text(
          'Review & submit',
          style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Double-check your details before sending your application.',
          style: theme.caption.copyWith(color: theme.textSecondary),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: theme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cvFile != null
                      ? _cvFile!.path.split('/').last
                      : _selectedSaved != null
                          ? _selectedSaved!.name
                          : 'Resume text (${_cvTextCtrl.text.trim().length} chars)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (answered.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Your answers',
            style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              children: [
                for (final f in answered)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            f.label ?? f.fieldKey,
                            style: theme.caption
                                .copyWith(color: theme.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _fieldCtrls[f.fieldKey]!.text.trim(),
                            style: theme.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
