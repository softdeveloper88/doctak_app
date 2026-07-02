import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Opens the certificate bottom sheet, issuing/generating first when needed.
Future<void> openEventCertificateSheet(
  BuildContext context, {
  required String eventId,
  bool generateForAllAttendees = false,
}) async {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Loading certificate…'),
      duration: Duration(seconds: 2),
    ),
  );

  try {
    String? certificateId = await CmeNodeApiService.getMyCertificateIdForEvent(eventId);

    if (certificateId == null) {
      if (generateForAllAttendees) {
        final result =
            await CmeNodeApiService.generateCertificatesForEvent(eventId);
        certificateId = result['certificateId'] as String?;
      } else {
        certificateId = await CmeNodeApiService.issueMyCertificateForEvent(eventId);
      }
    }

    if (!context.mounted) return;

    if (certificateId == null || certificateId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No certificate available yet. Complete attendance and assessment first.',
          ),
        ),
      );
      return;
    }

    messenger.hideCurrentSnackBar();
    await showCmeCertificateBottomSheet(
      context,
      certificateId: certificateId,
    );
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
