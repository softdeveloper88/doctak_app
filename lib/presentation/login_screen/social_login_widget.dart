import 'dart:convert';
import 'dart:developer' as logs;
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/widgets/custom_elevated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialLoginWidget extends StatefulWidget {
  const SocialLoginWidget({super.key});

  @override
  State<SocialLoginWidget> createState() => _SocialLoginWidgetState();
}

class _SocialLoginWidgetState extends State<SocialLoginWidget> {
  // _tryGoogleSignin() async {
  //   try {
  //     EasyLoading.show();
  //
  //     await ref
  //         .read(authenticationProvider)
  //         .signinWithGoogleCredentials()
  //         .then((response) {
  //       EasyLoading.dismiss();
  //
  //       Fluttertoast.showToast(
  //         backgroundColor:
  //         response.isSuccess ? null : Theme
  //             .of(context)
  //             .colorScheme
  //             .error,
  //         msg: response.message,
  //       );
  //       if (response.isSuccess) {
  //         var hasCompletedProfile =
  //             ref
  //                 .read(profileStateProvider)
  //                 ?.isProfileCompleted ?? false;
  //         if (hasCompletedProfile == false) {
  //           Navigator.pushNamedAndRemoveUntil(
  //               context, Routes.disclaimerPage, (route) => false);
  //         } else {
  //           Navigator.pushNamedAndRemoveUntil(
  //               context, Routes.mainScreen, (route) => false);
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     Fluttertoast.showToast(
  //       backgroundColor: Theme
  //           .of(context)
  //           .colorScheme
  //           .error,
  //       msg: somethingWentWrong,
  //     );
  //
  //     throw Exception(e);
  //   }
  // }
  //
  // _tryAppleSignin() async {
  //   try {
  //     EasyLoading.show();
  //
  //     await ref
  //         .read(authenticationProvider)
  //         .signinWithAppleCredentials()
  //         .then((response) {
  //       EasyLoading.dismiss();
  //
  //       Fluttertoast.showToast(
  //         backgroundColor:
  //         response.isSuccess ? null : Theme
  //             .of(context)
  //             .colorScheme
  //             .error,
  //         msg: response.message,
  //       );
  //       if (response.isSuccess) {
  //         var hasCompletedProfile =
  //             ref
  //                 .read(profileStateProvider)
  //                 ?.isProfileCompleted ?? false;
  //         if (hasCompletedProfile == false) {
  //           Navigator.pushNamedAndRemoveUntil(
  //               context, Routes.disclaimerPage, (route) => false);
  //         } else {
  //           Navigator.pushNamedAndRemoveUntil(
  //               context, Routes.mainScreen, (route) => false);
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     Fluttertoast.showToast(
  //       backgroundColor: Theme
  //           .of(context)
  //           .colorScheme
  //           .error,
  //       msg: somethingWentWrong,
  //     );
  //     throw Exception(e);
  //   }
  // }
  Future<void> performLogin(
      String provider, String name, String email, String token) async {
    EasyLoading.show();
    final apiUrl = Uri.parse(
        'https://doctak.net/api/login'); // Replace with your API endpoint
    print(token);
    try {
      final response = await http.post(apiUrl, body: {
        'email': email,
        'isSocialLogin': 'true',
        'name': name,
        'provider': provider,
        'token': '4a080919-3829-4b4a-abdc-95b1267c4371'
      });
      print(response.body);
      // Hide loading overlay once the response is received

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        bool success = responseData['success'];

        if (success) {
          var user = responseData['user'];

          final token = responseData['token'];
          // ... store user details and token in SharedPreferences
          // Store the rememberMe flag in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (user['country'] != null) {
            AppData.logInUserId = user['id'];
            await prefs.setBool('rememberMe', true);
            await prefs.setString('token', token ?? '');
            await prefs.setString('userId', user['id'] ?? '');
            await prefs.setString('name', user['name'] ?? '');
            await prefs.setString('profile_pic', user['profile_pic'] ?? '');
            await prefs.setString('email', user['email'] ?? '');
            await prefs.setString('phone', user['phone'] ?? '');
            await prefs.setString('background', user['background'] ?? '');
            await prefs.setString('licenseNo', user['license_no'] ?? '');
            await prefs.setString('title', user['title'] ?? '');
            await prefs.setString(
                'countryOrigin', user['country_origin'] ?? '');
            await prefs.setString('college', user['college'] ?? '');
            await prefs.setString('clinicName', user['clinic_name'] ?? '');
            await prefs.setString('dob', user['dob'] ?? '');
            await prefs.setString('user_type', user['user_type'] ?? '');
            if (user['country'] != null) {
              await prefs.setString('country', user['country'].toString());
              await prefs.setString('specialty', user['specialty'] ?? '');
              await prefs.setString('city', user['city'] ?? '');
            }
            await prefs.setString(
                'currency', responseData['country']['currency'] ?? '');
            if (responseData['university'] != null) {
              await prefs.setString(
                  'university', responseData['university']['name'] ?? '');
            }
            await prefs.setString(
                'practicingCountry', user['practicing_country'] ?? '');
            await prefs.setString('gender', user['gender'] ?? '');
            await prefs.setString('country', user['country'].toString());
            String? userToken = prefs.getString('token') ?? '';
            String? userId = prefs.getString('userId') ?? '';
            String? name = prefs.getString('name') ?? '';
            String? profile_pic = prefs.getString('profile_pic') ?? '';
            String? background = prefs.getString('background') ?? '';
            String? email = prefs.getString('email') ?? '';
            String? specialty = prefs.getString('specialty') ?? '';
            String? userType = prefs.getString('user_type') ?? '';
            String? university = prefs.getString('university') ?? '';
            String? countryName = prefs.getString('country') ?? '';
            String? currency = prefs.getString('currency') ?? '';
            logs.log(userToken.toString());
            if (userToken != '') {
              AppData.userToken = userToken;
              AppData.logInUserId = userId;
              AppData.name = name;
              AppData.profile_pic = profile_pic;
              AppData.university = university;
              AppData.userType = userType;
              AppData.background = background;
              AppData.email = email;
              AppData.specialty = specialty;
              AppData.countryName = countryName;
              AppData.currency = currency;
            }
            EasyLoading.dismiss();
            _navigateToHomeScreen();
          } else {
            EasyLoading.dismiss();
            // Navigator.push(context, MaterialPageRoute(builder: (context) => SocialAccountUpdate(responseData['token']
            // ,name)));
          }
        } else {
          EasyLoading.dismiss();
          String message =
              responseData['message'] ?? 'Email and Password not correct.';
          showErrorMessage(context, message);
        }
      } else {
        EasyLoading.dismiss();
        // Handle other status codes, possibly 400 or 500 series errors
        String errorDescription = 'An error occurred. Please try again later.';
        if (response.statusCode == 400) {
          errorDescription = 'Invalid request. Please check your credentials.';
        } else if (response.statusCode == 500) {
          EasyLoading.dismiss();
          errorDescription = 'Server error. Please try again later.';
        }
        EasyLoading.dismiss();
        showErrorMessage(context, errorDescription);
      }
    } on SocketException {
      // _hideLoadingOverlay();
      EasyLoading.dismiss();
      showErrorMessage(context,
          "No internet connection. Please check your network settings.");
    } catch (error) {
      EasyLoading.dismiss();
      // EasyLoading.dismiss();
      // _hideLoadingOverlay();
      print(error);
      showErrorMessage(
          context, 'An unexpected error occurred. Please try again later.');
    }
  }

  void showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(fontFamily: 'Poppins')),
          content: Text(message, style:const TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style:TextStyle(fontFamily: 'Poppins')),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToHomeScreen() {
    // Navigator.pushReplacement(
    //     context, MaterialPageRoute(builder: (context) =>  const HomeScreen()));
  }

  onPressedGoogleLogin() async {
    try {
      // GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      print(googleUser.toString());

      GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser!.authentication;
      String accessToken = googleSignInAuthentication.accessToken!;
      // await FirebaseMessaging.instance.getToken().then((token) async {
      //   print('token$googleUser');
      performLogin(
          'google', googleUser.displayName!, googleUser.email, accessToken);
      // var loginResponse = await RemoteService().getSocialLoginResponse(
      //     'google', googleUser.displayName!, googleUser.email, googleUser.id, token!);
      // if (loginResponse.result == false) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         loginResponse.message ?? '',
      //         style: const TextStyle(fontFamily: "Robotic"),
      //       ),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         loginResponse.message ?? '',
      //         style: const TextStyle(fontFamily: "Robotic"),
      //       ),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // }
      GoogleSignIn().disconnect();
      // });
    } on Exception catch (e) {
      print('error is ....... $e');
      // TODO
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    // await FirebaseMessaging.instance.getToken().then((token) async {
    //   print('token$token');
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // print(oauthCredential.signInMethod.);
    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    var response =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    performLogin('apple', response.user?.displayName ?? '',
        response.user?.email ?? '', response.user!.uid ?? '');
    print("${appleCredential.givenName} ${appleCredential.familyName}");
    // var loginResponse = await AuthRepository().getSocialLoginResponse(
    //     'google',
    //     response.user?.displayName ?? '',
    //     response.user?.email ?? '',
    //     response.user?.uid ?? '',
    //     access_token: appleCredential.identityToken,
    //     deviceToken: token);
    // print(appleCredential);
    // print(response);
    // print(loginResponse);
    // if (loginResponse.result == false) {
    //   // ToastComponent.showDialog(loginResponse.message ?? '',
    //   //     gravity: Toast.center, duration: Toast.lengthLong);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         loginResponse.message ?? '',
    //         style: const TextStyle(fontFamily: "Robotic"),
    //       ),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         loginResponse.message ?? '',
    //         style: const TextStyle(fontFamily: "Robotic"),
    //       ),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // ToastComponent.showDialog(loginResponse.message ?? '',
    //     gravity: Toast.center, duration: Toast.lengthLong);
    // AuthHelper().setUserData(loginResponse);
    // Navigator.of(context).pushNamedAndRemoveUntil(
    //   MainScreen.routeName,
    //       (route) => false,
    // );
    // }
    GoogleSignIn().disconnect();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomElevatedButton(
          width: 70.w,
          // name: continueWithGoogle,
          // color: Colors.redAccent,
          buttonStyle: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // button's shape
          )),
          leftIcon: const Icon(Icons.email),
          onPressed: onPressedGoogleLogin, text: '  Login with Google',
        ),
        const SizedBox(height: 20),
        if (Platform.isIOS)
          CustomElevatedButton(
            text: "   Login with Apple",
            // name: continueWithApple,
            // color: Colors.black,
            width: 70.w,
            buttonStyle: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // button's shape
            )),
            leftIcon: const Icon(Icons.apple),
            onPressed: signInWithApple,
          ),
      ],
    );
  }
}
