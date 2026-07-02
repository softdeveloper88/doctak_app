import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';

abstract class DiagnosisState {}

class DiagnosisInitialState extends DiagnosisState {}

// ── List States ──

class DiagnosisListLoadingState extends DiagnosisState {}

class DiagnosisListLoadingMoreState extends DiagnosisState {}

class DiagnosisListLoadedState extends DiagnosisState {}

class DiagnosisListErrorState extends DiagnosisState {
  final String message;
  DiagnosisListErrorState(this.message);
}

// ── Detail States ──

class DiagnosisDetailLoadingState extends DiagnosisState {}

class DiagnosisDetailLoadedState extends DiagnosisState {
  final DiagnosisDetailResponse detail;
  DiagnosisDetailLoadedState(this.detail);
}

class DiagnosisDetailErrorState extends DiagnosisState {
  final String message;
  DiagnosisDetailErrorState(this.message);
}

// ── Submit / Create States ──

class DiagnosisSubmittingState extends DiagnosisState {}

class DiagnosisSubmittedState extends DiagnosisState {
  final DiagnosisStoreResponse response;
  DiagnosisSubmittedState(this.response);
}

class DiagnosisSubmitErrorState extends DiagnosisState {
  final String message;
  DiagnosisSubmitErrorState(this.message);
}

// ── Analyze (Re-generate AI) States ──

class DiagnosisAnalyzingState extends DiagnosisState {}

class DiagnosisAnalyzedState extends DiagnosisState {
  final AnalyzeResponse response;
  DiagnosisAnalyzedState(this.response);
}

class DiagnosisAnalyzeErrorState extends DiagnosisState {
  final String message;
  DiagnosisAnalyzeErrorState(this.message);
}

// ── Delete State ──

class DiagnosisDeletedState extends DiagnosisState {}

class DiagnosisDeleteErrorState extends DiagnosisState {
  final String message;
  DiagnosisDeleteErrorState(this.message);
}

// ── Similar Cases ──

class SimilarCasesLoadingState extends DiagnosisState {}

class SimilarCasesLoadedState extends DiagnosisState {
  final List<SimilarCaseItem> cases;
  SimilarCasesLoadedState(this.cases);
}
