import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_colors.dart';
import 'package:vigia_app/core/theme/app_theme.dart';

/// WCAG 2.1 contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) / (darker.computeLuminance() + 0.05);
}

void main() {
  // Pairs the design system approves (docs/design/03-design-system.md, 3.5).
  // Text needs 4.5:1, components and graphics 3:1.
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    group('${entry.key} theme contrast', () {
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;

      final textPairs = <String, (Color, Color)>{
        'text on background': (scheme.onSurface, scheme.surface),
        'text on card': (scheme.onSurface, scheme.surfaceContainerLow),
        'secondary text on background': (scheme.onSurfaceVariant, scheme.surface),
        'secondary text on card': (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
        'primary button label': (scheme.onPrimary, scheme.primary),
        'link on background': (scheme.secondary, scheme.surface),
        'link on card': (scheme.secondary, scheme.surfaceContainerLow),
        'accent on background': (semantic.accent, scheme.surface),
        'error text on error container': (scheme.onErrorContainer, scheme.errorContainer),
        'error text on background': (scheme.error, scheme.surface),
        'success on its container': (semantic.success, semantic.successContainer),
        'info on its container': (semantic.info, semantic.infoContainer),
        'warning on its container': (semantic.warning, semantic.warningContainer),
        'snackbar text': (scheme.onInverseSurface, scheme.inverseSurface),
        'snackbar action': (scheme.inversePrimary, scheme.inverseSurface),
      };
      for (final pair in textPairs.entries) {
        test('${pair.key} is at least 4.5:1', () {
          final (fg, bg) = pair.value;
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      test('field border is at least 3:1 against the field', () {
        expect(contrast(scheme.outline, scheme.surfaceContainerLow), greaterThanOrEqualTo(3));
      });
    });
  }

  test('both themes use Material 3 and carry the semantic colors', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.light.extension<AppSemanticColors>(), isNotNull);
    expect(AppTheme.dark.extension<AppSemanticColors>(), isNotNull);
  });

  test('typography uses the brand families without a synthetic bold', () {
    final text = AppTheme.light.textTheme;
    expect(text.headlineSmall?.fontFamily, 'Fraunces');
    expect(text.bodyLarge?.fontFamily, 'IBMPlexSans');
    expect(text.bodyLarge?.fontWeight, isNull);
  });
}
