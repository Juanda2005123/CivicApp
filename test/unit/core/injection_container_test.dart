import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_cities_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/ui/cubit/auth_cubit.dart';
import 'package:vigia_app/features/auth/ui/cubit/auth_state.dart';

void main() {
  group('Dependency Injection Container Tests', () {
    test('registers and resolves all Clean Architecture dependencies', () async {
      await initDependencies();

      expect(sl.isRegistered<AuthRepository>(), isTrue);
      expect(sl.isRegistered<CityRepository>(), isTrue);
      expect(sl.isRegistered<LoginUseCase>(), isTrue);
      expect(sl.isRegistered<GetCitiesUseCase>(), isTrue);
      expect(sl.isRegistered<AuthCubit>(), isTrue);

      final authCubit = sl<AuthCubit>();
      expect(authCubit, isNotNull);
      expect(authCubit.state, isA<AuthInitial>());
    });
  });
}
