import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_print_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a CME certificate PDF locally (server `pdf_path` is often empty).
class CmeCertificatePdfService {
  static Future<File> saveCertificatePdf(CmeCertificateData cert) async {
    final remote = cert.downloadUrl;
    if (remote != null && remote.isNotEmpty && _looksLikePdfUrl(remote)) {
      try {
        return await _downloadRemotePdf(remote, cert);
      } catch (_) {
        // Fall through to generated PDF.
      }
    }

    final bytes = await buildPdfBytes(cert);
    final dir = await getTemporaryDirectory();
    final safeName = _safeFileName(cert);
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<List<int>> buildPdfBytes(CmeCertificateData cert) async {
    final printData = CmeCertificatePrintData.fromCertificate(cert);
    final recipient = printData.recipientName;
    final issued = printData.issuedLabel;
    final creditLabel = printData.creditLabel;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'DocTak CME',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.blue800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  printData.accreditationBody ?? 'ACCME Accredited',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Certificate of Completion',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This certifies that',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  recipient,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (printData.recipientSpecialty?.trim().isNotEmpty == true) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    printData.recipientSpecialty!,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Text(
                  'has successfully completed the continuing medical education activity',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  printData.eventTitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  creditLabel,
                  style: const pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _footerBlock('Issued', issued),
                    _footerBlock(
                      'Certificate no.',
                      printData.certificateNumber,
                    ),
                    _footerBlock(
                      'Provider',
                      printData.providerName ?? 'DocTak CME',
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Verify at doctak.com · ID ${printData.verifyId}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _footerBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }


  static String _safeFileName(CmeCertificateData cert) {
    final raw = cert.certificateNumber ?? cert.id ?? 'certificate';
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return 'CME_$safe.pdf';
  }

  static bool _looksLikePdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') || lower.contains('.pdf?');
  }

  static Future<File> _downloadRemotePdf(
    String url,
    CmeCertificateData cert,
  ) async {
    final resolved = url.startsWith('http')
        ? url
        : AppData.fullImageUrl(url).isNotEmpty
            ? AppData.fullImageUrl(url)
            : '${AppData.nodeApiUrl.replaceAll(RegExp(r'/$'), '')}$url';

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_safeFileName(cert)}';
    await Dio().download(
      resolved,
      path,
      options: Options(headers: buildHeaderTokens()),
    );
    return File(path);
  }
}
