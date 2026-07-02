import 'dart:convert';

import 'package:doctak_app/core/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A simple on-screen diagnostics page for FCM push notifications.
///
/// Shows the current FCM token (copyable), the iOS APNS token, device
/// identifiers, the doctak-node target URL, and a button to re-register the
/// token with the server — printing the server response (which echoes the saved
/// device row) so you can confirm the device landed in the `device_tokens` table.
class FcmDebugScreen extends StatefulWidget {
  const FcmDebugScreen({super.key});

  @override
  State<FcmDebugScreen> createState() => _FcmDebugScreenState();
}

class _FcmDebugScreenState extends State<FcmDebugScreen> {
  Map<String, dynamic> _status = {};
  Map<String, dynamic>? _registerResult;
  bool _loading = true;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final status = await NotificationService.debugFcmStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _reRegister() async {
    setState(() => _registering = true);
    final result = await NotificationService.debugRegisterCurrentToken();
    if (!mounted) return;
    setState(() {
      _registerResult = result;
      _registering = false;
    });
    final ok = result['ok'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Registered with server ✓' : 'Registration failed: ${result['error'] ?? result['statusCode']}'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)),
    );
  }

  String _pretty(Object? value) {
    if (value == null) return '—';
    if (value is String && value.isEmpty) return '—';
    try {
      if (value is Map) {
        // body may itself be a JSON string — try to re-decode for readability
        return const JsonEncoder.withIndent('  ').convert(value);
      }
      if (value is String && (value.startsWith('{') || value.startsWith('['))) {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
      }
    } catch (_) {}
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field('FCM token', _status['fcmToken'], copyable: true),
                if (_status.containsKey('apnsToken'))
                  _field('APNS token (iOS)', _status['apnsToken'], copyable: true),
                _field('Device type', _status['deviceType']),
                _field('Device ID', _status['deviceId'], copyable: true),
                _field('User ID', _status['userId']),
                _field('Auth token present', _status['authPresent']?.toString()),
                _field('Node API URL', _status['nodeApiUrl']),
                if (_status['error'] != null)
                  _field('Error', _status['error']),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _registering ? null : _reRegister,
                  icon: _registering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_registering ? 'Registering…' : 'Re-register token with server'),
                ),
                if (_registerResult != null) ...[
                  const SizedBox(height: 16),
                  const Text('Server response', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      _pretty(_registerResult),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _field(String label, Object? value, {bool copyable = false}) {
    final text = _pretty(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              if (copyable && text != '—')
                InkWell(
                  onTap: () => _copy(label, value.toString()),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
