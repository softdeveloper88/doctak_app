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
    this.role,
    this.typeLabel,
  });

  factory ActingOrganization.fromJson(Map<String, dynamic> json) {
    return ActingOrganization(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'Business'}',
      type: '${json['type'] ?? ''}',
      slug: json['slug'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo'] as String?,
      role: json['role'] as String?,
      typeLabel: json['typeLabel'] as String?,
    );
  }

  final String id;
  final String name;
  final String type;
  final String? slug;
  final String? logoUrl;
  final String? role;
  final String? typeLabel;

  bool get isCmeProvider => type == 'cme_provider';

  /// Mirrors web `canPostJobs` — only hospital & recruiter pages can post jobs.
  bool get canPostJobs => type == 'hospital' || type == 'recruiter';

  String get typeDisplay {
    if (typeLabel != null && typeLabel!.isNotEmpty) return typeLabel!;
    switch (type) {
      case 'hospital':
        return 'Hospital';
      case 'recruiter':
        return 'Recruiter';
      case 'cme_provider':
        return 'CME Provider';
      case 'pharma':
        return 'Pharma';
      default:
        return 'Business';
    }
  }

  String get roleDisplay {
    final r = (role ?? '').trim();
    if (r.isEmpty) return '';
    return r[0].toUpperCase() + r.substring(1);
  }
}

/// Mirrors the website acting-as model (`doctak_acting_org` cookie /
/// `X-Doctak-Acting-Org` header): the personal auth token never changes,
/// switching only selects which business page subsequent writes (posts,
/// comments, reposts, likes, jobs, CME) are attributed to.
class ActingContextService extends ChangeNotifier {
  ActingContextService._();
  static final ActingContextService instance = ActingContextService._();

  static const _tokenKey = 'doctak_acting_org_token';
  static const _orgIdKey = 'doctak_acting_org_id';

  String? _actingToken;
  ActingOrganization? _organization;
  List<ActingOrganization> _organizations = [];
  String? _serverActiveOrganizationId;
  bool _loaded = false;
  bool _switching = false;
  Future<void>? _initializeFuture;

  String? get actingToken => _actingToken;

  /// The business page currently being acted as, or null for personal.
  ActingOrganization? get organization => _organization;

  /// Every business page the user owns or is a member of.
  List<ActingOrganization> get organizations => _organizations;

  /// Backwards-compatible view used by the CME module.
  List<ActingOrganization> get cmeProviders =>
      _organizations.where((o) => o.isCmeProvider).toList();

  bool get isBusinessMode => _organization != null;
  bool get isProviderMode => _organization?.isCmeProvider == true;
  bool get isLoaded => _loaded;
  bool get isSwitching => _switching;

  /// Restore the last acting workspace after login / cold start.
  /// Safe to call multiple times — later callers await the same Future.
  Future<void> initialize() async {
    if (_loaded) return;
    final inFlight = _initializeFuture;
    if (inFlight != null) return inFlight;

    _initializeFuture = _doInitialize();
    try {
      await _initializeFuture;
    } finally {
      _initializeFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      final storage = SecureStorageService.instance;
      final storedToken = await storage.getString(_tokenKey);
      final storedOrgId = await storage.getString(_orgIdKey);

      if (storedToken != null && storedToken.isNotEmpty) {
        _actingToken = storedToken;
        await _validateContext();
      }

      await refreshOrganizations();

      // Restore a business workspace only when this device persisted one.
      // Do not auto-adopt users.active_organization_id from the server alone —
      // login should start on the personal account unless the user switches here.
      if (_organization == null) {
        final localOrgId = storedOrgId?.trim();
        if (localOrgId != null && localOrgId.isNotEmpty) {
          await _reissueActingToken(localOrgId);
        }
      }
    } catch (e, st) {
      debugPrint('ActingContextService.initialize: $e\n$st');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Asks the server which persona the stored acting token resolves to.
  Future<void> _validateContext() async {
    try {
      final response = await buildHttpResponseNode('/api/account/context');
      final data = await handleResponse(response);
      final ctx = data['context'] as Map<String, dynamic>?;
      final orgJson = ctx?['organization'] as Map<String, dynamic>?;
      if (orgJson != null && orgJson.isNotEmpty) {
        _organization = ActingOrganization.fromJson({
          ...orgJson,
          if (ctx?['role'] != null) 'role': ctx!['role'],
        });
        await _persistOrgId(_organization!.id);
      } else {
        // Token is stale/invalid — drop it, but keep the org id so we can
        // re-issue a fresh token from users.active_organization_id next.
        _actingToken = null;
        await SecureStorageService.instance.remove(_tokenKey);
        _organization = null;
      }
    } catch (e) {
      debugPrint('ActingContextService._validateContext: $e');
    }
  }

  Future<void> refreshOrganizations() async {
    try {
      final response = await buildHttpResponseNode('/api/business');
      final data = await handleResponse(response);
      final business = data['business'] as Map<String, dynamic>? ?? {};
      _organizations = (business['organizations'] as List<dynamic>? ?? [])
          .map((e) =>
              ActingOrganization.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      _serverActiveOrganizationId =
          business['activeOrganizationId']?.toString().trim();
      if (_serverActiveOrganizationId != null &&
          _serverActiveOrganizationId!.isEmpty) {
        _serverActiveOrganizationId = null;
      }

      // Enrich/refresh the active org from the dashboard list (role, logo…).
      final currentId = _organization?.id;
      if (currentId != null && currentId.isNotEmpty) {
        for (final org in _organizations) {
          if (org.id == currentId) {
            _organization = org;
            break;
          }
        }
        return;
      }

      // No in-memory workspace yet — adopt the server preference only when we
      // still have (or can re-issue) an acting token. Without a token the
      // server would treat writes as personal even if we show a business UI.
      // Also require a locally persisted org id so login does not jump to the
      // server's last active_organization_id when this app has none stored.
      final localOrgId = await SecureStorageService.instance.getString(_orgIdKey);
      final hasLocalOrgPreference =
          localOrgId != null && localOrgId.trim().isNotEmpty;
      if (_actingToken != null &&
          _actingToken!.isNotEmpty &&
          hasLocalOrgPreference) {
        final active = business['activeOrganization'] as Map<String, dynamic>?;
        if (active != null && active.isNotEmpty) {
          _organization = ActingOrganization.fromJson(active);
          await _persistOrgId(_organization!.id);
          return;
        }
        final activeId = _serverActiveOrganizationId;
        if (activeId != null) {
          for (final org in _organizations) {
            if (org.id == activeId) {
              _organization = org;
              await _persistOrgId(org.id);
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ActingContextService.refreshOrganizations: $e');
    }
  }

  /// Re-mint the acting JWT when the stored one expired but the user still
  /// has an active workspace preference (DB + local org id).
  Future<void> _reissueActingToken(String organizationId) async {
    try {
      final response = await buildHttpResponseNode(
        '/api/account/switch',
        method: HttpMethod.POST,
        body: {'organizationId': organizationId},
      );
      final data = await handleResponse(response);
      final token = data['actingToken']?.toString();
      if (token == null || token.isEmpty) return;

      await _persistToken(token);
      final ctx = data['context'] as Map<String, dynamic>?;
      final orgJson = ctx?['organization'] as Map<String, dynamic>?;
      if (orgJson != null) {
        _organization = ActingOrganization.fromJson({
          ...orgJson,
          if (ctx?['role'] != null) 'role': ctx!['role'],
        });
        await _persistOrgId(_organization!.id);
      }
      await refreshOrganizations();
    } catch (e) {
      debugPrint('ActingContextService._reissueActingToken: $e');
    }
  }

  /// POST /api/account/switch-personal — clears the acting token so all
  /// subsequent requests are attributed to the personal profile.
  Future<void> switchToPersonal() async {
    _switching = true;
    notifyListeners();
    try {
      final response = await buildHttpResponseNode(
        '/api/account/switch-personal',
        method: HttpMethod.POST,
      );
      await handleResponse(response);
      await _clearToken();
      await _clearOrgId();
      _organization = null;
      _serverActiveOrganizationId = null;
      await refreshOrganizations();
    } catch (e, st) {
      debugPrint('ActingContextService.switchToPersonal: $e\n$st');
      rethrow;
    } finally {
      _switching = false;
      notifyListeners();
    }
  }

  /// POST /api/account/switch — stores the signed acting token returned by
  /// the server; it is then sent as `X-Doctak-Acting-Org` on every request.
  Future<void> switchToOrganization(String organizationId) async {
    _switching = true;
    notifyListeners();
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
        _organization = ActingOrganization.fromJson({
          ...orgJson,
          if (ctx?['role'] != null) 'role': ctx!['role'],
        });
        await _persistOrgId(_organization!.id);
      }
      await refreshOrganizations();
    } catch (e, st) {
      debugPrint('ActingContextService.switchToOrganization: $e\n$st');
      rethrow;
    } finally {
      _switching = false;
      notifyListeners();
    }
  }

  Future<void> _persistToken(String token) async {
    _actingToken = token;
    await SecureStorageService.instance.setString(_tokenKey, token);
  }

  Future<void> _persistOrgId(String orgId) async {
    await SecureStorageService.instance.setString(_orgIdKey, orgId);
  }

  Future<void> _clearToken() async {
    _actingToken = null;
    await SecureStorageService.instance.remove(_tokenKey);
  }

  Future<void> _clearOrgId() async {
    await SecureStorageService.instance.remove(_orgIdKey);
  }

  /// Reset in-memory state on logout.
  Future<void> clear() async {
    await _clearToken();
    await _clearOrgId();
    _organization = null;
    _organizations = [];
    _serverActiveOrganizationId = null;
    _loaded = false;
    _initializeFuture = null;
  }

  Map<String, String> actingHeaders() {
    final token = _actingToken;
    if (token == null || token.isEmpty) return const {};
    return {'X-Doctak-Acting-Org': token};
  }
}
