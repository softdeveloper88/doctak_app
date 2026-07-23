import 'dart:io';

import 'package:doctak_app/data/apiClient/services/organization_profile_api_service.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart' hide AppButton;

/// Owner/admin editor for a business page — mirrors the website's
/// "Edit workspace" flow (PATCH /api/business/{id}/profile + media uploads).
class OrganizationProfileEditScreen extends StatefulWidget {
  const OrganizationProfileEditScreen({required this.profile, super.key});

  final OrganizationPublicProfileModel profile;

  @override
  State<OrganizationProfileEditScreen> createState() =>
      _OrganizationProfileEditScreenState();
}

/// A type-specific profile field (hospital / recruiter / CME / pharma),
/// same shape as the website's workspace editor.
class _TypeFieldSpec {
  const _TypeFieldSpec(
    this.key,
    this.label, {
    this.isList = false,
    this.keyboardType,
  });

  final String key;
  final String label;

  /// Comma-separated input persisted as a JSON list on the server.
  final bool isList;
  final TextInputType? keyboardType;
}

const _typeFieldSpecs = <String, List<_TypeFieldSpec>>{
  'hospital': [
    _TypeFieldSpec('departments', 'Departments (comma separated)', isList: true),
    _TypeFieldSpec('bedCount', 'Bed count', keyboardType: TextInputType.number),
    _TypeFieldSpec('accreditations', 'Accreditations (comma separated)',
        isList: true),
    _TypeFieldSpec('servicesOffered', 'Services offered (comma separated)',
        isList: true),
  ],
  'recruiter': [
    _TypeFieldSpec('companySize', 'Company size'),
    _TypeFieldSpec('industryFocus', 'Industry focus'),
    _TypeFieldSpec('specialtiesHired', 'Specialties hired (comma separated)',
        isList: true),
    _TypeFieldSpec('recruitmentAreas', 'Recruitment areas (comma separated)',
        isList: true),
  ],
  'cme_provider': [
    _TypeFieldSpec('accreditationBody', 'Accreditation body'),
    _TypeFieldSpec('accreditationNumber', 'Accreditation number'),
    _TypeFieldSpec(
        'creditTypesOffered', 'Credit types offered (comma separated)',
        isList: true),
    _TypeFieldSpec('specialtiesServed', 'Specialties served (comma separated)',
        isList: true),
  ],
  'pharma': [
    _TypeFieldSpec('registrationNumber', 'Registration number'),
    _TypeFieldSpec('taxId', 'Tax ID'),
    _TypeFieldSpec('keyProducts', 'Key products'),
    _TypeFieldSpec('targetMarket', 'Target market'),
    _TypeFieldSpec('companyType', 'Company type'),
  ],
};

class _OrganizationProfileEditScreenState
    extends State<OrganizationProfileEditScreen> {
  final _api = OrganizationProfileApiService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _address;
  late final TextEditingController _city;

  final Map<String, TextEditingController> _typeControllers = {};
  bool _emergencyServices = false;

  DateTime? _establishedAt;
  String? _logoUrl;
  String? _coverUrl;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _mediaChanged = false;

  OrganizationSummary get _org => widget.profile.organization;
  List<_TypeFieldSpec> get _typeFields => _typeFieldSpecs[_org.type] ?? const [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _org.name);
    _description = TextEditingController(text: _org.description ?? '');
    _email = TextEditingController(text: _org.email ?? '');
    _phone = TextEditingController(text: _org.phone ?? '');
    _website = TextEditingController(text: _org.website ?? '');
    _address = TextEditingController(text: _org.address ?? '');
    _city = TextEditingController(text: _org.city ?? '');
    _establishedAt = DateTime.tryParse(_org.establishedAt ?? '');
    _logoUrl = _org.logoUrl;
    _coverUrl = _org.coverUrl;

    final typeProfile = widget.profile.typeProfile;
    for (final spec in _typeFields) {
      _typeControllers[spec.key] =
          TextEditingController(text: _typeValueToText(typeProfile[spec.key]));
    }
    _emergencyServices = typeProfile['emergencyServices'] == true;
  }

  String _typeValueToText(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _address.dispose();
    _city.dispose();
    for (final controller in _typeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUpload(String kind) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: kind == 'cover' ? 2400 : 1200,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      // Common codes: already_active, photo_access_denied, channel-error
      // (channel-error often appears after hot restart — do a full rebuild).
      final code = e.code.toLowerCase();
      if (code == 'already_active') {
        toast('Finish the previous photo selection first');
      } else if (code.contains('denied') || code.contains('permission')) {
        toast('Photo access denied. Enable it in Settings.');
      } else if (code == 'channel-error') {
        toast('Gallery unavailable. Fully restart the app and try again.');
      } else {
        toast(e.message?.isNotEmpty == true
            ? e.message!
            : 'Could not open gallery');
      }
      return;
    } catch (_) {
      if (mounted) toast('Could not open gallery');
      return;
    }
    if (picked == null || !mounted) return;

    setState(() {
      if (kind == 'logo') {
        _uploadingLogo = true;
      } else {
        _uploadingCover = true;
      }
    });

    try {
      final url = await _api.uploadBusinessMedia(
        organizationId: _org.id,
        kind: kind,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() {
        _mediaChanged = true;
        if (kind == 'logo') {
          _logoUrl = url ?? _logoUrl;
        } else {
          _coverUrl = url ?? _coverUrl;
        }
      });
      toast(kind == 'logo' ? 'Logo updated' : 'Cover updated');
    } catch (e) {
      if (mounted) toast('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingLogo = false;
          _uploadingCover = false;
        });
      }
    }
  }

  Future<void> _pickEstablishedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _establishedAt ?? DateTime(now.year - 5),
      firstDate: DateTime(1850),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _establishedAt = picked);
    }
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> _typeProfilePayload() {
    final payload = <String, dynamic>{};
    for (final spec in _typeFields) {
      final raw = _typeControllers[spec.key]?.text.trim() ?? '';
      if (spec.isList) {
        payload[spec.key] = raw.isEmpty
            ? <String>[]
            : raw
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
      } else {
        payload[spec.key] = raw.isEmpty ? null : raw;
      }
    }
    if (_org.type == 'hospital') {
      payload['emergencyServices'] = _emergencyServices;
    }
    return payload;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await _api.updateBusinessProfile(
        businessId: _org.id,
        payload: {
          'name': _name.text.trim(),
          'description': _nullable(_description),
          'email': _nullable(_email),
          'phone': _nullable(_phone),
          'website': _nullable(_website),
          'address': _nullable(_address),
          'city': _nullable(_city),
          'establishedAt': _establishedAt == null
              ? null
              : _establishedAt!.toIso8601String().split('T').first,
          if (_typeFields.isNotEmpty) 'typeProfile': _typeProfilePayload(),
        },
      );
      if (!mounted) return;
      toast('Business profile updated');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        toast('$e'.replaceFirst('Exception: ', ''));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return PopScope(
      canPop: !_mediaChanged,
      onPopInvokedWithResult: (didPop, _) {
        // Logo/cover uploads apply immediately — tell the caller to refresh
        // even when the user backs out without saving the text fields.
        if (!didPop) Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: theme.textPrimary),
            onPressed: () => Navigator.pop(context, _mediaChanged),
          ),
          title: Text('Edit business page', style: theme.titleMedium),
          centerTitle: false,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildMediaEditor(theme),
              ),
              AppSectionCard(
                title: 'Basics',
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    OneUIFormField(
                      controller: _name,
                      label: 'Business name',
                      hintText: 'Enter business name',
                      required: true,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Business name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    OneUIFormField(
                      controller: _description,
                      label: 'Description',
                      hintText: 'Tell people about this business…',
                      maxLines: 4,
                      minLines: 3,
                    ),
                  ],
                ),
              ),
              AppSectionCard(
                title: 'Contact',
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    OneUIFormField(
                      controller: _email,
                      label: 'Email',
                      hintText: 'business@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    OneUIFormField(
                      controller: _phone,
                      label: 'Phone',
                      hintText: '+62 …',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    OneUIFormField(
                      controller: _website,
                      label: 'Website',
                      hintText: 'https://…',
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              AppSectionCard(
                title: 'Location & details',
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    OneUIFormField(
                      controller: _address,
                      label: 'Address',
                      hintText: 'Street address',
                    ),
                    const SizedBox(height: 14),
                    OneUIFormField(
                      controller: _city,
                      label: 'City',
                      hintText: 'City',
                    ),
                    const SizedBox(height: 14),
                    _buildEstablishedPicker(theme),
                  ],
                ),
              ),
              if (_typeFields.isNotEmpty)
                AppSectionCard(
                  title: '${_org.typeLabel} details',
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      for (var i = 0; i < _typeFields.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        OneUIFormField(
                          controller: _typeControllers[_typeFields[i].key]!,
                          label: _typeFields[i].label,
                          hintText: _typeFields[i].isList
                              ? 'Comma-separated values'
                              : _typeFields[i].label,
                          keyboardType: _typeFields[i].keyboardType ??
                              TextInputType.text,
                        ),
                      ],
                      if (_org.type == 'hospital') ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _emergencyServices,
                          onChanged: (value) =>
                              setState(() => _emergencyServices = value),
                          title: Text(
                            'Emergency services',
                            style: theme.bodyMedium
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          activeTrackColor: theme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              AppButton(
                text: _saving ? 'Saving…' : 'Save changes',
                enabled: !_saving,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaEditor(OneUITheme theme) {
    return SizedBox(
      height: 168,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 124,
              width: double.infinity,
              decoration: BoxDecoration(gradient: theme.coverGradient),
              child: (_coverUrl ?? '').isEmpty
                  ? Center(
                      child: Text(
                        'Add a cover photo',
                        style: theme.caption.copyWith(color: theme.textTertiary),
                      ),
                    )
                  : AppCachedNetworkImage(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _mediaButton(
              theme,
              icon: Icons.photo_camera_outlined,
              label: 'Cover',
              busy: _uploadingCover,
              onTap: () => _pickAndUpload('cover'),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 0,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardBackground, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (_logoUrl ?? '').isEmpty
                      ? Icon(Icons.business_rounded,
                          size: 34, color: theme.textTertiary)
                      : AppCachedNetworkImage(
                          imageUrl: _logoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(
                            Icons.business_rounded,
                            size: 34,
                            color: theme.textTertiary,
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploadingLogo ? null : () => _pickAndUpload('logo'),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: theme.cardBackground, width: 2),
                      ),
                      child: _uploadingLogo
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaButton(
    OneUITheme theme, {
    required IconData icon,
    required String label,
    required bool busy,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Date picker styled like [OneUIFormField] (label above + filled input).
  Widget _buildEstablishedPicker(OneUITheme theme) {
    final value = _establishedAt == null
        ? null
        : _establishedAt!.toIso8601String().split('T').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Established date',
          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickEstablishedDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select date',
              hintStyle: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: theme.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: theme.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.focusBorder, width: 1.5),
              ),
            ),
            child: Text(
              value ?? 'Select date',
              style: TextStyle(
                color: value == null
                    ? theme.textSecondary.withValues(alpha: 0.5)
                    : theme.textPrimary,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
