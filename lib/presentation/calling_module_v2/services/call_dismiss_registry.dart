import 'dart:convert';

import 'package:doctak_app/core/utils/secure_storage_service.dart';

/// Persists callIds that were cancelled/answered elsewhere so a late FCM
/// `incoming_call` (queued while offline) is ignored on delivery.
class CallDismissRegistry {
  CallDismissRegistry._();

  static const _storageKey = 'call_v2_dismissed_ids';
  static const _ttl = Duration(minutes: 10);

  static Future<void> markDismissed(String callId) async {
    if (callId.isEmpty) return;
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final map = await _readMap(prefs);
    map[callId] = DateTime.now().millisecondsSinceEpoch;
    await _prune(map);
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  static Future<bool> isDismissed(String callId) async {
    if (callId.isEmpty) return false;
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final map = await _readMap(prefs);
    await _prune(map);
    return map.containsKey(callId);
  }

  static Future<Map<String, int>> _readMap(SecureStorageService prefs) async {
    try {
      final raw = await prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), int.tryParse('$value') ?? 0),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _prune(Map<String, int> map) async {
    final cutoff = DateTime.now().subtract(_ttl).millisecondsSinceEpoch;
    map.removeWhere((_, ts) => ts < cutoff);
  }
}
