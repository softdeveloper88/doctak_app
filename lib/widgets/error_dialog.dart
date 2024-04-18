import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final Map<String, dynamic> errors;

  ErrorDialog({required this.errors});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Validation Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildErrorWidgets(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  List<Widget> _buildErrorWidgets() {
    List<Widget> errorWidgets = [];
    errors.forEach((field, errorMessages) {
      for (var errorMessage in errorMessages) {
        errorWidgets.add(Text('- $field: $errorMessage'));
      }
    });
    return errorWidgets;
  }
}