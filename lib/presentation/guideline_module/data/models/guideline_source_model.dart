/// Represents a guideline source organization (WHO, AHA, NICE, etc.)
class GuidelineSourceModel {
  final int id;
  final String name;
  final String? organization;
  final String? description;
  final String? website;
  final int? authorityLevel;
  final GuidelineCountry? country;

  const GuidelineSourceModel({
    required this.id,
    required this.name,
    this.organization,
    this.description,
    this.website,
    this.authorityLevel,
    this.country,
  });

  factory GuidelineSourceModel.fromJson(Map<String, dynamic> json) {
    return GuidelineSourceModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      organization: json['organization']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      authorityLevel: _parseInt(json['authority_level']),
      country: json['country'] != null
          ? GuidelineCountry.fromJson(json['country'])
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'organization': organization,
        'description': description,
        'website': website,
        'authority_level': authorityLevel,
        'country': country?.toJson(),
      };
}

class GuidelineCountry {
  final int id;
  final String name;
  final String? flag;

  const GuidelineCountry({
    required this.id,
    required this.name,
    this.flag,
  });

  factory GuidelineCountry.fromJson(Map<String, dynamic> json) {
    return GuidelineCountry(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      flag: json['flag']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'flag': flag,
      };
}
