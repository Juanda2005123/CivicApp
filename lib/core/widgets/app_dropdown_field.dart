import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_text_field.dart';

/// Dropdown of the design system, with the same look as [AppTextField]. It is
/// a [FormField], so `Form.validate()` runs its [validator].
///
/// The key follows [value], so the field adopts a value that the bloc sets
/// from outside (for example the city detected by GPS).
class AppDropdownField<T> extends FormField<T> {
  AppDropdownField({
    required String label,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    IconData? prefixIcon,
    T? value,
    super.validator,
  }) : super(
          key: ValueKey(value),
          initialValue: value,
          enabled: onChanged != null,
          builder: (state) {
            final context = state.context;
            final theme = Theme.of(context);
            return AppFieldLabel(
              label: label,
              child: InputDecorator(
                isEmpty: state.value == null,
                decoration: fieldDecoration(
                  context,
                  prefixIcon: prefixIcon,
                  errorText: state.errorText,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: state.value,
                    items: items,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: AppRadii.medium,
                    style: theme.textTheme.bodyLarge,
                    hint: Text(
                      hint,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onChanged: onChanged == null
                        ? null
                        : (next) {
                            state.didChange(next);
                            onChanged(next);
                          },
                  ),
                ),
              ),
            );
          },
        );
}
