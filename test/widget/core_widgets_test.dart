import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/core/widgets/theme_toggle_button.dart';
import 'package:vigia_app/core/widgets/app_dropdown_field.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/app_status_chip.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/brand_mark.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/location_blocked_dialog.dart';
import 'package:vigia_app/core/widgets/sign_in_required_dialog.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';
import 'package:vigia_app/core/theme/severity_colors.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget host(Widget child, {ThemeData? theme, bool reduceMotion = false}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('BrandMark and seals', () {
    testWidgets('the mark shows the wordmark, the tagline and the seal', (tester) async {
      await tester.pumpWidget(host(const BrandMark(tagline: 'Tu voz, con evidencia.')));

      expect(find.text('VIGÍA'), findsOneWidget);
      expect(find.text('Tu voz, con evidencia.'), findsOneWidget);
      expect(find.bySemanticsLabel('VIGÍA'), findsWidgets);
    });

    testWidgets('a rank seal shows its level and speaks its name', (tester) async {
      await tester.pumpWidget(host(const RankSeal(level: 3, semanticLabel: 'Nivel 3, Guardián Vial')));

      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Nivel 3, Guardián Vial'), findsOneWidget);
    });

    testWidgets('a rank outside 1 to 4 is clamped', (tester) async {
      await tester.pumpWidget(host(const RankSeal(level: 9)));

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('seals render in the dark theme', (tester) async {
      await tester.pumpWidget(host(const RankSeal(level: 1), theme: AppTheme.dark));

      expect(find.text('1'), findsOneWidget);
    });
  });

  group('PrimaryButton', () {
    testWidgets('calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PrimaryButton(label: 'Ingresar', onPressed: () => taps++)));

      await tester.tap(find.text('Ingresar'));

      expect(taps, 1);
    });

    testWidgets('while loading it shows the loading label and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PrimaryButton(
        label: 'Ingresar',
        loadingLabel: 'Ingresando…',
        isLoading: true,
        onPressed: () => taps++,
      )));

      expect(find.text('Ingresando…'), findsOneWidget);
      expect(find.byType(DottedSpinner), findsOneWidget);

      await tester.tap(find.text('Ingresando…'));

      expect(taps, 0);
    });
  });

  group('AppNotice', () {
    for (final kind in NoticeKind.values) {
      testWidgets('$kind has an icon and a text, not just a color', (tester) async {
        await tester.pumpWidget(host(AppNotice(message: 'Mensaje', kind: kind)));

        expect(find.text('Mensaje'), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      });
    }
  });

  group('AppStatusChip', () {
    testWidgets('a met rule shows a check, a pending one does not', (tester) async {
      await tester.pumpWidget(host(const Column(children: [
        AppStatusChip(label: 'Cumplida'),
        AppStatusChip(label: 'Pendiente', met: false),
      ])));

      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
      expect(find.text('Cumplida'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });
  });

  group('AppTextField', () {
    testWidgets('shows the validation error with an icon after validating', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(host(Form(
        key: formKey,
        child: AppTextField(
          label: 'Correo electrónico',
          hint: 'nombre@correo.com',
          controller: controller,
          validator: (value) => (value ?? '').isEmpty ? 'Escribe tu correo' : null,
        ),
      )));

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('nombre@correo.com'), findsOneWidget);
      expect(find.text('Escribe tu correo'), findsNothing);

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    });

    testWidgets('typing updates the form value and clears nothing by itself', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(host(Form(
        key: formKey,
        child: AppTextField(
          label: 'Correo electrónico',
          controller: controller,
          validator: (value) => (value ?? '').isEmpty ? 'Escribe tu correo' : null,
        ),
      )));

      await tester.enterText(find.byType(TextField), 'ana@correo.com');

      expect(formKey.currentState!.validate(), isTrue);
    });
  });

  group('ThemeToggleButton', () {
    testWidgets('switches the whole app between light and dark', (tester) async {
      await tester.pumpWidget(BlocProvider(
        create: (_) => ThemeCubit(),
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const Scaffold(body: Center(child: ThemeToggleButton())),
          ),
        ),
      ));
      final context = tester.element(find.byType(ThemeToggleButton));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(find.byTooltip('Cambiar a modo oscuro'), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(Theme.of(context).brightness, Brightness.dark);
      expect(find.byTooltip('Cambiar a modo claro'), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(Theme.of(context).brightness, Brightness.light);
    });
  });

  group('DottedSpinner', () {
    testWidgets('rotates normally and stops with reduced motion', (tester) async {
      await tester.pumpWidget(host(const DottedSpinner()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(host(const DottedSpinner(), reduceMotion: true));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('normalizeSearchText', () {
    test('lower-cases and strips Spanish accents', () {
      expect(normalizeSearchText('Bogotá'), 'bogota');
      expect(normalizeSearchText('NARIÑO'), 'narino');
      expect(normalizeSearchText('Cúcuta (Norte de Santander)'), 'cucuta (norte de santander)');
    });
  });

  group('showSignInRequiredDialog', () {
    Widget opener(ThemeData theme, {VoidCallback? onSignIn, VoidCallback? onRegister}) => host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSignInRequiredDialog(
                context,
                message: 'Para reportar un daño necesitas una cuenta.',
                onSignIn: onSignIn ?? () {},
                onRegister: onRegister ?? () {},
              ),
              child: const Text('Abrir'),
            ),
          ),
          theme: theme,
        );

    for (final theme in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
      testWidgets('explains why and offers to sign in or register in ${theme.key}', (tester) async {
        await tester.pumpWidget(opener(theme.value));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
        expect(find.text('Para reportar un daño necesitas una cuenta.'), findsOneWidget);
        expect(find.text('Ahora no'), findsOneWidget);
        expect(find.text('Crear cuenta'), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsOneWidget);
      });
    }

    testWidgets('each action closes the modal and calls back only its own callback', (tester) async {
      var signIns = 0;
      var registers = 0;
      await tester.pumpWidget(opener(AppTheme.light, onSignIn: () => signIns++, onRegister: () => registers++));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect((signIns, registers), (0, 0));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect((signIns, registers), (0, 1));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect((signIns, registers), (1, 1));
      expect(find.text('Necesitas iniciar sesión'), findsNothing);
    });
  });

  group('showLocationBlockedDialog', () {
    Widget opener(ThemeData theme, VoidCallback onOpenSettings) => host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showLocationBlockedDialog(
                context,
                message: 'El permiso de ubicación está bloqueado.',
                onOpenSettings: onOpenSettings,
              ),
              child: const Text('Abrir'),
            ),
          ),
          theme: theme,
        );

    for (final theme in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
      testWidgets('explains the block and offers the settings in ${theme.key}', (tester) async {
        await tester.pumpWidget(opener(theme.value, () {}));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Ubicación bloqueada'), findsOneWidget);
        expect(find.text('El permiso de ubicación está bloqueado.'), findsOneWidget);
        expect(find.text('Ahora no'), findsOneWidget);
        expect(find.text('Abrir ajustes'), findsOneWidget);
      });
    }

    testWidgets('"Abrir ajustes" closes the modal and calls back; "Ahora no" only closes', (tester) async {
      var opened = 0;
      await tester.pumpWidget(opener(AppTheme.light, () => opened++));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('Ubicación bloqueada'), findsNothing);
      expect(opened, 0);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Ubicación bloqueada'), findsNothing);
      expect(opened, 1);
    });
  });

  group('SeverityChip', () {
    testWidgets('each level shows its own text and its own shape', (tester) async {
      for (final (level, text, shape) in [
        (SeverityLevel.low, 'Baja', Icons.circle_outlined),
        (SeverityLevel.medium, 'Media', Icons.change_history_outlined),
        (SeverityLevel.high, 'Alta', Icons.diamond_outlined),
        (SeverityLevel.critical, 'Crítica', Icons.dangerous_outlined),
      ]) {
        await tester.pumpWidget(host(SeverityChip(level: level)));

        expect(find.text(text), findsOneWidget, reason: '$level text');
        expect(find.byIcon(shape), findsOneWidget, reason: '$level shape');
      }
    });

    testWidgets('the four shapes are different, so color is never the only signal', (tester) async {
      final shapes = SeverityLevel.values.map(SeverityChip.shapeOf).toSet();
      final labels = SeverityLevel.values.map(SeverityChip.labelOf).toSet();

      expect(shapes, hasLength(4));
      expect(labels, hasLength(4));
    });

    testWidgets('it paints the theme color of the level, in light and dark', (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(host(const SeverityChip(level: SeverityLevel.high), theme: theme));
        // MaterialApp animates a theme change: wait until the new one is in.
        await tester.pumpAndSettle();
        final colors = theme.extension<AppSeverityColors>()!;

        final box = tester.widget<Container>(find.descendant(of: find.byType(SeverityChip), matching: find.byType(Container)));
        final decoration = box.decoration! as BoxDecoration;
        final text = tester.widget<Text>(find.text('Alta'));

        expect(decoration.color, colors.high);
        expect(text.style?.color, colors.onHigh);
      }
    });

    testWidgets('it is 28 dp tall and keeps a readable text', (tester) async {
      await tester.pumpWidget(host(const SeverityChip(level: SeverityLevel.low)));

      expect(tester.getSize(find.byType(SeverityChip)).height, AppSizes.chip);
    });

    testWidgets('it speaks the level and grows with the text size without overflowing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(body: Center(child: SeverityChip(level: SeverityLevel.critical))),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Gravedad Crítica'), findsOneWidget);
      expect(tester.getSize(find.byType(SeverityChip)).height, greaterThan(AppSizes.chip));
    });
  });
}
