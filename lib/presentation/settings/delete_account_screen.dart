import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/data/apiClient/services/account_deletion_api_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
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
              padding: const EdgeInsets.all(16),
              children: [
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete your DocTak account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account will be deactivated immediately and permanently deleted after a 30-day grace period. Sign in before the scheduled date to cancel.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: theme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data that will be deleted',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...AccountDeletionApiService.dataCategories.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, size: 6, color: theme.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: theme.textSecondary,
                                    height: 1.4,
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
                const SizedBox(height: 12),
                if (_status?.hasPending == true)
                  AppSurfaceCard(
                    margin: EdgeInsets.zero,
                    borderColor: Colors.orange.withValues(alpha: 0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deletion scheduled',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your account is scheduled for deletion on ${_formatDate(_status?.scheduledAt)}.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _cancelling ? null : _cancelDeletion,
                            child: Text(_cancelling ? 'Cancelling…' : 'Cancel deletion request'),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  AppSurfaceCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.lbl_delete_account_confirmation,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.msg_delete_account_warning,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: theme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText: 'Reason (optional)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Current password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: 'Type DELETE to confirm',
                            hintText: 'DELETE',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _submitting ? null : _submitDeletion,
                            child: Text(
                              _submitting ? 'Submitting…' : 'Schedule account deletion',
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web deletion page',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AccountDeletionApiService.publicDeleteUrl,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openWebDeletionPage,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open in browser'),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13),
                  ),
                ],
              ],
            ),
    );
  }
}
