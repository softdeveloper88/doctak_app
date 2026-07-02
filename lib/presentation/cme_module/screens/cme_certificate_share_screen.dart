import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_state.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_certificate_pdf_service.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_print_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CmeCertificateShareScreen extends StatefulWidget {
  final String certificateId;

  const CmeCertificateShareScreen({super.key, required this.certificateId});

  @override
  State<CmeCertificateShareScreen> createState() =>
      _CmeCertificateShareScreenState();
}

class _CmeCertificateShareScreenState extends State<CmeCertificateShareScreen> {
  bool _downloadingPdf = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeCertificateShareBloc()
        ..add(CmeLoadCertificateDetailEvent(certificateId: widget.certificateId)),
      child: _CertificateShareView(
        certificateId: widget.certificateId,
        downloadingPdf: _downloadingPdf,
        onDownloadPdf: _downloadPdf,
      ),
    );
  }

  Future<void> _downloadPdf(CmeShareableCertificate cert) async {
    if (_downloadingPdf || cert.id == null) return;
    setState(() => _downloadingPdf = true);
    final theme = OneUITheme.of(context);
    try {
      final detail = await CmeNodeApiService.getCertificateDetail(cert.id!);
      final file = await CmeCertificatePdfService.saveCertificatePdf(detail);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: file.path.split('/').last)],
        subject: 'CME Certificate',
        text: 'My CME certificate',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create PDF: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }
}

class _CertificateShareView extends StatelessWidget {
  const _CertificateShareView({
    required this.certificateId,
    required this.downloadingPdf,
    required this.onDownloadPdf,
  });

  final String certificateId;
  final bool downloadingPdf;
  final Future<void> Function(CmeShareableCertificate cert) onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(title: 'Certificate'),
      body: BlocConsumer<CmeCertificateShareBloc, CmeCertificateShareState>(
        listener: (context, state) {
          if (state is CmeCertificateShareSharedState) {
            final cert = context.read<CmeCertificateShareBloc>().certificate;
            final link = cert?.shareUrl;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  link != null
                      ? 'Share link ready — copied to clipboard'
                      : 'Share link generated',
                ),
                backgroundColor: theme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
            if (link != null) {
              Clipboard.setData(ClipboardData(text: link));
            }
          }
          if (state is CmeCertificateShareErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CmeCertificateShareLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          final bloc = context.read<CmeCertificateShareBloc>();
          final cert = bloc.certificate;

          if (cert == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: theme.textTertiary),
                  const SizedBox(height: 12),
                  Text('Certificate not found', style: theme.titleMedium),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CmeCertificatePrintWidget.fromShareable(cert),
                const SizedBox(height: 16),
                _buildDetailsCard(theme, cert),
                const SizedBox(height: 16),
                _buildActionsCard(context, theme, cert),
                const SizedBox(height: 16),
                _buildVerificationCard(context, theme, cert),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(OneUITheme theme, CmeShareableCertificate cert) {
    return Container(
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: theme.titleSmall),
          const SizedBox(height: 12),
          _buildDetailRow(
              theme, 'Status', cert.isValid == true ? 'Valid' : 'Invalid',
              valueColor:
                  cert.isValid == true ? theme.success : Colors.red),
          _buildDetailRow(
              theme, 'Certificate #', cert.certificateNumber ?? 'N/A'),
          _buildDetailRow(
              theme, 'Credit Type', cert.creditType ?? 'N/A'),
          _buildDetailRow(
              theme, 'Credits', '${cert.creditAmount ?? 0}'),
          if (cert.accreditationBody != null)
            _buildDetailRow(
                theme, 'Accreditation', cert.accreditationBody!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(OneUITheme theme, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.bodySecondary),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor ?? theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
      BuildContext context, OneUITheme theme, CmeShareableCertificate cert) {
    return Container(
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions', style: theme.titleSmall),
          const SizedBox(height: 12),
          // Share link
          if (cert.shareUrl != null)
            _buildActionButton(
              theme,
              Icons.link,
              'Copy Share Link',
              () {
                Clipboard.setData(ClipboardData(text: cert.shareUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Link copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          if (cert.shareUrl != null)
            _buildActionButton(
              theme,
              Icons.ios_share,
              'Share with others',
              () async {
                await Share.share(
                  'My CME certificate: ${cert.eventTitle ?? 'CME Activity'}\n${cert.shareUrl}',
                  subject: 'CME Certificate',
                );
              },
            ),
          // Download PDF
          _buildActionButton(
            theme,
            downloadingPdf ? Icons.hourglass_top : Icons.download,
            downloadingPdf ? 'Preparing PDF…' : 'Download PDF',
            downloadingPdf ? () {} : () => onDownloadPdf(cert),
          ),
          // Refresh share link from server
          _buildActionButton(
            theme,
            Icons.share,
            cert.shareUrl == null ? 'Generate Share Link' : 'Refresh Share Link',
            () {
              final bloc = context.read<CmeCertificateShareBloc>();
              bloc.add(CmeShareCertificateEvent(
                  certificateId: cert.id ?? certificateId));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      OneUITheme theme, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
      BuildContext context, OneUITheme theme, CmeShareableCertificate cert) {
    return Container(
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: theme.success, size: 20),
              const SizedBox(width: 8),
              Text('Verification', style: theme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (cert.qrCodeUrl != null) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  cert.qrCodeUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.qr_code,
                    size: 64,
                    color: theme.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (cert.verificationUrl != null)
            Text(
              'Scan QR code or visit verification URL to verify this certificate.',
              style: theme.caption,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          if (cert.verificationUrl != null)
            OutlinedButton(
              onPressed: () async {
                final uri = Uri.tryParse(cert.verificationUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Open Verification Page'),
            ),
        ],
      ),
    );
  }
}
