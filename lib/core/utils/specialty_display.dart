import 'package:doctak_app/data/apiClient/shared_api_service.dart';

/// Resolves numeric specialty IDs (e.g. "17") to human-readable names.
class SpecialtyDisplay {
  SpecialtyDisplay._();

  static final SpecialtyDisplay instance = SpecialtyDisplay._();

  static final RegExp _numericId = RegExp(r'^\d+$');

  final Map<String, String> _idToName = {};
  bool _loaded = false;
  Future<void>? _loading;

  static bool isNumericId(String? value) {
    if (value == null) return false;
    return _numericId.hasMatch(value.trim());
  }

  Future<void> ensureLoaded() {
    _loading ??= _load();
    return _loading!;
  }

  Future<void> _load() async {
    if (_loaded) return;
    try {
      final response = await SharedApiService().getSpecialty();
      if (response.success && response.data != null) {
        for (final entry in response.data!) {
          if (entry is! Map) continue;
          final id = entry['id']?.toString();
          final name = entry['name']?.toString().trim();
          if (id != null && name != null && name.isNotEmpty) {
            _idToName[id] = name;
          }
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  /// Synchronous resolve — returns empty when [raw] is a numeric ID not yet cached.
  String resolve(String? raw) {
    if (raw == null) return '';
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (isNumericId(value)) {
      return _idToName[value] ?? '';
    }
    return value;
  }

  Future<String> resolveAsync(String? raw) async {
    await ensureLoaded();
    return resolve(raw);
  }

  void clear() {
    _idToName.clear();
    _loaded = false;
    _loading = null;
  }
}

String displaySpecialty(String? raw) => SpecialtyDisplay.instance.resolve(raw);

Future<String> displaySpecialtyAsync(String? raw) =>
    SpecialtyDisplay.instance.resolveAsync(raw);

Future<void> preloadSpecialties() => SpecialtyDisplay.instance.ensureLoaded();

/// User-facing specialty line — never returns a bare numeric ID.
String? specialtyLabelOrNull(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final resolved = displaySpecialty(value);
  if (resolved.isNotEmpty) return resolved;
  if (SpecialtyDisplay.isNumericId(value)) return null;
  return value;
}
