import 'package:doctak_app/data/apiClient/settings_api_service.dart';
import 'package:doctak_app/presentation/settings/security_two_factor_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SecurityAccountScreen extends StatefulWidget {
  const SecurityAccountScreen({super.key});

  @override
  State<SecurityAccountScreen> createState() => _SecurityAccountScreenState();
}

class _SecurityAccountScreenState extends State<SecurityAccountScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldController.text;
    final newPassword = _newController.text;
    final confirmation = _confirmController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      toast('Enter your current and new password.');
      return;
    }
    if (newPassword.length < 8) {
      toast('New password must be at least 8 characters.');
      return;
    }
    if (newPassword != confirmation) {
      toast('Password confirmation does not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      final message = await SettingsApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmation: confirmation,
      );
      if (!mounted) return;
      _oldController.clear();
      _newController.clear();
      _confirmController.clear();
      toast(message);
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passwordVisibilityToggle({
    required OneUITheme theme,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      tooltip: obscure ? 'Show password' : 'Hide password',
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: theme.textSecondary,
      ),
      onPressed: onToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Security',
        titleIcon: Icons.shield_rounded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppSurfaceCard(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            onTap: () => AppNavigator.push(context, const SecurityTwoFactorScreen()),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.verified_user_rounded, color: theme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-factor authentication',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email OTP and authenticator app',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: theme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.textSecondary),
              ],
            ),
          ),
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change password',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a strong password you do not reuse elsewhere.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: theme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                OneUIFormField(
                  label: 'Current password',
                  hintText: 'Enter your current password',
                  controller: _oldController,
                  required: true,
                  obscureText: _obscureOld,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: _passwordVisibilityToggle(
                    theme: theme,
                    obscure: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                const SizedBox(height: 16),
                OneUIFormField(
                  label: 'New password',
                  hintText: 'At least 8 characters',
                  controller: _newController,
                  required: true,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: _passwordVisibilityToggle(
                    theme: theme,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 16),
                OneUIFormField(
                  label: 'Confirm new password',
                  hintText: 'Re-enter new password',
                  controller: _confirmController,
                  required: true,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: _passwordVisibilityToggle(
                    theme: theme,
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  onFieldSubmitted: (_) {
                    if (!_busy) _changePassword();
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _changePassword,
                    style: OneUIButtons.filled(theme).copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
                      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 48)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update password'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
