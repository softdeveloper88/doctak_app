import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  Future<void> _uploadDocument(jobId, context) async {
    try {
      if (_documentFile == null) return;

      setState(() {
        _isUploading = true;
      });
      final Dio _dio = Dio(BaseOptions(baseUrl: AppData.remoteUrl2));

      final response = await _dio.post(
        '/jobs/apply',
        data: FormData.fromMap({
          'job_id': jobId,
          'cv': _documentFile!.path != ""
              ? await MultipartFile.fromFile(_documentFile!.path,
              filename: _documentFile!.path)
              : "",
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
      } else {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document')),
        );
      }

      setState(() {
        _isUploading = false;
      });
    }catch(e){
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload document')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Upload your resume",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Help us get to know you better by sharing your resume.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickDocument,
              child: Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    if (_documentFile == null)
                      const Text('No document selected.')
                    else
                      Text(
                          'Selected File: ${_documentFile!.path.split('/').last}'),
                    const Text(
                      "Click to upload",
                      style: TextStyle(color: Colors.grey),
                    ),
                     const Text(
                      "Acceptable file types: PDF, DOCX (5MB max)",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _documentFile != null && !_isUploading
                      ? () {
                          _uploadDocument(widget.jobId, context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Upload',
                          style: TextStyle(color: Colors.white),
                        ),
                  // const Text("Upload Now",style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    //   AlertDialog(
    //   title:  Text('Upload Resume',style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500,fontSize: 16),),
    //   content: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       _documentFile == null
    //           ? const Text('No document selected.')
    //           : Text('Selected File: ${_documentFile!.path.split('/').last}'),
    //       const SizedBox(height: 10),
    //       ElevatedButton.icon(
    //         onPressed: _pickDocument,
    //         icon: const Icon(Icons.folder),
    //         label: const Text('Select Document'),
    //       ),
    //     ],
    //   ),
    //   actions: [
    //     ElevatedButton(
    //       onPressed: () {
    //         Navigator.of(context).pop();
    //       },
    //       child: const Text('Cancel'),
    //     ),
    //     ElevatedButton(
    //       onPressed: _documentFile != null && !_isUploading ? () {
    //         _uploadDocument(widget.jobId,context);
    //       } : null,
    //       child: _isUploading
    //           ? const CircularProgressIndicator(
    //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    //       )
    //           : const Text('Upload'),
    //     ),
    //   ],
    // );
  }
}
