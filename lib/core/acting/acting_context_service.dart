import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class ActingOrganization {
  ActingOrganization({
    required this.id,
    required this.name,
    required this.type,
    this.slug,
    this.logoUrl,
  });

  factory ActingOrganization.fromJson(Map<String, dynamic> json) {
    return ActingOrganization(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'Business'}',
      type: '${json['type'] ?? ''}',
      slug: json['slug'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo'] as String?,
    );
  }

  final String id;
  final String name;
  final String type;
  final String? slug;
  final String? logoUrl;

  bool get isCmeProvider => type == 'cme_provider';
}

/// Mirrors web `doctak_acting_org` — personal vs business CME provider workspace.
class ActingContextService extends ChangeNotifier {
  ActingContextService._();
  static final ActingContextService instance = ActingContextService._();

  static const _tokenKey = 'doctak_acting_org_token';

  String? _actingToken;
  ActingOrganization? _organization;
  List<ActingOrganization> _cmeProviders = [];
  bool _loaded = false;

  String? get actingToken => _actingToken;
  ActingOrganization? get organization => _organization;
  List<ActingOrganization> get cmeProviders => _cmeProviders;
  bool get isProviderMode => _organization?.isCmeProvider == true;
  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    if (_loaded) return;
    final stored = await SecureStorageService.instance.getString(_tokenKey);
    if (stored != null && stored.isNotEmpty) {
      _actingToken = stored;
    }
    await refreshOrganizations();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refreshOrganizations() async {
    try {
      final response = await buildHttpResponseNode('/api/business');
      final data = await handleResponse(response);
      final business = data['business'] as Map<String, dynamic>? ?? {};
      final orgs = (business['organizations'] as List<dynamic>? ?? [])
          .map((e) => ActingOrganization.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((o) => o.isCmeProvider)
          .toList();
      _cmeProviders = orgs;

      final activeId = business['activeOrganizationId']?.toString();
      final active = business['activeOrganization'] as Map<String, dynamic>?;
      if (active != null && active.isNotEmpty) {
        final parsed = ActingOrganization.fromJson(active);
        if (parsed.isCmeProvider) {
          _organization = parsed;
        } else {
          _organization = null;
        }
      } else if (activeId != null && activeId.isNotEmpty) {
        ActingOrganization? match;
        for (final org in orgs) {
          if (org.id == activeId) {
            match = org;
            break;
          }
        }
        _organization = match;
      }
    } catch (e) {
      debugPrint('ActingContextService.refreshOrganizations: $e');
    }
  }

  Future<void> switchToPersonal() async {
    try {
      final response = await buildHttpResponseNode(
        '/api/account/switch-personal',
        method: HttpMethod.POST,
      );
      await handleResponse(response);
      await _clearToken();
      _organization = null;
      await refreshOrganizations();
      notifyListeners();
    } catch (e, st) {
      debugPrint('ActingContextService.switchToPersonal: $e\n$st');
      rethrow;
    }
  }

  Future<void> switchToOrganization(String organizationId) async {
    try {
      final response = await buildHttpResponseNode(
        '/api/account/switch',
        method: HttpMethod.POST,
        body: {'organizationId': organizationId},
      );
      final data = await handleResponse(response);
      final token = data['actingToken']?.toString();
      if (token != null && token.isNotEmpty) {
        await _persistToken(token);
      }
      final ctx = data['context'] as Map<String, dynamic>?;
      final orgJson = ctx?['organization'] as Map<String, dynamic>?;
      if (orgJson != null) {
        _organization = ActingOrganization.fromJson(orgJson);
      }
      await refreshOrganizations();
      notifyListeners();
    } catch (e, st) {
      debugPrint('ActingContextService.switchToOrganization: $e\n$st');
      rethrow;
    }
  }

  Future<void> _persistToken(String token) async {
    _actingToken = token;
    await SecureStorageService.instance.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    _actingToken = null;
    await SecureStorageService.instance.remove(_tokenKey);
  }

  Map<String, String> actingHeaders() {
    final token = _actingToken;
    if (token == null || token.isEmpty) return const {};
    return {'X-Doctak-Acting-Org': token};
  }
}
