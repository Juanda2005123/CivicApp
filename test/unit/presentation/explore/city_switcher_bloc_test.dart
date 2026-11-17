import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/explore/domain/usecases/get_city_options_usecase.dart';
import 'package:vigia_app/features/explore/domain/usecases/search_cities_usecase.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

const _bogota = City(
  id: 1,
  name: 'Bogotá',
  department: 'Cundinamarca',
  latitude: 4.7,
  longitude: -74.07,
  isCapital: true,
);
const _pasto = City(
  id: 2,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.21,
  longitude: -77.28,
  isCapital: true,
);

void main() {
  CitySwitcherBloc buildBloc({FakeCityRepository? cities}) {
    final bloc = CitySwitcherBloc(
      GetCityOptionsUseCase(cities ?? FakeCityRepository(const [_bogota, _pasto]), FakeRecentCitiesRepository(['Pasto'])),
      SearchCitiesUseCase(),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  test('opening loads the catalog, the recents and the quick cities', () async {
    final states = await emittedStates(buildBloc(), CitySwitcherOpened());

    expect(states.map((s) => s.status), [CitySwitcherStatus.loading, CitySwitcherStatus.success]);
    expect(states.last.options!.recent, [_pasto]);
    expect(states.last.options!.quick, [_bogota]);
    expect(states.last.isSearching, isFalse);
  });

  test('typing filters the catalog ignoring accents', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, CitySwitcherOpened());

    final states = await emittedStates(bloc, CityQueryChanged('bogota'));

    expect(states.last.isSearching, isTrue);
    expect(states.last.results, [_bogota]);
  });

  test('clearing the text goes back to the shortcuts', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, CitySwitcherOpened());
    await emittedStates(bloc, CityQueryChanged('pasto'));

    final states = await emittedStates(bloc, CityQueryChanged(''));

    expect(states.last.isSearching, isFalse);
    expect(states.last.results, isEmpty);
  });

  test('an empty catalog is not an error', () async {
    final states = await emittedStates(buildBloc(cities: FakeCityRepository(const [])), CitySwitcherOpened());

    expect(states.last.status, CitySwitcherStatus.success);
    expect(states.last.options!.all, isEmpty);
  });
}
