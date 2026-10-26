import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_cities_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_event.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_state.dart';

import '../../support/bloc_helpers.dart';
import '../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
  kind: CityKind.capital,
  radiusKm: 18.0,
);
const _pasto = City(
  id: 2,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.2136,
  longitude: -77.2811,
  isCapital: true,
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeLocationRepository location;
  late RegisterBloc bloc;

  RegisterBloc buildBloc() {
    final cities = FakeCityRepository(const [_cali, _pasto]);
    return RegisterBloc(
      GetCitiesUseCase(cities),
      DetectNearestCityUseCase(location, cities),
      SignUpUseCase(auth, profiles),
    );
  }

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    location = FakeLocationRepository(
      coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
    );
    bloc = buildBloc();
  });

  tearDown(() => bloc.close());

  RegisterSubmitted submit({String name = 'Ana Gomez', String password = 'Abc123'}) {
    return RegisterSubmitted(fullName: name, email: 'ana@example.com', password: password);
  }

  test('starts with the form idle and no cities', () {
    expect(bloc.state.status, RegisterStatus.initial);
    expect(bloc.state.cities, isEmpty);
    expect(bloc.state.selectedCity, isNull);
  });

  test('RegisterStarted loads the coverage cities', () async {
    final states = await emittedStates(bloc, RegisterStarted());

    expect(states.single.cities, [_cali, _pasto]);
  });

  test('CitySelected stores the choice and clears a previous GPS message', () async {
    await emittedStates(bloc, RegisterStarted());
    await emittedStates(bloc, NearestCityRequested());

    final states = await emittedStates(bloc, CitySelected(2));

    expect(states.single.selectedCity, _pasto);
    expect(states.single.gpsStatus, GpsStatus.idle);
    expect(states.single.gpsMessage, isNull);
  });

  group('NearestCityRequested', () {
    test('emits detecting and then the detected city', () async {
      await emittedStates(bloc, RegisterStarted());

      final states = await emittedStates(bloc, NearestCityRequested());

      expect(states.map((s) => s.gpsStatus), [GpsStatus.detecting, GpsStatus.success]);
      expect(states.last.selectedCity, _cali);
      expect(states.last.gpsMessage, 'Detected nearest city: Cali (Valle del Cauca)');
    });

    test('emits the location error message when the position is unavailable', () async {
      location = FakeLocationRepository(error: Exception('Permission denied.'));
      bloc = buildBloc();

      final states = await emittedStates(bloc, NearestCityRequested());

      expect(states.last.gpsStatus, GpsStatus.failure);
      expect(states.last.gpsMessage, 'Permission denied.');
      expect(states.last.selectedCity, isNull);
    });
  });

  group('RegisterSubmitted', () {
    test('without a selected city fails without calling any service', () async {
      final states = await emittedStates(bloc, submit());

      expect(states.single.status, RegisterStatus.failure);
      expect(states.single.errorMessage, 'Please select your residence city.');
      expect(auth.calls, isEmpty);
    });

    test('emits loading and then success with the created profile', () async {
      await emittedStates(bloc, RegisterStarted());
      await emittedStates(bloc, CitySelected(1));

      final states = await emittedStates(bloc, submit());

      expect(states.map((s) => s.status), [RegisterStatus.loading, RegisterStatus.success]);
      expect(states.last.profile?.fullName, 'Ana Gomez');
      expect(states.last.profile?.cityName, 'Cali');
      expect(profiles.stored.keys, ['uid-1']);
    });

    test('emits the use case message when a rule fails and clears it on retry', () async {
      await emittedStates(bloc, RegisterStarted());
      await emittedStates(bloc, CitySelected(1));

      final failed = await emittedStates(bloc, submit(password: 'abc'));
      expect(failed.last.status, RegisterStatus.failure);
      expect(failed.last.errorMessage, contains('at least 6 characters'));

      final retried = await emittedStates(bloc, submit());
      expect(retried.first.status, RegisterStatus.loading);
      expect(retried.first.errorMessage, isNull);
      expect(retried.last.status, RegisterStatus.success);
    });

    test('emits the Auth error message, for example a repeated email', () async {
      auth.signUpError = Exception('This email is already registered in VIGÍA.');
      await emittedStates(bloc, RegisterStarted());
      await emittedStates(bloc, CitySelected(1));

      final states = await emittedStates(bloc, submit());

      expect(states.last.status, RegisterStatus.failure);
      expect(states.last.errorMessage, 'This email is already registered in VIGÍA.');
    });
  });
}
