import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SecurityTwoFactorScreen extends StatefulWidget {
  const SecurityTwoFactorScreen({super.key});

  @override
  State<SecurityTwoFactorScreen> createState() => _SecurityTwoFactorScreenState();
}

class _SecurityTwoFactorScreenState extends State<SecurityTwoFactorScreen> {
  bool _loading = true;
  bool _emailEnabled = false;
  bool _appEnabled = false;
  bool _appConfigured = false;
  bool _emailBusy = false;
  bool _setupBusy = false;
  bool _verifyBusy = false;
  String? _secret;
  String? _otpauthUri;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  String? _status;

  Dio get _dio => Dio(BaseOptions(
        baseUrl: AppData.nodeApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          if ((AppData.userToken ?? '').isNotEmpty) 'Authorization': 'Bearer ${AppData.userToken}',
        },
      ));

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get('/api/v1/settings/two-factor');
      final data = response.data;
      if (data is Map) {
        setState(() {
          _emailEnabled = data['emailEnabled'] == true;
          _appEnabled = data['appEnabled'] == true;
          _appConfigured = data['appConfigured'] == true || data['appEnabled'] == true;
        });
      }
    } catch (_) {
      setState(() => _error = 'Could not load two-factor settings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return data['message']?.toString();
      }
    }
    return null;
  }

  bool _isDuplicateMessage(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('duplicate entry') || lower.contains('user_two_factor_auth_user_id_unique');
  }

  Future<void> _toggleEmail(bool enabled) async {
    if (_emailBusy) return;
    setState(() {
      _emailBusy = true;
      _error = null;
    });
    try {
      final response = await _dio.post('/api/v1/settings/two-factor/email', data: {'enabled': enabled});
      final data = response.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _emailEnabled = enabled;
          _status = data['message']?.toString();
        });
        if (mounted) {
          toasty(context, data['message']?.toString() ?? 'Updated', bgColor: Colors.green, textColor: Colors.white);
        }
      } else {
        final message = (data is Map ? data['message']?.toString() : null) ?? 'Failed to update Email OTP.';
        await _recoverFromDuplicateIfNeeded(message, desiredEmail: enabled);
      }
    } on DioException catch (e) {
      final message = _messageFromError(e) ?? 'Failed to update Email OTP.';
      await _recoverFromDuplicateIfNeeded(message, desiredEmail: enabled);
    } catch (_) {
      setState(() => _error = 'Failed to update Email OTP.');
    } finally {
      if (mounted) setState(() => _emailBusy = false);
    }
  }

  Future<void> _recoverFromDuplicateIfNeeded(String message, {required bool desiredEmail}) async {
    if (_isDuplicateMessage(message)) {
      await _loadStatus();
      if (!mounted) return;
      if (_emailEnabled == desiredEmail || (desiredEmail && _emailEnabled)) {
        setState(() {
          _emailEnabled = desiredEmail ? true : _emailEnabled;
          _error = null;
          _status = desiredEmail
              ? 'Email OTP is enabled.'
              : 'Email OTP settings refreshed.';
        });
        toasty(context, _status!, bgColor: Colors.green, textColor: Colors.white);
        return;
      }
    }
    setState(() => _error = message);
  }

  Future<void> _startAuthenticatorSetup({bool reset = false}) async {
    if (_setupBusy) return;
    setState(() {
      _setupBusy = true;
      _error = null;
    });
    try {
      final response = await _dio.post(
        '/api/v1/settings/two-factor/app/setup',
        data: {'reset': reset},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _secret = data['secret']?.toString();
          _otpauthUri = data['otpauthUri']?.toString();
          _appEnabled = false;
          _codeController.clear();
          _passwordController.clear();
          _status = data['message']?.toString() ??
              'Scan the QR code, then enter the 6-digit code to activate.';
        });
      } else {
        final message =
            (data is Map ? data['message']?.toString() : null) ?? 'Could not start authenticator setup.';
        if (_isDuplicateMessage(message)) {
          await _loadStatus();
          // Retry once after conflict — row now exists.
          final retry = await _dio.post(
            '/api/v1/settings/two-factor/app/setup',
            data: {'reset': reset},
          );
          final retryData = retry.data;
          if (retryData is Map && retryData['success'] == true) {
            setState(() {
              _secret = retryData['secret']?.toString();
              _otpauthUri = retryData['otpauthUri']?.toString();
              _appEnabled = false;
              _status = retryData['message']?.toString();
              _error = null;
            });
            return;
          }
        }
        setState(() => _error = message);
      }
    } on DioException catch (e) {
      final message = _messageFromError(e) ?? 'Could not start authenticator setup.';
      if (_isDuplicateMessage(message)) {
        await _loadStatus();
        try {
          final retry = await _dio.post(
            '/api/v1/settings/two-factor/app/setup',
            data: {'reset': reset},
          );
          final retryData = retry.data;
          if (retryData is Map && retryData['success'] == true) {
            setState(() {
              _secret = retryData['secret']?.toString();
              _otpauthUri = retryData['otpauthUri']?.toString();
              _appEnabled = false;
              _status = retryData['message']?.toString();
              _error = null;
            });
            return;
          }
        } catch (_) {}
      }
      setState(() => _error = message);
    } catch (_) {
      setState(() => _error = 'Could not start authenticator setup.');
    } finally {
      if (mounted) setState(() => _setupBusy = false);
    }
  }

  Future<void> _verifyAuthenticator() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _verifyBusy) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }
    setState(() {
      _verifyBusy = true;
      _error = null;
    });
    try {
      final response = await _dio.post(
        '/api/v1/settings/two-factor/app/verify',
        data: {'code': code, 'action': 'verify'},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _appEnabled = true;
          _appConfigured = true;
          _secret = null;
          _otpauthUri = null;
          _codeController.clear();
          _status = data['message']?.toString() ?? 'Authenticator enabled.';
        });
        if (mounted) {
          toasty(context, 'Authenticator enabled', bgColor: Colors.green, textColor: Colors.white);
        }
        await _loadStatus();
      } else {
        setState(() => _error = (data is Map ? data['message']?.toString() : null) ?? 'Invalid code.');
      }
    } on DioException catch (e) {
      setState(() => _error = _messageFromError(e) ?? 'Invalid code.');
    } catch (_) {
      setState(() => _error = 'Invalid code.');
    } finally {
      if (mounted) setState(() => _verifyBusy = false);
    }
  }

  Future<void> _disableAuthenticator() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if ((code.length < 4 && password.isEmpty) || _verifyBusy) {
      setState(() => _error = 'Enter an authenticator code, or your DocTak password if you lost the app entry.');
      return;
    }
    setState(() {
      _verifyBusy = true;
      _error = null;
    });
    try {
      final response = await _dio.post(
        '/api/v1/settings/two-factor/app/verify',
        data: {
          'action': 'disable',
          'code': code.length >= 4 ? code : '',
          'password': password,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _appEnabled = false;
          _appConfigured = false;
          _secret = null;
          _otpauthUri = null;
          _codeController.clear();
          _passwordController.clear();
          _status = data['message']?.toString() ?? 'Authenticator disabled.';
        });
      } else {
        setState(() => _error = (data is Map ? data['message']?.toString() : null) ?? 'Could not disable authenticator.');
      }
    } on DioException catch (e) {
      setState(() => _error = _messageFromError(e) ?? 'Could not disable authenticator.');
    } catch (_) {
      setState(() => _error = 'Could not disable authenticator.');
    } finally {
      if (mounted) setState(() => _verifyBusy = false);
    }
  }

  Future<void> _copySecret() async {
    if (_secret == null || _secret!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _secret!));
    if (!mounted) return;
    toasty(context, 'Secret copied', bgColor: Colors.green, textColor: Colors.white);
  }

  Future<void> _openAuthenticatorApp() async {
    final uri = _otpauthUri;
    if (uri == null || uri.isEmpty) return;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    final launched = await launchUrl(parsed, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      toasty(context, 'Open Google Authenticator and scan the QR code.', bgColor: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final setupInProgress = _otpauthUri != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(title: 'Account Protection', titleIcon: Icons.security_rounded),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  AppSurfaceCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    borderColor: Colors.red.withValues(alpha: 0.3),
                    child: Text(_error!, style: TextStyle(color: theme.error, height: 1.35)),
                  ),
                if (_status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_status!, style: TextStyle(color: theme.primary, height: 1.35)),
                  ),
                AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email OTP', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive a verification code by email when you sign in.'),
                    value: _emailEnabled,
                    onChanged: _emailBusy ? null : _toggleEmail,
                  ),
                ),
                AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Authenticator App',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_appEnabled ? Colors.green : theme.textTertiary).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _appEnabled ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _appEnabled ? Colors.green : theme.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use Google Authenticator or Microsoft Authenticator. After setup, DocTak asks for a 6-digit code at login on website and app.',
                        style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      if (!setupInProgress) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _setupBusy
                                ? null
                                : () => _startAuthenticatorSetup(reset: _appEnabled || _appConfigured),
                            icon: _setupBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.qr_code_2_rounded),
                            label: Text(
                              _setupBusy
                                  ? 'Preparing…'
                                  : _appEnabled
                                      ? 'Re-setup authenticator'
                                      : 'Set up authenticator',
                            ),
                          ),
                        ),
                      ],
                      if (setupInProgress) ...[
                        _SetupStep(
                          theme: theme,
                          number: '1',
                          title: 'Open authenticator',
                          body: 'Install or open Google Authenticator / Microsoft Authenticator on this phone.',
                        ),
                        const SizedBox(height: 10),
                        _SetupStep(
                          theme: theme,
                          number: '2',
                          title: 'Scan QR or add secret',
                          body: 'Scan the DocTak.net QR below, or copy the secret and add it manually.',
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.divider),
                            ),
                            child: QrImageView(
                              data: _otpauthUri!,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Issuer: DocTak.net',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                        if (_secret != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.inputBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manual secret',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  _secret!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _copySecret,
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  label: const Text('Copy secret'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openAuthenticatorApp,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                  label: const Text('Open app'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        _SetupStep(
                          theme: theme,
                          number: '3',
                          title: 'Enter the 6-digit code',
                          body: 'Type the code shown for DocTak.net, then tap Activate.',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: '6-digit code',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _verifyAuthenticator(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _verifyBusy ? null : _verifyAuthenticator,
                                  child: Text(_verifyBusy ? 'Verifying…' : 'Verify & Activate'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => setState(() {
                                _otpauthUri = null;
                                _secret = null;
                                _codeController.clear();
                                _status = null;
                              }),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                      if (_appEnabled && !setupInProgress) ...[
                        const SizedBox(height: 14),
                        Text(
                          'To disable: use a current authenticator code, or your DocTak password if you deleted the DocTak.net entry.',
                          style: TextStyle(color: theme.textSecondary, fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Code to disable (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Account password (if you lost the code)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _verifyBusy ? null : _disableAuthenticator,
                          child: Text(_verifyBusy ? 'Disabling…' : 'Disable authenticator'),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  'After enabling Email OTP or Authenticator, sign out and sign in again. You will be asked for a verification code before entering the app.',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.theme,
    required this.number,
    required this.title,
    required this.body,
  });

  final OneUITheme theme;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: theme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  height: 1.35,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
