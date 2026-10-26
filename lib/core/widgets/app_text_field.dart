import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Text field of the design system: label above, 52 dp field, optional leading
/// icon and trailing widget, and an error shown with an icon and the thick
/// error border (never color alone).
///
/// It is a [FormField], so `Form.validate()` runs its [validator].
class AppTextField extends FormField<String> {
  AppTextField({
    super.key,
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
    bool obscureText = false,
    super.enabled,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    super.validator,
    ValueChanged<String>? onFieldSubmitted,
  }) : super(
          initialValue: controller.text,
          builder: (state) {
            final context = state.context;
            return AppFieldLabel(
              label: label,
              child: TextField(
                controller: controller,
                enabled: enabled,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                textCapitalization: textCapitalization,
                autofillHints: autofillHints,
                onChanged: state.didChange,
                onSubmitted: onFieldSubmitted,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: fieldDecoration(
                  context,
                  hint: hint,
                  prefixIcon: prefixIcon,
                  suffix: suffix,
                  errorText: state.errorText,
                ),
              ),
            );
          },
        );
}

/// Decoration shared by every field: leading icon, trailing widget, and the
/// error as an icon plus text.
InputDecoration fieldDecoration(
  BuildContext context, {
  String? hint,
  IconData? prefixIcon,
  Widget? suffix,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: AppSizes.icon),
    suffixIcon: suffix,
    error: errorText == null ? null : _FieldError(errorText),
  );
}

/// Label above a field, for widgets that build their own field.
class AppFieldLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const AppFieldLabel({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm - 2),
        child,
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  final String message;

  const _FieldError(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 14, color: scheme.error),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
