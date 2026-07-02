import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/services/verification_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = VerificationApiService();

  final _fullNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  File? _docId;
  File? _docLicense;
  File? _docAdditional;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isVerified = false;
  bool _hasPending = false;
  VerificationRequestInfo? _latestRequest;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _api.getStatus();
      if (!mounted) return;
      setState(() {
        _isVerified = status.isVerified;
        _hasPending = status.hasPending;
        _latestRequest = status.latestRequest;
        _isLoading = false;

        // Pre-fill form if no pending
        if (!_hasPending && !_isVerified) {
          _fullNameCtrl.text = _latestRequest?.fullName ?? AppData.name.trim();
          _specialtyCtrl.text = _latestRequest?.specialty ?? AppData.specialty;
          _licenseCtrl.text = _latestRequest?.licenseNumber ?? '';
          _countryCtrl.text = _latestRequest?.country ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final file = File(path);
    const maxBytes = 8 * 1024 * 1024;
    if (await file.length() > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents must be 8MB or smaller.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      switch (type) {
        case 'id':
          _docId = file;
          break;
        case 'license':
          _docLicense = file;
          break;
        case 'additional':
          _docAdditional = file;
          break;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _api.submit(
        fullName: _fullNameCtrl.text.trim(),
        professionalTitle: _titleCtrl.text.trim().isEmpty
            ? null
            : _titleCtrl.text.trim(),
        specialty: _specialtyCtrl.text.trim().isEmpty
            ? null
            : _specialtyCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim().isEmpty
            ? null
            : _licenseCtrl.text.trim(),
        institution: _institutionCtrl.text.trim().isEmpty
            ? null
            : _institutionCtrl.text.trim(),
        country: _countryCtrl.text.trim().isEmpty
            ? null
            : _countryCtrl.text.trim(),
        reason: _reasonCtrl.text.trim().isEmpty
            ? null
            : _reasonCtrl.text.trim(),
        documentId: _docId,
        documentLicense: _docLicense,
        documentAdditional: _docAdditional,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _titleCtrl.dispose();
    _specialtyCtrl.dispose();
    _licenseCtrl.dispose();
    _institutionCtrl.dispose();
    _countryCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Apply for Verification',
        titleIcon: Icons.verified_rounded,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isVerified
          ? _buildVerifiedState(theme)
          : _hasPending
          ? _buildPendingState(theme)
          : _buildForm(theme),
    );
  }

  Widget _buildVerifiedState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1DA1F2).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 48,
                color: Color(0xFF1DA1F2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account Verified',
              style: theme.titleMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account has been verified. The verified badge is now visible on your profile.',
              textAlign: TextAlign.center,
              style: theme.bodySecondary.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Pending',
              style: theme.titleMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Your verification request has been submitted and is under review. You will be notified once it is processed.',
              textAlign: TextAlign.center,
              style: theme.bodySecondary.copyWith(fontSize: 15),
            ),
            if (_latestRequest?.status == 'rejected') ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Request Rejected',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    if (_latestRequest?.adminNotes != null &&
                        _latestRequest!.adminNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _latestRequest!.adminNotes!,
                        style: theme.bodySecondary.copyWith(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(OneUITheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What is account verification?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A verified badge confirms that your account represents a real, notable medical professional. Submit your credentials and documents for review by our team.',
                          style: theme.bodySecondary.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rejected note
            if (_latestRequest?.status == 'rejected') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous request was rejected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    if (_latestRequest?.adminNotes != null &&
                        _latestRequest!.adminNotes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _latestRequest!.adminNotes!,
                        style: theme.bodySecondary.copyWith(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Form fields
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Full Legal Name *',
                    controller: _fullNameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Professional Title',
                    hint: 'e.g., Surgeon, Researcher',
                    controller: _titleCtrl,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Specialty',
                    controller: _specialtyCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Medical License Number',
                    controller: _licenseCtrl,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Current Institution / Hospital',
                    hint: 'Where you currently practice',
                    controller: _institutionCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    theme,
                    label: 'Country',
                    controller: _countryCtrl,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildField(
              theme,
              label: 'Why should your account be verified?',
              hint:
                  'Briefly describe your professional background and why you are requesting verification...',
              controller: _reasonCtrl,
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            // Documents
            Text(
              'Supporting Documents',
              style: theme.titleMedium.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload clear photos or scans. Accepted: JPG, PNG, PDF (max 5MB each)',
              style: theme.caption,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDocTile(
                    theme,
                    icon: Icons.badge_outlined,
                    label: 'Government ID',
                    file: _docId,
                    onTap: () => _pickDocument('id'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDocTile(
                    theme,
                    icon: Icons.description_outlined,
                    label: 'Medical License',
                    file: _docLicense,
                    onTap: () => _pickDocument('license'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDocTile(
                    theme,
                    icon: Icons.file_present_outlined,
                    label: 'Additional',
                    file: _docAdditional,
                    onTap: () => _pickDocument('additional'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit Verification Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    OneUITheme theme, {
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: theme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textTertiary,
            ),
            filled: true,
            fillColor: theme.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocTile(
    OneUITheme theme, {
    required IconData icon,
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: hasFile
              ? theme.primary.withValues(alpha: 0.06)
              : theme.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? theme.primary.withValues(alpha: 0.3)
                : theme.divider,
            style: hasFile ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: CustomPaint(
          painter: hasFile ? null : _DashedBorderPainter(color: theme.divider),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFile ? Icons.check_circle_rounded : icon,
                  size: 32,
                  color: hasFile ? theme.primary : theme.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  hasFile ? 'Uploaded' : label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: hasFile ? theme.primary : theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => color != old.color;
}
