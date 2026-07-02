import 'package:equatable/equatable.dart';
import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';

abstract class DiagnosisEvent extends Equatable {
  const DiagnosisEvent();
}

/// Load diagnosis list (paginated)
class LoadDiagnosisList extends DiagnosisEvent {
  final bool refresh;
  final String? search;
  final String? contentType;
  final String? gender;

  const LoadDiagnosisList({
    this.refresh = false,
    this.search,
    this.contentType,
    this.gender,
  });

  @override
  List<Object?> get props => [refresh, search, contentType, gender];
}

/// Load more diagnoses (pagination trigger)
class LoadMoreDiagnoses extends DiagnosisEvent {
  final int index;

  const LoadMoreDiagnoses({required this.index});

  @override
  List<Object?> get props => [index];
}

/// Load a single diagnosis detail
class LoadDiagnosisDetail extends DiagnosisEvent {
  final int id;

  const LoadDiagnosisDetail({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Submit a new diagnosis (5-step form)
class SubmitDiagnosis extends DiagnosisEvent {
  final DiagnosisModel diagnosis;

  const SubmitDiagnosis({required this.diagnosis});

  @override
  List<Object?> get props => [diagnosis];
}

/// Update an existing diagnosis
class UpdateDiagnosis extends DiagnosisEvent {
  final int id;
  final DiagnosisModel diagnosis;

  const UpdateDiagnosis({required this.id, required this.diagnosis});

  @override
  List<Object?> get props => [id, diagnosis];
}

/// Delete a diagnosis
class DeleteDiagnosis extends DiagnosisEvent {
  final int id;

  const DeleteDiagnosis({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Regenerate AI analysis with a different content type
class AnalyzeDiagnosis extends DiagnosisEvent {
  final int id;
  final String contentType;

  const AnalyzeDiagnosis({required this.id, required this.contentType});

  @override
  List<Object?> get props => [id, contentType];
}

/// Search similar cases
class SearchSimilarCases extends DiagnosisEvent {
  final String complaint;

  const SearchSimilarCases({required this.complaint});

  @override
  List<Object?> get props => [complaint];
}
