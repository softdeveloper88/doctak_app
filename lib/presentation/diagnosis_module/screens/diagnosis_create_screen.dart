import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_bloc.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_event.dart';
import 'package:doctak_app/presentation/diagnosis_module/bloc/diagnosis_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiagnosisCreateScreen extends StatefulWidget {
  final DiagnosisModel? existingDiagnosis;

  const DiagnosisCreateScreen({super.key, this.existingDiagnosis});

  @override
  State<DiagnosisCreateScreen> createState() => _DiagnosisCreateScreenState();
}

class _DiagnosisCreateScreenState extends State<DiagnosisCreateScreen> {
  late final DiagnosisBloc _bloc;
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  static const _totalSteps = 5;

  // Step 1: Basic Info
  final _ageController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  String _selectedGender = 'male';

  // Step 2: Medical History
  final _pastMedicalController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergenController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _lifestyleController = TextEditingController();

  // Step 3: Examination - Vital Signs
  final _temperatureController = TextEditingController();
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseRateController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _o2SaturationController = TextEditingController();
  final _painScoreController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  // Physical exam
  final _generalAppearanceController = TextEditingController();
  final _heentController = TextEditingController();
  final _cardiovascularController = TextEditingController();
  final _respiratoryExamController = TextEditingController();
  final _gastrointestinalController = TextEditingController();
  final _neurologicalController = TextEditingController();
  final _skinController = TextEditingController();
  final _musculoskeletalController = TextEditingController();
  final _otherFindingsController = TextEditingController();

  // Step 4: Lab & Imaging
  final _cbcController = TextEditingController();
  final _bmpController = TextEditingController();
  final _lftController = TextEditingController();
  final _coagulationController = TextEditingController();
  final _otherLabController = TextEditingController();
  final _xrayController = TextEditingController();
  final _ctController = TextEditingController();
  final _mriController = TextEditingController();
  final _ultrasoundController = TextEditingController();
  final _otherImagingController = TextEditingController();

  // Step 5: Content type selection
  String _selectedContentType = 'diagnoses';

  static const _genderOptions = [
    'male',
    'female',
    'non-binary',
    'other',
    'prefer_not_to_say',
  ];

  static const _contentTypeOptions = [
    {
      'key': 'diagnoses',
      'label': 'Differential Diagnosis',
      'desc': 'Ranked list of probable conditions with likelihood',
      'icon': Icons.medical_services,
    },
    {
      'key': 'treatment',
      'label': 'Treatment Plan',
      'desc': 'Pharmacological & non-pharmacological interventions',
      'icon': Icons.healing,
    },
    {
      'key': 'labs',
      'label': 'Lab Recommendations',
      'desc': 'Recommended diagnostic tests with rationale',
      'icon': Icons.science,
    },
    {
      'key': 'interactions',
      'label': 'Drug Interactions',
      'desc': 'Drug-drug and drug-condition interactions',
      'icon': Icons.compare_arrows,
    },
    {
      'key': 'education',
      'label': 'Patient Education',
      'desc': 'Patient-friendly health information',
      'icon': Icons.school,
    },
    {
      'key': 'note',
      'label': 'Clinical Note (SOAP)',
      'desc': 'Complete SOAP format note with ICD codes',
      'icon': Icons.note_alt,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bloc = DiagnosisBloc();
    _populateFromExisting();
  }

  void _populateFromExisting() {
    final d = widget.existingDiagnosis;
    if (d == null) return;
    _ageController.text = d.age ?? '';
    _selectedGender = d.gender ?? 'male';
    _chiefComplaintController.text = d.chiefComplaint ?? '';
    _symptomsController.text = d.symptoms ?? '';
    _pastMedicalController.text = d.pastMedicalConditions ?? '';
    _medicationController.text = d.medicationName ?? '';
    _allergenController.text = d.allergen ?? '';
    _familyHistoryController.text = d.familyMedicalHistory ?? '';
    _lifestyleController.text = d.lifestyleHabits ?? '';
    _temperatureController.text = d.temperature ?? '';
    _bpSystolicController.text = d.bpSystolic ?? '';
    _bpDiastolicController.text = d.bpDiastolic ?? '';
    _pulseRateController.text = d.pulseRate ?? '';
    _respiratoryRateController.text = d.respiratoryRate ?? '';
    _o2SaturationController.text = d.o2Saturation ?? '';
    _painScoreController.text = d.painScore ?? '';
    _weightController.text = d.weight ?? '';
    _heightController.text = d.height ?? '';
    _generalAppearanceController.text = d.generalAppearance ?? '';
    _heentController.text = d.heent ?? '';
    _cardiovascularController.text = d.cardiovascular ?? '';
    _respiratoryExamController.text = d.respiratoryExam ?? '';
    _gastrointestinalController.text = d.gastrointestinal ?? '';
    _neurologicalController.text = d.neurological ?? '';
    _skinController.text = d.skin ?? '';
    _musculoskeletalController.text = d.musculoskeletal ?? '';
    _otherFindingsController.text = d.otherFindings ?? '';
    _cbcController.text = d.cbcResults ?? '';
    _bmpController.text = d.bmpResults ?? '';
    _lftController.text = d.lftResults ?? '';
    _coagulationController.text = d.coagulationResults ?? '';
    _otherLabController.text = d.otherLabResults ?? '';
    _xrayController.text = d.xrayResults ?? '';
    _ctController.text = d.ctResults ?? '';
    _mriController.text = d.mriResults ?? '';
    _ultrasoundController.text = d.ultrasoundResults ?? '';
    _otherImagingController.text = d.otherImaging ?? '';
    _selectedContentType = d.contentType ?? 'diagnoses';
  }

  @override
  void dispose() {
    _bloc.close();
    _ageController.dispose();
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _pastMedicalController.dispose();
    _medicationController.dispose();
    _allergenController.dispose();
    _familyHistoryController.dispose();
    _lifestyleController.dispose();
    _temperatureController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseRateController.dispose();
    _respiratoryRateController.dispose();
    _o2SaturationController.dispose();
    _painScoreController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _generalAppearanceController.dispose();
    _heentController.dispose();
    _cardiovascularController.dispose();
    _respiratoryExamController.dispose();
    _gastrointestinalController.dispose();
    _neurologicalController.dispose();
    _skinController.dispose();
    _musculoskeletalController.dispose();
    _otherFindingsController.dispose();
    _cbcController.dispose();
    _bmpController.dispose();
    _lftController.dispose();
    _coagulationController.dispose();
    _otherLabController.dispose();
    _xrayController.dispose();
    _ctController.dispose();
    _mriController.dispose();
    _ultrasoundController.dispose();
    _otherImagingController.dispose();
    super.dispose();
  }

  DiagnosisModel _buildDiagnosisModel() {
    return DiagnosisModel(
      age: _ageController.text.trim(),
      gender: _selectedGender,
      chiefComplaint: _chiefComplaintController.text.trim(),
      symptoms: _symptomsController.text.trim(),
      contentType: _selectedContentType,
      pastMedicalConditions: _pastMedicalController.text.trim(),
      medicationName: _medicationController.text.trim(),
      allergen: _allergenController.text.trim(),
      familyMedicalHistory: _familyHistoryController.text.trim(),
      lifestyleHabits: _lifestyleController.text.trim(),
      temperature: _temperatureController.text.trim(),
      bpSystolic: _bpSystolicController.text.trim(),
      bpDiastolic: _bpDiastolicController.text.trim(),
      pulseRate: _pulseRateController.text.trim(),
      respiratoryRate: _respiratoryRateController.text.trim(),
      o2Saturation: _o2SaturationController.text.trim(),
      painScore: _painScoreController.text.trim(),
      weight: _weightController.text.trim(),
      height: _heightController.text.trim(),
      generalAppearance: _generalAppearanceController.text.trim(),
      heent: _heentController.text.trim(),
      cardiovascular: _cardiovascularController.text.trim(),
      respiratoryExam: _respiratoryExamController.text.trim(),
      gastrointestinal: _gastrointestinalController.text.trim(),
      neurological: _neurologicalController.text.trim(),
      skin: _skinController.text.trim(),
      musculoskeletal: _musculoskeletalController.text.trim(),
      otherFindings: _otherFindingsController.text.trim(),
      cbcResults: _cbcController.text.trim(),
      bmpResults: _bmpController.text.trim(),
      lftResults: _lftController.text.trim(),
      coagulationResults: _coagulationController.text.trim(),
      otherLabResults: _otherLabController.text.trim(),
      xrayResults: _xrayController.text.trim(),
      ctResults: _ctController.text.trim(),
      mriResults: _mriController.text.trim(),
      ultrasoundResults: _ultrasoundController.text.trim(),
      otherImaging: _otherImagingController.text.trim(),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final model = _buildDiagnosisModel();
    if (widget.existingDiagnosis?.id != null) {
      _bloc.add(
        UpdateDiagnosis(id: widget.existingDiagnosis!.id!, diagnosis: model),
      );
    } else {
      _bloc.add(SubmitDiagnosis(diagnosis: model));
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isEditing = widget.existingDiagnosis != null;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<DiagnosisBloc, DiagnosisState>(
        listener: (context, state) {
          if (state is DiagnosisSubmittedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: theme.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is DiagnosisSubmitErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: DoctakAppBar(
            title: isEditing ? 'Edit Diagnosis' : 'New Diagnosis',
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildStepIndicator(theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentStep(theme),
                  ),
                ),
                _buildBottomBar(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(OneUITheme theme) {
    const labels = [
      'Basic Info',
      'History',
      'Examination',
      'Lab & Imaging',
      'AI Analysis',
    ];
    return Container(
      color: theme.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone || isActive
                              ? theme.primary
                              : theme.divider,
                        ),
                      ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? theme.primary
                            : isActive
                            ? theme.primary
                            : theme.surfaceVariant,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : theme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (i < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone ? theme.primary : theme.divider,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: isActive ? theme.primary : theme.textTertiary,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(OneUITheme theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo(theme);
      case 1:
        return _buildStep2MedicalHistory(theme);
      case 2:
        return _buildStep3Examination(theme);
      case 3:
        return _buildStep4LabImaging(theme);
      case 4:
        return _buildStep5ContentType(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(OneUITheme theme) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      bloc: _bloc,
      builder: (context, state) {
        final isSubmitting = state is DiagnosisSubmittingState;
        return Container(
          color: theme.cardBackground,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.primary),
                    ),
                    child: Text('Back', style: TextStyle(color: theme.primary)),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentStep == 0 ? 1 : 1,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : (_currentStep == _totalSteps - 1
                            ? _onSubmit
                            : _nextStep),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.primary,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Generate Analysis'
                              : 'Next',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────── Step 1: Basic Info ──────────────────────────

  Widget _buildStep1BasicInfo(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Patient Information', Icons.person),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _ageController,
          label: 'Age *',
          hint: 'Enter patient age',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Age is required';
            final age = int.tryParse(v);
            if (age == null || age < 0 || age > 150)
              return 'Enter valid age (0-150)';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          theme,
          label: 'Gender *',
          value: _selectedGender,
          items: _genderOptions
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(_formatGenderLabel(g)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedGender = v!),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _chiefComplaintController,
          label: 'Chief Complaint *',
          hint: 'Describe the main complaint',
          maxLines: 3,
          validator: (v) =>
              v == null || v.isEmpty ? 'Chief complaint is required' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _symptomsController,
          label: 'Symptoms',
          hint: 'Describe associated symptoms',
          maxLines: 3,
        ),
      ],
    );
  }

  // ────────────────────────── Step 2: Medical History ──────────────────────

  Widget _buildStep2MedicalHistory(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Medical History', Icons.history),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _pastMedicalController,
          label: 'Past Medical Conditions',
          hint: 'e.g., Diabetes, Hypertension',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _medicationController,
          label: 'Current Medications',
          hint: 'List current medications',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _allergenController,
          label: 'Allergies',
          hint: 'Known allergies',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _familyHistoryController,
          label: 'Family Medical History',
          hint: 'Relevant family history',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _lifestyleController,
          label: 'Lifestyle Habits',
          hint: 'e.g., Smoking, Alcohol, Exercise',
        ),
      ],
    );
  }

  // ────────────────────────── Step 3: Examination ──────────────────────────

  Widget _buildStep3Examination(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Vital Signs', Icons.monitor_heart),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                theme,
                controller: _temperatureController,
                label: 'Temp (°F)',
                hint: '98.6',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                theme,
                controller: _pulseRateController,
                label: 'Pulse (bpm)',
                hint: '72',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                theme,
                controller: _bpSystolicController,
                label: 'BP Systolic',
                hint: '120',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                theme,
                controller: _bpDiastolicController,
                label: 'BP Diastolic',
                hint: '80',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                theme,
                controller: _respiratoryRateController,
                label: 'Resp Rate',
                hint: '16',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                theme,
                controller: _o2SaturationController,
                label: 'O₂ Sat (%)',
                hint: '98',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                theme,
                controller: _painScoreController,
                label: 'Pain (0-10)',
                hint: '0',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                theme,
                controller: _weightController,
                label: 'Weight (kg)',
                hint: '70',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                theme,
                controller: _heightController,
                label: 'Height (cm)',
                hint: '170',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'Physical Examination', Icons.accessibility_new),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _generalAppearanceController,
          label: 'General Appearance',
          hint: 'Alert, well-appearing, etc.',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _heentController,
          label: 'HEENT',
          hint: 'Head, Eyes, Ears, Nose, Throat',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _cardiovascularController,
          label: 'Cardiovascular',
          hint: 'Heart sounds, rhythm, etc.',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _respiratoryExamController,
          label: 'Respiratory',
          hint: 'Breath sounds, effort, etc.',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _gastrointestinalController,
          label: 'Gastrointestinal',
          hint: 'Abdomen exam findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _musculoskeletalController,
          label: 'Musculoskeletal',
          hint: 'Joint, muscle findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _neurologicalController,
          label: 'Neurological',
          hint: 'Mental status, cranial nerves, etc.',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _skinController,
          label: 'Skin',
          hint: 'Rashes, lesions, etc.',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _otherFindingsController,
          label: 'Other Findings',
          hint: 'Any additional exam findings',
          maxLines: 2,
        ),
      ],
    );
  }

  // ────────────────────────── Step 4: Lab & Imaging ──────────────────────

  Widget _buildStep4LabImaging(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Laboratory Results', Icons.biotech),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _cbcController,
          label: 'CBC Results',
          hint: 'Complete blood count findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _bmpController,
          label: 'BMP Results',
          hint: 'Basic metabolic panel findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _lftController,
          label: 'LFT Results',
          hint: 'Liver function test findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _coagulationController,
          label: 'Coagulation Results',
          hint: 'PT/INR, aPTT findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _otherLabController,
          label: 'Other Lab Results',
          hint: 'Any other lab findings',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'Imaging Results', Icons.image_search),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _xrayController,
          label: 'X-Ray Results',
          hint: 'X-ray findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _ctController,
          label: 'CT Scan Results',
          hint: 'CT scan findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _mriController,
          label: 'MRI Results',
          hint: 'MRI findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _ultrasoundController,
          label: 'Ultrasound Results',
          hint: 'Ultrasound findings',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _otherImagingController,
          label: 'Other Imaging',
          hint: 'Any other imaging findings',
          maxLines: 2,
        ),
      ],
    );
  }

  // ────────────────────────── Step 5: AI Content Type ──────────────────────

  Widget _buildStep5ContentType(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Select Analysis Type', Icons.auto_awesome),
        const SizedBox(height: 8),
        Text(
          'Choose the type of AI-powered analysis to generate:',
          style: TextStyle(color: theme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ..._contentTypeOptions.map((opt) {
          final key = opt['key'] as String;
          final isSelected = _selectedContentType == key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedContentType = key),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary.withValues(alpha: 0.12)
                            : theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        opt['icon'] as IconData,
                        color: isSelected ? theme.primary : theme.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['desc'] as String,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: key,
                      groupValue: _selectedContentType,
                      onChanged: (v) =>
                          setState(() => _selectedContentType = v!),
                      activeColor: theme.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ────────────────────────── Shared Helpers ──────────────────────────

  Widget _sectionTitle(OneUITheme theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    OneUITheme theme, {
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          textInputType: keyboardType,
          validator: validator,
          autofocus: false,
          hintText: hint,
          hintStyle: TextStyle(color: theme.textTertiary),
          textStyle: TextStyle(color: theme.textPrimary, fontSize: 15),
          filled: true,
          fillColor: theme.cardBackground,
          borderDecoration: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    OneUITheme theme, {
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: theme.textPrimary, fontSize: 15),
          dropdownColor: theme.cardBackground,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatGenderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'non-binary':
        return 'Non-Binary';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Prefer Not to Say';
      default:
        return gender;
    }
  }
}
