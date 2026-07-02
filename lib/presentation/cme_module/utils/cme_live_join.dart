import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:flutter/material.dart';

/// Joins a CME live session via the shared meeting module (same flow as web).
Future<bool> joinCmeLiveMeeting(
  BuildContext context, {
  required String eventId,
}) async {
  ProgressDialogUtils.showProgressDialog();
  try {
    Map<String, dynamic> result;
    try {
      result = await CmeNodeApiService.joinLiveEvent(eventId);
    } catch (_) {
      final legacy = await CmeApiService.joinEvent(eventId);
      result = Map<String, dynamic>.from(legacy as Map);
    }

    final code = result['code']?.toString() ?? '';
    if (code.isEmpty) {
      throw Exception(
        result['message']?.toString() ?? 'Could not get meeting code',
      );
    }

    if (!context.mounted) return false;
    ProgressDialogUtils.hideProgressDialog();

    await AppNavigator.push(
      context,
      ManageMeetingScreen(
        meetingCode: code,
        autoJoin: true,
        cmeEventId: eventId,
      ),
    );
    return true;
  } catch (e) {
    ProgressDialogUtils.hideProgressDialog();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}
