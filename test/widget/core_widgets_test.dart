import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/core/widgets/theme_toggle_button.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/app_status_chip.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/brand_mark.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';

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

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
}
