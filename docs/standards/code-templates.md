# Code templates — the professor's way, step by step

Canonical skeletons for one feature. They follow the course (lessons "Clean Architecture con BLoC", "Entendiendo BlocProvider y
BlocBuilder", "State Management Strategies", Lab 4/5/6/7, "Inyección de dependencias con GetIt") and the reference implementation
`262App4`, adapted to this repo's naming (`ui/`, `datasources/`, `repositories/`, package `vigia_app`). Imports are shown once at the
top of each block only when they teach something. Build in this order: **entity + contract → data → use case → bloc → screen → DI → tests.**

The worked example is the registration flow of Sprint 1 as the course teaches it (Lab 5): one form, **two destinations**
(Auth + a profile table), so two repositories and one use case that fixes the order.

> **This repo differs in two details — read before copying column names.** (1) The real table is `user_profile` with
> `id_user`, `id_rank`, `full_name`, `email`, `reference_city`, `last_city`, `experience_points`… (see `data model/schema.sql`);
> the names in the snippets below (`id`, `residence_city_id`) are illustrative. (2) Today the profile row is created **by the
> database trigger `handle_new_user`** from the `signUp` metadata, with a self-healing fallback in
> `AuthRemoteDataSource`, instead of the explicit second insert shown here. Keep that behaviour unless the user decides to move
> to the course's explicit two-step flow; in that case the use case owns the order and the trigger must go.

---

## 1. Domain

```dart
// features/auth/domain/entities/auth_user.dart — what Auth returns. No password: it only travels to Auth.
class AuthUser {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});
}

// features/auth/domain/entities/profile.dart — what WE store, keyed by the Auth UID.
class Profile {
  final String id;
  final String fullName;
  final int cityId;

  const Profile({required this.id, required this.fullName, required this.cityId});
}
```

```dart
// features/auth/domain/repositories/auth_repository.dart — contracts say WHAT, never HOW. One per destination.
abstract class AuthRepository {
  Future<AuthUser> signUp({required String email, required String password});
  Future<AuthUser> signIn({required String email, required String password});
  Future<void> signOut();
  AuthUser? currentUser();
}

// features/auth/domain/repositories/profile_repository.dart
abstract class ProfileRepository {
  Future<void> createProfile(Profile profile);
  Future<Profile> getProfile(String id);
}
```

```dart
// features/auth/domain/usecases/sign_up_usecase.dart
// One responsibility. Knows only contracts. THIS is where the order of the two steps and the business rules live.
class SignUpUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  SignUpUseCase(this._auth, this._profiles);

  Future<Profile> call({
    required String fullName,
    required String email,
    required String password,
    required int cityId,
  }) async {
    if (fullName.trim().split(RegExp(r'\s+')).length < 2) {
      throw Exception('Enter your first and last name');           // business rule → clear message
    }
    final user = await _auth.signUp(email: email, password: password);   // step 1: account
    final profile = Profile(id: user.id, fullName: fullName.trim(), cityId: cityId);
    await _profiles.createProfile(profile);                               // step 2: profile with the returned id
    // If step 2 can fail, decide HERE what happens to the already-created account (retry, sign out, message).
    return profile;
  }
}
```

`call(...)` lets the Bloc write `await _signUp(...)`. A read-only use case that must run two steps (login → fetch profile)
looks the same: `final user = await _auth.signIn(...); return _profiles.getProfile(user.id);`.

---

## 2. Data

```dart
// features/auth/data/datasources/auth_remote_data_source.dart — the ONLY file that knows Supabase Auth.
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthUser> signUp({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) throw Exception('Could not create the account');   // never `user!`
      return AuthUser(id: user.id, email: user.email ?? email);
    } on AuthException catch (e) {
      throw Exception(e.message);                                            // translate SDK errors
    }
  }
}
```

```dart
// features/auth/data/datasources/profile_remote_data_source.dart — column names live here and nowhere else.
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSource(this._client);

  Future<void> createProfile(Profile profile) async {
    try {
      await _client.from('user_profile').insert({
        'id': profile.id,
        'full_name': profile.fullName,
        'residence_city_id': profile.cityId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Could not save the profile: ${e.message}');
    }
  }

  Future<Profile> getProfile(String id) async {
    final row = await _client.from('user_profile').select().eq('id', id).single();
    return Profile(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      cityId: row['residence_city_id'] as int,
    );
  }
}
```

```dart
// features/auth/data/repositories/auth_repository_impl.dart — "doesn't think, only delegates".
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      _dataSource.signUp(email: email, password: password);
  // …same one-liners for signIn / signOut / currentUser
}
```

(Use `data/models/*_model.dart` with `fromJson/toJson` when the table → entity mapping grows; the entity itself stays pure.
Column names for this repo's real tables are in `data model/schema.sql` — check it before writing queries.)

---

## 3. Bloc (events, state, handler)

```dart
// features/auth/ui/bloc/register_event.dart — events say WHAT HAPPENED.
abstract class RegisterEvent {}

class RegisterSubmitted extends RegisterEvent {
  final String fullName;
  final String email;
  final String password;
  final int cityId;

  RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.cityId,
  });
}
```

```dart
// features/auth/ui/bloc/register_state.dart — Strategy A: single class + status enum + copyWith.
enum RegisterStatus { initial, loading, success, failure }

class RegisterState {
  final RegisterStatus status;
  final Profile? profile;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.profile,
    this.errorMessage,
  });

  RegisterState copyWith({RegisterStatus? status, Profile? profile, String? errorMessage}) {
    return RegisterState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

```dart
// Strategy B (login/register swap the whole screen): abstract parent + subclasses.
// Data shown in EVERY moment goes in the parent with `required super.x`; message only in the failure subclass.
abstract class ProductsState {
  final List<Product> products;
  ProductsState({required this.products});
}
class ProductsLoadingState extends ProductsState { ProductsLoadingState({required super.products}); }
class ProductsErrorState  extends ProductsState {
  final String message;
  ProductsErrorState(this.message, {required super.products});
}
// and in the Bloc: emit(ProductsLoadingState(products: state.products)) — pass state.products explicitly.
```

```dart
// features/auth/ui/bloc/register_bloc.dart
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SignUpUseCase _signUp;                       // UseCases only — never a repository or SDK

  RegisterBloc(this._signUp) : super(const RegisterState()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(RegisterSubmitted event, Emitter<RegisterState> emit) async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      final profile = await _signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        cityId: event.cityId,
      );
      emit(state.copyWith(status: RegisterStatus.success, profile: profile));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
```

Stream-based Bloc (realtime): subscribe in a handler, feed results back through a private event, cancel in `close()`:

```dart
StreamSubscription<List<Message>>? _subscription;

void _onSubscribed(SubscribeRequested e, Emitter<ChatState> emit) {
  emit(state.copyWith(status: ChatStatus.loading));
  _subscription?.cancel();
  _subscription = _watchMessages(e.conversationId).listen((m) => add(_MessagesUpdated(m)));
}

@override
Future<void> close() {
  _subscription?.cancel();
  return super.close();
}
```

---

## 4. Screen and route

```dart
// core/constants/app_routes.dart — the BlocProvider wraps the Screen, ABOVE it. Blocs come from GetIt.
register: (_) => BlocProvider(
  create: (_) => sl<RegisterBloc>(),
  child: const RegisterScreen(),
),
```

```dart
// features/auth/ui/screens/register_screen.dart
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();          // controllers live in State, never in build()
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Only trivial, knowledge-free checks here; business rules live in the UseCase.
    context.read<RegisterBloc>().add(RegisterSubmitted(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      cityId: 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: BlocListener<RegisterBloc, RegisterState>(          // side effects: once per state
          listener: (context, state) {
            if (state.status == RegisterStatus.success) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<RegisterBloc, RegisterState>(       // drawing: pure state → widgets
              builder: (context, state) => Column(
                children: [
                  // TextFields bound to the controllers …
                  if (state.status == RegisterStatus.failure) ErrorMessage(message: state.errorMessage ?? ''),
                  PrimaryButton(
                    label: 'Register',
                    isLoading: state.status == RegisterStatus.loading,   // blocks double submit
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

A Screen that loads data on open: `initState() { super.initState(); context.read<XBloc>().add(XStarted()); }` — the Screen is a
`StatefulWidget` only for that. No `setState` for anything the Bloc owns.

Component that reports upward without knowing the Bloc (lesson "Vista y BLoC: filtrar por categoría"):

```dart
class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final Function(String?) onSelected;
  const CategoryChips({super.key, required this.categories, required this.selected, required this.onSelected});
  // … ChoiceChip(selected: selected == c, onSelected: (_) => onSelected(c))
}
// used as: onSelected: (c) => context.read<ProductsBloc>().add(CategorySelected(c))
```

Page (hosted piece, no Scaffold) + host Screen that owns the tab index with `setState` and does the navigating:

```dart
class ProfilePage extends StatelessWidget {                    // ui/pages/ — root is Column, NEVER Scaffold
  final Profile profile;
  final Function() onLogout;                                    // reports up; the host Screen navigates
  const ProfilePage({super.key, required this.profile, required this.onLogout});
}
```

---

## 5. Dependency injection

```dart
// core/di/injection_container.dart
final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl()));

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));        // contract type!
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));

  sl.registerLazySingleton(() => SignUpUseCase(sl(), sl()));

  sl.registerFactory(() => RegisterBloc(sl()));                                      // Bloc = factory
}
```

`main.dart`: `WidgetsFlutterBinding.ensureInitialized(); await Supabase.initialize(...); await initDependencies(); runApp(const VigiaApp());`

---

## 6. Tests

```dart
// UseCase — pure Dart, fake repositories, no Flutter, no network.
class FakeAuthRepository implements AuthRepository { /* returns canned AuthUser, records calls */ }

test('creates the account before the profile', () async {
  final auth = FakeAuthRepository();
  final profiles = FakeProfileRepository();
  final result = await SignUpUseCase(auth, profiles)(
      fullName: 'Ana Gómez', email: 'a@b.co', password: 'Abc123', cityId: 1);
  expect(profiles.created.single.id, auth.userId);
  expect(result.fullName, 'Ana Gómez');
});

// Bloc — event in, states out (add `bloc_test` only if the user approves; otherwise collect `bloc.stream`).
final states = <RegisterState>[];
final bloc = RegisterBloc(fakeSignUp)..stream.listen(states.add);
bloc.add(RegisterSubmitted(/* … */));
await Future<void>.delayed(Duration.zero);
expect(states.map((s) => s.status), [RegisterStatus.loading, RegisterStatus.success]);
```

Widget tests wrap the Screen in `BlocProvider<RegisterBloc>` with a fake use case behind it.
