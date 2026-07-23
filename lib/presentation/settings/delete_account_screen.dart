import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/data/apiClient/services/account_deletion_api_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _reasonController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool _cancelling = false;
  bool _obscurePassword = true;
  AccountDeletionRequestStatus? _status;
  String? _error;

  static const _pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 32);
  static const _cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const _sectionGap = SizedBox(height: 14);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await AccountDeletionApiService.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitDeletion() async {
    final confirm = _confirmController.text.trim().toUpperCase();
    if (confirm != 'DELETE') {
      _showSnack('Type DELETE in the confirmation field to continue.');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showSnack('Your current password is required.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final message = await AccountDeletionApiService.requestDeletion(
        password: _passwordController.text,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      _showSnack(message);
      await AppSharedPreferences().clearSharedPreferencesData(context);
      if (!mounted) return;
      AppNavigator.pushReplacement(context, const LoginScreen());
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
      setState(() => _submitting = false);
    }
  }

  Future<void> _cancelDeletion() async {
    setState(() => _cancelling = true);
    try {
      final message = await AccountDeletionApiService.cancelDeletion();
      if (!mounted) return;
      _showSnack(message);
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openWebDeletionPage() async {
    final uri = Uri.parse(AccountDeletionApiService.deleteAccountWebUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'the scheduled date';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _sectionTitle(OneUITheme theme, String text, {double size = 16}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: theme.textPrimary,
        height: 1.3,
      ),
    );
  }

  Widget _bodyText(OneUITheme theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: theme.textSecondary,
        height: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final t = translation(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: t.lbl_delete_account,
        titleIcon: Icons.delete_outline_rounded,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : ListView(
              padding: _pagePadding,
              children: [
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: _cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(theme, 'Delete your DocTak account', size: 18),
                      const SizedBox(height: 10),
                      _bodyText(
                        theme,
                        'Your account will be deactivated immediately and permanently deleted after a 30-day grace period. Sign in before the scheduled date to cancel.',
                      ),
                    ],
                  ),
                ),
                _sectionGap,
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: _cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(theme, 'Data that will be deleted'),
                      const SizedBox(height: 14),
                      ...AccountDeletionApiService.dataCategories.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: theme.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13.5,
                                    color: theme.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionGap,
                if (_status?.hasPending == true)
                  AppSurfaceCard(
                    margin: EdgeInsets.zero,
                    padding: _cardPadding,
                    borderColor: Colors.orange.withValues(alpha: 0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(theme, 'Deletion scheduled'),
                        const SizedBox(height: 10),
                        _bodyText(
                          theme,
                          'Your account is scheduled for deletion on ${_formatDate(_status?.scheduledAt)}.',
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _cancelling ? null : _cancelDeletion,
                            child: Text(
                              _cancelling ? 'Cancelling…' : 'Cancel deletion request',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AppSurfaceCard(
                    margin: EdgeInsets.zero,
                    padding: _cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(theme, t.lbl_delete_account_confirmation),
                        const SizedBox(height: 10),
                        _bodyText(theme, t.msg_delete_account_warning),
                        const SizedBox(height: 20),
                        OneUIFormField(
                          label: 'Reason (optional)',
                          hintText: 'Tell us why you are leaving…',
                          controller: _reasonController,
                          maxLines: 4,
                          minLines: 3,
                          maxLength: 1000,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                        OneUIFormField(
                          label: 'Current password',
                          hintText: 'Enter your password',
                          controller: _passwordController,
                          required: true,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.visiblePassword,
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OneUIFormField(
                          label: 'Type DELETE to confirm',
                          hintText: 'DELETE',
                          controller: _confirmController,
                          required: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_submitting) _submitDeletion();
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submitting ? null : _submitDeletion,
                            child: Text(
                              _submitting ? 'Submitting…' : 'Schedule account deletion',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _sectionGap,
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: _cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(theme, 'Web deletion page'),
                      const SizedBox(height: 10),
                      _bodyText(
                        theme,
                        'You can also schedule deletion from the website if you prefer.',
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        AccountDeletionApiService.publicDeleteUrl,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          color: theme.primary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _openWebDeletionPage,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Open in browser'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.error,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
