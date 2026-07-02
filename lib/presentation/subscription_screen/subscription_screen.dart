import 'package:doctak_app/presentation/subscription_screen/subscription_content.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

/// Standalone subscription page – wraps the shared [SubscriptionContent]
/// in a Scaffold with an app bar.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Subscription',
        titleIcon: Icons.workspace_premium_rounded,
      ),
      body: const SubscriptionContent(),
    );
  }
}
