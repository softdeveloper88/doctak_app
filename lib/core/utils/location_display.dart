import 'package:doctak_app/data/apiClient/shared_api_service.dart';

/// Resolves numeric country/city IDs to human-readable names when possible.
class LocationDisplay {
  LocationDisplay._();

  static final LocationDisplay instance = LocationDisplay._();

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
      final response = await SharedApiService().getCountries();
      if (response.success && response.data?.countries != null) {
        for (final country in response.data!.countries!) {
          final id = country.id?.toString();
          final name = country.countryName?.trim();
          if (id != null && name != null && name.isNotEmpty) {
            _idToName[id] = name;
          }
        }
      }
    } catch (_) {}
    _loaded = true;
  }

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

String displayLocation(String? raw) => LocationDisplay.instance.resolve(raw);

Future<String> displayLocationAsync(String? raw) =>
    LocationDisplay.instance.resolveAsync(raw);

Future<void> preloadLocations() => LocationDisplay.instance.ensureLoaded();

/// User-facing location line — never returns a bare numeric ID.
String? locationLabelOrNull(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final resolved = displayLocation(value);
  if (resolved.isNotEmpty) return resolved;
  if (LocationDisplay.isNumericId(value)) return null;
  return value;
}

/// Joins city / state / country (or any location parts), skipping blanks and dupes.
String? joinLocationLabels(Iterable<String?> parts) {
  final seen = <String>{};
  final labels = <String>[];
  for (final part in parts) {
    final label = locationLabelOrNull(part);
    if (label == null || label.isEmpty) continue;
    final key = label.toLowerCase();
    if (!seen.add(key)) continue;
    labels.add(label);
  }
  if (labels.isEmpty) return null;
  return labels.join(', ');
}

String organizationLocationSubtitle({
  required String typeLabel,
  String? city,
  String? state,
  String? country,
}) {
  final location = joinLocationLabels([city, state, country]);
  if (location != null && location.isNotEmpty) {
    return '$typeLabel · $location';
  }
  return typeLabel;
}
