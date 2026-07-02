import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Web-parity certificate layout (`CmeCertificatePrint` / `dt-cme-cert-print`).
class CmeCertificatePrintWidget extends StatelessWidget {
  const CmeCertificatePrintWidget({
    super.key,
    required this.data,
    this.compact = false,
  });

  final CmeCertificatePrintData data;
  final bool compact;

  factory CmeCertificatePrintWidget.fromCertificate(
    CmeCertificateData cert, {
    bool compact = false,
  }) {
    return CmeCertificatePrintWidget(
      data: CmeCertificatePrintData.fromCertificate(cert),
      compact: compact,
    );
  }

  factory CmeCertificatePrintWidget.fromShareable(
    CmeShareableCertificate cert, {
    bool compact = false,
  }) {
    return CmeCertificatePrintWidget(
      data: CmeCertificatePrintData.fromShareable(cert),
      compact: compact,
    );
  }

  static const _brandBlue = Color(0xFF1D4ED8);
  static const _textPrimary = Color(0xFF111827);
  static const _textMuted = Color(0xFF4B5563);
  static const _textSubtle = Color(0xFF6B7280);
  static const _labelGrey = Color(0xFF9CA3AF);
  static const _outlineBlue = Color(0xFF93C5FD);

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.82 : 1.0;
    final framePadding = EdgeInsets.symmetric(
      horizontal: 28 * scale,
      vertical: 24 * scale,
    );
    final nameSize = compact ? 26.0 : 32.0;
    final eventSize = compact ? 18.0 : 22.0;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(8 * scale),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _brandBlue, width: 3),
            color: Colors.white,
          ),
          child: Container(
            margin: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: _outlineBlue, width: 1),
            ),
            padding: framePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOCTAK CME',
                      style: TextStyle(
                        color: _brandBlue,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${data.accreditationBody ?? 'ACCME'} ACCREDITED',
                      style: TextStyle(
                        color: _textSubtle,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                SizedBox(height: 20 * scale),
                Center(
                  child: Container(
                    height: 2,
                    width: MediaQuery.sizeOf(context).width * 0.55,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, _brandBlue, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),
                Text(
                  'CERTIFICATE OF COMPLETION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _brandBlue,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Text(
                  'This certifies that',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  data.recipientName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.15,
                  ),
                ),
                if (data.recipientSpecialty?.trim().isNotEmpty == true) ...[
                  SizedBox(height: 8 * scale),
                  Text(
                    data.recipientSpecialty!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSubtle,
                      fontSize: 13 * scale,
                    ),
                  ),
                ],
                SizedBox(height: 12 * scale),
                Text(
                  'has successfully completed the continuing medical education activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14 * scale,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 16 * scale),
                Text(
                  data.eventTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: eventSize,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 14 * scale),
                Text(
                  data.creditLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _brandBlue,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 24 * scale),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                SizedBox(height: 16 * scale),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _footerCol('ISSUED', data.issuedLabel, scale)),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: _footerCol('CERTIFICATE NO.', data.certificateNumber, scale),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: _footerCol('PROVIDER', data.providerName ?? 'DocTak CME', scale),
                    ),
                  ],
                ),
                SizedBox(height: 18 * scale),
                Text(
                  'Verify at doctak.com · ID ${data.verifyId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _labelGrey,
                    fontSize: 10 * scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerCol(String label, String value, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _labelGrey,
            fontSize: 9 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class CmeCertificatePrintData {
  const CmeCertificatePrintData({
    required this.recipientName,
    required this.eventTitle,
    required this.creditLabel,
    required this.issuedLabel,
    required this.certificateNumber,
    required this.verifyId,
    this.recipientSpecialty,
    this.accreditationBody,
    this.providerName,
  });

  final String recipientName;
  final String? recipientSpecialty;
  final String eventTitle;
  final String creditLabel;
  final String? accreditationBody;
  final String issuedLabel;
  final String certificateNumber;
  final String? providerName;
  final String verifyId;

  factory CmeCertificatePrintData.fromCertificate(CmeCertificateData cert) {
    final recipient = _resolveRecipientName(cert.recipientName);
    return CmeCertificatePrintData(
      recipientName: recipient,
      recipientSpecialty: cert.recipientSpecialty,
      eventTitle: cert.eventTitle?.trim().isNotEmpty == true
          ? cert.eventTitle!.trim()
          : 'CME Activity',
      creditLabel: _creditLabel(cert.creditAmount, cert.creditType),
      accreditationBody: cert.accreditationBody,
      issuedLabel: _formatIssued(cert.issuedDate),
      certificateNumber: cert.certificateNumber ?? cert.id ?? '—',
      providerName: cert.providerName,
      verifyId: _shortId(cert.id),
    );
  }

  factory CmeCertificatePrintData.fromShareable(CmeShareableCertificate cert) {
    final recipient = _resolveRecipientName(cert.holderName);
    return CmeCertificatePrintData(
      recipientName: recipient,
      recipientSpecialty: cert.holderSpecialty,
      eventTitle: cert.eventTitle?.trim().isNotEmpty == true
          ? cert.eventTitle!.trim()
          : 'CME Activity',
      creditLabel: _creditLabel(cert.creditAmount, cert.creditType),
      accreditationBody: cert.accreditationBody,
      issuedLabel: _formatIssued(cert.issueDate),
      certificateNumber: cert.certificateNumber ?? cert.id ?? '—',
      providerName: cert.providerName,
      verifyId: _shortId(cert.id),
    );
  }

  static String _resolveRecipientName(String? apiName) {
    final trimmed = apiName?.trim();
    if (trimmed != null &&
        trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'participant' &&
        trimmed.toLowerCase() != 'n/a') {
      return trimmed;
    }
    final local = AppData.name.trim();
    if (local.isNotEmpty) return local;
    return 'Participant';
  }

  static String _creditLabel(dynamic credits, String? creditType) {
    final amount = credits is num ? credits.toDouble() : double.tryParse('$credits');
    if (amount != null && amount > 0) {
      return '$amount ${creditType ?? 'AMA PRA Category 1 Credit™'}';
    }
    return 'Continuing Medical Education';
  }

  static String formatIssuedDate(String? iso) => _formatIssued(iso);

  static String _formatIssued(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt.toLocal());
  }

  static String _shortId(String? id) {
    final raw = (id ?? '').trim();
    if (raw.isEmpty) return '—';
    final slice = raw.length >= 8 ? raw.substring(0, 8) : raw;
    return slice.toUpperCase();
  }
}
