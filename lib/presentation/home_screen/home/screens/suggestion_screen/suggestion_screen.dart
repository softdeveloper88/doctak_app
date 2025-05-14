import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // New variable to track loading state
  SuggestionBloc suggestionBloc = SuggestionBloc();
  final FocusNode _nameFocusNode = FocusNode(); // Create a FocusNode
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> submitSuggestion() async {
    if (_formKey.currentState!.validate()) {
      // API call to submit the suggestion

      setState(() => _isLoading = true); // Start loading
      suggestionBloc.add(SaveSuggestion(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        message: _messageController.text,
      ));
      // final response = await http.post(
      //   Uri.parse("${AppData.remoteUrl}/save-suggestion"),
      //   headers: {
      //     'Authorization': 'Bearer ${AppData.userToken}',
      //     // Add token to the request header
      //   },
      //   body: {
      //     'name': _nameController.text,
      //     'phone': _phoneController.text,
      //     'email': _emailController.text,
      //     'message': _messageController.text,
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   setState(() => _isLoading = false); // Stop loading
      //
      //   // Show success message
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Message Sent Successfully!')),
      //   );
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _messageController.clear();

      _nameFocusNode.requestFocus();
      // _showSuccessDialog();
    } else {
      // Handle errors
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translation(context).lbl_success),
          content: Text(translation(context).msg_suggestion_thank_you),
          actions: <Widget>[
            TextButton(
              child: Text(translation(context).lbl_ok),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(translation(context).lbl_suggestions, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 20),
                _buildTextField(
                  translation(context).lbl_enter_your_name,
                  _nameController,
                  translation(context).lbl_name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return translation(context).msg_please_enter_name;
                    }
                    return null;
                  }
                ),
                _buildTextField(
                  '03xxxxxxxx',
                  _phoneController,
                  translation(context).lbl_phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return translation(context).msg_please_enter_phone;
                    }
                    return null;
                  }
                ),
                _buildTextField(
                  'info@doctak.net',
                  _emailController,
                  translation(context).lbl_email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return translation(context).msg_please_enter_email;
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return translation(context).err_msg_please_enter_valid_email;
                    }
                    return null;
                  }
                ),
                _buildTextField(
                  translation(context).lbl_type_message_here,
                  _messageController,
                  translation(context).lbl_message,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return translation(context).msg_please_enter_message;
                    }
                    return null;
                  }
                ),

                BlocListener<SuggestionBloc, SuggestionState>(
                  bloc: suggestionBloc,
                  listener: (BuildContext context, SuggestionState state) {
                    if (state is PaginationLoadedState) {
                      // var data = jsonDecode(state.response);
                      // if (data['message'] == true) {}
                    }
                  },
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : submitSuggestion,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    // Disable button when loading
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(translation(context).lbl_submit),
                  ),
                ),
                const SizedBox(height: 20),

                _buildWhatsAppContactRow(),
                // Call the method to build the new row
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppContactRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          translation(context).msg_need_more_help,
          style: TextStyle(
            color: svGetBodyColor(),
            fontSize: 16.0,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              final Uri url = Uri.parse(
                  'https://wa.me/+971504957572'); // WhatsApp URL as a Uri object
              // Ask the user for confirmation before launching the URL
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(translation(context).lbl_open_whatsapp),
                    content: Text(translation(context).msg_open_whatsapp_confirm),
                    actions: <Widget>[
                      TextButton(
                        child: Text(translation(context).lbl_cancel),
                        onPressed: () {
                          Navigator.of(context).pop(
                              false); // User does not want to leave the app
                        },
                      ),
                      TextButton(
                        child: Text(translation(context).lbl_yes),
                        onPressed: () {
                          Navigator.of(context)
                              .pop(true); // User confirms to leave the app
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await launchUrl(url);
              }
            },
            child: Row(
              children: [
                Image.asset(
                  color: Colors.green,
                  'assets/logo/whatsapp.png',
                  // Make sure you have a WhatsApp icon in SVG format in your assets
                  height: 20,
                  width: 20,
                ),
                Flexible(
                  child: Text(
                    translation(context).msg_connect_on_whatsapp,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String hint, TextEditingController controller, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: controller == _nameController ? _nameFocusNode : null,
        // Assign the FocusNode here

        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}
