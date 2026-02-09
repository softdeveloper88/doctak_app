import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/specialty_loading_shimmer.dart';
import '../../../localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../core/utils/unified_gallery_picker.dart';
import '../../../theme/one_ui_theme.dart';

class CreateDiscussionScreen extends StatefulWidget {
  final CaseDiscussion? existingCase; // For edit mode

  const CreateDiscussionScreen({super.key, this.existingCase});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clinicalKeywordsController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedSpecialty = 'General';
  String _selectedSpecialtyId = '1';
  String? _selectedGender;
  String? _selectedEthnicity;
  String _selectedClinicalComplexity = 'low';
  String _selectedTeachingValue = 'low';
  // Remove medical history - ethnicity is now in patient demographics
  bool _isAnonymized = false;

  final List<File> _selectedImages = [];
  List<String> _selectedImageNames = [];
  List<String> _existingFileUrls = []; // Track existing file URLs for edit mode
  List<String> _clinicalTags = []; // Track clinical tags for better UI

  late CaseDiscussionRepository _repository;

  // Specialty options from API
  List<SpecialtyFilter> _specialties = [];
  bool _isLoadingSpecialties = true;

  @override
  void initState() {
    super.initState();
    _repository = CaseDiscussionRepository(baseUrl: AppData.base, getAuthToken: () => AppData.userToken ?? "");
    print('Repository initialized with baseUrl: ${AppData.base}');
    print('Auth token available: ${AppData.userToken != null && AppData.userToken!.isNotEmpty}');

    // Initialize form with existing data if in edit mode
    if (widget.existingCase != null) {
      _initializeEditMode();
    }

    _loadSpecialties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clinicalKeywordsController.dispose();
    _ageController.dispose();
    // Removed medical history controller disposal
    super.dispose();
  }

  void _initializeEditMode() {
    final existingCase = widget.existingCase!;

    // Set basic fields
    _titleController.text = existingCase.title;
    _descriptionController.text = existingCase.description;

    // Set specialty
    _selectedSpecialty = existingCase.specialty;
    if (existingCase.specialtyId != null) {
      _selectedSpecialtyId = existingCase.specialtyId.toString();
    }

    // Parse and set existing tags
    if (existingCase.symptoms != null && existingCase.symptoms!.isNotEmpty) {
      _clinicalTags = existingCase.symptoms!;
      _updateTagsController();
    }

    // Extract patient demographics from metadata
    if (existingCase.metadata != null && existingCase.metadata!['patient_demographics'] != null) {
      final demographics = existingCase.metadata!['patient_demographics'] as Map<String, dynamic>;

      if (demographics['age'] != null) {
        _ageController.text = demographics['age'].toString();
      }
      if (demographics['gender'] != null) {
        _selectedGender = demographics['gender'].toString();
      }
      if (demographics['ethnicity'] != null) {
        _selectedEthnicity = demographics['ethnicity'].toString();
      }
    }

    // Set clinical metadata
    if (existingCase.metadata != null) {
      if (existingCase.metadata!['clinical_complexity'] != null) {
        _selectedClinicalComplexity = existingCase.metadata!['clinical_complexity'].toString();
      }
      if (existingCase.metadata!['teaching_value'] != null) {
        _selectedTeachingValue = existingCase.metadata!['teaching_value'].toString();
      }
      if (existingCase.metadata!['is_anonymized'] != null) {
        _isAnonymized = existingCase.metadata!['is_anonymized'] as bool;
      }
    }

    // Handle existing attached files
    if (existingCase.attachments != null && existingCase.attachments!.isNotEmpty) {
      _selectedImageNames = existingCase.attachments!
          .where((attachment) => attachment.url.isNotEmpty && attachment.url != '[]' && !attachment.url.startsWith('"'))
          .map((attachment) => attachment.description.isNotEmpty ? attachment.description : 'attachment_${attachment.id}')
          .toList();
      _existingFileUrls = existingCase.attachments!
          .where((attachment) => attachment.url.isNotEmpty && attachment.url != '[]' && !attachment.url.startsWith('"'))
          .map((attachment) => attachment.url)
          .toList();
    }

    print('=== Edit Mode Initialized ===');
    print('Title: ${_titleController.text}');
    print('Description: ${_descriptionController.text}');
    print('Specialty: $_selectedSpecialty ($_selectedSpecialtyId)');
    print('Age: ${_ageController.text}');
    print('Gender: $_selectedGender');
    print('Clinical Complexity: $_selectedClinicalComplexity');
    print('Teaching Value: $_selectedTeachingValue');
    print('Is Anonymized: $_isAnonymized');
    print('Attached Files: $_selectedImageNames');
  }

  Future<void> _loadSpecialties() async {
    print('=== Starting specialty loading ===');
    try {
      print('Repository baseUrl: ${_repository.baseUrl}');
      final filterData = await _repository.getFilterData();
      print('Filter data keys: ${filterData.keys}');
      print('Specialties type: ${filterData['specialties'].runtimeType}');

      if (filterData['specialties'] is List<SpecialtyFilter>) {
        final specialties = filterData['specialties'] as List<SpecialtyFilter>;
        print('Specialties count: ${specialties.length}');

        if (specialties.isNotEmpty) {
          setState(() {
            _specialties = specialties;
            _isLoadingSpecialties = false;
            _selectedSpecialtyId = _specialties.first.id.toString();
            _selectedSpecialty = _specialties.first.name;
          });
          print('✅ Specialties loaded successfully: ${_specialties.map((s) => '${s.id}:${s.name}').join(', ')}');
          return;
        }
      }

      print('❌ No valid specialties found, using defaults');
      _useDefaultSpecialties();
    } catch (e, stackTrace) {
      print('❌ Error loading specialties: $e');
      print('Stack trace: $stackTrace');
      _useDefaultSpecialties();
    }
  }

  void _useDefaultSpecialties() {
    setState(() {
      _isLoadingSpecialties = false;
      // Use a minimal set that should work
      _specialties = [
        SpecialtyFilter(id: 1, name: 'General Medicine', slug: 'general-medicine'),
        SpecialtyFilter(id: 2, name: 'Cardiology', slug: 'cardiology'),
        SpecialtyFilter(id: 3, name: 'Neurology', slug: 'neurology'),
        SpecialtyFilter(id: 4, name: 'Orthopedics', slug: 'orthopedics'),
        SpecialtyFilter(id: 5, name: 'Pediatrics', slug: 'pediatrics'),
        SpecialtyFilter(id: 6, name: 'Internal Medicine', slug: 'internal-medicine'),
        SpecialtyFilter(id: 7, name: 'Surgery', slug: 'surgery'),
        SpecialtyFilter(id: 8, name: 'Dermatology', slug: 'dermatology'),
        SpecialtyFilter(id: 9, name: 'Psychiatry', slug: 'psychiatry'),
        SpecialtyFilter(id: 10, name: 'Radiology', slug: 'radiology'),
      ];
      _selectedSpecialtyId = '1';
      _selectedSpecialty = 'General Medicine';
    });
    print('Using default specialties');
  }

  // File picker methods
  Future<void> _pickFile() async {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final innerTheme = OneUITheme.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.lbl_select_attachment,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: innerTheme.primary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(icon: Icons.camera_alt, label: AppLocalizations.of(context)!.lbl_camera, onTap: () => _pickImageFromCamera(), theme: innerTheme),
                  _buildAttachmentOption(icon: Icons.photo_library, label: AppLocalizations.of(context)!.lbl_gallery, onTap: () => _pickImageFromGallery(), theme: innerTheme),
                  _buildAttachmentOption(icon: Icons.attach_file, label: AppLocalizations.of(context)!.lbl_file, onTap: () => _pickDocument(), theme: innerTheme),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({required IconData icon, required String label, required VoidCallback onTap, required OneUITheme theme}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final File? photo = await UnifiedGalleryPicker.captureFromCamera(context);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
          _selectedImageNames.add(photo.path.split('/').last);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.msg_error_picking_image}: $e')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Use unified gallery picker for consistent experience
      final List<File>? pickedFiles = await UnifiedGalleryPicker.pickMultipleImages(
        context,
        title: AppLocalizations.of(context)!.lbl_gallery,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (mounted) {
          setState(() {
            for (var pickedFile in pickedFiles) {
              _selectedImages.add(pickedFile);
              _selectedImageNames.add(pickedFile.path.split('/').last);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.msg_error_picking_image}: $e')));
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'], allowMultiple: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _selectedImages.add(File(file.path!));
              _selectedImageNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.msg_error_picking_file}: $e')));
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImageNames.removeAt(index);
    });
  }

  // Helper method to format tags as JSON string
  String? _formatTagsAsJson(String tagsInput) {
    if (tagsInput.trim().isEmpty) return null;

    // Split by comma and clean up
    final tags = tagsInput.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

    if (tags.isEmpty) return null;

    // Format as JSON array with value objects
    final tagObjects = tags.map((tag) => {'value': tag}).toList();
    return jsonEncode(tagObjects);
  }

  // Helper method to parse existing tags from JSON format
  List<String> _parseTagsFromJson(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];

    try {
      if (tagsJson.startsWith('[') && tagsJson.endsWith(']')) {
        final List<dynamic> parsed = jsonDecode(tagsJson);
        return parsed.map((item) {
          if (item is Map<String, dynamic> && item['value'] != null) {
            return item['value'].toString();
          }
          return item.toString();
        }).toList();
      } else {
        // Handle simple comma-separated format
        return tagsJson.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      }
    } catch (e) {
      print('Error parsing tags: $e');
      // Fallback to simple comma-separated parsing
      return tagsJson.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    }
  }

  // Add a tag to the list
  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_clinicalTags.contains(tag.trim())) {
      setState(() {
        _clinicalTags.add(tag.trim());
        _updateTagsController();
      });
    }
  }

  // Remove a tag from the list
  void _removeTag(int index) {
    setState(() {
      _clinicalTags.removeAt(index);
      _updateTagsController();
    });
  }

  // Update the controller with comma-separated tags
  void _updateTagsController() {
    _clinicalKeywordsController.text = _clinicalTags.join(', ');
  }

  // Parse tags when controller text changes
  void _onTagsChanged(String value) {
    final tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    if (tags.length != _clinicalTags.length || !tags.every((tag) => _clinicalTags.contains(tag))) {
      setState(() {
        _clinicalTags = tags;
      });
    }
  }

  void _submitForm() {
    final theme = OneUITheme.of(context);
    if (_formKey.currentState!.validate()) {
      if (!_isAnonymized) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.msg_confirm_patient_info_removed), backgroundColor: theme.warning, duration: const Duration(seconds: 3)));
        return;
      }

      print('=== Form Validation Passed ===');
      print('📝 Title: ${_titleController.text.trim()}');
      print('📄 Description: ${_descriptionController.text.trim()}');
      print('🏷️ Clinical Keywords: ${_clinicalKeywordsController.text.trim()}');
      print('🩺 Specialty ID: $_selectedSpecialtyId');
      print('🩺 Specialty Name: $_selectedSpecialty');
      print('👤 Patient Demographics: {age: ${_ageController.text.trim()}, gender: $_selectedGender, ethnicity: $_selectedEthnicity}');
      print('👤 Ethnicity: $_selectedEthnicity');
      print('📊 Clinical Complexity: $_selectedClinicalComplexity');
      print('📚 Teaching Value: $_selectedTeachingValue');
      print('🔒 Anonymized: $_isAnonymized');
      print('📸 Medical Images: ${_selectedImages.length} files');

      // Create patient demographics object
      final patientDemographics = {
        'age': _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) ?? 0 : 0,
        'gender': _selectedGender?.toLowerCase(),
        'ethnicity': _selectedEthnicity,
      };

      // Combine existing file URLs with new file paths
      final allFiles = <String>[];

      // Add existing file URLs (for edit mode) - filter out invalid URLs
      if (widget.existingCase != null) {
        final validExistingUrls = _existingFileUrls.where((url) => url.isNotEmpty && url != '[]' && !url.startsWith('"') && !url.contains('null')).toList();
        allFiles.addAll(validExistingUrls);
      }

      // Add new file paths
      allFiles.addAll(_selectedImages.map((file) => file.path).toList());

      print('📎 All files being sent: $allFiles');

      // Format tags as JSON string in the required format
      final formattedTags = _formatTagsAsJson(_clinicalKeywordsController.text.trim());
      print('🏷️ Formatted Tags JSON: $formattedTags');

      final request = CreateCaseRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: formattedTags,
        // specialtyId: _selectedSpecialtyId, // Removed specialty from request
        patientDemographics: patientDemographics,
        // ethnicity is now in patient demographics
        clinicalComplexity: _selectedClinicalComplexity,
        teachingValue: _selectedTeachingValue,
        isAnonymized: _isAnonymized,
        attachedFiles: allFiles,
      );

      // Check if we're in edit mode or create mode
      if (widget.existingCase != null) {
        print('🔄 Updating existing case: ${widget.existingCase!.id}');
        context.read<CreateDiscussionBloc>().add(UpdateDiscussion(widget.existingCase!.id, request));
      } else {
        print('✨ Creating new case');
        context.read<CreateDiscussionBloc>().add(CreateDiscussion(request));
      }
    } else {
      print('❌ Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    // Initialize dropdown values with localized strings
    _selectedGender ??= AppLocalizations.of(context)!.lbl_male;
    _selectedEthnicity ??= AppLocalizations.of(context)!.lbl_not_specified;
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: widget.existingCase != null ? translation(context).lbl_edit_case_discussion : AppLocalizations.of(context)!.lbl_create_case_discussion,
        titleIcon: Icons.medical_information_rounded,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.help_outline, color: theme.primary, size: 14),
              ),
              onPressed: () {
                // Show help dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.lbl_create_case_discussion),
                    content: Text(AppLocalizations.of(context)!.msg_create_case_discussion_description),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.lbl_got_it))],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocListener<CreateDiscussionBloc, CreateDiscussionState>(
        listener: (context, state) {
          if (state is CreateDiscussionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.cardBackground),
                    const SizedBox(width: 12),
                    Text(state.isUpdate ? translation(context).msg_case_discussion_updated : AppLocalizations.of(context)!.msg_case_discussion_created),
                  ],
                ),
                backgroundColor: theme.success,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is CreateDiscussionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.cardBackground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${AppLocalizations.of(context)!.msg_failed_to_create_discussion}: ${state.message}', style: TextStyle(color: theme.cardBackground)),
                    ),
                  ],
                ),
                backgroundColor: theme.error,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(label: AppLocalizations.of(context)!.lbl_retry, textColor: theme.cardBackground, onPressed: _submitForm),
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Container(
            color: theme.cardBackground,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                  ),
                  child: AppTextField(
                    controller: _titleController,
                    textFieldType: TextFieldType.NAME,
                    textStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '${AppLocalizations.of(context)!.lbl_case_title} *',
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(Icons.title_rounded, color: theme.primary.withValues(alpha: 0.6), size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.msg_please_enter_title;
                      }
                      return null;
                    },
                  ),
                ),

                // Description Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                  ),
                  child: AppTextField(
                    controller: _descriptionController,
                    textFieldType: TextFieldType.MULTILINE,
                    maxLines: 5,
                    textStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '${AppLocalizations.of(context)!.lbl_case_description} *',
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(Icons.description_rounded, color: theme.primary.withValues(alpha: 0.6), size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.msg_please_enter_description;
                      }
                      return null;
                    },
                  ),
                ),

                // Patient Demographics Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.person_rounded, color: theme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.lbl_patient_demographics,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Age Field
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AppTextField(
                          controller: _ageController,
                          textFieldType: TextFieldType.NUMBER,
                          textStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: theme.primary, width: 1.5),
                            ),
                            hintText: translation(context).lbl_age_years,
                            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),

                      // Gender and Ethnicity Row
                      Row(
                        children: [
                          // Gender Dropdown
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8, bottom: 12),
                              child: OneUIDropdownFormField<String>(
                                value: _selectedGender,
                                showContainer: false,
                                borderRadius: 8,
                                contentPadding: const EdgeInsets.all(12),
                                hintText: AppLocalizations.of(context)!.lbl_select_gender,
                                labelText: AppLocalizations.of(context)!.lbl_gender,
                                items: [AppLocalizations.of(context)!.lbl_male, AppLocalizations.of(context)!.lbl_female, AppLocalizations.of(context)!.lbl_other].map((gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(
                                      gender,
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedGender = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          // Ethnicity Dropdown
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8, bottom: 12),
                              child: OneUIDropdownFormField<String>(
                                value: _selectedEthnicity,
                                showContainer: false,
                                borderRadius: 8,
                                contentPadding: const EdgeInsets.all(12),
                                hintText: AppLocalizations.of(context)!.lbl_select_ethnicity,
                                labelText: AppLocalizations.of(context)!.lbl_ethnicity,
                                items:
                                    [
                                      AppLocalizations.of(context)!.lbl_not_specified,
                                      AppLocalizations.of(context)!.lbl_caucasian,
                                      AppLocalizations.of(context)!.lbl_african_american,
                                      AppLocalizations.of(context)!.lbl_asian,
                                      AppLocalizations.of(context)!.lbl_hispanic_latino,
                                      AppLocalizations.of(context)!.lbl_middle_eastern,
                                      AppLocalizations.of(context)!.lbl_other,
                                    ].map((ethnicity) {
                                      return DropdownMenuItem<String>(
                                        value: ethnicity,
                                        child: Text(
                                          ethnicity,
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedEthnicity = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Medical history removed - ethnicity is now in patient demographics
                    ],
                  ),
                ),

                // Clinical Keywords/Tags Field with enhanced UI
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.warning.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: theme.warning.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.sell_rounded, color: theme.warning, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.lbl_clinical_keywords,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        translation(context).msg_clinical_keywords_hint,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // Tags input field
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.border),
                        ),
                        child: AppTextField(
                          controller: _clinicalKeywordsController,
                          textFieldType: TextFieldType.MULTILINE,
                          maxLines: 2,
                          onChanged: _onTagsChanged,
                          textStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: translation(context).msg_clinical_keywords_example,
                            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),

                      // Display current tags as chips
                      if (_clinicalTags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          translation(context).lbl_current_tags,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _clinicalTags.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tag = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.warning.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: TextStyle(color: theme.warning, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeTag(index),
                                    child: Icon(Icons.close_rounded, size: 14, color: theme.warning),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Medical Images Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.success.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: theme.success.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.photo_library_rounded, color: theme.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.lbl_attach_medical_images,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Add Images Button
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [theme.success.withValues(alpha: 0.15), theme.success.withValues(alpha: 0.08)]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.success.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.add_photo_alternate_rounded, color: theme.success, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.lbl_add_medical_images,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.success, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Display selected images
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Column(
                          children: _selectedImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.success.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.image_outlined, color: theme.success, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedImageNames[index],
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.success, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeAttachment(index),
                                    icon: Icon(Icons.close_rounded, color: theme.error, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Specialty Dropdown
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _isLoadingSpecialties
                      ? const SpecialtyLoadingShimmer()
                      : OneUIDropdownFormField<String>(
                          value: _specialties.isNotEmpty ? _selectedSpecialtyId : null,
                          hintText: translation(context).lbl_select_specialty,
                          labelText: translation(context).lbl_medical_specialty,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icons.medical_services_rounded,
                          items: _specialties.map((specialty) {
                            return DropdownMenuItem<String>(
                              value: specialty.id.toString(),
                              child: Text(
                                specialty.name,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSpecialtyId = value;
                                _selectedSpecialty = _specialties.firstWhere((s) => s.id.toString() == value).name;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translation(context).msg_please_select_specialty;
                            }
                            return null;
                          },
                        ),
                ),

                // Clinical Complexity and Teaching Value Row
                Row(
                  children: [
                    // Clinical Complexity Dropdown
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 16),
                        child: OneUIDropdownFormField<String>(
                          value: _selectedClinicalComplexity,
                          hintText: AppLocalizations.of(context)!.lbl_select_clinical_complexity,
                          labelText: AppLocalizations.of(context)!.lbl_clinical_complexity,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icons.assessment_outlined,
                          items: [
                            DropdownMenuItem(
                              value: 'low',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_low,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_medium,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_high,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedClinicalComplexity = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    // Teaching Value Dropdown
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 16),
                        child: OneUIDropdownFormField<String>(
                          value: _selectedTeachingValue,
                          hintText: AppLocalizations.of(context)!.lbl_select_teaching_value,
                          labelText: AppLocalizations.of(context)!.lbl_teaching_value,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icons.school_outlined,
                          items: [
                            DropdownMenuItem(
                              value: 'low',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_low,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_medium,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text(
                                AppLocalizations.of(context)!.lbl_high,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTeachingValue = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Anonymization Checkbox - One UI 8.5 Switch Style
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.warning.withValues(alpha: 0.08), theme.warning.withValues(alpha: 0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.security_rounded, color: theme.warning, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAnonymized = !_isAnonymized;
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.msg_confirm_patient_info_removed_checkbox,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: theme.warning, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: _isAnonymized,
                          onChanged: (value) {
                            setState(() {
                              _isAnonymized = value;
                            });
                          },
                          activeThumbColor: theme.warning,
                          activeTrackColor: theme.warning.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button - One UI 8.5 Style
                BlocBuilder<CreateDiscussionBloc, CreateDiscussionState>(
                  builder: (context, state) {
                    final isDisabled = state is CreateDiscussionLoading || !_isAnonymized;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isDisabled ? null : LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        color: isDisabled ? theme.surfaceVariant : null,
                        boxShadow: isDisabled ? null : [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isDisabled ? null : _submitForm,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: state is CreateDiscussionLoading
                                ? Center(
                                    child: SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(isDisabled ? theme.textSecondary : theme.buttonPrimaryText)),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: (isDisabled ? theme.textSecondary : Colors.white).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Icon(
                                          widget.existingCase != null ? Icons.update_rounded : Icons.send_rounded,
                                          size: 18,
                                          color: isDisabled ? theme.textSecondary : theme.buttonPrimaryText,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.existingCase != null ? translation(context).lbl_update_case : AppLocalizations.of(context)!.lbl_submit_case,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDisabled ? theme.textSecondary : theme.buttonPrimaryText,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
