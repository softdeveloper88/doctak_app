class CmeCapabilities {
  CmeCapabilities({
    this.isAuthenticated = false,
    this.canCreate = false,
    this.hasProviderMembership = false,
    this.providerOrg,
    this.pendingSpeakerInvitations = 0,
    this.activeRegistrations = 0,
  });

  factory CmeCapabilities.fromJson(Map<String, dynamic> json) {
    final org = json['providerOrg'] as Map<String, dynamic>?;
    return CmeCapabilities(
      isAuthenticated: json['isAuthenticated'] == true,
      canCreate: json['canCreate'] == true,
      hasProviderMembership: json['hasProviderMembership'] == true,
      providerOrg: org != null ? CmeProviderOrg.fromJson(org) : null,
      pendingSpeakerInvitations: _asInt(json['pendingSpeakerInvitations']),
      activeRegistrations: _asInt(json['activeRegistrations']),
    );
  }

  final bool isAuthenticated;
  final bool canCreate;
  final bool hasProviderMembership;
  final CmeProviderOrg? providerOrg;
  final int pendingSpeakerInvitations;
  final int activeRegistrations;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class CmeProviderOrg {
  CmeProviderOrg({
    required this.id,
    required this.name,
    this.slug,
    this.logoUrl,
  });

  factory CmeProviderOrg.fromJson(Map<String, dynamic> json) {
    return CmeProviderOrg(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'Provider'}',
      slug: json['slug'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final String? slug;
  final String? logoUrl;
}
