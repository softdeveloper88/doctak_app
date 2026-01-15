import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentUploadDialog extends StatefulWidget {
  String jobId;

  DocumentUploadDialog(this.jobId, {super.key});

  @override
  _DocumentUploadDialogState createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> with TickerProviderStateMixin {
  File? _documentFile;
  bool _isUploading = false;
  final bool _isDragOver = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Validate file size and type
  bool _validateFile(File file) {
    final fileSize = file.lengthSync();
    final fileSizeInMB = fileSize / (1024 * 1024);
    final fileName = file.path.toLowerCase();

    setState(() {
      _errorMessage = null;
    });

    if (fileSizeInMB > 5) {
      setState(() {
        _errorMessage = 'File size must be less than 5MB';
      });
      return false;
    }

    if (!fileName.endsWith('.pdf') && !fileName.endsWith('.doc') && !fileName.endsWith('.docx') && !fileName.endsWith('.txt')) {
      setState(() {
        _errorMessage = 'Please select a PDF, DOC, DOCX, or TXT file';
      });
      return false;
    }

    return true;
  }

  // Get file size in readable format
  String _getFileSize(File file) {
    final fileSize = file.lengthSync();
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Get file icon based on extension
  IconData _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  // Function to pick document from the file picker
  Future<void> _pickDocument() async {
    try {
      HapticFeedback.lightImpact();

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'txt']);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (_validateFile(file)) {
          setState(() {
            _documentFile = file;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file. Please try again.';
      });
    }
  }

  // Function to show upload resume message
  void _showUploadResumeMessage() {
    setState(() {
      _errorMessage = 'Please select a document first to upload your resume.';
    });
  }

  // Function to send document to server
  Future<void> _uploadDocument(jobId, context) async {
    try {
      if (_documentFile == null) return;

      setState(() {
        _isUploading = true;
      });
      final Dio dio = Dio(BaseOptions(baseUrl: AppData.remoteUrl2));

      final response = await dio.post(
        '/jobs/apply',
        data: FormData.fromMap({'job_id': jobId, 'cv': _documentFile!.path != "" ? await MultipartFile.fromFile(_documentFile!.path, filename: _documentFile!.path) : ""}),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}',
            // Add Bearer token to headers
          },
          contentType: 'multipart/form-data', // Ensure content type is multipart
        ),
      );
      // final uri = Uri.parse('${AppData.remoteUrl2}/jobs/apply');
      // var request = http.MultipartRequest('POST', uri);
      // request.files.add(await http.MultipartFile.fromPath('cv', _documentFile!.path));
      // request.fields['job_id'] = jobId;
      // var response = await request.send();
      print(response);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!')));
      } else {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
      }

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardBackground,
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Upload Resume",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Share your professional document",
                          style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Upload Area
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _pickDocument,
                      onTapDown: (_) => _animationController.forward(),
                      onTapUp: (_) => _animationController.reverse(),
                      onTapCancel: () => _animationController.reverse(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _documentFile != null
                              ? theme.success.withValues(alpha: 0.1)
                              : _isDragOver
                              ? theme.primary.withValues(alpha: 0.1)
                              : theme.surfaceVariant,
                          border: Border.all(
                            color: _documentFile != null
                                ? theme.success.withValues(alpha: 0.5)
                                : _isDragOver
                                ? theme.primary.withValues(alpha: 0.5)
                                : theme.border,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _documentFile == null ? _buildUploadPrompt(theme) : _buildSelectedFile(theme),
                      ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.error, fontFamily: 'Poppins', fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.textSecondary),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Upload Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _documentFile != null && !_isUploading
                              ? () {
                                  HapticFeedback.lightImpact();
                                  _uploadDocument(widget.jobId, context);
                                }
                              : () {
                                  _showUploadResumeMessage();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _documentFile != null && !_isUploading ? theme.primary : theme.primary.withValues(alpha: 0.1),
                            foregroundColor: _documentFile != null && !_isUploading ? Colors.white : theme.primary.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: _documentFile == null ? BorderSide(color: theme.primary.withValues(alpha: 0.3), width: 1.5) : null,
                            elevation: _documentFile != null ? 2 : 0,
                            shadowColor: _documentFile != null ? theme.primary.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                          child: _isUploading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_documentFile != null ? Colors.white : theme.primary.withValues(alpha: 0.5)),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_rounded, size: 18, color: _documentFile != null && !_isUploading ? Colors.white : theme.primary.withValues(alpha: 0.5)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upload Resume',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: _documentFile != null && !_isUploading ? Colors.white : theme.primary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build upload prompt widget
  Widget _buildUploadPrompt(OneUITheme theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(Icons.cloud_upload_rounded, size: 32, color: theme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Select Document',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimary, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a file to upload your resume',
          style: TextStyle(fontSize: 14, color: theme.textSecondary, fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border),
          ),
          child: Text(
            'PDF, DOC, DOCX, TXT • Max 5MB',
            style: TextStyle(fontSize: 12, color: theme.textTertiary, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Build selected file widget
  Widget _buildSelectedFile(OneUITheme theme) {
    if (_documentFile == null) return Container();

    final fileName = _documentFile!.path.split('/').last;
    final fileSize = _getFileSize(_documentFile!);
    final fileIcon = _getFileIcon(fileName);

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(fileIcon, size: 24, color: theme.success),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: TextStyle(fontSize: 12, color: theme.textSecondary, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _documentFile = null;
                  _errorMessage = null;
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.error.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, size: 16, color: theme.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: theme.success, size: 16),
              const SizedBox(width: 8),
              Text(
                'File ready to upload',
                style: TextStyle(color: theme.success, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.refresh, size: 16, color: theme.primary),
          label: Text(
            'Choose Different File',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.primary),
          ),
        ),
      ],
    );
  }
}
