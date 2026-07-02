import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';
import '../models/clinical_snapshot.dart';
import '../repository/case_discussion_repository.dart';

/// Screen for creating or editing a case discussion.
/// Features:
///  - Title + description fields
///  - Tags input (comma-separated)
///  - Specialty selector
///  - Patient demographics (age, gender, ethnicity — anonymized)
///  - Clinical metadata (complexity, teaching value)
///  - File picker for attachments (images, docs)
///  - Edit mode with pre-populated fields
class CreateDiscussionScreen extends StatefulWidget {
  final CaseDiscussion? existingCase;

  const CreateDiscussionScreen({super.key, this.existingCase});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _ageController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _pastMedicalHxController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _clinicalQuestionController = TextEditingController();
  final _vitalBpController = TextEditingController();
  final _vitalHrController = TextEditingController();
  final _vitalSpo2Controller = TextEditingController();
  final _vitalTempController = TextEditingController();
  final _vitalRrController = TextEditingController();
  bool _vitalBpAbnormal = false;
  bool _vitalHrAbnormal = false;
  bool _vitalSpo2Abnormal = false;
  bool _vitalTempAbnormal = false;
  bool _vitalRrAbnormal = false;
  List<LabResult> _labResults = [];

  String? _selectedSpecialty;
  String? _selectedCountry;
  String? _selectedGender;
  String? _selectedComplexity;
  String? _selectedTeachingValue;
  String? _selectedEthnicity;
  bool _isAnonymized = true;

  // API-loaded filter data
  List<SpecialtyFilter> _loadedSpecialties = [];
  List<CountryFilter> _loadedCountries = [];
  bool _loadingFilters = true;

  List<PlatformFile> _selectedFiles = [];
  List<String> _existingFileUrls = [];
  CaseDiscussion? _editCase;

  bool get _isEditMode => widget.existingCase != null;

  static const _genderOptions = ['male', 'female', 'other'];
  static const _ethnicityOptions = [
    'Asian',
    'Black',
    'Caucasian',
    'Hispanic',
    'Middle Eastern',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _editCase = widget.existingCase;
      _applyCaseToForm(_editCase!);
      _refreshEditCase();
    }
    _loadFilterData();
  }

  Future<void> _refreshEditCase() async {
    final caseId = widget.existingCase?.id;
    if (caseId == null) return;

    try {
      final repo = CaseDiscussionRepository(
        baseUrl: AppData.base2,
        getAuthToken: () => AppData.userToken ?? '',
      );
      final fresh = await repo.getCaseDiscussion(caseId);
      if (!mounted) return;
      setState(() {
        _editCase = fresh;
        _applyCaseToForm(fresh);
      });
    } catch (_) {}
  }

  Future<void> _loadFilterData() async {
    try {
      final repo = CaseDiscussionRepository(
        baseUrl: AppData.base2,
        getAuthToken: () => AppData.userToken ?? '',
      );
      final data = await repo.getFilterData();
      if (mounted) {
        setState(() {
          _loadedSpecialties = data['specialties'] as List<SpecialtyFilter>;
          _loadedCountries = data['countries'] as List<CountryFilter>;
          _loadingFilters = false;
          if (_isEditMode && _editCase != null) {
            _selectedSpecialty = _resolveSpecialtyName(_editCase!);
            _selectedCountry = _resolveCountryName(_editCase!);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  void _applyCaseToForm(CaseDiscussion c) {
    _titleController.text = c.title;
    _descriptionController.text = c.description;
    _tagsController.text = c.parsedTags.join(', ');
    _selectedSpecialty = _resolveSpecialtyName(c);
    _selectedCountry = _resolveCountryName(c);

    if (c.metadata != null) {
      _selectedComplexity = _normalizeLevel(c.metadata!.clinicalComplexity);
      _selectedTeachingValue = _normalizeLevel(c.metadata!.teachingValue);
      _isAnonymized = c.metadata!.isAnonymized;

      final snapshot = c.metadata!.clinicalSnapshot;
      _ageController.text = snapshot.age ?? '';
      _selectedGender = _normalizeGender(snapshot.gender);
      _selectedEthnicity = _normalizeEthnicity(snapshot.ethnicity);
      _chiefComplaintController.text = snapshot.chiefComplaint ?? '';
      _pastMedicalHxController.text = snapshot.pastMedicalHistory ?? '';
      _medicationsController.text = snapshot.medications ?? '';
      _clinicalQuestionController.text = snapshot.clinicalQuestion ?? '';
      _vitalBpController.text = snapshot.vitalSigns.bp?.value ?? '';
      _vitalBpAbnormal = snapshot.vitalSigns.bp?.abnormal ?? false;
      _vitalHrController.text = snapshot.vitalSigns.hr?.value ?? '';
      _vitalHrAbnormal = snapshot.vitalSigns.hr?.abnormal ?? false;
      _vitalSpo2Controller.text = snapshot.vitalSigns.spo2?.value ?? '';
      _vitalSpo2Abnormal = snapshot.vitalSigns.spo2?.abnormal ?? false;
      _vitalTempController.text = snapshot.vitalSigns.temp?.value ?? '';
      _vitalTempAbnormal = snapshot.vitalSigns.temp?.abnormal ?? false;
      _vitalRrController.text = snapshot.vitalSigns.rr?.value ?? '';
      _vitalRrAbnormal = snapshot.vitalSigns.rr?.abnormal ?? false;
      _labResults = List<LabResult>.from(snapshot.labResults);
    }

    _existingFileUrls = c.attachments.map((a) => a.url).toList();
  }

  String? _normalizeLevel(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toLowerCase();
    if (v == 'low' || v == 'medium' || v == 'high') return v;
    return value;
  }

  String? _normalizeGender(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toLowerCase();
    return _genderOptions.contains(v) ? v : null;
  }

  String? _normalizeEthnicity(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toLowerCase().replaceAll(' ', '_');
    for (final item in _ethnicityOptions) {
      if (item.toLowerCase() == value.toLowerCase()) return item;
      if (item.toLowerCase().replaceAll(' ', '_') == normalized) return item;
    }
    const aliases = {
      'white': 'Caucasian',
      'middle_eastern': 'Middle Eastern',
      'mixed': 'Other',
    };
    return aliases[normalized];
  }

  String? _resolveSpecialtyName(CaseDiscussion c) {
    if (_loadedSpecialties.isNotEmpty && c.specialtyId != null) {
      for (final specialty in _loadedSpecialties) {
        if (specialty.id == c.specialtyId) return specialty.name;
      }
    }
    if (c.specialty != null && c.specialty!.isNotEmpty) {
      if (_loadedSpecialties.isEmpty) return c.specialty;
      for (final specialty in _loadedSpecialties) {
        if (specialty.name.toLowerCase() == c.specialty!.toLowerCase()) {
          return specialty.name;
        }
      }
      return c.specialty;
    }
    return null;
  }

  String? _resolveCountryName(CaseDiscussion c) {
    if (_loadedCountries.isNotEmpty && c.countryId != null) {
      for (final country in _loadedCountries) {
        if (country.id == c.countryId) return country.name;
      }
    }
    if (c.countryName != null && c.countryName!.isNotEmpty) {
      if (_loadedCountries.isEmpty) return c.countryName;
      for (final country in _loadedCountries) {
        if (country.name.toLowerCase() == c.countryName!.toLowerCase()) {
          return country.name;
        }
      }
      return c.countryName;
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _ageController.dispose();
    _chiefComplaintController.dispose();
    _pastMedicalHxController.dispose();
    _medicationsController.dispose();
    _clinicalQuestionController.dispose();
    _vitalBpController.dispose();
    _vitalHrController.dispose();
    _vitalSpo2Controller.dispose();
    _vitalTempController.dispose();
    _vitalRrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocListener<CreateDiscussionBloc, CreateDiscussionState>(
      listener: (context, state) {
        if (state is CreateDiscussionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.isUpdate
                  ? 'Case updated successfully'
                  : 'Case created successfully'),
              backgroundColor: theme.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is CreateDiscussionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: _isEditMode ? 'Edit Case' : 'New Case Discussion',
          actions: [
            BlocBuilder<CreateDiscussionBloc, CreateDiscussionState>(
              builder: (context, state) {
                final isLoading = state is CreateDiscussionLoading;
                return TextButton(
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update' : 'Post',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.primary,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──
                _SectionLabel(label: 'Title *', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _titleController,
                  hint: 'Case title (e.g., Unusual presentation of...)',
                  theme: theme,
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (v.trim().length < 10) {
                      return 'Title must be at least 10 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Description ──
                _SectionLabel(label: 'Description *', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _descriptionController,
                  hint: 'Describe the clinical scenario, presenting symptoms, examination findings...',
                  theme: theme,
                  maxLines: 8,
                  minLines: 4,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (v.trim().length < 30) {
                      return 'Description must be at least 30 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Tags ──
                _SectionLabel(label: 'Tags', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _tagsController,
                  hint: 'e.g., cardiology, rare-case, pediatric (comma-separated)',
                  theme: theme,
                ),

                const SizedBox(height: 20),

                // ── Specialty & Country Row ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Specialty', theme: theme),
                          const SizedBox(height: 6),
                          _loadingFilters
                              ? _LoadingDropdownPlaceholder(theme: theme)
                              : _DropdownField(
                                  value: _selectedSpecialty,
                                  hint: 'Select specialty',
                                  items: _loadedSpecialties
                                      .map((s) => s.name)
                                      .toList(),
                                  theme: theme,
                                  onChanged: (v) =>
                                      setState(() => _selectedSpecialty = v),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Country', theme: theme),
                          const SizedBox(height: 6),
                          _loadingFilters
                              ? _LoadingDropdownPlaceholder(theme: theme)
                              : _DropdownField(
                                  value: _selectedCountry,
                                  hint: 'Select country',
                                  items: _loadedCountries
                                      .map((c) => c.name)
                                      .toList(),
                                  theme: theme,
                                  onChanged: (v) =>
                                      setState(() => _selectedCountry = v),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Patient Demographics ──
                _SectionDivider(
                    label: 'Patient Demographics', theme: theme),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Age', theme: theme),
                          const SizedBox(height: 6),
                          _StyledTextField(
                            controller: _ageController,
                            hint: 'e.g., 45',
                            theme: theme,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Gender', theme: theme),
                          const SizedBox(height: 6),
                          _DropdownField(
                            value: _selectedGender,
                            hint: 'Select',
                            items: _genderOptions,
                            theme: theme,
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Ethnicity', theme: theme),
                          const SizedBox(height: 6),
                          _DropdownField(
                            value: _selectedEthnicity,
                            hint: 'Select',
                            items: _ethnicityOptions,
                            theme: theme,
                            onChanged: (v) =>
                                setState(() => _selectedEthnicity = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Anonymized toggle
                Row(
                  children: [
                    Switch(
                      value: _isAnonymized,
                      activeThumbColor: theme.primary,
                      onChanged: (v) =>
                          setState(() => _isAnonymized = v),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Patient identity is anonymized',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Clinical Presentation ──
                _SectionDivider(
                    label: 'Clinical Presentation', theme: theme),
                const SizedBox(height: 12),
                _SectionLabel(label: 'Chief Complaint', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _chiefComplaintController,
                  hint: 'e.g. Crushing chest pain radiating to left arm with SOB',
                  theme: theme,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Past Medical History', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _pastMedicalHxController,
                  hint: 'e.g. DM Type 2, MI (2019), HTN',
                  theme: theme,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Medications', theme: theme),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _medicationsController,
                  hint: 'e.g. Metformin, Aspirin, Ramipril',
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _SectionDivider(label: 'Vital Signs', theme: theme),
                const SizedBox(height: 12),
                _VitalSignField(
                  label: 'BP',
                  controller: _vitalBpController,
                  abnormal: _vitalBpAbnormal,
                  theme: theme,
                  onAbnormalChanged: (v) => setState(() => _vitalBpAbnormal = v),
                ),
                const SizedBox(height: 10),
                _VitalSignField(
                  label: 'HR',
                  controller: _vitalHrController,
                  abnormal: _vitalHrAbnormal,
                  theme: theme,
                  onAbnormalChanged: (v) => setState(() => _vitalHrAbnormal = v),
                ),
                const SizedBox(height: 10),
                _VitalSignField(
                  label: 'SPO2',
                  controller: _vitalSpo2Controller,
                  abnormal: _vitalSpo2Abnormal,
                  theme: theme,
                  onAbnormalChanged: (v) => setState(() => _vitalSpo2Abnormal = v),
                ),
                const SizedBox(height: 10),
                _VitalSignField(
                  label: 'TEMP',
                  controller: _vitalTempController,
                  abnormal: _vitalTempAbnormal,
                  theme: theme,
                  onAbnormalChanged: (v) => setState(() => _vitalTempAbnormal = v),
                ),
                const SizedBox(height: 10),
                _VitalSignField(
                  label: 'RR',
                  controller: _vitalRrController,
                  abnormal: _vitalRrAbnormal,
                  theme: theme,
                  onAbnormalChanged: (v) => setState(() => _vitalRrAbnormal = v),
                ),
                const SizedBox(height: 20),
                _SectionDivider(label: 'Lab Results', theme: theme),
                const SizedBox(height: 12),
                ..._labResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lab = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LabResultRow(
                      lab: lab,
                      theme: theme,
                      onChanged: (updated) {
                        setState(() => _labResults[index] = updated);
                      },
                      onRemove: () {
                        setState(() => _labResults.removeAt(index));
                      },
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _labResults.add(const LabResult(name: '', value: ''));
                    });
                  },
                  icon: Icon(Icons.add, size: 18, color: theme.primary),
                  label: Text(
                    'Add lab result',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionDivider(label: 'Clinical Question', theme: theme),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _clinicalQuestionController,
                  hint: 'What is the optimal management strategy given...',
                  theme: theme,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                // ── Clinical Metadata ──
                _SectionDivider(
                    label: 'Clinical Metadata', theme: theme),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              label: 'Complexity', theme: theme),
                          const SizedBox(height: 6),
                          _DropdownField(
                            value: _selectedComplexity,
                            hint: 'Select level',
                            items: const [
                              'low',
                              'medium',
                              'high',
                            ],
                            theme: theme,
                            onChanged: (v) =>
                                setState(() => _selectedComplexity = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              label: 'Teaching Value', theme: theme),
                          const SizedBox(height: 6),
                          _DropdownField(
                            value: _selectedTeachingValue,
                            hint: 'Select level',
                            items: const [
                              'low',
                              'medium',
                              'high',
                            ],
                            theme: theme,
                            onChanged: (v) =>
                                setState(
                                    () => _selectedTeachingValue = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Attachments ──
                _SectionDivider(label: 'Attachments', theme: theme),
                const SizedBox(height: 12),

                // Existing files (edit mode)
                if (_existingFileUrls.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _existingFileUrls.asMap().entries.map((e) {
                      return _ExistingFileTile(
                        url: e.value,
                        theme: theme,
                        onRemove: () {
                          setState(() {
                            _existingFileUrls.removeAt(e.key);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // New files
                if (_selectedFiles.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedFiles.asMap().entries.map((e) {
                      return _NewFileTile(
                        file: e.value,
                        theme: theme,
                        onRemove: () {
                          setState(() {
                            _selectedFiles.removeAt(e.key);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Add files button
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text(
                    'Add Files',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(
                        color: theme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported: Images (JPEG, PNG), Documents (PDF, DOC). Max 10MB each.',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    color: theme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        'pdf', 'doc', 'docx', 'xls', 'xlsx'
      ],
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final snapshot = ClinicalSnapshot(
      age: _ageController.text.trim().isNotEmpty
          ? _ageController.text.trim()
          : null,
      gender: _selectedGender,
      ethnicity: _selectedEthnicity,
      chiefComplaint: _chiefComplaintController.text.trim().isNotEmpty
          ? _chiefComplaintController.text.trim()
          : null,
      pastMedicalHistory: _pastMedicalHxController.text.trim().isNotEmpty
          ? _pastMedicalHxController.text.trim()
          : null,
      medications: _medicationsController.text.trim().isNotEmpty
          ? _medicationsController.text.trim()
          : null,
      vitalSigns: VitalSignsMap(
        bp: _vitalBpController.text.trim().isNotEmpty
            ? VitalSign(
                value: _vitalBpController.text.trim(),
                abnormal: _vitalBpAbnormal,
              )
            : null,
        hr: _vitalHrController.text.trim().isNotEmpty
            ? VitalSign(
                value: _vitalHrController.text.trim(),
                abnormal: _vitalHrAbnormal,
              )
            : null,
        spo2: _vitalSpo2Controller.text.trim().isNotEmpty
            ? VitalSign(
                value: _vitalSpo2Controller.text.trim(),
                abnormal: _vitalSpo2Abnormal,
              )
            : null,
        temp: _vitalTempController.text.trim().isNotEmpty
            ? VitalSign(
                value: _vitalTempController.text.trim(),
                abnormal: _vitalTempAbnormal,
              )
            : null,
        rr: _vitalRrController.text.trim().isNotEmpty
            ? VitalSign(
                value: _vitalRrController.text.trim(),
                abnormal: _vitalRrAbnormal,
              )
            : null,
      ),
      labResults: _labResults
          .where((l) => l.name.trim().isNotEmpty && l.value.trim().isNotEmpty)
          .toList(),
      clinicalQuestion: _clinicalQuestionController.text.trim().isNotEmpty
          ? _clinicalQuestionController.text.trim()
          : null,
    );
    final demographics = snapshot.toDemographicsJson();

    // Collect file paths from selected files
    final filePaths = _selectedFiles
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    int? specialtyId;
    for (final s in _loadedSpecialties) {
      if (s.name == _selectedSpecialty) {
        specialtyId = s.id;
        break;
      }
    }

    int? countryId;
    for (final ct in _loadedCountries) {
      if (ct.name == _selectedCountry) {
        countryId = ct.id;
        break;
      }
    }

    final request = CreateCaseRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: tags.isNotEmpty ? tags.join(',') : null,
      clinicalComplexity: _selectedComplexity,
      teachingValue: _selectedTeachingValue,
      isAnonymized: _isAnonymized,
      patientDemographics: demographics.isNotEmpty ? demographics : null,
      attachedFiles: filePaths.isNotEmpty ? filePaths : null,
      existingFileUrls: _existingFileUrls.isNotEmpty ? _existingFileUrls : null,
      specialtyId: specialtyId,
      countryId: countryId,
    );

    final bloc = context.read<CreateDiscussionBloc>();

    if (_isEditMode) {
      bloc.add(UpdateDiscussion((_editCase ?? widget.existingCase)!.id, request));
    } else {
      bloc.add(CreateDiscussion(request));
    }
  }

}

// ── Helper Widgets ──

class _LoadingDropdownPlaceholder extends StatelessWidget {
  final OneUITheme theme;
  const _LoadingDropdownPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final OneUITheme theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        color: theme.textPrimary,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final OneUITheme theme;
  const _SectionDivider({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: theme.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.divider)),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final OneUITheme theme;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.theme,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: theme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          color: theme.textTertiary,
        ),
        filled: true,
        fillColor: theme.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.error),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final OneUITheme theme;
  final Function(String?) onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: theme.textTertiary,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary),
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: theme.textPrimary,
          ),
          dropdownColor: theme.cardBackground,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item.isNotEmpty
                    ? '${item[0].toUpperCase()}${item.substring(1)}'
                    : item,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ExistingFileTile extends StatelessWidget {
  final String url;
  final OneUITheme theme;
  final VoidCallback onRemove;

  const _ExistingFileTile({
    required this.url,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.gif') ||
        url.contains('.webp');

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
        image: isImage
            ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              )
            : null,
        color: isImage ? null : theme.surfaceVariant,
      ),
      child: Stack(
        children: [
          if (!isImage)
            Center(
              child: Icon(Icons.description,
                  size: 30, color: theme.textTertiary),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewFileTile extends StatelessWidget {
  final PlatformFile file;
  final OneUITheme theme;
  final VoidCallback onRemove;

  const _NewFileTile({
    required this.file,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ext = file.extension?.toLowerCase() ?? '';
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
        color: theme.surfaceVariant,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImage ? Icons.image : Icons.description,
                  size: 24,
                  color: theme.textTertiary,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 8,
                      fontFamily: 'Poppins',
                      color: theme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalSignField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool abnormal;
  final OneUITheme theme;
  final ValueChanged<bool> onAbnormalChanged;

  const _VitalSignField({
    required this.label,
    required this.controller,
    required this.abnormal,
    required this.theme,
    required this.onAbnormalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: _StyledTextField(
            controller: controller,
            hint: 'Value',
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: abnormal,
              activeColor: theme.error,
              onChanged: (v) => onAbnormalChanged(v ?? false),
            ),
            Text(
              'Abnormal',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                color: theme.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabResultRow extends StatelessWidget {
  final LabResult lab;
  final OneUITheme theme;
  final ValueChanged<LabResult> onChanged;
  final VoidCallback onRemove;

  const _LabResultRow({
    required this.lab,
    required this.theme,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            initialValue: lab.name,
            onChanged: (v) => onChanged(lab.copyWith(name: v)),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Test name',
              filled: true,
              fillColor: theme.inputBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.inputBorder),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: lab.value,
            onChanged: (v) => onChanged(lab.copyWith(value: v)),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Value',
              filled: true,
              fillColor: theme.inputBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.inputBorder),
              ),
            ),
          ),
        ),
        Checkbox(
          value: lab.abnormal,
          activeColor: theme.error,
          onChanged: (v) => onChanged(lab.copyWith(abnormal: v ?? false)),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18, color: theme.textTertiary),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
