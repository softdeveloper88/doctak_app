import 'dart:convert';

class VitalSign {
  final String value;
  final bool abnormal;

  const VitalSign({required this.value, this.abnormal = false});

  Map<String, dynamic> toJson() => {
        'value': value,
        if (abnormal) 'abnormal': true,
      };

  factory VitalSign.fromJson(dynamic raw) {
    if (raw is! Map) return const VitalSign(value: '');
    return VitalSign(
      value: raw['value']?.toString() ?? '',
      abnormal: raw['abnormal'] == true || raw['abnormal'] == 1,
    );
  }
}

class LabResult {
  final String name;
  final String value;
  final bool abnormal;

  const LabResult({
    required this.name,
    required this.value,
    this.abnormal = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        if (abnormal) 'abnormal': true,
        if (abnormal) 'trend': 'up',
      };

  factory LabResult.fromJson(dynamic raw) {
    if (raw is! Map) return const LabResult(name: '', value: '');
    return LabResult(
      name: raw['name']?.toString() ?? '',
      value: raw['value']?.toString() ?? '',
      abnormal: raw['abnormal'] == true || raw['abnormal'] == 1,
    );
  }

  LabResult copyWith({String? name, String? value, bool? abnormal}) {
    return LabResult(
      name: name ?? this.name,
      value: value ?? this.value,
      abnormal: abnormal ?? this.abnormal,
    );
  }
}

class VitalSignsMap {
  final VitalSign? bp;
  final VitalSign? hr;
  final VitalSign? spo2;
  final VitalSign? temp;
  final VitalSign? rr;

  const VitalSignsMap({this.bp, this.hr, this.spo2, this.temp, this.rr});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (bp != null && bp!.value.isNotEmpty) map['bp'] = bp!.toJson();
    if (hr != null && hr!.value.isNotEmpty) map['hr'] = hr!.toJson();
    if (spo2 != null && spo2!.value.isNotEmpty) map['spo2'] = spo2!.toJson();
    if (temp != null && temp!.value.isNotEmpty) map['temp'] = temp!.toJson();
    if (rr != null && rr!.value.isNotEmpty) map['rr'] = rr!.toJson();
    return map;
  }

  factory VitalSignsMap.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const VitalSignsMap();
    VitalSign? sign(String key) {
      final v = raw[key];
      if (v == null) return null;
      final parsed = VitalSign.fromJson(v);
      return parsed.value.isEmpty ? null : parsed;
    }

    return VitalSignsMap(
      bp: sign('bp'),
      hr: sign('hr'),
      spo2: sign('spo2'),
      temp: sign('temp'),
      rr: sign('rr'),
    );
  }

  bool get isEmpty =>
      (bp?.value.isEmpty ?? true) &&
      (hr?.value.isEmpty ?? true) &&
      (spo2?.value.isEmpty ?? true) &&
      (temp?.value.isEmpty ?? true) &&
      (rr?.value.isEmpty ?? true);
}

class ClinicalSnapshot {
  final String? age;
  final String? gender;
  final String? ethnicity;
  final String? chiefComplaint;
  final String? pastMedicalHistory;
  final String? medications;
  final VitalSignsMap vitalSigns;
  final List<LabResult> labResults;
  final String? clinicalQuestion;

  const ClinicalSnapshot({
    this.age,
    this.gender,
    this.ethnicity,
    this.chiefComplaint,
    this.pastMedicalHistory,
    this.medications,
    this.vitalSigns = const VitalSignsMap(),
    this.labResults = const [],
    this.clinicalQuestion,
  });

  bool get isEmpty =>
      (age?.isEmpty ?? true) &&
      (gender?.isEmpty ?? true) &&
      (ethnicity?.isEmpty ?? true) &&
      (chiefComplaint?.isEmpty ?? true) &&
      (pastMedicalHistory?.isEmpty ?? true) &&
      (medications?.isEmpty ?? true) &&
      vitalSigns.isEmpty &&
      labResults.isEmpty &&
      (clinicalQuestion?.isEmpty ?? true);

  String? get patientLabel {
    final parts = <String>[];
    if (age != null && age!.isNotEmpty) parts.add('$age-year-old');
    if (gender != null && gender!.isNotEmpty) {
      parts.add(gender![0].toUpperCase() + gender!.substring(1));
    }
    return parts.isEmpty ? null : parts.join(' ');
  }

  Map<String, dynamic> toDemographicsJson() {
    final map = <String, dynamic>{};
    if (age != null && age!.isNotEmpty) map['age'] = age;
    if (gender != null && gender!.isNotEmpty) map['gender'] = gender;
    if (ethnicity != null && ethnicity!.isNotEmpty) map['ethnicity'] = ethnicity;
    if (chiefComplaint != null && chiefComplaint!.isNotEmpty) {
      map['chief_complaint'] = chiefComplaint;
    }
    if (pastMedicalHistory != null && pastMedicalHistory!.isNotEmpty) {
      map['past_medical_history'] = pastMedicalHistory;
    }
    if (medications != null && medications!.isNotEmpty) {
      map['medications'] = medications;
    }
    final vitals = vitalSigns.toJson();
    if (vitals.isNotEmpty) map['vital_signs'] = vitals;
    if (labResults.isNotEmpty) {
      map['lab_results'] = labResults.map((e) => e.toJson()).toList();
    }
    if (clinicalQuestion != null && clinicalQuestion!.isNotEmpty) {
      map['clinical_question'] = clinicalQuestion;
    }
    return map;
  }

  factory ClinicalSnapshot.fromDemographics(Map<String, dynamic>? demo) {
    if (demo == null) return const ClinicalSnapshot();

    List<LabResult> labs = [];
    final rawLabs = demo['lab_results'] ?? demo['labResults'];
    if (rawLabs is List) {
      labs = rawLabs.map(LabResult.fromJson).where((l) => l.name.isNotEmpty).toList();
    }

    final rawVitals = demo['vital_signs'] ?? demo['vitalSigns'];
    VitalSignsMap vitals = const VitalSignsMap();
    if (rawVitals is Map<String, dynamic>) {
      vitals = VitalSignsMap.fromMap(rawVitals);
    } else if (rawVitals is Map) {
      vitals = VitalSignsMap.fromMap(Map<String, dynamic>.from(rawVitals));
    }

    return ClinicalSnapshot(
      age: demo['age']?.toString(),
      gender: demo['gender']?.toString(),
      ethnicity: demo['ethnicity']?.toString(),
      chiefComplaint: demo['chief_complaint']?.toString() ??
          demo['chiefComplaint']?.toString(),
      pastMedicalHistory: demo['past_medical_history']?.toString() ??
          demo['pastMedicalHistory']?.toString(),
      medications: demo['medications']?.toString(),
      vitalSigns: vitals,
      labResults: labs,
      clinicalQuestion: demo['clinical_question']?.toString() ??
          demo['clinicalQuestion']?.toString(),
    );
  }

  factory ClinicalSnapshot.fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return const ClinicalSnapshot();
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return ClinicalSnapshot.fromDemographics(decoded);
      }
    } catch (_) {}
    return const ClinicalSnapshot();
  }
}
