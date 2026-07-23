import 'package:doctak_app/core/utils/email_verification_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/widgets/show_loading_dialog.dart';
import 'package:flutter/material.dart';

Future<void> requestEmailVerificationLink({
  required BuildContext context,
  required String email,
}) async {
  showLoadingDialog(context);

  try {
    final result = await EmailVerificationService.resend(email);
    if (!context.mounted) return;

    hideLoadingDialog(context);
    _showVerificationSnackBar(context, result);
  } catch (_) {
    if (!context.mounted) return;
    hideLoadingDialog(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_something_went_wrong),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void _showVerificationSnackBar(BuildContext context, EmailVerificationResult result) {
  final l10n = translation(context);
  final String text;

  switch (result.code) {
    case EmailVerificationCode.sent:
      text = result.message.isNotEmpty
          ? result.message
          : 'Verification link sent. Open the link in your email to verify.';
      break;
    case EmailVerificationCode.alreadyVerified:
      text = result.message.isNotEmpty ? result.message : l10n.msg_user_already_verified;
      break;
    case EmailVerificationCode.notFound:
    case EmailVerificationCode.sendFailed:
    case EmailVerificationCode.rateLimited:
    case EmailVerificationCode.unknown:
      text = result.message.isNotEmpty ? result.message : l10n.msg_something_went_wrong;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 3),
    ),
  );
}
