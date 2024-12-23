import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/screen_utils.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/widgets/show_loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerifyEmailCard extends StatelessWidget {


  const VerifyEmailCard({Key? key}) : super(key: key);
  Future<void> sendVerificationLink(String email, BuildContext context) async {
  showLoadingDialog(context);
  // Show the loading dialog
  // showDialog(
  //   context: context,
  //   barrierDismissible: false, // Disallow dismissing while loading
  //   builder: (BuildContext context) {
  //     return SimpleDialog(
  //       title: const Text('Sending Verification Link'),
  //       children: [
  //         Center(
  //           child: CircularProgressIndicator(
  //             color: svGetBodyColor(),
  //           ),
  //         ),
  //       ],
  //     );
  //   },
  // );
  try {
  final response = await http.post(
  Uri.parse('${AppData.remoteUrl}/send-verification-link'),
  body: {'email': email},
  );

  // Close the loading dialog
  Navigator.of(context).pop();

  if (response.statusCode == 200) {
  // Successful API call, handle the response if needed
  // Show success Snackbar
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Verification link sent successfully'),
  duration: Duration(seconds: 2),
  ),
  );
  } else if (response.statusCode == 422) {
  // Validation error or user email not found
  // Show error Snackbar
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Validation error or user email not found'),
  duration: Duration(seconds: 2),
  ),
  );
  } else if (response.statusCode == 404) {
  // User already verified
  // Show info Snackbar
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('User already verified'),
  duration: Duration(seconds: 2),
  ),
  );
  } else {
  // Something went wrong
  // Show error Snackbar
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Something went wrong.'),
  duration: Duration(seconds: 2),
  ),
  );
  }
  } catch (e) {
  // Handle network errors or other exceptions
  // Close the loading dialog
  Navigator.of(context).pop();

  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Something went wrong.'),
  duration: Duration(seconds: 2),
  ),
  );
  }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please verify your email to continue.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (){
                  sendVerificationLink(AppData.email,context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SVAppColorPrimary,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Verify Email",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
