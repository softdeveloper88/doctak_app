import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PostUtils {
  // Function to show alert dialog for deleting a post
  static Color HexColor(String hexColorString) {
    hexColorString = hexColorString.replaceAll("#", "");
    if (hexColorString.length == 6) {
      hexColorString = "FF$hexColorString"; // Add FF for opacity
      return Color(int.parse(hexColorString, radix: 16));
    } else {
      return Color(int.parse('ffffff', radix: 16));
    }
  }

  // Function to launch URL with confirmation dialog
  static Future<void> launchURL(BuildContext context, String urlString) async {
    Uri url = Uri.parse(urlString);

    // Show a confirmation dialog before launching the URL
    bool shouldLaunch =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Open Link'),
              content: Text('Would you like to open this link? \n$urlString'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false to shouldLaunch
                  },
                ),
                TextButton(
                  child: const Text('Open'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true to shouldLaunch
                  },
                ),
              ],
            );
          },
        ) ??
        false; // shouldLaunch will be false if the dialog is dismissed

    if (shouldLaunch) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leaving the app canceled.'), backgroundColor: Colors.blue));
    }
  }

  // Function to get a contrasting text color
  static Color contrastingTextColor(Color bgColor) {
    // Calculate the luminance of the background color
    double luminance = bgColor.computeLuminance();
    // Return black or white text color based on luminance
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
