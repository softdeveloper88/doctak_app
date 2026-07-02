import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/theme/doctak_palette.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared auth layout matching the DocTak standalone HTML composer.
/// Uses [OneUITheme] / [DoctakPalette] tokens — not hardcoded orange from the mock.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ColoredBox(
      color: theme.authBackgroundColor,
      child: DecoratedBox(
        decoration: theme.authBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: theme.authLogoDecoration,
            child: Hero(
              tag: 'app_logo',
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(eyebrow, style: theme.authEyebrowStyle),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: theme.authHeadlineStyle),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.authSubtitleStyle,
          ),
        ],
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: theme.authCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced(children, 13),
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(label, style: theme.authFieldLabelStyle),
        ),
        child,
        if (error != null && error!.isNotEmpty)
          AuthFieldError(message: error!),
      ],
    );
  }
}

/// Validation / API error shown below the input border.
class AuthFieldError extends StatelessWidget {
  const AuthFieldError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          height: 1.35,
        ),
      ),
    );
  }
}

/// Text input with errors rendered below [AuthInputShell], not inside it.
class AuthFormInput extends StatelessWidget {
  const AuthFormInput({
    super.key,
    required this.icon,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.suffix,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.belowShell,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode autovalidateMode;
  final Widget? belowShell;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return FormField<String>(
      initialValue: controller.text,
      autovalidateMode: autovalidateMode,
      validator: (_) => validator?.call(controller.text.trim()),
      builder: (field) {
        if (field.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) {
              field.didChange(controller.text);
            }
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInputShell(
              icon: icon,
              suffix: suffix,
              hasError: field.hasError,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                enableSuggestions: !obscureText,
                autocorrect: !obscureText,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textPrimary,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: TextStyle(color: theme.textTertiary, fontSize: 15),
                  contentPadding: EdgeInsets.zero,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                onChanged: (value) {
                  field.didChange(value);
                  onChanged?.call(value);
                },
              ),
            ),
            if (belowShell != null) belowShell!,
            if (field.hasError && field.errorText != null)
              AuthFieldError(message: field.errorText!),
          ],
        );
      },
    );
  }
}

/// Password strength meter — informational only, does not block signup.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (password.isEmpty) return const SizedBox.shrink();

    final level = getPasswordStrengthLevel(password);

    final Color color;
    final String label;
    final int filledSegments;

    switch (level) {
      case PasswordStrengthLevel.weak:
        color = theme.error;
        label = 'Weak password';
        filledSegments = 1;
      case PasswordStrengthLevel.medium:
        color = const Color(0xFFE8A317);
        label = 'Fair password';
        filledSegments = 2;
      case PasswordStrengthLevel.strong:
        color = theme.success;
        label = 'Strong password';
        filledSegments = 4;
      case PasswordStrengthLevel.none:
        color = theme.error;
        label = 'Weak password';
        filledSegments = 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final active = index < filledSegments;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? color : theme.border.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldRow extends StatelessWidget {
  const AuthFieldRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class AuthInputShell extends StatelessWidget {
  const AuthInputShell({
    super.key,
    required this.icon,
    required this.child,
    this.suffix,
    this.hasError = false,
  });

  static const double shellHeight = 50;

  final IconData icon;
  final Widget child;
  final Widget? suffix;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      height: shellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? theme.error.withValues(alpha: 0.75) : theme.border,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.primary),
          const SizedBox(width: 10),
          Expanded(child: child),
          if (suffix != null)
            SizedBox(
              width: 32,
              height: 32,
              child: Center(child: suffix),
            ),
        ],
      ),
    );
  }
}

class AuthRememberForgotRow extends StatelessWidget {
  const AuthRememberForgotRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.rememberLabel,
    required this.forgotLabel,
    required this.onForgot,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final String rememberLabel;
  final String forgotLabel;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 21,
          height: 21,
          child: Checkbox(
            value: rememberMe,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            activeColor: theme.primary,
            side: BorderSide(color: theme.border, width: 1.5),
            onChanged: (v) => onRememberChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rememberLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onForgot,
          child: Text(forgotLabel, style: theme.authLinkStyle),
        ),
      ],
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.message,
    required this.actionText,
    required this.onTap,
  });

  final String message;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: GestureDetector(
        onTap: onTap,
        child: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: DoctakPalette.textMuted,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            children: [
              TextSpan(text: '$message '),
              TextSpan(
                text: actionText,
                style: TextStyle(
                  color: theme.accentInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
