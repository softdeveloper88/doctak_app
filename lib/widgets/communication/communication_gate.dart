import 'package:doctak_app/data/apiClient/services/communication_service.dart';
import 'package:doctak_app/widgets/communication/communication_restriction_sheet.dart';
import 'package:flutter/material.dart';

/// A helper that gates chat / call actions behind a communication permission check.
///
/// Usage:
/// ```dart
/// CommunicationGate.guardMessage(
///   context: context,
///   targetUserId: userId,
///   targetUserName: userName,
///   onAllowed: () => openChat(),
/// );
/// ```
class CommunicationGate {
  static final _service = CommunicationService();

  /// Guard a **message / chat** action.
  static Future<void> guardMessage({
    required BuildContext context,
    required String targetUserId,
    required String targetUserName,
    required VoidCallback onAllowed,
    VoidCallback? onRestrictionAction,
  }) async {
    final permission = await _service.checkPermission(targetUserId);
    if (!context.mounted) return;

    if (permission.canMessage) {
      onAllowed();
    } else {
      CommunicationRestrictionSheet.show(
        context: context,
        permission: permission,
        targetUserName: targetUserName,
        targetUserId: targetUserId,
        onActionDone: onRestrictionAction,
      );
    }
  }

  /// Guard an **audio / video call** action.
  static Future<void> guardCall({
    required BuildContext context,
    required String targetUserId,
    required String targetUserName,
    required VoidCallback onAllowed,
    VoidCallback? onRestrictionAction,
  }) async {
    final permission = await _service.checkPermission(targetUserId);
    if (!context.mounted) return;

    if (permission.canCall) {
      onAllowed();
    } else {
      CommunicationRestrictionSheet.show(
        context: context,
        permission: permission,
        targetUserName: targetUserName,
        targetUserId: targetUserId,
        onActionDone: onRestrictionAction,
      );
    }
  }

  /// Check permission without UI — returns the model.
  static Future<CommunicationPermission> check(String targetUserId) {
    return _service.checkPermission(targetUserId);
  }
}
