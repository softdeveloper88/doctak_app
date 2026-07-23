import 'dart:io';

import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_search_header.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Create / edit job — Role → Form fields → Promotion → Review.
class JobPostWizardScreen extends StatefulWidget {
  const JobPostWizardScreen({super.key, this.jobId});

  final String? jobId;

  @override
  State<JobPostWizardScreen> createState() => _JobPostWizardScreenState();
}

class _JobPostWizardScreenState extends State<JobPostWizardScreen> {
  int _step = 0;
  bool _loading = false;
  bool _bootstrapping = false;

  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _experience = TextEditingController();
  final _salary = TextEditingController();
  final _description = TextEditingController();
  final _externalLink = TextEditingController();
  final _openings = TextEditingController(text: '1');
  final _lastDate = TextEditingController();

  String _jobType = 'full_time';
  String _applyType = 'easy_apply';
  String _promoTier = 'free';
  String? _coverPath;
  List<Map<String, dynamic>> _countries = [];
  String? _countryId;

  /// All selectable specialties (id + name) and the chosen ones — mirrors
  /// the website wizard's multi-select "Specialties" tag input (max 8).
  List<Map<String, dynamic>> _allSpecialties = [];
  final List<Map<String, dynamic>> _selectedSpecialties = [];
  static const _maxSpecialties = 8;

  final _presetFields = <String>{
    'cover_letter',
    'years_experience',
    'expected_salary',
  };

  bool get isEdit => widget.jobId != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _bootstrapping = true);
    try {
      final results = await Future.wait([
        JobsNodeApiService.getCountries(),
        JobsNodeApiService.getSpecialties(),
      ]);
      _countries = results[0];
      _allSpecialties = results[1];
      if (isEdit) {
        final job = await JobsNodeApiService.getJobDetail(widget.jobId!);
        _title.text = job.title;
        _company.text = job.companyName ?? '';
        _location.text = job.location ?? '';
        _experience.text = job.experience ?? '';
        _preselectSpecialties(job.specialties.isNotEmpty
            ? job.specialties
            : (job.specialty ?? '')
                .split(RegExp('[,;]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList());
        _salary.text = job.salaryRange ?? '';
        _description.text = job.description ?? '';
        _externalLink.text = job.link ?? '';
        _jobType = job.jobType ?? 'full_time';
        _applyType = job.applyType;
        _promoTier = job.promotionTier ?? 'free';
        _coverPath = job.image;
        if (job.totalJobs != null) _openings.text = '${job.totalJobs}';
        if (job.lastDate != null) {
          _lastDate.text = job.lastDate!.split('T').first;
        }
        for (final f in job.applicationFields) {
          _presetFields.add(f.fieldKey);
        }
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  void _preselectSpecialties(List<String> names) {
    _selectedSpecialties.clear();
    for (final name in names) {
      final match = _allSpecialties.firstWhere(
        (s) =>
            (s['name']?.toString() ?? '').toLowerCase() == name.toLowerCase(),
        orElse: () => {'id': null, 'name': name},
      );
      if (_selectedSpecialties.length < _maxSpecialties) {
        _selectedSpecialties.add(match);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _location.dispose();
    _experience.dispose();
    _salary.dispose();
    _description.dispose();
    _externalLink.dispose();
    _openings.dispose();
    _lastDate.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      final path = result?.files.single.path;
      if (path == null) return;
      final uploaded = await JobsNodeApiService.uploadCover(File(path));
      if (uploaded != null) setState(() => _coverPath = uploaded);
    } catch (e) {
      toast(e.toString());
    }
  }

  Map<String, dynamic> _payload() {
    // Mirrors the website wizard: specialtyIds (job_specialities pivot) plus
    // a joined `specialty` string for legacy display/search.
    final specialtyIds = _selectedSpecialties
        .map((s) => int.tryParse('${s['id'] ?? ''}'))
        .whereType<int>()
        .toList();
    final specialtyNames = _selectedSpecialties
        .map((s) => s['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    return {
      'title': _title.text.trim(),
      'companyName': _company.text.trim(),
      'location': _location.text.trim(),
      'experience': _experience.text.trim(),
      'specialty': specialtyNames.isEmpty ? null : specialtyNames,
      'specialtyIds': specialtyIds,
      'salaryRange': _salary.text.trim(),
      'description': _description.text.trim(),
      'jobType': _jobType,
      'applyType': _applyType,
      'link': _applyType == 'external' ? _externalLink.text.trim() : null,
      'totalJobs': int.tryParse(_openings.text.trim()),
      'lastDate': _lastDate.text.trim().isEmpty ? null : _lastDate.text.trim(),
      'countryId': int.tryParse(_countryId ?? ''),
      'jobImage': _coverPath,
      'promotionTier': _promoTier,
      'applicationFields': _presetFields
          .map((k) => {'fieldKey': k, 'required': true})
          .toList(),
    };
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      toast('Title and location are required');
      setState(() => _step = 0);
      return;
    }
    if (_applyType == 'external' && _externalLink.text.trim().isEmpty) {
      toast('External apply link is required');
      setState(() => _step = 0);
      return;
    }
    setState(() => _loading = true);
    try {
      final body = _payload();
      String jobId;
      if (isEdit) {
        await JobsNodeApiService.updateJob(widget.jobId!, body);
        jobId = widget.jobId!;
      } else {
        jobId = await JobsNodeApiService.createJob(body);
      }

      if (_promoTier != 'free' && jobId.isNotEmpty) {
        final url = await JobsNodeApiService.createPromoteCheckout(
          jobId: jobId,
          tier: _promoTier,
          jobTitle: _title.text.trim(),
        );
        if (url != null && url.isNotEmpty) {
          await JobDisplayUtils.openExternalUrl(url);
          if (!mounted) return;
          toast(isEdit ? 'Job updated — finish payment to promote' : 'Job posted — finish payment to promote');
          // Return to Jobs Manage; payment-success deep link also lands here.
          Navigator.pop(context, true);
          return;
        }
      }

      if (!mounted) return;
      toast(isEdit ? 'Job updated' : 'Job posted');
      Navigator.pop(context, true);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: isEdit ? 'Edit job' : 'Post a job',
        subtitle: 'Step ${_step + 1} of 4',
      ),
      body: _bootstrapping
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  color: theme.primary,
                  backgroundColor: theme.surfaceVariant,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _step,
                    children: [
                      _roleStep(theme),
                      _fieldsStep(theme),
                      _promoStep(theme),
                      _reviewStep(theme),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        if (_step > 0)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _step -= 1),
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  if (_step < 3) {
                                    setState(() => _step += 1);
                                  } else {
                                    _submit();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primary,
                            minimumSize: const Size(140, 44),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_step == 3 ? 'Publish' : 'Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(OneUITheme theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: theme.textSecondary,
      ),
      filled: true,
      fillColor: theme.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 1.4),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: theme.textPrimary,
        ),
        decoration: _inputDecoration(theme, label),
      ),
    );
  }

  Widget _sectionCard(
    OneUITheme theme, {
    required String label,
    required List<Widget> children,
  }) {
    return JobsSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobSectionLabel(label),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Multi-select specialties — chips with remove + a search sheet,
  /// mirroring the website's TagSearchInput (max 8 tags).
  Widget _specialtiesPicker(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialties',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedSpecialties.map(
              (s) => Chip(
                label: Text(s['name']?.toString() ?? ''),
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
                backgroundColor: theme.accentSoft,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                deleteIcon: Icon(Icons.close_rounded,
                    size: 16, color: theme.primary),
                onDeleted: () =>
                    setState(() => _selectedSpecialties.remove(s)),
              ),
            ),
            if (_selectedSpecialties.length < _maxSpecialties)
              ActionChip(
                avatar: Icon(Icons.add_rounded, size: 18, color: theme.primary),
                label: Text(
                  _selectedSpecialties.isEmpty
                      ? 'Add specialty'
                      : 'Add more',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
                backgroundColor: theme.surfaceVariant,
                side: BorderSide(color: theme.border.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: _openSpecialtySheet,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSpecialtySheet() async {
    final theme = OneUITheme.of(context);
    final selectedNames = _selectedSpecialties
        .map((s) => (s['name']?.toString() ?? '').toLowerCase())
        .toSet();
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.trim().toLowerCase();
            final options = _allSpecialties.where((s) {
              final name = (s['name']?.toString() ?? '').toLowerCase();
              if (name.isEmpty || selectedNames.contains(name)) return false;
              return q.isEmpty || name.contains(q);
            }).toList();
            return Container(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
              ),
              height: MediaQuery.sizeOf(sheetContext).height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Select specialty', style: theme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setSheetState(() => query = v),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: theme.textPrimary,
                    ),
                    decoration: _inputDecoration(theme, 'Search specialties')
                        .copyWith(
                      prefixIcon: Icon(Icons.search_rounded,
                          color: theme.textTertiary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: options.isEmpty
                        ? Center(
                            child: Text('No specialties found',
                                style: theme.caption),
                          )
                        : ListView.builder(
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final s = options[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                leading: Icon(Icons.medical_services_outlined,
                                    size: 20, color: theme.primary),
                                title: Text(
                                  s['name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: theme.textPrimary,
                                  ),
                                ),
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(s),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (_selectedSpecialties.length < _maxSpecialties) {
          _selectedSpecialties.add(picked);
        }
      });
    }
  }

  Widget _roleStep(OneUITheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          theme,
          label: 'Role basics',
          children: [
            _field(_title, 'Job title *'),
            _field(_company, 'Company / hospital'),
            _field(_location, 'Location *'),
            if (_countries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _countryId,
                  isExpanded: true,
                  decoration: _inputDecoration(theme, 'Country'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                  dropdownColor: theme.cardBackground,
                  items: _countries
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id']?.toString(),
                          child: Text(
                            c['name']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _countryId = v),
                ),
              ),
            _specialtiesPicker(theme),
          ],
        ),
        _sectionCard(
          theme,
          label: 'Details',
          children: [
            _field(_experience, 'Experience'),
            _field(_salary, 'Salary range'),
            _field(_openings, 'Openings'),
            _field(_lastDate, 'Closing date (YYYY-MM-DD)'),
            DropdownButtonFormField<String>(
              value: _jobType,
              isExpanded: true,
              decoration: _inputDecoration(theme, 'Job type'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: theme.textPrimary,
              ),
              dropdownColor: theme.cardBackground,
              items: const [
                DropdownMenuItem(value: 'full_time', child: Text('Full-time')),
                DropdownMenuItem(value: 'part_time', child: Text('Part-time')),
                DropdownMenuItem(value: 'contract', child: Text('Contract')),
                DropdownMenuItem(value: 'locum', child: Text('Locum')),
                DropdownMenuItem(
                  value: 'internship',
                  child: Text('Internship'),
                ),
              ],
              onChanged: (v) => setState(() => _jobType = v ?? 'full_time'),
            ),
          ],
        ),
        _sectionCard(
          theme,
          label: 'How to apply',
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'easy_apply', label: Text('Easy Apply')),
                  ButtonSegment(value: 'external', label: Text('External')),
                ],
                selected: {_applyType},
                onSelectionChanged: (s) =>
                    setState(() => _applyType = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: theme.surfaceVariant,
                  foregroundColor: theme.textSecondary,
                  selectedBackgroundColor: theme.primary,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(color: theme.border.withValues(alpha: 0.6)),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_applyType == 'external') ...[
              const SizedBox(height: 12),
              _field(_externalLink, 'External apply URL *'),
            ],
          ],
        ),
        _sectionCard(
          theme,
          label: 'Description & media',
          children: [
            _field(_description, 'Description', maxLines: 8),
            OutlinedButton.icon(
              onPressed: _pickCover,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _coverPath == null ? 'Add cover image' : 'Cover selected',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldsStep(OneUITheme theme) {
    const options = {
      'cover_letter': 'Cover letter',
      'years_experience': 'Years of experience',
      'expected_salary': 'Expected salary',
      'current_location': 'Current location',
      'availability_date': 'Availability date',
      'top_skills': 'Top skills',
      'education_level': 'Education level',
      'willing_to_relocate': 'Willing to relocate',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        JobsSurfaceCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application questions',
                style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Candidates will answer these when using Easy Apply.',
                style: theme.caption.copyWith(color: theme.textSecondary),
              ),
              const SizedBox(height: 8),
              ...options.entries.map(
                (e) => CheckboxListTile(
                  value: _presetFields.contains(e.key),
                  contentPadding: EdgeInsets.zero,
                  activeColor: theme.primary,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _presetFields.add(e.key);
                    } else {
                      _presetFields.remove(e.key);
                    }
                  }),
                  title: Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promoStep(OneUITheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        JobsSurfaceCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Promotion', style: theme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Paid tiers open website checkout. After payment you’ll return to the app.',
                style: theme.caption.copyWith(color: theme.textSecondary),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'free',
                groupValue: _promoTier,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primary,
                onChanged: (v) => setState(() => _promoTier = v!),
                title: const Text('Free listing'),
              ),
              RadioListTile<String>(
                value: 'standard',
                groupValue: _promoTier,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primary,
                onChanged: (v) => setState(() => _promoTier = v!),
                title: const Text('Standard — \$49'),
                subtitle: const Text('Featured for 30 days'),
              ),
              RadioListTile<String>(
                value: 'premium',
                groupValue: _promoTier,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primary,
                onChanged: (v) => setState(() => _promoTier = v!),
                title: const Text('Premium — \$149'),
                subtitle: const Text('Top placement + highlight'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(OneUITheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        JobsSurfaceCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review', style: theme.titleSmall),
              const SizedBox(height: 12),
              Text(_title.text, style: theme.titleMedium),
              Text(
                '${_company.text} · ${_location.text}',
                style: theme.bodyMedium.copyWith(color: theme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: $_jobType · Apply: $_applyType · Promo: $_promoTier',
                style: theme.bodyMedium,
              ),
              if (_selectedSpecialties.isNotEmpty)
                Text(
                  'Specialties: ${_selectedSpecialties.map((s) => s['name']).join(', ')}',
                  style: theme.bodyMedium,
                ),
              Text(
                'Questions: ${_presetFields.length}',
                style: theme.bodyMedium,
              ),
              if (_description.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _description.text,
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis,
                  style: theme.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
