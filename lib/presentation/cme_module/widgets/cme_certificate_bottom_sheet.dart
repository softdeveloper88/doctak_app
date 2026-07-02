import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_certificate_share_screen.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_certificate_pdf_service.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_print_widget.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showCmeCertificateBottomSheet(
  BuildContext context, {
  required String certificateId,
  Future<void> Function(String certificateId)? onDownload,
}) {
  final theme = OneUITheme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return FutureBuilder<CmeCertificateData>(
            future: CmeNodeApiService.getCertificateDetail(certificateId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load certificate',
                    style: theme.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final detail = snapshot.data!;

              return ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textTertiary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CmeCertificatePrintWidget.fromCertificate(detail, compact: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        AppNavigator.push(
                          context,
                          CmeCertificateShareScreen(certificateId: certificateId),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            if (onDownload != null) {
                              await onDownload(certificateId);
                            } else {
                              await _defaultDownloadPdf(context, detail);
                            }
                          },
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Download PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            AppNavigator.push(
                              context,
                              CmeCertificateShareScreen(certificateId: certificateId),
                            );
                          },
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

Future<void> _defaultDownloadPdf(BuildContext context, CmeCertificateData detail) async {
  final theme = OneUITheme.of(context);
  try {
    final file = await CmeCertificatePdfService.saveCertificatePdf(detail);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: file.path.split('/').last)],
      subject: 'CME Certificate',
      text: 'My CME certificate',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create PDF: $e'), backgroundColor: theme.error),
      );
    }
  }
}
