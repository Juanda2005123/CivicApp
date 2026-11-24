import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// One option of [showChoiceSheet]: what the citizen reads and the value it means.
class ChoiceOption<T> {
  final String label;
  final T value;

  const ChoiceOption(this.label, this.value);
}

/// Bottom sheet with one choice out of a list (HU-20: category, neighborhood and
/// order). The selected option shows a check as well as a heavier weight, so the
/// state is never only a color. Tapping an option closes the sheet and reports it.
///
/// [options] is asked again every time [updates] emits: the categories and
/// neighborhoods come from reports that may still be loading when it opens.
Future<void> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceOption<T>> Function() options,
  required T Function() selected,
  required ValueChanged<T> onSelected,
  Stream<Object?>? updates,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
              ),
              Flexible(
                child: StreamBuilder<Object?>(
                  stream: updates,
                  builder: (context, _) {
                    final current = selected();
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final option in options())
                          ListTile(
                            selected: option.value == current,
                            minVerticalPadding: AppSpacing.md,
                            title: Text(
                              option.label,
                              style: option.value == current
                                  ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                                  : theme.textTheme.bodyLarge,
                            ),
                            trailing: option.value == current ? const Icon(Icons.check) : null,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onSelected(option.value);
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
