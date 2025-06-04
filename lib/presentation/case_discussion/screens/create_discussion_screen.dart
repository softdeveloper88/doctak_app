import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/specialty_loading_shimmer.dart';
import '../../../localization/app_localization.dart';
import '../../../core/utils/app/AppData.dart';
import '../../home_screen/utils/SVColors.dart';
import '../../home_screen/utils/SVCommon.dart';

class CreateDiscussionScreen extends StatefulWidget {
  const CreateDiscussionScreen({Key? key}) : super(key: key);

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  String _selectedSpecialty = 'General';
  String _selectedSpecialtyId = '1';
  File? _selectedFile;
  String? _selectedFileName;
  List<String> _tags = [];
  
  final ImagePicker _imagePicker = ImagePicker();
  late CaseDiscussionRepository _repository;
  
  // Specialty options from API
  List<SpecialtyFilter> _specialties = [];
  bool _isLoadingSpecialties = true;

  @override
  void initState() {
    super.initState();
    _repository = CaseDiscussionRepository(
      baseUrl: AppData.base,
      getAuthToken: () => AppData.userToken ?? "",
    );
    print('Repository initialized with baseUrl: ${AppData.base}');
    print('Auth token available: ${AppData.userToken != null && AppData.userToken!.isNotEmpty}');
    _loadSpecialties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImageFromCamera(),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImageFromGallery(),
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'File',
                  onTap: () => _pickDocument(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue[600]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedFileName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedFileName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  // Tag management functions
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print('=== Form Validation Passed ===');
      print('📝 Title: ${_titleController.text.trim()}');
      print('📄 Description: ${_descriptionController.text.trim()}');
      print('🏷️ Tags: ${_tags.isNotEmpty ? _tags.join(',') : 'None'}');
      print('🩺 Specialty ID: $_selectedSpecialtyId');
      print('🩺 Specialty Name: $_selectedSpecialty');
      print('📎 Attached File: ${_selectedFile?.path ?? 'None'}');
      
      final request = CreateCaseRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags.isNotEmpty ? _tags.join(',') : null,
        specialtyId: _selectedSpecialtyId,
        attachedFile: _selectedFile?.path,
        specialty: _selectedSpecialty,
      );

      context.read<CreateDiscussionBloc>().add(CreateDiscussion(request));
    } else {
      print('❌ Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_rounded,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Create Case Discussion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  color: Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                // Show help dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Create Case Discussion'),
                    content: const Text(
                      'Share medical cases for discussion with other healthcare professionals. '
                      'Include relevant details and attach files if needed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
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
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Case discussion created successfully!'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is CreateDiscussionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to create discussion: ${state.message}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _submitForm,
                ),
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Container(
            color: svGetScaffoldColor(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: AppTextField(
                    controller: _titleController,
                    textFieldType: TextFieldType.NAME,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Case Title *',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        color: Colors.blue.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                ),

                // Description Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: AppTextField(
                    controller: _descriptionController,
                    textFieldType: TextFieldType.MULTILINE,
                    maxLines: 5,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Case Description *',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.description_rounded,
                        color: Colors.blue.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ),

                // Tags Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            color: Colors.blue.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tags (Optional)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Tag input field
                      StatefulBuilder(
                        builder: (context, setState) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blue.withOpacity(0.6),
                                        width: 2,
                                      ),
                                    ),
                                    hintText: 'Add a tag...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // Rebuild to update button state
                                  },
                                  onSubmitted: (_) {
                                    if (_tagController.text.trim().isNotEmpty) {
                                      _addTag();
                                      setState(() {}); // Rebuild after adding tag
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _tagController.text.trim().isNotEmpty ? () {
                                  _addTag();
                                  setState(() {}); // Rebuild after adding tag
                                } : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _tagController.text.trim().isNotEmpty 
                                        ? Colors.blue[600] 
                                        : Colors.grey[400],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      // Display tags as chips
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeTag(tag),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.blue[600],
                                    ),
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
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: _isLoadingSpecialties
                    ? const SpecialtyLoadingShimmer()
                    : DropdownButtonFormField<String>(
                        value: _specialties.isNotEmpty ? _selectedSpecialtyId : null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select Specialty',
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.medical_services_rounded,
                            color: Colors.blue.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                        items: _specialties.map((specialty) {
                          return DropdownMenuItem<String>(
                            value: specialty.id.toString(),
                            child: Text(
                              specialty.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSpecialtyId = value;
                              _selectedSpecialty = _specialties.firstWhere(
                                (s) => s.id.toString() == value,
                              ).name;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a specialty';
                          }
                          return null;
                        },
                      ),
                ),

                // File Attachment Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            color: Colors.blue.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Attachment (Optional)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_selectedFile == null)
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_rounded,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to attach file',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFileName ?? 'File attached',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: _removeAttachment,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.red[600],
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                BlocBuilder<CreateDiscussionBloc, CreateDiscussionState>(
                  builder: (context, state) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: ElevatedButton(
                        onPressed: state is CreateDiscussionLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: state is CreateDiscussionLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Create Discussion',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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