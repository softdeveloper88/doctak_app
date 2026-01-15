import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
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
      suggestionBloc.add(SaveSuggestion(name: _nameController.text, phone: _phoneController.text, email: _emailController.text, message: _messageController.text));
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
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(title: translation(context).lbl_suggestions, titleIcon: Icons.feedback_rounded),
      body: Container(
        color: theme.scaffoldBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
            children: <Widget>[
              // Header Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: theme.cardShadow),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.message_rounded, color: theme.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'d love to hear from you!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your suggestions, feedback, or ideas to help us improve.',
                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: theme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Form Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: theme.cardShadow),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      theme,
                      translation(context).lbl_enter_your_name,
                      _nameController,
                      translation(context).lbl_name,
                      Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translation(context).msg_please_enter_name;
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      theme,
                      '03xxxxxxxx',
                      _phoneController,
                      translation(context).lbl_phone,
                      Icons.phone_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translation(context).msg_please_enter_phone;
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      theme,
                      'info@doctak.net',
                      _emailController,
                      translation(context).lbl_email,
                      Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translation(context).msg_please_enter_email;
                        }
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return translation(context).err_msg_please_enter_valid_email;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      theme,
                      translation(context).lbl_type_message_here,
                      _messageController,
                      translation(context).lbl_message,
                      Icons.message_outlined,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translation(context).msg_please_enter_message;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              // Submit Button
              BlocListener<SuggestionBloc, SuggestionState>(
                bloc: suggestionBloc,
                listener: (BuildContext context, SuggestionState state) {
                  if (state is PaginationLoadedState) {
                    // var data = jsonDecode(state.response);
                    // if (data['message'] == true) {}
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : submitSuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                translation(context).lbl_submit,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              // WhatsApp Contact Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.success.withValues(alpha: 0.2), width: 1),
                  boxShadow: [BoxShadow(color: theme.success.withValues(alpha: 0.05), offset: const Offset(0, 2), blurRadius: 8, spreadRadius: 0)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.support_agent_rounded, color: theme.success, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context).msg_need_more_help,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get instant support via WhatsApp',
                                style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: theme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('https://wa.me/+971504957572');
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded, color: theme.success, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_open_whatsapp,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              content: Text(translation(context).msg_open_whatsapp_confirm, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                  child: Text(
                                    translation(context).lbl_cancel,
                                    style: TextStyle(color: theme.textSecondary, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    translation(context).lbl_yes,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          await launchUrl(url);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.success.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo/whatsapp.png', height: 24, width: 24, color: theme.success),
                            const SizedBox(width: 12),
                            Text(
                              translation(context).msg_connect_on_whatsapp,
                              style: TextStyle(color: theme.success, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: theme.success, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(OneUITheme theme, String hint, TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? Function(String?)? validator}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: controller == _nameController ? _nameFocusNode : null,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: theme.primary),
          ),
          labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textSecondary),
          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.error.withValues(alpha: 0.7), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.error, width: 2),
          ),
          filled: true,
          fillColor: theme.surfaceVariant,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
        ),
      ),
    );
  }
}
