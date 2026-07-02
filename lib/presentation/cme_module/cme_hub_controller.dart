import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_capabilities_model.dart';
import 'package:doctak_app/data/models/cme/cme_dashboard_model.dart';
import 'package:flutter/foundation.dart';

enum CmeHubDestination {
  browse,
  myRegistrations,
  inProgress,
  completed,
  certificates,
  credits,
  speaking,
  invitations,
  providerAll,
  providerOpen,
  providerClosed,
}

class CmeHubController extends ChangeNotifier {
  CmeHubController() {
    ActingContextService.instance.addListener(_onActingChanged);
  }

  bool loading = true;
  String? error;
  CmeDashboardResponse? dashboard;
  CmeCapabilities? capabilities;
  CmeHubDestination destination = CmeHubDestination.browse;

  bool get isProviderMode => ActingContextService.instance.isProviderMode;
  ActingOrganization? get activeOrg => ActingContextService.instance.organization;

  CmeNavCounts get navCounts => dashboard?.navCounts ?? CmeNavCounts();
  CmeProviderCounts get providerCounts =>
      dashboard?.providerCounts ?? CmeProviderCounts();

  bool _refreshing = false;
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void _onActingChanged() {
    if (_disposed) return;
    // ignore: discarded_futures
    refresh();
  }

  Future<void> initialize() async {
    if (_disposed) return;
    await ActingContextService.instance.initialize();
    if (_disposed) return;
    if (isProviderMode) {
      destination = CmeHubDestination.providerAll;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    loading = true;
    error = null;
    _safeNotify();
    try {
      final results = await Future.wait([
        CmeNodeApiService.getDashboard(),
        CmeNodeApiService.getCapabilities(),
      ]);
      if (_disposed) return;
      dashboard = results[0] as CmeDashboardResponse;
      capabilities = results[1] as CmeCapabilities;
      error = null;
    } catch (e) {
      if (_disposed) return;
      error = '$e';
    } finally {
      _refreshing = false;
      if (_disposed) return;
      loading = false;
      _safeNotify();
    }
  }

  void selectDestination(CmeHubDestination next) {
    if (_disposed || destination == next) return;
    destination = next;
    _safeNotify();
  }

  Future<void> switchToPersonal() async {
    if (_disposed) return;
    destination = CmeHubDestination.browse;
    _safeNotify();
    await ActingContextService.instance.switchToPersonal();
    if (_disposed) return;
  }

  Future<void> switchToProvider(String organizationId) async {
    if (_disposed) return;
    destination = CmeHubDestination.providerAll;
    _safeNotify();
    await ActingContextService.instance.switchToOrganization(organizationId);
    if (_disposed) return;
  }

  @override
  void dispose() {
    _disposed = true;
    ActingContextService.instance.removeListener(_onActingChanged);
    super.dispose();
  }
}
