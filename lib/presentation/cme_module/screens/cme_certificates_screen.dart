import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_state.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_bottom_sheet.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class CmeCertificatesScreen extends StatefulWidget {
  const CmeCertificatesScreen({super.key});

  @override
  State<CmeCertificatesScreen> createState() => _CmeCertificatesScreenState();
}

class _CmeCertificatesScreenState extends State<CmeCertificatesScreen> {
  CmeCertificatesBloc get _bloc => context.read<CmeCertificatesBloc>();
  bool _sharingPdf = false;

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
        if (state is CmeCertificateDownloadingState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Preparing PDF…'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is CmeCertificateDownloadState) {
          _sharePdfFile(state.localFilePath);
        } else if (state is CmeCertificatesErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: theme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CmeCertificatesLoadingState && _bloc.certificatesList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CmeCertificatesErrorState && _bloc.certificatesList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.errorMessage,
                    style: theme.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _bloc.add(CmeLoadCertificatesEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
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
                        ? theme.success.withValues(alpha: 0.1)
                        : theme.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 28,
                    color: cert.isValid
                        ? theme.success
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
                            ? theme.success.withValues(alpha: 0.1)
                            : theme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cert.isValid ? 'Valid' : 'Expired',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cert.isValid
                              ? theme.success
                              : theme.error,
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
    if (cert.id == null) return;
    showCmeCertificateBottomSheet(
      context,
      certificateId: cert.id!,
      onDownload: (id) async {
        _bloc.add(CmeDownloadCertificateEvent(certificateId: id));
      },
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
              color: theme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.workspace_premium_outlined,
                size: 48, color: theme.warning),
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

  Future<void> _sharePdfFile(String path) async {
    if (_sharingPdf) return;
    _sharingPdf = true;
    try {
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf', name: path.split('/').last)],
        subject: 'CME Certificate',
        text: 'My CME certificate',
      );
    } finally {
      _sharingPdf = false;
    }
  }
}
