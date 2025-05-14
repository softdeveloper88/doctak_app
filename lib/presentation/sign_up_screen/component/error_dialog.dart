import 'package:flutter/material.dart';
import 'package:doctak_app/localization/app_localization.dart';

class ErrorDialog extends StatelessWidget {
  final Map<String, dynamic> errors;
  ErrorDialog({required this.errors});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(translation(context).lbl_validation_error),
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
          child: Text(translation(context).lbl_ok),
        ),
      ],
    );
  }

  List<Widget> _buildErrorWidgets() {
    List<Widget> errorWidgets = [];
    print(errors);
    errors.forEach((field, errorMessages) {
      for (var errorMessage in errorMessages) {
        errorWidgets.add(Text('- $field: $errorMessage'));
      }
    });
    return errorWidgets;
  }
}
