import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';
import 'package:vigia_app/features/city_identity/data/datasources/city_pack_local_data_source.dart';
import 'package:vigia_app/features/city_identity/data/datasources/last_city_local_data_source.dart';
import 'package:vigia_app/features/city_identity/data/repositories/city_identity_repository_impl.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_city_identity_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_featured_cities_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_last_city_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/save_last_city_usecase.dart';
import 'package:vigia_app/features/city_identity/ui/bloc/city_ambience_bloc.dart';
import 'package:vigia_app/features/city_identity/ui/bloc/city_ambience_event.dart';
import 'package:vigia_app/features/city_identity/ui/widgets/city_ambience_scope.dart';

void main() {
  late CityAmbienceBloc bloc;
  late DateTime clock;

  // The bloc remembers the city on the device: without a mock it would wait forever.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScope(WidgetTester tester, {bool reduceMotion = false}) async {
    clock = DateTime(2026, 11, 25, 8);
    final repository = CityIdentityRepositoryImpl(CityPackLocalDataSource(), LastCityLocalDataSource());
    bloc = CityAmbienceBloc(
      GetCityIdentityUseCase(repository),
      GetFeaturedCitiesUseCase(repository),
      GetLastCityUseCase(repository),
      SaveLastCityUseCase(repository),
      now: () => clock,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: CityAmbienceScope(child: child!),
        ),
        home: const Scaffold(body: Text('inicio')),
      ),
    ));
    bloc.add(ActiveCityChanged(name: 'Cali', department: 'Valle del Cauca'));
    await tester.pumpAndSettle();
  }

  testWidgets('the first city draws no curtain; moving to another one does, and it leaves (7A)', (tester) async {
    await pumpScope(tester);
    expect(find.byType(FlagCurtain), findsNothing);

    bloc.add(ActiveCityChanged(name: 'Medellín', department: 'Antioquia', switched: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final curtain = tester.widget<FlagCurtain>(find.byType(FlagCurtain));
    expect(curtain.flag.map((band) => band.weight), [1, 1], reason: 'the flag of the new city');

    await tester.pumpAndSettle();
    expect(find.byType(FlagCurtain), findsNothing);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('a city without a flag draws no curtain', (tester) async {
    await pumpScope(tester);

    bloc.add(ActiveCityChanged(name: 'Pasto', department: 'Nariño', switched: true));
    await tester.pump();

    expect(find.byType(FlagCurtain), findsNothing);
  });

  testWidgets('with reduced motion there is no curtain', (tester) async {
    await pumpScope(tester, reduceMotion: true);

    bloc.add(ActiveCityChanged(name: 'Medellín', department: 'Antioquia', switched: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FlagCurtain), findsNothing);
  });

  testWidgets('coming back to the foreground reads the moment of the day again', (tester) async {
    await pumpScope(tester);
    expect(bloc.state.dayPart, DayPart.morning);
    clock = DateTime(2026, 11, 25, 20);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(bloc.state.dayPart, DayPart.night);
  });
}
