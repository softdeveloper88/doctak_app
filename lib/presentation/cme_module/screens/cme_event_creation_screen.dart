import 'dart:io';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CmeEventCreationScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? initialData;

  const CmeEventCreationScreen({super.key, this.eventId, this.initialData});

  @override
  State<CmeEventCreationScreen> createState() => _CmeEventCreationScreenState();
}

class _CmeEventCreationScreenState extends State<CmeEventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController();
  final _creditAmountCtrl = TextEditingController();
  final _accreditationBodyCtrl = TextEditingController();
  final _accreditationNumberCtrl = TextEditingController();
  final _registrationFeeCtrl = TextEditingController();
  final _earlyBirdFeeCtrl = TextEditingController();
  final _specialtiesCtrl = TextEditingController();
  final _targetAudienceCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();
  final _learningObjectivesCtrl = TextEditingController();

  File? _coverImage;
  String? _existingCoverUrl;

  String _selectedType = 'conference';
  String _selectedFormat = 'in_person';
  String _selectedCreditType = 'AMA PRA Category 1';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;

  bool get isEditing => widget.eventId != null;

  static const _eventTypes = [
    'conference',
    'workshop',
    'webinar',
    'seminar',
    'grand_rounds',
    'journal_club',
    'simulation',
    'self_study',
  ];

  static const _formatTypes = [
    'in_person',
    'virtual',
    'hybrid',
  ];

  static const _creditTypes = [
    'AMA PRA Category 1',
    'AMA PRA Category 2',
    'AAFP Prescribed',
    'AOA Category 1A',
    'Self-Assessment',
    'Patient Safety',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _populateFields(widget.initialData!);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _titleCtrl.text = data['title'] ?? '';
    _descriptionCtrl.text = data['description'] ?? '';
    _shortDescCtrl.text = data['short_description'] ?? '';
    _locationCtrl.text = data['location'] ?? '';
    _venueCtrl.text = data['venue'] ?? '';
    _cityCtrl.text = data['city'] ?? '';
    _countryCtrl.text = data['country'] ?? '';
    _maxParticipantsCtrl.text = '${data['max_participants'] ?? ''}';
    _creditAmountCtrl.text = '${data['credit_amount'] ?? ''}';
    _accreditationBodyCtrl.text = data['accreditation_body'] ?? '';
    _accreditationNumberCtrl.text = data['accreditation_number'] ?? '';
    _registrationFeeCtrl.text = '${data['registration_fee'] ?? ''}';
    _earlyBirdFeeCtrl.text = '${data['early_bird_fee'] ?? ''}';
    _specialtiesCtrl.text = data['specialties'] ?? '';
    _targetAudienceCtrl.text = data['target_audience'] ?? '';
    _meetingLinkCtrl.text = data['meeting_link'] ?? '';
    _learningObjectivesCtrl.text = data['learning_objectives'] ?? '';
    _existingCoverUrl = data['banner_image'] ?? data['thumbnail'];

    if (data['type'] != null && _eventTypes.contains(data['type'])) {
      _selectedType = data['type'];
    }
    if (data['format'] != null && _formatTypes.contains(data['format'])) {
      _selectedFormat = data['format'];
    }
    if (data['credit_type'] != null) {
      _selectedCreditType = data['credit_type'];
    }
    if (data['start_date'] != null) {
      _startDate = DateTime.tryParse(data['start_date']);
    }
    if (data['end_date'] != null) {
      _endDate = DateTime.tryParse(data['end_date']);
    }
    if (data['registration_deadline'] != null) {
      _registrationDeadline = DateTime.tryParse(data['registration_deadline']);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _shortDescCtrl.dispose();
    _locationCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _creditAmountCtrl.dispose();
    _accreditationBodyCtrl.dispose();
    _accreditationNumberCtrl.dispose();
    _registrationFeeCtrl.dispose();
    _earlyBirdFeeCtrl.dispose();
    _specialtiesCtrl.dispose();
    _targetAudienceCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _learningObjectivesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: Text(
          isEditing ? 'Edit Event' : 'Create CME Event',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    isEditing ? 'Update' : 'Create',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Basic Info ──
            _sectionTitle(theme, 'Basic Information'),
            const SizedBox(height: 10),

            // ── Cover Image ──
            _buildCoverImagePicker(theme),
            const SizedBox(height: 14),

            _buildTextField(theme, _titleCtrl, 'Event Title',
                required: true, maxLines: 1),
            const SizedBox(height: 10),
            _buildTextField(theme, _shortDescCtrl, 'Short Description',
                maxLines: 2),
            const SizedBox(height: 10),
            _buildTextField(theme, _descriptionCtrl, 'Description',
                maxLines: 5),
            const SizedBox(height: 10),
            _buildTextField(theme, _learningObjectivesCtrl,
                'Learning Objectives', maxLines: 4),
            const SizedBox(height: 14),

            // ── Type & Format ──
            Row(
              children: [
                Expanded(child: _buildDropdown(
                    theme, 'Event Type', _selectedType, _eventTypes,
                    (v) => setState(() => _selectedType = v!))),
                const SizedBox(width: 10),
                Expanded(child: _buildDropdown(
                    theme, 'Format', _selectedFormat, _formatTypes,
                    (v) => setState(() => _selectedFormat = v!))),
              ],
            ),
            const SizedBox(height: 20),

            // ── Dates ──
            _sectionTitle(theme, 'Dates & Schedule'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildDatePicker(
                    theme, 'Start Date', _startDate,
                    (d) => setState(() => _startDate = d))),
                const SizedBox(width: 10),
                Expanded(child: _buildDatePicker(
                    theme, 'End Date', _endDate,
                    (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 10),
            _buildDatePicker(theme, 'Registration Deadline',
                _registrationDeadline,
                (d) => setState(() => _registrationDeadline = d)),
            const SizedBox(height: 20),

            // ── Location ──
            if (_selectedFormat != 'virtual') ...[
              _sectionTitle(theme, 'Location'),
              const SizedBox(height: 10),
              _buildTextField(theme, _venueCtrl, 'Venue'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(theme, _cityCtrl, 'City')),
                  const SizedBox(width: 10),
                  Expanded(child:
                      _buildTextField(theme, _countryCtrl, 'Country')),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(theme, _locationCtrl, 'Location / Address'),
              const SizedBox(height: 20),
            ],

            // ── Virtual Link ──
            if (_selectedFormat != 'in_person') ...[
              _sectionTitle(theme, 'Virtual Meeting'),
              const SizedBox(height: 10),
              _buildTextField(theme, _meetingLinkCtrl, 'Meeting Link'),
              const SizedBox(height: 20),
            ],

            // ── Credits ──
            _sectionTitle(theme, 'Credits & Accreditation'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                      theme, 'Credit Type', _selectedCreditType,
                      _creditTypes,
                      (v) => setState(() => _selectedCreditType = v!)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                      theme, _creditAmountCtrl, 'Credits',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(
                    theme, _accreditationBodyCtrl, 'Accreditation Body')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(
                    theme, _accreditationNumberCtrl, 'Accreditation #')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Registration ──
            _sectionTitle(theme, 'Registration & Fees'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(
                    theme, _maxParticipantsCtrl, 'Max Participants',
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(
                    theme, _registrationFeeCtrl, 'Fee (\$)',
                    keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(theme, _earlyBirdFeeCtrl, 'Early Bird Fee (\$)',
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),

            // ── Target ──
            _sectionTitle(theme, 'Audience'),
            const SizedBox(height: 10),
            _buildTextField(theme, _specialtiesCtrl,
                'Specialties (comma separated)'),
            const SizedBox(height: 10),
            _buildTextField(theme, _targetAudienceCtrl, 'Target Audience'),
            const SizedBox(height: 30),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEditing ? 'Update Event' : 'Create Event',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImagePicker(OneUITheme theme) {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!), fit: BoxFit.cover)
              : _existingCoverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_existingCoverUrl!),
                      fit: BoxFit.cover)
                  : null,
        ),
        child: (_coverImage == null && _existingCoverUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: theme.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Add Cover Image',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: theme.textTertiary,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16,
                          color: Colors.white),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() {
                        _coverImage = null;
                        _existingCoverUrl = null;
                      }),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  Widget _sectionTitle(OneUITheme theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    OneUITheme theme,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: theme.textPrimary,
      ),
      decoration: theme.inputDecoration(hint: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildDropdown(
    OneUITheme theme,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: theme.cardBackground,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: theme.textPrimary,
          ),
          hint: Text(label, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: theme.textTertiary)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(_formatLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    OneUITheme theme,
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date == null) return;

        final time = await showTimePicker(
          context: context,
          initialTime: value != null
              ? TimeOfDay.fromDateTime(value)
              : TimeOfDay.now(),
        );

        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 9,
          time?.minute ?? 0,
        );
        onPicked(dateTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? '${value.month}/${value.day}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: value != null ? theme.textPrimary : theme.textTertiary,
                ),
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: theme.textTertiary),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, String>{
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'short_description': _shortDescCtrl.text.trim(),
        'type': _selectedType,
        'format': _selectedFormat,
        'credit_type': _selectedCreditType,
      };

      if (_creditAmountCtrl.text.isNotEmpty) {
        data['credit_amount'] = _creditAmountCtrl.text.trim();
      }
      if (_startDate != null) {
        data['start_date'] = _startDate!.toIso8601String();
      }
      if (_endDate != null) {
        data['end_date'] = _endDate!.toIso8601String();
      }
      if (_registrationDeadline != null) {
        data['registration_deadline'] =
            _registrationDeadline!.toIso8601String();
      }
      if (_locationCtrl.text.isNotEmpty) {
        data['location'] = _locationCtrl.text.trim();
      }
      if (_venueCtrl.text.isNotEmpty) {
        data['venue'] = _venueCtrl.text.trim();
      }
      if (_cityCtrl.text.isNotEmpty) {
        data['city'] = _cityCtrl.text.trim();
      }
      if (_countryCtrl.text.isNotEmpty) {
        data['country'] = _countryCtrl.text.trim();
      }
      if (_maxParticipantsCtrl.text.isNotEmpty) {
        data['max_participants'] = _maxParticipantsCtrl.text.trim();
      }
      if (_accreditationBodyCtrl.text.isNotEmpty) {
        data['accreditation_body'] = _accreditationBodyCtrl.text.trim();
      }
      if (_accreditationNumberCtrl.text.isNotEmpty) {
        data['accreditation_number'] = _accreditationNumberCtrl.text.trim();
      }
      if (_registrationFeeCtrl.text.isNotEmpty) {
        data['registration_fee'] = _registrationFeeCtrl.text.trim();
      }
      if (_earlyBirdFeeCtrl.text.isNotEmpty) {
        data['early_bird_fee'] = _earlyBirdFeeCtrl.text.trim();
      }
      if (_specialtiesCtrl.text.isNotEmpty) {
        data['specialties'] = _specialtiesCtrl.text.trim();
      }
      if (_targetAudienceCtrl.text.isNotEmpty) {
        data['target_audience'] = _targetAudienceCtrl.text.trim();
      }
      if (_meetingLinkCtrl.text.isNotEmpty) {
        data['meeting_link'] = _meetingLinkCtrl.text.trim();
      }
      if (_learningObjectivesCtrl.text.isNotEmpty) {
        data['learning_objectives'] = _learningObjectivesCtrl.text.trim();
      }

      if (isEditing) {
        await CmeApiService.updateEvent(widget.eventId!, data);
      } else {
        await CmeApiService.createEventWithImage(data, _coverImage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Event updated successfully'
                : 'Event created successfully'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
