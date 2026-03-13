import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_certificate_share_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CmeCertificatesScreen extends StatefulWidget {
  const CmeCertificatesScreen({super.key});

  @override
  State<CmeCertificatesScreen> createState() => _CmeCertificatesScreenState();
}

class _CmeCertificatesScreenState extends State<CmeCertificatesScreen> {
  CmeCertificatesBloc get _bloc => context.read<CmeCertificatesBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(CmeLoadCertificatesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocConsumer<CmeCertificatesBloc, CmeCertificatesState>(
      listener: (context, state) {
        if (state is CmeCertificateDownloadState) {
          _launchDownload(state.downloadUrl);
        } else if (state is CmeCertificatesErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CmeCertificatesLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_bloc.certificatesList.isEmpty) {
          return _buildEmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _bloc.add(CmeLoadCertificatesEvent());
          },
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: _bloc.certificatesList.length,
            itemBuilder: (context, index) {
              return _buildCertificateCard(
                  theme, _bloc.certificatesList[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildCertificateCard(
      OneUITheme theme, CmeCertificateData cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: theme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: theme.radiusM,
          onTap: () => _showCertificateDetail(theme, cert),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Certificate icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cert.isValid
                        ? const Color(0xFF34C759).withValues(alpha: 0.1)
                        : theme.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 28,
                    color: cert.isValid
                        ? const Color(0xFF34C759)
                        : theme.textTertiary,
                  ),
                ),
                const SizedBox(width: 14),

                // Certificate info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.eventTitle ?? 'Certificate',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (cert.creditType != null)
                            CmeCreditBadge(
                              creditType: cert.creditType!,
                              creditAmount: cert.creditAmount,
                              compact: true,
                            ),
                          if (cert.creditType != null)
                            const SizedBox(width: 8),
                          Text(
                            cert.issuedDate != null
                                ? _formatDate(cert.issuedDate!)
                                : '',
                            style: theme.caption,
                          ),
                        ],
                      ),
                      if (cert.certificateNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '#${cert.certificateNumber}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: theme.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status + Download
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cert.isValid
                            ? const Color(0xFF34C759).withValues(alpha: 0.1)
                            : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cert.isValid ? 'Valid' : 'Expired',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cert.isValid
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        if (cert.id != null) {
                          _bloc.add(CmeDownloadCertificateEvent(
                              certificateId: cert.id!));
                        }
                      },
                      child: Icon(Icons.download_rounded,
                          size: 22, color: theme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCertificateDetail(OneUITheme theme, CmeCertificateData cert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.workspace_premium_rounded,
                  size: 56,
                  color: cert.isValid
                      ? const Color(0xFF34C759)
                      : theme.textTertiary),
              const SizedBox(height: 12),
              Text('CME Certificate', style: theme.titleMedium),
              const SizedBox(height: 4),
              Text(cert.eventTitle ?? '', style: theme.bodySecondary,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _detailRow(theme, 'Certificate #', cert.certificateNumber ?? 'N/A'),
              _detailRow(theme, 'Credits', cert.displayCredits),
              _detailRow(theme, 'Accreditation', cert.accreditationBody ?? 'N/A'),
              _detailRow(theme, 'Issued', cert.issuedDate != null
                  ? _formatDate(cert.issuedDate!) : 'N/A'),
              if (cert.expiryDate != null)
                _detailRow(theme, 'Expires', _formatDate(cert.expiryDate!)),
              _detailRow(theme, 'Status',
                  cert.isValid ? 'Valid' : 'Expired'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (cert.id != null) {
                          _bloc.add(CmeDownloadCertificateEvent(
                              certificateId: cert.id!));
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                theme.radiusM),
                      ),
                    ),
                  ),
                  if (cert.verificationUrl != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchDownload(cert.verificationUrl!),
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('Verify'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primary,
                          side: BorderSide(color: theme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  theme.radiusM),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (cert.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CmeCertificateShareScreen(
                              certificateId: cert.id!),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share Certificate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: theme.radiusM),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(OneUITheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.caption),
          Text(value, style: theme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                size: 48, color: Color(0xFFFF9500)),
          ),
          const SizedBox(height: 16),
          Text(
            'No certificates yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete CME events to earn certificates',
            style: theme.caption,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _launchDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
