import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';

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

  String? _selectedSpecialty;
  String? _selectedCountry;
  String? _selectedGender;
  String? _selectedComplexity;
  String? _selectedTeachingValue;
  String? _selectedEthnicity;
  bool _isAnonymized = true;

  List<PlatformFile> _selectedFiles = [];
  List<String> _existingFileUrls = [];

  bool get _isEditMode => widget.existingCase != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFromExisting();
    }
  }

  void _populateFromExisting() {
    final c = widget.existingCase!;
    _titleController.text = c.title;
    _descriptionController.text = c.description;
    _tagsController.text = c.parsedTags.join(', ');
    _selectedSpecialty = c.specialty;
    _selectedCountry = c.countryName;

    if (c.metadata != null) {
      _selectedComplexity = c.metadata!.clinicalComplexity;
      _selectedTeachingValue = c.metadata!.teachingValue;
      _isAnonymized = c.metadata!.isAnonymized;

      final demo = c.metadata!.parsedDemographics;
      if (demo != null) {
        _ageController.text = demo['age']?.toString() ?? '';
        _selectedGender = demo['gender'];
        _selectedEthnicity = demo['ethnicity'];
      }
    }

    // Keep existing file URLs
    _existingFileUrls = c.attachments.map((a) => a.url).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _ageController.dispose();
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
                          _DropdownField(
                            value: _selectedSpecialty,
                            hint: 'Select specialty',
                            items: _specialties,
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
                          _DropdownField(
                            value: _selectedCountry,
                            hint: 'Select country',
                            items: _countries,
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
                            items: const ['male', 'female', 'other'],
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
                            items: const [
                              'Asian',
                              'Black',
                              'Caucasian',
                              'Hispanic',
                              'Middle Eastern',
                              'Other',
                            ],
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

    final demographics = <String, dynamic>{};
    if (_ageController.text.isNotEmpty) {
      demographics['age'] = int.tryParse(_ageController.text);
    }
    if (_selectedGender != null) {
      demographics['gender'] = _selectedGender;
    }
    if (_selectedEthnicity != null) {
      demographics['ethnicity'] = _selectedEthnicity;
    }

    // Collect file paths from selected files
    final filePaths = _selectedFiles
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

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
    );

    final bloc = context.read<CreateDiscussionBloc>();

    if (_isEditMode) {
      bloc.add(UpdateDiscussion(widget.existingCase!.id, request));
    } else {
      bloc.add(CreateDiscussion(request));
    }
  }

  static const _specialties = [
    'Cardiology',
    'Dermatology',
    'Emergency Medicine',
    'Endocrinology',
    'Gastroenterology',
    'General Surgery',
    'Internal Medicine',
    'Nephrology',
    'Neurology',
    'Obstetrics & Gynecology',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Radiology',
    'Rheumatology',
    'Urology',
  ];

  static const _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'India',
    'Germany',
    'France',
    'Saudi Arabia',
    'UAE',
    'Pakistan',
    'Egypt',
    'Brazil',
    'South Africa',
    'Japan',
    'South Korea',
    'China',
  ];
}

// ── Helper Widgets ──

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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
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
        border: Border.all(color: theme.border),
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
          icon: Icon(Icons.arrow_drop_down, color: theme.textTertiary),
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
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
                  fontSize: 13,
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
