import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_spacing.dart';
import '../utils/search_text.dart';
import 'app_text_field.dart';

// Kept here so the widget and its tests keep importing it from this file.
export '../utils/search_text.dart';

/// Searchable dropdown of the design system, with the same look as
/// [AppTextField]: the user opens the list or types to filter it (accent and
/// case insensitive). It is a [FormField], so `Form.validate()` runs its
/// [validator]; typing without choosing an entry does not select anything.
///
/// The key follows [value], so the field adopts a value that the bloc sets
/// from outside (for example the city detected by GPS).
class AppDropdownField<T> extends FormField<T> {
  AppDropdownField({
    required String label,
    required String hint,
    required List<DropdownMenuEntry<T>> entries,
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
              child: DropdownMenu<T>(
                enabled: onChanged != null,
                expandedInsets: EdgeInsets.zero,
                menuHeight: AppSizes.dropdownMenuHeight,
                initialSelection: state.value,
                trailingIcon: const Icon(LucideIcons.chevronDown, size: AppSizes.icon),
                selectedTrailingIcon: const Icon(LucideIcons.chevronUp, size: AppSizes.icon),
                dropdownMenuEntries: entries,
                enableFilter: true,
                requestFocusOnTap: true,
                textStyle: theme.textTheme.bodyLarge,
                filterCallback: (entries, filter) {
                  final query = normalizeSearchText(filter.trim());
                  return entries.where((entry) => normalizeSearchText(entry.label).contains(query)).toList();
                },
                decorationBuilder: (context, controller) => fieldDecoration(
                  context,
                  hint: hint,
                  prefixIcon: prefixIcon,
                  errorText: state.errorText,
                ),
                onSelected: onChanged == null
                    ? null
                    : (next) {
                        state.didChange(next);
                        onChanged(next);
                      },
              ),
            );
          },
        );
}
