import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_identity.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_ref.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_city_identity_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_featured_cities_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_last_city_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/save_last_city_usecase.dart';
import 'package:vigia_app/features/city_identity/ui/bloc/city_ambience_bloc.dart';
import 'package:vigia_app/features/city_identity/ui/bloc/city_ambience_event.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fake_city_identity_repository.dart';

void main() {
  final cali = samplePack('cali', name: 'Cali', department: 'Valle del Cauca');
  final medellin = samplePack('medellin', name: 'Medellín', department: 'Antioquia');

  late FakeCityIdentityRepository repository;
  late DateTime clock;

  setUp(() {
    repository = FakeCityIdentityRepository(fullPacks: [cali, medellin]);
    clock = DateTime(2026, 11, 25, 8);
  });

  CityAmbienceBloc buildBloc() {
    final bloc = CityAmbienceBloc(
      GetCityIdentityUseCase(repository),
      GetFeaturedCitiesUseCase(repository),
      GetLastCityUseCase(repository),
      SaveLastCityUseCase(repository),
      now: () => clock,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  test('starts with the default look, the featured cities and the moment of the day', () {
    final state = buildBloc().state;

    expect(state.identity.level, CityIdentityLevel.fallback);
    expect(state.featured, [cali, medellin]);
    expect(state.dayPart, DayPart.morning);
    expect(state.citySwitches, 0);
  });

  test('opening dresses the app for the last city it showed', () async {
    repository.lastCity = const CityRef(name: 'Cali', department: 'Valle del Cauca');

    final states = await emittedStates(buildBloc(), CityAmbienceStarted());

    expect(states.last.identity, cali);
    expect(states.last.citySwitches, 0);
  });

  test('a city that arrives first wins over the remembered one', () async {
    repository.lastCity = const CityRef(name: 'Cali');
    final bloc = buildBloc()
      ..add(ActiveCityChanged(name: 'Medellín', department: 'Antioquia'))
      ..add(CityAmbienceStarted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.identity, medellin);
  });

  test('the first city dresses the app without a curtain and is remembered', () async {
    final states = await emittedStates(
      buildBloc(),
      ActiveCityChanged(name: 'Cali', department: 'Valle del Cauca'),
    );

    expect(states.single.identity, cali);
    expect(states.single.citySwitches, 0);
    expect(repository.saved, [const CityRef(name: 'Cali', department: 'Valle del Cauca')]);
  });

  test('moving to another city counts a switch, which draws the curtain', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, ActiveCityChanged(name: 'Cali', department: 'Valle del Cauca'));

    final states = await emittedStates(
      bloc,
      ActiveCityChanged(name: 'Medellín', department: 'Antioquia', switched: true),
    );

    expect(states.single.identity, medellin);
    expect(states.single.citySwitches, 1);
    expect(states.single.arrivedBySwitch, isTrue);
  });

  test('the same city again changes nothing', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, ActiveCityChanged(name: 'Cali', department: 'Valle del Cauca'));

    final states = await emittedStates(
      bloc,
      ActiveCityChanged(name: 'Cali', department: 'Valle del Cauca', switched: true),
    );

    expect(states, isEmpty);
  });

  test('the citizen\'s own city is kept apart from the explored one', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, ReferenceCityChanged('Cali'));
    await emittedStates(bloc, ActiveCityChanged(name: 'Medellín', department: 'Antioquia'));

    expect(bloc.state.reference, cali);
    expect(bloc.state.identity, medellin);
  });

  test('coming back to the foreground reads the moment of the day again', () async {
    final bloc = buildBloc();
    clock = DateTime(2026, 11, 25, 19, 15);

    final states = await emittedStates(bloc, AppResumed());

    expect(states.single.dayPart, DayPart.night);
  });
}
