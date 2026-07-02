import 'dart:convert';

class DiagnosisModel {
  int? id;
  String? userId;
  String? fullName;
  String? age;
  String? gender;
  String? chiefComplaint;
  String? symptoms;
  String? pastMedicalConditions;
  String? familyMedicalHistory;
  String? lifestyleHabits;
  String? medicationName;
  String? allergen;
  String? contentType;
  String? recommendationFromAi;
  List<Map<String, dynamic>>? aiHistory;

  // Vital signs
  String? temperature;
  String? bpSystolic;
  String? bpDiastolic;
  String? pulseRate;
  String? heartRate;
  String? respiratoryRate;
  String? o2Saturation;
  String? painScore;
  String? height;
  String? weight;

  // Physical examination
  String? generalAppearance;
  String? heent;
  String? cardiovascular;
  String? respiratoryExam;
  String? gastrointestinal;
  String? musculoskeletal;
  String? neurological;
  String? skin;
  String? otherFindings;

  // Lab results
  String? cbcResults;
  String? bmpResults;
  String? lftResults;
  String? coagulationResults;
  String? otherLabResults;

  // Imaging
  String? xrayResults;
  String? ctResults;
  String? mriResults;
  String? ultrasoundResults;
  String? otherImaging;

  String? createdAt;
  String? updatedAt;

  DiagnosisModel({
    this.id,
    this.userId,
    this.fullName,
    this.age,
    this.gender,
    this.chiefComplaint,
    this.symptoms,
    this.pastMedicalConditions,
    this.familyMedicalHistory,
    this.lifestyleHabits,
    this.medicationName,
    this.allergen,
    this.contentType,
    this.recommendationFromAi,
    this.aiHistory,
    this.temperature,
    this.bpSystolic,
    this.bpDiastolic,
    this.pulseRate,
    this.heartRate,
    this.respiratoryRate,
    this.o2Saturation,
    this.painScore,
    this.height,
    this.weight,
    this.generalAppearance,
    this.heent,
    this.cardiovascular,
    this.respiratoryExam,
    this.gastrointestinal,
    this.musculoskeletal,
    this.neurological,
    this.skin,
    this.otherFindings,
    this.cbcResults,
    this.bmpResults,
    this.lftResults,
    this.coagulationResults,
    this.otherLabResults,
    this.xrayResults,
    this.ctResults,
    this.mriResults,
    this.ultrasoundResults,
    this.otherImaging,
    this.createdAt,
    this.updatedAt,
  });

  DiagnosisModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id']?.toString();
    fullName = json['full_name'];
    age = json['age']?.toString();
    gender = json['gender'];
    chiefComplaint = _parseTagValue(json['chief_complaint']);
    symptoms = _parseTagValue(json['symptoms']);
    pastMedicalConditions = _parseTagValue(json['past_medical_conditions']);
    familyMedicalHistory = _parseTagValue(json['family_medical_history']);
    lifestyleHabits = _parseTagValue(json['lifestyle_habits']);
    medicationName = _parseTagValue(json['medication_name']);
    allergen = _parseTagValue(json['allergen']);
    contentType = json['content_type'];
    recommendationFromAi = json['RecommendationFromAi'];
    if (json['ai_history'] != null) {
      aiHistory = (json['ai_history'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    temperature = json['temperature'];
    bpSystolic = json['bp_systolic'];
    bpDiastolic = json['bp_diastolic'];
    pulseRate = json['pulse_rate'];
    heartRate = json['heart_rate'];
    respiratoryRate = json['respiratory_rate'];
    o2Saturation = json['o2_saturation'];
    painScore = json['pain_score'];
    height = json['height'];
    weight = json['weight'];
    generalAppearance = json['general_appearance'];
    heent = json['heent'];
    cardiovascular = json['cardiovascular'];
    respiratoryExam = json['respiratory_exam'];
    gastrointestinal = json['gastrointestinal'];
    musculoskeletal = json['musculoskeletal'];
    neurological = json['neurological'];
    skin = json['skin'];
    otherFindings = json['other_findings'];
    cbcResults = json['cbc_results'];
    bmpResults = json['bmp_results'];
    lftResults = json['lft_results'];
    coagulationResults = json['coagulation_results'];
    otherLabResults = json['other_lab_results'];
    xrayResults = json['xray_results'];
    ctResults = json['ct_results'];
    mriResults = json['mri_results'];
    ultrasoundResults = json['ultrasound_results'];
    otherImaging = json['other_imaging'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, String> toRequestBody() {
    final map = <String, String>{};
    if (age != null) map['age'] = age!;
    if (gender != null) map['gender'] = gender!;
    if (chiefComplaint != null) map['chief_complaint'] = chiefComplaint!;
    if (fullName != null && fullName!.isNotEmpty) map['full_name'] = fullName!;
    if (contentType != null) map['content_type'] = contentType!;
    if (symptoms != null && symptoms!.isNotEmpty) map['symptoms'] = symptoms!;
    if (pastMedicalConditions != null && pastMedicalConditions!.isNotEmpty) {
      map['past_medical_conditions'] = pastMedicalConditions!;
    }
    if (familyMedicalHistory != null && familyMedicalHistory!.isNotEmpty) {
      map['family_medical_history'] = familyMedicalHistory!;
    }
    if (lifestyleHabits != null && lifestyleHabits!.isNotEmpty) {
      map['lifestyle_habits'] = lifestyleHabits!;
    }
    if (medicationName != null && medicationName!.isNotEmpty) {
      map['medication_name'] = medicationName!;
    }
    if (allergen != null && allergen!.isNotEmpty) map['allergen'] = allergen!;
    // Vital signs
    if (temperature != null && temperature!.isNotEmpty) map['temperature'] = temperature!;
    if (bpSystolic != null && bpSystolic!.isNotEmpty) map['bp_systolic'] = bpSystolic!;
    if (bpDiastolic != null && bpDiastolic!.isNotEmpty) map['bp_diastolic'] = bpDiastolic!;
    if (pulseRate != null && pulseRate!.isNotEmpty) map['pulse_rate'] = pulseRate!;
    if (heartRate != null && heartRate!.isNotEmpty) map['heart_rate'] = heartRate!;
    if (respiratoryRate != null && respiratoryRate!.isNotEmpty) {
      map['respiratory_rate'] = respiratoryRate!;
    }
    if (o2Saturation != null && o2Saturation!.isNotEmpty) {
      map['o2_saturation'] = o2Saturation!;
    }
    if (painScore != null && painScore!.isNotEmpty) map['pain_score'] = painScore!;
    if (height != null && height!.isNotEmpty) map['height'] = height!;
    if (weight != null && weight!.isNotEmpty) map['weight'] = weight!;
    // Physical examination
    if (generalAppearance != null && generalAppearance!.isNotEmpty) {
      map['general_appearance'] = generalAppearance!;
    }
    if (heent != null && heent!.isNotEmpty) map['heent'] = heent!;
    if (cardiovascular != null && cardiovascular!.isNotEmpty) {
      map['cardiovascular'] = cardiovascular!;
    }
    if (respiratoryExam != null && respiratoryExam!.isNotEmpty) {
      map['respiratory_exam'] = respiratoryExam!;
    }
    if (gastrointestinal != null && gastrointestinal!.isNotEmpty) {
      map['gastrointestinal'] = gastrointestinal!;
    }
    if (musculoskeletal != null && musculoskeletal!.isNotEmpty) {
      map['musculoskeletal'] = musculoskeletal!;
    }
    if (neurological != null && neurological!.isNotEmpty) {
      map['neurological'] = neurological!;
    }
    if (skin != null && skin!.isNotEmpty) map['skin'] = skin!;
    if (otherFindings != null && otherFindings!.isNotEmpty) {
      map['other_findings'] = otherFindings!;
    }
    // Lab results
    if (cbcResults != null && cbcResults!.isNotEmpty) map['cbc_results'] = cbcResults!;
    if (bmpResults != null && bmpResults!.isNotEmpty) map['bmp_results'] = bmpResults!;
    if (lftResults != null && lftResults!.isNotEmpty) map['lft_results'] = lftResults!;
    if (coagulationResults != null && coagulationResults!.isNotEmpty) {
      map['coagulation_results'] = coagulationResults!;
    }
    if (otherLabResults != null && otherLabResults!.isNotEmpty) {
      map['other_lab_results'] = otherLabResults!;
    }
    // Imaging
    if (xrayResults != null && xrayResults!.isNotEmpty) map['xray_results'] = xrayResults!;
    if (ctResults != null && ctResults!.isNotEmpty) map['ct_results'] = ctResults!;
    if (mriResults != null && mriResults!.isNotEmpty) map['mri_results'] = mriResults!;
    if (ultrasoundResults != null && ultrasoundResults!.isNotEmpty) {
      map['ultrasound_results'] = ultrasoundResults!;
    }
    if (otherImaging != null && otherImaging!.isNotEmpty) {
      map['other_imaging'] = otherImaging!;
    }
    return map;
  }

  /// Parse tag-input JSON values like `[{"value":"text"}]` or plain strings.
  static String? _parseTagValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['value'] ?? e.values.first) : '$e')
          .join(', ');
    }
    final str = raw.toString();
    if (str.startsWith('[')) {
      try {
        final list = List<Map<String, dynamic>>.from(
          (str.startsWith('[') ? _tryDecodeJson(str) : null) ?? [],
        );
        if (list.isNotEmpty) {
          return list.map((e) => e['value'] ?? e.values.first).join(', ');
        }
      } catch (_) {}
    }
    return str;
  }

  static dynamic _tryDecodeJson(String str) {
    try {
      return List<dynamic>.from(
        (const JsonDecoder().convert(str)) as List,
      );
    } catch (_) {
      return null;
    }
  }
}

class DiagnosisOverview {
  final int total;
  final int thisWeek;
  final int differentials;
  final int treatments;

  DiagnosisOverview({
    this.total = 0,
    this.thisWeek = 0,
    this.differentials = 0,
    this.treatments = 0,
  });

  factory DiagnosisOverview.fromJson(Map<String, dynamic> json) {
    return DiagnosisOverview(
      total: json['total'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      differentials: json['differentials'] ?? 0,
      treatments: json['treatments'] ?? 0,
    );
  }
}

class DiagnosisListResponse {
  final List<DiagnosisModel> diagnoses;
  final DiagnosisOverview overview;
  final int currentPage;
  final int lastPage;

  DiagnosisListResponse({
    required this.diagnoses,
    required this.overview,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  factory DiagnosisListResponse.fromJson(Map<String, dynamic> json) {
    final diagData = json['diagnoses'] ?? {};
    final diagList = (diagData['data'] as List?)
            ?.map((e) => DiagnosisModel.fromJson(e))
            .toList() ??
        [];
    return DiagnosisListResponse(
      diagnoses: diagList,
      overview: DiagnosisOverview.fromJson(json['overview'] ?? {}),
      currentPage: diagData['current_page'] ?? 1,
      lastPage: diagData['last_page'] ?? 1,
    );
  }
}

class DiagnosisStoreResponse {
  final bool status;
  final String message;
  final int? diagnosisId;
  final String? redirectUrl;
  final String? newAiContent;
  final String? oldAiContent;
  final bool limitReached;
  final String? planSlug;
  final int? dailyLimit;
  final int? dailyUsed;

  DiagnosisStoreResponse({
    required this.status,
    required this.message,
    this.diagnosisId,
    this.redirectUrl,
    this.newAiContent,
    this.oldAiContent,
    this.limitReached = false,
    this.planSlug,
    this.dailyLimit,
    this.dailyUsed,
  });

  factory DiagnosisStoreResponse.fromJson(Map<String, dynamic> json) {
    return DiagnosisStoreResponse(
      status: json['status'] == true,
      message: json['message'] ?? '',
      diagnosisId: json['diagnosis_id'],
      redirectUrl: json['redirect_url'],
      newAiContent: json['new_ai_content'],
      oldAiContent: json['old_ai_content'],
      limitReached: json['limit_reached'] == true,
      planSlug: json['plan_slug'],
      dailyLimit: json['daily_limit'],
      dailyUsed: json['daily_used'],
    );
  }
}

class DiagnosisDetailResponse {
  final DiagnosisModel diagnosis;
  final List<DifferentialItem> differentials;
  final List<DiagnosisModel> relatedDiagnoses;
  final AiUsageInfo aiUsageInfo;

  DiagnosisDetailResponse({
    required this.diagnosis,
    required this.differentials,
    required this.relatedDiagnoses,
    required this.aiUsageInfo,
  });

  factory DiagnosisDetailResponse.fromJson(Map<String, dynamic> json) {
    final diffList = (json['differentials'] as List?)
            ?.map((e) => DifferentialItem.fromJson(e))
            .toList() ??
        [];
    final relatedList = (json['relatedDiagnoses'] as List?)
            ?.map((e) => DiagnosisModel.fromJson(e))
            .toList() ??
        [];
    return DiagnosisDetailResponse(
      diagnosis: DiagnosisModel.fromJson(json['diagnosis'] ?? {}),
      differentials: diffList,
      relatedDiagnoses: relatedList,
      aiUsageInfo: AiUsageInfo.fromJson(json['aiUsageInfo'] ?? {}),
    );
  }
}

class DifferentialItem {
  final String name;
  final int probability;
  final String explanation;

  DifferentialItem({
    required this.name,
    required this.probability,
    required this.explanation,
  });

  factory DifferentialItem.fromJson(Map<String, dynamic> json) {
    return DifferentialItem(
      name: json['name'] ?? '',
      probability: json['probability'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class AiUsageInfo {
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;
  final bool canAccess;

  AiUsageInfo({
    this.dailyLimit = 0,
    this.dailyUsed = 0,
    this.dailyRemaining = 0,
    this.canAccess = true,
  });

  factory AiUsageInfo.fromJson(Map<String, dynamic> json) {
    return AiUsageInfo(
      dailyLimit: json['daily_limit'] ?? 0,
      dailyUsed: json['daily_used'] ?? 0,
      dailyRemaining: json['daily_remaining'] ?? 0,
      canAccess: json['can_access'] == true,
    );
  }
}

class AnalyzeResponse {
  final bool status;
  final String? html;
  final int? aiRemaining;

  AnalyzeResponse({
    required this.status,
    this.html,
    this.aiRemaining,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      status: json['status'] == true,
      html: json['html'],
      aiRemaining: json['ai_remaining'],
    );
  }
}

class SimilarCaseItem {
  final int id;
  final String? age;
  final String? gender;
  final String? chiefComplaint;
  final String? date;

  SimilarCaseItem({
    required this.id,
    this.age,
    this.gender,
    this.chiefComplaint,
    this.date,
  });

  factory SimilarCaseItem.fromJson(Map<String, dynamic> json) {
    return SimilarCaseItem(
      id: json['id'] ?? 0,
      age: json['age']?.toString(),
      gender: json['gender'],
      chiefComplaint: json['chief_complaint'],
      date: json['date'],
    );
  }
}
