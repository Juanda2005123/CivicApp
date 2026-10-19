import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/user.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:vigia_app/features/auth/ui/cubit/auth_cubit.dart';
import 'package:vigia_app/features/auth/ui/cubit/auth_state.dart';
import 'package:vigia_app/features/dashboard/ui/screens/dashboard_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<User> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<User?> getCurrentUser() async => null;
}

Widget createDashboardTestWidget(AuthCubit cubit) {
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      routes: {
        AppRoutes.login: (context) => const Scaffold(body: Text('Login Screen Mock')),
      },
    ),
  );
}

void main() {
  late _FakeAuthRepository repository;
  late AuthCubit authCubit;

  final testCitizen = const User(
    id: 'user-777',
    email: 'juand@vigia.co',
    fullName: 'Juan David Quintero',
    residenceCityId: 1,
    cityName: 'Cali (Valle del Cauca)',
    rankId: 1,
    rankName: 'Urban Observer',
    reputationPoints: 0,
  );

  setUp(() {
    repository = _FakeAuthRepository();
    authCubit = AuthCubit(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders all citizen profile details correctly', (tester) async {
      authCubit.emit(Authenticated(testCitizen));

      await tester.pumpWidget(createDashboardTestWidget(authCubit));
      await tester.pumpAndSettle();

      expect(find.text('VIGÍA Civic Dashboard'), findsOneWidget);
      expect(find.text('Successfully logged in!'), findsOneWidget);
      expect(find.text('Civic Profile Summary'), findsOneWidget);
      expect(find.text('Juan David Quintero'), findsOneWidget);
      expect(find.text('juand@vigia.co'), findsOneWidget);
      expect(find.text('Cali (Valle del Cauca)'), findsOneWidget);
      expect(find.text('Urban Observer (Rank 1)'), findsOneWidget);
      expect(find.text('0 pts'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('tapping logout button triggers cubit logout and navigates to login', (tester) async {
      authCubit.emit(Authenticated(testCitizen));

      await tester.pumpWidget(createDashboardTestWidget(authCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalled, isTrue);
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });
  });
}
