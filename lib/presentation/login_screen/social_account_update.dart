// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
//
// class SocialAccountUpdate extends StatefulWidget {
//    SocialAccountUpdate(this.token, this.name,{Key? key}) : super(key: key);
// String token;
// String name;
//    @override
//   State<SocialAccountUpdate> createState() => _SocialAccountUpdateState();
// }
//
// class _SocialAccountUpdateState extends State<SocialAccountUpdate> {
//   late Timer _timer;
//   double _gradientOffset = 0;
//
//   final TextEditingController _fullNameController = TextEditingController();
//   // final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneNoController = TextEditingController();
//   final TextEditingController _genderController = TextEditingController();
//   // final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _newClinicController = TextEditingController();
//   final TextEditingController _newUniversityController =
//   TextEditingController();
//   final TextEditingController _controller = TextEditingController();
//   bool _isLoading = false;
//   bool isCountryLoaded = false;
//   bool isStateLoaded = false;
//   bool isClinicLoaded = false;
//   bool isUniversityLoaded = false;
//   bool isSpecialtyLoaded = false;
//   List<String> countryList = [];
//   List<String> stateList = [];
//   List<String> clinicList = [];
//   List<String> universityList = [];
//   List<String> specialtyList = [];
//   String? selectedType;
//   String? specialtySelected;
//   String? selectedState;
//   String? selectedClinic;
//   String? selectedUniversity;
//   bool showNewUniversity = false;
//   bool showNewClinic = false;
//   String? countryValidationError;
//   String? stateValidationError;
//   String? clinicValidationError;
//   List<String> _filteredClinics = [];
//   bool isDoctorRole = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fullNameController.text=widget.name;
//     _timer = Timer.periodic(const Duration(milliseconds: 100), _updateGradient);
//
//     fetchCountryList();
//     fetchSpecialty();
//   }
//
//   void _filterClinics(String query) {
//     setState(() {
//       _filteredClinics = clinicList
//           .where((clinic) => clinic.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   void showUniversityTextField() {
//     print(selectedUniversity);
//     if (selectedUniversity == "Add new University") {
//       setState(() {
//         showNewUniversity = true;
//       });
//     } else {
//       setState(() {
//         showNewUniversity = false;
//       });
//     }
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
//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }
//
//   Future<void> fetchCountryList() async {
//     final RemoteService service = RemoteService();
//
//     try {
//       List<String>? countries = await service.getCountryListwithOutAuth();
//
//       if (countries != null) {
//         setState(() {
//           countryList = countries;
//           if (countryList.isNotEmpty) {
//             selectedType = countryList.first;
//             fetchStates();
//           }
//           isCountryLoaded = true;
//         });
//       } else {
//         // Handle the case where countries are null
//         print("Error fetching country list");
//       }
//     } catch (e) {
//       // Handle other exceptions that might occur during the fetch
//       print("Error fetching country list: $e");
//     }
//   }
//
//   Future<void> fetchSpecialty() async {
//     final RemoteService service = RemoteService();
//     try {
//       List<String>? specialties = await service.getSpecialty();
//       if (specialties != null) {
//         setState(() {
//           specialtyList = specialties;
//           if (specialtyList.isNotEmpty) {
//             specialtySelected = specialtyList.first;
//             // _controller.text='';
//             // fetchStates();
//             print("dddd $specialtySelected");
//           }
//           isSpecialtyLoaded = true;
//         });
//       } else {
//         // Handle the case where countries are null
//         print("Error fetching country list");
//       }
//     } catch (e) {
//       // Handle other exceptions that might occur during the fetch
//       print("Error fetching country list: $e");
//     }
//   }
//
//   Future<void> fetchClinics() async {
//     final RemoteService service = RemoteService();
//
//     try {
//       List<String>? states = await service.getClinic(selectedState!);
//
//       if (states != null) {
//         setState(() {
//           clinicList = states;
//           if (clinicList.isNotEmpty) {
//             selectedClinic = clinicList.first;
//           }
//           isClinicLoaded = true;
//         });
//       } else {
//         // Handle the case where states are null
//         print("Error fetching state list");
//       }
//     } catch (e) {
//       // Handle other exceptions that might occur during the fetch
//       print("Error fetching state list: $e");
//     }
//   }
//
//   Future<void> fetchUniversity(state) async {
//     final RemoteService service = RemoteService();
//
//     try {
//       List<String>? states = await service.getUniversity(selectedState!);
//       states.add("Add new University");
//       if (states != null) {
//         setState(() {
//           universityList = states;
//           if (universityList.isNotEmpty) {
//             selectedUniversity = universityList.first;
//           }
//           isUniversityLoaded = true;
//         });
//       } else {
//         // Handle the case where states are null
//         print("Error fetching state list");
//       }
//     } catch (e) {
//       // Handle other exceptions that might occur during the fetch
//       print("Error fetching state list: $e");
//     }
//   }
//
//   Future<void> fetchStates() async {
//     final RemoteService service = RemoteService();
//
//     try {
//       List<String>? states = await service.getStates(selectedType!);
//
//       if (states != null) {
//         setState(() {
//           stateList = states;
//           if (stateList.isNotEmpty) {
//             selectedState = stateList.first;
//             fetchUniversity(stateList.first);
//           }
//           isStateLoaded = true;
//         });
//       } else {
//         // Handle the case where states are null
//         print("Error fetching state list");
//       }
//     } catch (e) {
//       // Handle other exceptions that might occur during the fetch
//       print("Error fetching state list: $e");
//     }
//   }
//
//   Future<void> _registerUser() async {
//     print(specialtySelected);
//
//     // Check if the form is valid
//     if (!_isFormValid()) {
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final url = Uri.parse('${AppData.remoteUrl}/complete-profile');
//     http.Response response;
//     if (isDoctorRole) {
//       response = await http.post(
//         url,
//         body: {
//           'name':_fullNameController.text,
//           'phone': _phoneNoController.text,
//           'specialty': _controller.text,
//           'country': selectedType,
//           'state': selectedState,
//           'user_type': 'doctor'
//         },
//         headers: <String, String>{
//           'Authorization': 'Bearer ${widget.token}',
//           // Replace with your actual token
//         },
//       );
//     } else {
//       response = await http.post(
//         url,
//         body: {
//           'name':_fullNameController.text,
//           'phone': _phoneNoController.text,
//           'new_university_name': _newUniversityController.text ?? "",
//           'university_name': selectedUniversity,
//           'country': selectedType,
//           'state': selectedState,
//           'user_type': 'student'
//         },
//         headers: <String, String>{
//           'Authorization': 'Bearer ${widget.token}',
//           // Replace with your actual token
//         },
//       );
//     }
//     if (response.statusCode == 200) {
//       final responseData = jsonDecode(response.body);
//       bool success = responseData['success'];
//       print(responseData);
//       if (success) {
//         var user = responseData['user'];
//
//         final token = responseData['token'];
//         // ... store user details and token in SharedPreferences
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         AppData.logInUserId = user['id'];
//         await prefs.setBool('rememberMe', true);
//         await prefs.setString('token', token ?? '');
//         await prefs.setString('userId', user['id'] ?? '');
//         await prefs.setString('name', user['name'] ?? '');
//         await prefs.setString('profile_pic', user['profile_pic'] ?? '');
//         await prefs.setString('email', user['email'] ?? '');
//         await prefs.setString('phone', user['phone'] ?? '');
//         await prefs.setString('background', user['background'] ?? '');
//         await prefs.setString('specialty', user['specialty'] ?? '');
//         await prefs.setString('licenseNo', user['license_no'] ?? '');
//         await prefs.setString('title', user['title'] ?? '');
//         await prefs.setString('city', user['city'] ?? '');
//         await prefs.setString('countryOrigin', user['country_origin'] ?? '');
//         await prefs.setString('college', user['college'] ?? '');
//         await prefs.setString('clinicName', user['clinic_name'] ?? '');
//         await prefs.setString('dob', user['dob'] ?? '');
//         await prefs.setString('user_type', user['user_type'] ?? '');
//         await prefs.setString('countryName', responseData['country']['countryName'] ?? '');
//         await prefs.setString('currency', responseData['country']['currency'] ?? '');
//         if (responseData['university'] != null) {
//           await prefs.setString('university', responseData['university']['name'] ?? '');
//         }
//         await prefs.setString('practicingCountry', user['practicing_country'] ?? '');
//         await prefs.setString('gender', user['gender'] ?? '');
//          await prefs.setString('country', user['country'].toString()??'');
//         String? userToken = prefs.getString('token') ?? '';
//         String? userId = prefs.getString('userId') ?? '';
//         String? name = prefs.getString('name') ?? '';
//         String? profile_pic = prefs.getString('profile_pic') ?? '';
//         String? background = prefs.getString('background') ?? '';
//         String? email = prefs.getString('email') ?? '';
//         String? specialty = prefs.getString('specialty') ?? '';
//         String? userType = prefs.getString('user_type') ?? '';
//         String? university = prefs.getString('university') ?? '';
//         String? countryName = prefs.getString('country') ?? '';
//         String? currency = prefs.getString('currency') ?? '';
//         if (userToken != '') {
//           AppData.userToken = userToken;
//           AppData.logInUserId = userId;
//           AppData.name = name;
//           AppData.profile_pic = profile_pic;
//           AppData.university = university;
//           AppData.userType = userType;
//           AppData.background = background;
//           AppData.email = email;
//           AppData.specialty = specialty;
//           AppData.countryName = countryName;
//           AppData.currency = currency;
//         }
//         // Navigate to home screen
//         _navigateToHomeScreen();
//
//         // _showSuccessDialog();
//       }
//     } else if (response.statusCode == 409) {
//       final responseData = json.decode(response.body);
//       final errorMessage =
//           responseData['message'] ?? 'Email already registered';
//       _showErrorDialog(errorMessage);
//     } else {
//       _showErrorDialog(
//           '${response.statusCode}');
//     }
//     setState(() {
//       _isLoading = false;
//     });
//   }
//   void _navigateToHomeScreen() {
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) =>  const HomeScreen()));
//   }
//
//   bool _isFormValid() {
//     // Validate each field and return true if the form is valid
//
//     // Add validations for other fields if needed
//
//     if (_fullNameController.text.isEmpty) {
//       _showErrorDialog('Name must not be empty');
//       return false;
//     } if (_phoneNoController.text.isEmpty) {
//       _showErrorDialog('Phone must not be empty');
//       return false;
//     }
//     if (isDoctorRole) {
//       if (_controller.text.isEmpty) {
//         _showErrorDialog('Select your speciality');
//         return false;
//       }
//     }
//     if (showNewUniversity) {
//       if (_newUniversityController.text.isEmpty) {
//         _showErrorDialog('Enter name of new University');
//         return false;
//       }
//     }
//     //   if (_passwordController.text.isEmpty) {
//     //     _showErrorDialog('Password must not be empty');
//     //     return false;
//     //   }
//     // }
//
//     // If all validations pass, return true
//     return true;
//   }
//
//   void updateStatesBasedOnCountry() {
//     // You can add logic here to update other states based on the selected country
//     // For example, you can make a network call to fetch additional information based on the country
//     // and update the corresponding state variables.
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Registration Completed'),
//           content: const Text('Your registration was successful.'),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 final SharedPreferences prefs =
//                 await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 Navigator.pop(context); // Close the dialog
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const SignInScreen()));
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Error'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // Close the dialog
//               },
//               child: const Text('OK'),
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
//       body: SingleChildScrollView(
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 100),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment(_gradientOffset, 0),
//                     end: Alignment(_gradientOffset - 4, 0),
//                     colors: const [Colors.white60, Colors.cyan],
//                   ),
//                 ),
//               ),
//             ),
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       'assets/logo/logo.png',
//                       // Replace with your app logo image path
//                       height: 150,
//                     ),
//                     Text("Please Complete your profile",style: GoogleFonts.poppins(color: Colors.black,fontSize: 16.sp,fontWeight: FontWeight.w500),),
//                     const SizedBox(height: 10,),
//                     Container(
//                       width: 90.w,
//                       // height: 15.w,
//                       decoration: BoxDecoration(
//                           color: Colors.blueGrey[300],
//                           borderRadius:
//                           const BorderRadius.all(Radius.circular(15))),
//                       child: Row(
//                         children: [
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 isDoctorRole = true;
//                               });
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(10),
//                               width: 45.w,
//                               height: 12.w,
//                               decoration: BoxDecoration(
//                                   color: !isDoctorRole
//                                       ? Colors.blueGrey[300]
//                                       : Colors.blue,
//                                   borderRadius: const BorderRadius.all(
//                                       Radius.circular(15))),
//                               child: Center(
//                                   child: Text(
//                                     "Doctor",
//                                     style: CustomTextStyles
//                                         .titleMediumOnPrimaryContainer,
//                                   )),
//                             ),
//                           ),
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 isDoctorRole = false;
//                               });
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(10),
//                               width: 45.w,
//                               height: 12.w,
//                               decoration: BoxDecoration(
//                                   color: isDoctorRole
//                                       ? Colors.blueGrey[300]
//                                       : Colors.blue,
//                                   borderRadius: const BorderRadius.all(
//                                       Radius.circular(15))),
//                               child: Center(
//                                   child: Text(
//                                     "Medical student",
//                                     style: CustomTextStyles
//                                         .titleMediumOnPrimaryContainer,
//                                   )),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       controller: _fullNameController,
//                       decoration: InputDecoration(
//                         labelText: 'Full Name',
//                         labelStyle: GoogleFonts.acme(
//                           fontSize: 15,
//                           color: Colors.black,
//                         ),
//                         prefixIcon: const Icon(Icons.person),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your full name';
//                         }
//                         return null; // Return null if the input is valid
//                       },
//                     ),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       controller: _phoneNoController,
//                       keyboardType: TextInputType.phone,
//                       // Set the keyboard type to phone
//                       decoration: InputDecoration(
//                         labelText: 'Phone',
//                         labelStyle: GoogleFonts.acme(
//                           fontSize: 15,
//                           color: Colors.black,
//                         ),
//                         prefixIcon: const Icon(Icons.mobile_friendly_outlined),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your phone number';
//                         } else if (!isValidPhone(value)) {
//                           return 'Please enter a valid phone number';
//                         }
//                         return null; // Return null if the input is valid
//                       },
//                     ),
//                     const SizedBox(height: 20),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.all(4.0),
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: isCountryLoaded ? selectedType : null,
//                         underline: const SizedBox(),
//                         items: isCountryLoaded
//                             ? countryList.map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Row(
//                               children: <Widget>[
//                                 const Icon(Icons.flag_outlined),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   value,
//                                   style: const TextStyle(
//                                       color: Colors.black),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList()
//                             : [
//                           const DropdownMenuItem<String>(
//                             value: null,
//                             child: Text(
//                               'Loading...',
//                               style: TextStyle(color: Colors.black),
//                             ),
//                           ),
//                         ],
//                         onChanged: isCountryLoaded
//                             ? (String? value) {
//                           setState(() {
//                             selectedType = value!;
//                             fetchStates();
//                           });
//                         }
//                             : null,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.all(4.0),
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: isStateLoaded ? selectedState : null,
//                         underline: const SizedBox(),
//                         items: isStateLoaded
//                             ? stateList.map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Row(
//                               children: <Widget>[
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   value,
//                                   style: const TextStyle(
//                                       color: Colors.black),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList()
//                             : [
//                           const DropdownMenuItem<String>(
//                             value: null,
//                             child: Text(
//                               'Loading...',
//                               style: TextStyle(color: Colors.black),
//                             ),
//                           ),
//                         ],
//                         onChanged: isStateLoaded
//                             ? (String? value) {
//                           setState(() {
//                             selectedState = value!;
//                             fetchUniversity(selectedState);
//                           });
//                         }
//                             : null,
//                       ),
//                     ),
//                     //  if(!isDoctorRole)const SizedBox(height: 20),
//                     // if(!isDoctorRole) Container(
//                     //    decoration: BoxDecoration(
//                     //      border: Border.all(color: Colors.grey),
//                     //      borderRadius: BorderRadius.circular(20),
//                     //    ),
//                     //    padding: const EdgeInsets.all(4.0),
//                     //    child: DropdownButton<String>(
//                     //      isExpanded: true,
//                     //      value: studentStatus.first,
//                     //      underline: const SizedBox(),
//                     //      items:studentStatus.map((String value) {
//                     //        return DropdownMenuItem<String>(
//                     //          value: value,
//                     //          child: Row(
//                     //            children: <Widget>[
//                     //              const SizedBox(width: 8),
//                     //              Text(
//                     //                value,
//                     //                style: const TextStyle(color: Colors.black),
//                     //              ),
//                     //            ],
//                     //          ),
//                     //        );
//                     //      }).toList(),
//                     //      onChanged: (String? value) {
//                     //        setState(() {
//                     //          selectedStudentStatus = value!;
//                     //        });
//                     //      },
//                     //    ),
//                     //  ),
//                     const SizedBox(height: 20),
//                     if (isDoctorRole)
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         padding: const EdgeInsets.all(4.0),
//                         // child: DropdownButton<String>(
//                         //   isExpanded: true,
//                         //   value: isSpecialtyLoaded ? specialtySelected : null,
//                         //   underline: const SizedBox(),
//                         //   items: isSpecialtyLoaded
//                         //       ? specialtyList.map((String value) {
//                         //           return DropdownMenuItem<String>(
//                         //               value: value,
//                         //               child: Row(
//                         //                 children: [
//                         //                   Expanded(
//                         //                     child: ClipRect(
//                         //                       child: Text(
//                         //                         value,
//                         //                         style: const TextStyle(
//                         //                             color: Colors.black),
//                         //                       ),
//                         //                     ),
//                         //                   ),
//                         //                 ],
//                         //               ));
//                         //         }).toList()
//                         //       : [
//                         //           const DropdownMenuItem<String>(
//                         //             value: null,
//                         //             child: Text(
//                         //               ' Loading...',
//                         //               style: TextStyle(color: Colors.black),
//                         //             ),
//                         //           ),
//                         //         ],
//                         //   onChanged: isSpecialtyLoaded
//                         //       ? (String? value) {
//                         //           setState(() {
//                         //             specialtySelected = value!;
//                         //             // fetchStates();
//                         //           });
//                         //         }
//                         //       : null,
//                         // ),
//                         child: Column(
//                           children: [
//                             isSpecialtyLoaded
//                                 ? CustomDropdownSearch(
//                               hintText: 'Select speciality',
//                               textController: _controller,
//                               items: specialtyList,
//                               dropdownHeight: 300,
//                               onSelect: (select) {
//                                 setState(() {
//                                   specialtySelected = select;
//                                 });
//                               },
//                             )
//                                 : Container(
//                               width: 90.w,
//                               padding: const EdgeInsets.all(4.0),
//                               child: const Text('Loading...'),
//                             )
//                           ],
//                         ),
//                       )
//                     else
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         padding: const EdgeInsets.all(4.0),
//                         child: DropdownButton<String>(
//                           isExpanded: true,
//                           value: isUniversityLoaded ? selectedUniversity : null,
//                           underline: const SizedBox(),
//                           items: isUniversityLoaded
//                               ? universityList.map((String value) {
//                             return DropdownMenuItem<String>(
//                                 value: value,
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: ClipRect(
//                                         child: Text(
//                                           value,
//                                           style: const TextStyle(
//                                               color: Colors.black),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ));
//                           }).toList()
//                               : [
//                             const DropdownMenuItem<String>(
//                               value: null,
//                               child: Text(
//                                 ' Loading...',
//                                 style: TextStyle(color: Colors.black),
//                               ),
//                             ),
//                           ],
//                           onChanged: isUniversityLoaded
//                               ? (String? value) {
//                             setState(() {
//                               selectedUniversity = value!;
//                               // fetchStates();
//                               showUniversityTextField();
//                             });
//                           }
//                               : null,
//                         ),
//                       ),
//                     Column(
//                       children: [
//                         // Existing widgets
//                         if (showNewUniversity) const SizedBox(height: 20),
//                         if (showNewUniversity)
//                           TextFormField(
//                             controller: _newUniversityController,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'University name must not be empty';
//                               }
//                               return null;
//                             },
//                             decoration: InputDecoration(
//                               labelText: 'Add new University',
//                               labelStyle: GoogleFonts.acme(
//                                 fontSize: 15,
//                                 color: Colors.black,
//                               ),
//                               prefixIcon: const Icon(Icons.local_hospital),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     // const SizedBox(height: 20),
//                     const SizedBox(height: 20),
//                     if (_isLoading)
//                       const CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                       )
//                     else
//                       AnimatedContainer(
//                         duration: const Duration(milliseconds: 100),
//                         child: ElevatedButton(
//                           onPressed: _registerUser,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 40, vertical: 12),
//                             foregroundColor: Colors.lightBlueAccent,
//                             backgroundColor: Colors.transparent,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                               side: const BorderSide(color: Colors.cyan),
//                             ),
//                           ),
//                           child: Text(
//                             'Proceed',
//                             style: GoogleFonts.acme(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Already have an account? ",
//                           style: GoogleFonts.acme(
//                             color: Colors.black,
//                           ),
//                         ),
//                         InkWell(
//                           onTap: () {
//                             // Navigate to signin screen
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                     const SignInScreen()));
//                           },
//                           child: Text(
//                             'Sign In',
//                             style: GoogleFonts.acme(
//                               fontWeight: FontWeight.w600,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 80),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   bool isValidEmail(String email) {
//     // Use a regular expression for basic email format validation
//     final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
//     return emailRegex.hasMatch(email);
//   }
//   bool isValidPhone(String phone) {
//     // Use a regular expression for basic phone number format validation
//     final phoneRegex = RegExp(r'^[0-9]{10}$');
//     return phoneRegex.hasMatch(phone);
//   }
// }
