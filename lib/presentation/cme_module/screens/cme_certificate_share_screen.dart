import 'package:doctak_app/data/models/cme/cme_gamification_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificate_share_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class CmeCertificateShareScreen extends StatelessWidget {
  final String certificateId;

  const CmeCertificateShareScreen({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeCertificateShareBloc()
        ..add(CmeLoadCertificateDetailEvent(certificateId: certificateId)),
      child: const _CertificateShareView(),
    );
  }
}

class _CertificateShareView extends StatelessWidget {
  const _CertificateShareView();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('Certificate',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: BlocConsumer<CmeCertificateShareBloc, CmeCertificateShareState>(
        listener: (context, state) {
          if (state is CmeCertificateShareSharedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Share link generated'),
                backgroundColor: const Color(0xFF34C759),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
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
                _buildCertificatePreview(context, theme, cert),
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

  Widget _buildCertificatePreview(
      BuildContext context, OneUITheme theme, CmeShareableCertificate cert) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Certificate header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary,
                  theme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Certificate of Completion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (cert.accreditationBody != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    cert.accreditationBody!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Certificate content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'This certifies that',
                  style: theme.caption,
                ),
                const SizedBox(height: 8),
                Text(
                  cert.holderName ?? 'N/A',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('has successfully completed', style: theme.caption),
                const SizedBox(height: 8),
                Text(
                  cert.eventTitle ?? 'N/A',
                  style: theme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCertStat(theme, '${cert.creditAmount ?? 0}',
                        'Credits'),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.divider,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildCertStat(
                        theme,
                        cert.creditType?.toUpperCase() ?? 'CME',
                        'Type'),
                  ],
                ),
                const SizedBox(height: 12),
                // Certificate number
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Certificate #${cert.certificateNumber ?? 'N/A'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: theme.textTertiary,
                      letterSpacing: 0.5,
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

  Widget _buildCertStat(OneUITheme theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primary,
          ),
        ),
        Text(label, style: theme.caption),
      ],
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
                  cert.isValid == true ? const Color(0xFF34C759) : Colors.red),
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
          // Download PDF
          if (cert.downloadUrl != null)
            _buildActionButton(
              theme,
              Icons.download,
              'Download PDF',
              () async {
                final uri = Uri.tryParse(cert.downloadUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          // Generate share link
          _buildActionButton(
            theme,
            Icons.share,
            'Generate Share Link',
            () {
              final bloc = context.read<CmeCertificateShareBloc>();
              bloc.add(CmeShareCertificateEvent(
                  certificateId: cert.id ?? ''));
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
                side: BorderSide(color: theme.primary.withOpacity(0.3)),
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
