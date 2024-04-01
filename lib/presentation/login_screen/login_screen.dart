import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/SVHomeFragment.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_event.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/widgets/app_bar/appbar_title.dart';
import 'package:nb_utils/nb_utils.dart';

import '../home_screen/utils/SVCommon.dart';
import 'bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/widgets/app_bar/appbar_leading_image.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_elevated_button.dart';
import 'package:doctak_app/widgets/custom_outlined_button.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:doctak_app/domain/googleauth/google_auth_helper.dart';
import 'package:doctak_app/domain/facebookauth/facebook_auth_helper.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static Widget builder(BuildContext context) {
    return BlocProvider<LoginBloc>(
        create: (context) => LoginBloc(), child: LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(context),
            body: BlocListener<LoginBloc, LoginState>(
                listener: (context, state) {
                  if (state is LoginSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.push (
                      context,
                      MaterialPageRoute (
                        builder: (BuildContext context) =>  SVDashboardScreen(),
                      ),
                    );
                    // Navigate to the home screen or perform desired action
                  } else if (state is LoginFailure) {
                    // Show an error message

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: SizedBox(
                    width: SizeUtils.width,
                    child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Form(
                            key: _formKey,
                            child: Container(
                                width: double.maxFinite,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24.h, vertical: 39.v),
                                child: Column(children: [
                                  CustomTextFormField(
                                      controller: emailController,
                                      hintText: translation(context).msg_enter_your_email,
                                      textInputType: TextInputType.emailAddress,
                                      prefix: Container(
                                          margin: EdgeInsets.fromLTRB(
                                              24.h, 16.v, 16.h, 16.v),
                                          child: CustomImageView(
                                              color: Colors.blueGrey,
                                              imagePath:
                                                  ImageConstant.imgCheckmark,
                                              height: 24.adaptSize,
                                              width: 24.adaptSize)),
                                      prefixConstraints:
                                          BoxConstraints(maxHeight: 56.v),
                                      validator: (value) {
                                        if (value == null ||
                                            (!isValidEmail(value,
                                                isRequired: true))) {
                                          return translation(context).err_msg_please_enter_valid_email
                                              ;
                                        }
                                        return null;
                                      },
                                      contentPadding: EdgeInsets.only(
                                          top: 18.v,
                                          right: 30.h,
                                          bottom: 18.v)),
                                  SizedBox(height: 16.v),
                                  BlocBuilder<LoginBloc, LoginState>(
                                      builder: (context, state) {
                                    return CustomTextFormField(
                                        controller: passwordController,
                                        hintText: translation(context).msg_enter_new_password,
                                        textInputAction: TextInputAction.done,
                                        textInputType:
                                            TextInputType.visiblePassword,
                                        prefix: Container(
                                            margin: EdgeInsets.fromLTRB(
                                                24.h, 16.v, 16.h, 16.v),
                                            child: CustomImageView(
                                                color: Colors.blueGrey,
                                                imagePath:
                                                    ImageConstant.imgLocation,
                                                height: 24.adaptSize,
                                                width: 24.adaptSize)),
                                        prefixConstraints:
                                            BoxConstraints(maxHeight: 56.v),
                                        suffix: InkWell(
                                            onTap: () {
                                              context.read<LoginBloc>().add(
                                                  ChangePasswordVisibilityEvent(
                                                      value: !state
                                                          .isShowPassword));
                                            },
                                            child: Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    30.h, 16.v, 24.h, 16.v),
                                                child: CustomImageView(
                                                    color: Colors.blueGrey,
                                                    imagePath:
                                                        ImageConstant.imgEye,
                                                    height: 24.adaptSize,
                                                    width: 24.adaptSize))),
                                        suffixConstraints:
                                            BoxConstraints(maxHeight: 56.v),
                                        validator: (value) {
                                          if (value == null ||
                                              (!isValidPassword(value,
                                                  isRequired: true))) {
                                            return translation(context).err_msg_please_enter_valid_password
                                                ;
                                          }
                                          return null;
                                        },
                                        obscureText: state.isShowPassword);
                                  }),
                                  SizedBox(height: 10.v),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                          onTap: () {
                                            onTapTxtForgotPassword(context);
                                          },
                                          child: Text(translation(context).msg_forgot_password,
                                              style: CustomTextStyles
                                                  .titleSmallPrimary))),
                                  SizedBox(height: 32.v),
                                  svAppButton(
                                    context: context,
                                    text: 'LOGIN',
                                    onTap: () {
                                            BlocProvider.of<LoginBloc>(context).add(
                                              LoginButtonPressed(
                                                username: emailController.text,
                                                // replace with real input
                                                password: passwordController
                                                    .text, // replace with real input
                                              ),
                                            );
                                    },
                                  ),
                                  SizedBox(height: 25.v),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                          padding: EdgeInsets.only(left: 48.h),
                                          child: Row(children: [
                                            Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 1.v),
                                                child: Text(
                                                    translation(context).msg_don_t_have_an_account
                                                        ,
                                                    style: CustomTextStyles
                                                        .bodyMediumGray600)),
                                            GestureDetector(
                                                onTap: () {
                                                  onTapTxtSignUp(context);
                                                },
                                                child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4.h),
                                                    child: Text(
                                                        translation(context).lbl_sign_up,
                                                        style: CustomTextStyles
                                                            .titleSmallPrimarySemiBold)))
                                          ]))),
                                  SizedBox(height: 34.v),
                                  _buildORDivider(context),
                                  SizedBox(height: 29.v),
                                  _buildSocial(context),
                                  SizedBox(height: 5.v)
                                ]))))))));
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
        leadingWidth: 56.h,
        leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgIconChevronLeft,
            margin: EdgeInsets.only(left: 32.h, top: 8.v, bottom: 8.v)),
        centerTitle: true,
        title: AppbarTitle(text: translation(context).lbl_login));
  }

  /// Section Widget
  Widget _buildORDivider(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.only(top: 8.v, bottom: 9.v),
              child: SizedBox(width: 137.h, child: const Divider())),
          Text(translation(context).lbl_or, style: theme.textTheme.bodyLarge),
          Padding(
              padding: EdgeInsets.only(top: 8.v, bottom: 9.v),
              child: SizedBox(width: 137.h, child: const Divider()))
        ]);
  }

  /// Section Widget
  Widget _buildSocial(BuildContext context) {
    return Column(children: [
      CustomOutlinedButton(
          text: translation(context).msg_sign_in_with_google,
          leftIcon: Container(
              margin: EdgeInsets.only(right: 30.h),
              child: CustomImageView(
                  color: Colors.red,
                  imagePath: ImageConstant.imgGoogle,
                  height: 20.v,
                  width: 19.h)),
          onPressed: () {
            onTapSignInWithGoogle(context);
          }),
      SizedBox(height: 16.v),
      CustomOutlinedButton(
          text: translation(context).msg_sign_in_with_apple,
          leftIcon: Container(
              margin: EdgeInsets.only(right: 30.h),
              child: CustomImageView(
                  color: Colors.blueGrey,
                  imagePath: ImageConstant.imgApple,
                  height: 20.v,
                  width: 16.h))),
      SizedBox(height: 16.v),
    ]);
  }

  onTapTxtForgotPassword(BuildContext context) {
    // TODO: implement Actions
  }


  onTapTxtSignUp(BuildContext context) {
    // TODO: implement Actions
    SignUpScreen().launch(context);
    // Navigator.pushNamed(context, AppRoutes.signUpScreen);
  }
  onTapSignInWithGoogle(BuildContext context) async {
    await GoogleAuthHelper().googleSignInProcess().then((googleUser) {
      if (googleUser != null) {
        //TODO Actions to be performed after signin
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('user data is empty')));
      }
    }).catchError((onError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(onError.toString())));
    });
  }

  onTapSignInWithFacebook(BuildContext context) async {
    await FacebookAuthHelper().facebookSignInProcess().then((facebookUser) {
      //TODO Actions to be performed after signin
    }).catchError((onError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(onError.toString())));
    });
  }
}

// class LoginScreen extends StatefulWidget {
//   LoginScreen({Key? key}) : super(key: key);
//
//
//   static Widget builder(BuildContext context) {
//     return BlocProvider<LoginBloc>(
//         create: (context) => LoginBloc(LoginState(loginModelObj: LoginModel()))
//           ..add(LoginInitialEvent()),
//         child: LoginScreen());
//   }
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   late Timer _timer;
//
//   double _gradientOffset = 0;
//
//   bool rememberMe = false;
//
//   bool _passwordVisible = false;
//  // Add this to your class variables
//   final TextEditingController emailController = TextEditingController();
//
//   final TextEditingController passwordController = TextEditingController();
//
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(milliseconds: 100), _updateGradient);
//     checkRememberMe();
//   }
//
//   Future<void> checkRememberMe() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool rememberMe = prefs.getBool('rememberMe') ?? false;
//     if (rememberMe) {
//       // If rememberMe is true, navigate to the home screen
//       // Navigator.push(
//       //   context,
//       //   MaterialPageRoute(builder: (context) =>  const HomeScreen()),
//       // );
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel();
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
//
//   void _updateGradient(Timer timer) {
//     setState(() {
//       _gradientOffset += 0.01;
//       if (_gradientOffset >= 1) {
//         _gradientOffset = 0;
//       }
//     });
//   }
//
//   void _showForgotPasswordDialog() {
//     final TextEditingController _forgotPasswordController =
//     TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Forgot Password', style: GoogleFonts.acme()),
//           content: TextField(
//             controller: _forgotPasswordController,
//             decoration: InputDecoration(
//               labelText: 'Enter your email',
//               labelStyle: GoogleFonts.acme(),
//               border: const OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.emailAddress,
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel', style: GoogleFonts.acme()),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: Text('Send Email', style: GoogleFonts.acme()),
//               onPressed: () {
//                 _sendResetEmail(_forgotPasswordController.text);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _sendResetEmail(String email) async {
//     // Close the dialog
//     Navigator.of(context).pop();
//
//     // Here you'd normally call your API to send a password reset email
//     // For this example, we'll just simulate a delay and show a success message
//
//     _showLoadingOverlay();
//
//     // Simulate a network request delay
//     await Future.delayed(const Duration(seconds: 2));
//
//     _hideLoadingOverlay();
//
//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'A reset link has been sent to $email',
//           style: GoogleFonts.acme(),
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//
//     // Optional: Add a delay to read the snackbar message before navigating away
//     await Future.delayed(const Duration(seconds: 3));
//
//     // After showing a success message, navigate to the sign-in screen
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   }
//
//   OverlayEntry? _loadingOverlayEntry;
//
//   void _showLoadingOverlay() {
//     _loadingOverlayEntry = OverlayEntry(
//       builder: (context) => const Stack(
//         children: [
//           Opacity(
//             opacity: 0.5,
//             child: ModalBarrier(dismissible: false, color: Colors.grey),
//           ),
//           Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//
//     Overlay.of(context)!.insert(_loadingOverlayEntry!);
//   }
//
//   void _hideLoadingOverlay() {
//     if (_loadingOverlayEntry != null) {
//       _loadingOverlayEntry!.remove();
//       _loadingOverlayEntry = null;
//     }
//   }
//
//   Future<void> performLogin(String email, String password) async {
//     _showLoadingOverlay();
//     final apiUrl = Uri.parse(
//         'https://doctak.net/api/login'); // Replace with your API endpoint
//
//     try {
//       final response = await http.post(apiUrl, body: {
//         'email': email,
//         'password': password,
//         'device_id': "12345",
//         'device_type': "mobile",
//       });
//       print(response.body);
//
//       // Hide loading overlay once the response is received
//       _hideLoadingOverlay();
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         bool success = responseData['success'];
//
//         if (success) {
//           var user = responseData['user'];
//
//           final token = responseData['token'];
//           // ... store user details and token in SharedPreferences
//
//           AppData.logInUserId = user['id'];
//
//           if (rememberMe) {
//             // Store the rememberMe flag in SharedPreferences
//             SharedPreferences prefs = await SharedPreferences.getInstance();
//             await prefs.setBool('rememberMe', true);
//           }
//
//           if (user['email_verified_at'] == null) {
//             showVerifyMessage(context);
//             return;
//           }
//
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           await prefs.setString('token', token??'');
//           await prefs.setString('userId', user['id']??'');
//           await prefs.setString('name', user['name']??'');
//           await prefs.setString('profile_pic', user['profile_pic']??'');
//           await prefs.setString('email', user['email'] ?? '');
//           await prefs.setString('phone', user['phone'] ?? '');
//           await prefs.setString('background', user['background'] ?? '');
//           await prefs.setString('specialty', user['specialty']??'');
//           await prefs.setString('licenseNo', user['license_no'] ?? '');
//           await prefs.setString('title', user['title'] ?? '');
//           await prefs.setString('city', user['city'] ?? '');
//           await prefs.setString('countryOrigin', user['country_origin'] ?? '');
//           await prefs.setString('college', user['college'] ?? '');
//           await prefs.setString('clinicName', user['clinic_name'] ?? '');
//           await prefs.setString('dob', user['dob'] ?? '');
//           await prefs.setString('user_type', user['user_type'] ?? '');
//           await prefs.setString('countryName',  responseData['country']['countryName'] ?? '');
//           await prefs.setString('currency',  responseData['country']['currency'] ?? '');
//           if(responseData['university'] !=null) {
//             await prefs.setString('university',  responseData['university']['name'] ?? '');
//           }
//           await prefs.setString('practicingCountry', user['practicing_country'] ?? '');
//           await prefs.setString('gender', user['gender'] ?? '');
//           await prefs.setString('country', user['country'].toString());
//           String? userToken = prefs.getString('token')??'';
//           String? userId = prefs.getString('userId')??'';
//           String? name = prefs.getString('name')??'';
//           String? profile_pic = prefs.getString('profile_pic')??'';
//           String? background = prefs.getString('background')??'';
//           String? email = prefs.getString('email')??'';
//           String? specialty = prefs.getString('specialty')??'';
//           String? userType = prefs.getString('user_type')??'';
//           String? university = prefs.getString('university') ?? '';
//           String? countryName = prefs.getString('country') ?? '';
//           String? currency = prefs.getString('currency') ?? '';
//
//           if (userToken != '') {
//             AppData.userToken = userToken;
//             AppData.logInUserId = userId;
//             AppData.name = name;
//             AppData.profile_pic = profile_pic;
//             AppData.university= university;
//             AppData.userType= userType;
//             AppData.background = background;
//             AppData.email = email;
//             AppData.specialty = specialty;
//             AppData.countryName = countryName;
//             AppData.currency = currency;
//           }
//           // Navigate to home screen
//           _navigateToHomeScreen();
//
//         } else {
//           String message =
//               responseData['message'] ?? 'Email and Password not correct.';
//           showErrorMessage(context, message);
//         }
//       } else {
//         // Handle other status codes, possibly 400 or 500 series errors
//         String errorDescription = 'An error occurred. Please try again later.';
//         if (response.statusCode == 400) {
//           errorDescription = 'Invalid request. Please check your credentials.';
//         } else if (response.statusCode == 500) {
//           errorDescription = 'Server error. Please try again later.';
//         }
//         showErrorMessage(context, errorDescription);
//       }
//     } on SocketException {
//       _hideLoadingOverlay();
//
//       showErrorMessage(context,
//           'No internet connection. Please check your network settings.');
//     } catch (error) {
//       _hideLoadingOverlay();
//       print(error);
//       showErrorMessage(
//           context, 'An unexpected error occurred. Please try again later.');
//     }
//   }
//
//   void _navigateToHomeScreen() {
//     // Navigator.pushReplacement(
//     //     context, MaterialPageRoute(builder: (context) =>  const HomeScreen()));
//   }
//
//   Future<void> sendVerificationLink(String email, BuildContext context) async {
//     // Show the loading dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Disallow dismissing while loading
//       builder: (BuildContext context) {
//         return const SimpleDialog(
//           title: Text('Sending Verification Link'),
//           children: [
//             Center(
//               child: CircularProgressIndicator(),
//             ),
//           ],
//         );
//       },
//     );
//
//     try {
//       final response = await http.post(
//         Uri.parse('${AppData.remoteUrl}/send-verification-link'),
//         body: {'email': email},
//       );
//
//       // Close the loading dialog
//       Navigator.of(context).pop();
//
//       if (response.statusCode == 200) {
//         // Successful API call, handle the response if needed
//         // Show success Snackbar
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Verification link sent successfully'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else if (response.statusCode == 422) {
//         // Validation error or user email not found
//         // Show error Snackbar
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Validation error or user email not found'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else if (response.statusCode == 404) {
//         // User already verified
//         // Show info Snackbar
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('User already verified'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else {
//         // Something went wrong
//         // Show error Snackbar
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Something went wrong.'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       // Handle network errors or other exceptions
//       // Close the loading dialog
//       Navigator.of(context).pop();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Something went wrong.'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   void showVerifyMessage(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Verify Account'),
//           content: const Text('Please verify your account.'),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 // Add your logic for resending the verification link here
//
//                 String email = emailController.text;
//                 sendVerificationLink(email,context);
//               },
//               child: const Text('Resend Link'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void showErrorMessage(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Error', style: GoogleFonts.acme()),
//           content: Text(message, style: GoogleFonts.acme()),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK', style: GoogleFonts.acme()),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Dismiss the dialog
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       //resizeToAvoidBottomInset: false,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 100),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment(_gradientOffset, 0),
//                   end: Alignment(_gradientOffset - 4, 0),
//                   colors: const [Colors.white60, Colors.cyan],
//                 ),
//               ),
//             ),
//           ),
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Image.asset(
//                         'assets/logo/logo.png',
//                         // Replace with your app logo image path
//                         height: 150,
//                       ),
//                       const SizedBox(height: 20),
//                       TextField(
//                         controller: emailController,
//                         decoration: InputDecoration(
//                           labelText: 'Email',
//                           labelStyle: GoogleFonts.acme(
//                             fontSize: 15,
//                             color: Colors.black,
//                           ),
//                           prefixIcon: const Icon(Icons.email),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//
// // Inside your build method, modify the password TextField as follows:
//                       TextField(
//                         obscureText: !_passwordVisible,
//                         // This will hide/show the password based on _passwordVisible
//                         controller: passwordController,
//                         decoration: InputDecoration(
//                           labelText: 'Password',
//                           labelStyle: GoogleFonts.acme(
//                             fontSize: 15,
//                             color: Colors.black,
//                           ),
//                           prefixIcon: const Icon(Icons.lock),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               // Change the icon based on the state of _passwordVisible
//                               _passwordVisible
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                             ),
//                             onPressed: () {
//                               // Update the state to toggle password visibility
//                               setState(() {
//                                 _passwordVisible = !_passwordVisible;
//                               });
//                             },
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 10),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: InkWell(
//                           onTap: () {
//                             // TODO: Navigate to Forgot Password Screen
//                             _showForgotPasswordDialog();
//                           },
//                           child: Text(
//                             'Forgot Password?',
//                             style: GoogleFonts.acme(
//                               color: Colors.blue,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Checkbox(
//                             value: rememberMe,
//                             onChanged: (bool? value) {
//                               setState(() {
//                                 rememberMe = value!;
//                               });
//                             },
//                             activeColor: Colors.blue,
//                           ),
//                           Text('Remember Me',
//                               style: GoogleFonts.acme(color: Colors.black)),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       Container(
//                         margin: const EdgeInsets.all(16.0),
//                         // Add desired margin around the button
//                         child:  CustomElevatedButton(
//                           width: 70.w,
//                           // name: continueWithGoogle,
//                           // color: Colors.redAccent,
//                           buttonStyle: ElevatedButton.styleFrom(
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(
//                                     20), // button's shape
//                               )),
//                           text: 'Login',
//                           onPressed: () {
//                             String email = emailController.text;
//                             String password = passwordController.text;
//                             performLogin(email, password);
//                           },
//                         ),
//                       ),
//
//                       if (_isLoading)
//                         const CircularProgressIndicator(
//                           valueColor:
//                           AlwaysStoppedAnimation<Color>(Colors.blue),
//                         ),
//                       const Text('OR'),
//                       const SizedBox(height: 10),
//                       const SocialLoginWidget(),
//                       const SizedBox(height: 20),
//                       InkWell(
//                         onTap: () {
//                           // Navigator.push(
//                           //   context,
//                           //   MaterialPageRoute(
//                           //       builder: (context) => const SignupScreen()),
//                           // );
//                         },
//                         child: RichText(
//                           text: TextSpan(
//                             text: "Don't have an account? ",
//                             style: GoogleFonts.acme(color: Colors.black),
//                             children: <TextSpan>[
//                               TextSpan(
//                                 text: 'Register',
//                                 style: GoogleFonts.acme(
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Center(
//                         child: Column(
//                           children: <Widget>[
//                             const Center(
//                               child: Row(
//                                 children: [
//                                   Center(
//                                     child: Text(
//                                       'Need More Help? ',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: 16.0,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//
//                             Column(
//                               children: [
//                                 InkWell(
//                                   onTap: () async {
//                                     final Uri url = Uri.parse(
//                                         'https://wa.me/+971504957572'); // WhatsApp URL as a Uri object
//                                     // Ask the user for confirmation before launching the URL
//                                     bool? confirm = await showDialog<bool>(
//                                       context: context,
//                                       builder: (BuildContext context) {
//                                         return AlertDialog(
//                                           title: const Text('Open WhatsApp'),
//                                           content: const Text(
//                                               'Would you like to open WhatsApp to send a message?'),
//                                           actions: <Widget>[
//                                             TextButton(
//                                               child: const Text('Cancel'),
//                                               onPressed: () {
//                                                 Navigator.of(context)
//                                                     .pop(false); // User does not want to leave the app
//                                               },
//                                             ),
//                                             TextButton(
//                                               child: const Text('Yes'),
//                                               onPressed: () {
//                                                 Navigator.of(context)
//                                                     .pop(true); // User confirms to leave the app
//                                               },
//                                             ),
//                                           ],
//                                         );
//                                       },
//                                     );
//
//                                     if (confirm == true) {
//                                       await launchUrl(url);
//                                     }
//                                   },
//                                   child: Row(
//                                     children: [
//                                       Image.asset(
//                                         'assets/logo/whatsapp.png',
//                                         // Make sure you have a WhatsApp icon in SVG format in your assets
//                                         height: 20,
//                                         width: 20,
//                                       ),
//                                       const Text(
//                                         ' Connect on WhatsApp',
//                                         style: TextStyle(
//                                           color: Colors.green,
//                                           fontSize: 16.0,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       )
//
//
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
