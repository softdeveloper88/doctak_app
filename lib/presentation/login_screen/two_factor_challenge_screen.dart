import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/auth_session_helper.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/presentation/auth/auth_screen_widgets.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class TwoFactorChallengeScreen extends StatefulWidget {
  const TwoFactorChallengeScreen({
    super.key,
    required this.pendingToken,
    required this.methods,
    this.maskedEmail,
    this.rememberMe = true,
    this.deviceToken = '',
    this.initialMessage,
    this.autoResendEmail = false,
  });

  final String pendingToken;
  final Map<String, bool> methods;
  final String? maskedEmail;
  final bool rememberMe;
  final String deviceToken;
  final String? initialMessage;
  final bool autoResendEmail;

  @override
  State<TwoFactorChallengeScreen> createState() => _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState extends State<TwoFactorChallengeScreen> {
  final _codeController = TextEditingController();
  late String _method;
  late String _pendingToken;
  bool _submitting = false;
  bool _resending = false;
  String? _error;
  String? _status;

  bool get _emailEnabled => widget.methods['email'] == true;
  bool get _appEnabled => widget.methods['app'] == true;

  @override
  void initState() {
    super.initState();
    _method = _emailEnabled ? 'email' : 'app';
    _pendingToken = widget.pendingToken;
    final initial = widget.initialMessage;
    final looksLikeSendFailure = initial != null &&
        RegExp(r'could not (prepare|send)|failed to send|try again', caseSensitive: false)
            .hasMatch(initial);
    if (looksLikeSendFailure) {
      _error = initial;
    } else {
      _status = initial;
    }
    if (widget.autoResendEmail || looksLikeSendFailure) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resend();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4 || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ));

      final response = await dio.post(
        '${AppData.nodeApiUrl}/api/auth/two-factor/verify',
        data: {
          'method': _method,
          'code': code,
          'pending_token': _pendingToken,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      if (data is Map && (data['success'] == true || data['token'] != null)) {
        final parsed = PostLoginDeviceAuthResp.fromJson(Map<String, dynamic>.from(data));
        await AuthSessionHelper.persistSession(
          parsed,
          deviceToken: widget.deviceToken,
          rememberMe: widget.rememberMe,
        );
        if (!mounted) return;
        toasty(context, 'Signed in successfully', bgColor: Colors.green, textColor: Colors.white);
        AppNavigator.pushReplacement(context, const SVDashboardScreen());
        return;
      }

      setState(() {
        _error = (data is Map ? data['message']?.toString() : null) ?? 'Invalid verification code.';
      });
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      setState(() => _error = message ?? 'Could not verify the code. Please try again.');
    } catch (_) {
      setState(() => _error = 'Could not verify the code. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (!_emailEnabled || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ));

      final response = await dio.post(
        '${AppData.nodeApiUrl}/api/auth/two-factor/resend',
        data: {'pending_token': _pendingToken},
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      final nextToken = data is Map ? data['pending_token']?.toString() : null;
      final emailSent = data is Map ? data['email_sent'] != false : true;
      final message = (data is Map ? data['message']?.toString() : null) ??
          'A new verification code has been sent${widget.maskedEmail != null ? ' to ${widget.maskedEmail}' : ''}.';
      setState(() {
        _method = 'email';
        if (nextToken != null && nextToken.isNotEmpty) {
          _pendingToken = nextToken;
        }
        if (emailSent) {
          _error = null;
          _status = message;
        } else {
          _status = null;
          _error = message;
        }
      });
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      final nextToken = e.response?.data is Map ? e.response?.data['pending_token']?.toString() : null;
      setState(() {
        if (nextToken != null && nextToken.isNotEmpty) {
          _pendingToken = nextToken;
        }
        _error = message ?? 'Could not resend the code.';
      });
    } catch (_) {
      setState(() => _error = 'Could not resend the code.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final subtitle = _method == 'email'
        ? (widget.maskedEmail != null
            ? 'Enter the 6-digit code sent to ${widget.maskedEmail}.'
            : 'Enter the 6-digit code sent to your email.')
        : 'Enter the 6-digit code from your authenticator app.';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.authBackgroundColor,
        body: AuthScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBrandHeader(
                eyebrow: 'Extra security',
                title: "Verify it's you",
                subtitle: subtitle,
              ),
              AuthFormCard(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: theme.error, fontSize: 13)),
                    )
                  else if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_status!, style: TextStyle(color: theme.primary, fontSize: 13)),
                    ),
                  if (_emailEnabled && _appEnabled) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MethodChip(
                            label: 'Email OTP',
                            icon: CupertinoIcons.mail,
                            selected: _method == 'email',
                            onTap: () => setState(() => _method = 'email'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MethodChip(
                            label: 'Authenticator',
                            icon: CupertinoIcons.lock_shield,
                            selected: _method == 'app',
                            onTap: () => setState(() => _method = 'app'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  AuthField(
                    label: 'Verification code',
                    child: AuthFormInput(
                      icon: CupertinoIcons.lock,
                      controller: _codeController,
                      hint: '6-digit code',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        final cleaned = value.replaceAll(RegExp(r'\D'), '');
                        final clipped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
                        if (clipped != value) {
                          _codeController.value = TextEditingValue(
                            text: clipped,
                            selection: TextSelection.collapsed(offset: clipped.length),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  theme.buildAuthPrimaryButton(
                    label: _submitting ? 'Verifying…' : 'Verify and continue',
                    icon: Icons.verified_user_rounded,
                    onPressed: _submitting ? null : _verify,
                  ),
                  if (_emailEnabled)
                    TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(_resending ? 'Sending…' : 'Resend email code'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primary.withValues(alpha: 0.1) : theme.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? theme.primary : theme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? theme.primary : theme.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? theme.primary : theme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
