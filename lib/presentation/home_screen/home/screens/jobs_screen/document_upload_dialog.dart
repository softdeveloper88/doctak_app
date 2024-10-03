import 'dart:io';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class DocumentUploadDialog extends StatefulWidget {
  String jobId;
  DocumentUploadDialog(this.jobId, {super.key});
  @override
  _DocumentUploadDialogState createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  File? _documentFile;
  bool _isUploading = false;

  // Function to pick document from the file picker
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _documentFile = File(result.files.single.path!);
      });
    }
  }

  // Function to send document to server
  Future<void> _uploadDocument(jobId) async {
    if (_documentFile == null) return;

    setState(() {
      _isUploading = true;
    });
    final Dio _dio = Dio(BaseOptions(baseUrl: AppData.remoteUrl2));

    final response = await _dio.post(
      '/jobs/apply',
      data:  FormData.fromMap({
        'job_id':jobId,
        'cv': _documentFile!.path !=""?await MultipartFile.fromFile( _documentFile!.path, filename:  _documentFile!.path):"",

      }),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload document')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Resume'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _documentFile == null
              ? const Text('No document selected.')
              : Text('Selected File: ${_documentFile!.path.split('/').last}'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.folder),
            label: const Text('Select Document'),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _documentFile != null && !_isUploading ? () {
            _uploadDocument(widget.jobId);
          } : null,
          child: _isUploading
              ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
              : const Text('Upload'),
        ),
      ],
    );
  }
}
