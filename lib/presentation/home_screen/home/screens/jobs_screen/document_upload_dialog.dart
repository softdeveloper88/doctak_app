import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class DocumentUploadDialog extends StatefulWidget {
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
  Future<void> _uploadDocument() async {
    if (_documentFile == null) return;

    setState(() {
      _isUploading = true;
    });

    final uri = Uri.parse('https://your-server-endpoint.com/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('document', _documentFile!.path));

    var response = await request.send();

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
          onPressed: _documentFile != null && !_isUploading ? _uploadDocument : null,
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
