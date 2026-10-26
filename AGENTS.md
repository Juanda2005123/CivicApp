# AGENTS.md — VIGÍA (CivicApp) engineering standards

Instructions for every AI coding agent working in this repository (Claude Code, Codex, Gemini, Cursor, Copilot…).
This is the **single source of truth** for all agents. `CLAUDE.md` and `GEMINI.md` are only pointers that import this file;
never put rules in them. Visual design rules are in §6b.

This is a university project for **Aplicaciones Móviles** (Universidad Icesi, professor Domiciano Rincón). The professor
teaches one specific way of writing Flutter apps: **Clean Architecture + Bloc + Supabase + GetIt**. The code you write
must look like code the professor would have written, because that is what gets graded.

> **Precedence.** (1) What the user asks in the current conversation. (2) This file and `docs/standards/`.
> (3) The professor's course material (see `docs/standards/course-reference.md`). (4) Generic Flutter "best practices".
> If a generic best practice contradicts the course (for example `go_router`, Riverpod, Freezed, `injectable`,
> a different folder layout), **the course wins**. Ask the user before bringing in anything the course does not teach.
> The visual design system (§6b, `docs/design/`) governs every UI change and never overrides the architecture below.
> The older rules in `.antigravity/rules/` were written for the web and are superseded by it.

---

## 1. Project context

- **App:** VIGÍA — citizens report and audit potholes and abandoned road works in Colombian cities. Flutter + Supabase.
  Business documents live in `docs/` (problem, screens/flows, business rules, decisions) and the schema in `data model/`.
- **Model:** "community" model of the final project: a **single role** (citizen), no admin role in the mobile client.
  Required core functions: publish a report, and interact with other people's reports.
- **Course requirement for the final app** (lesson "Proyecto final"): splash, login, registration, user summary
  (name, role, description, rating), publication screen, interaction/feed screen, push notifications for ≥ 2 events.
- **Package name:** `vigia_app` (use `package:vigia_app/...` imports).

### Sprint 1 (current deliverable) — basic authentication
1. Registration with minimal onboarding data. 2. Login. 3. Profile summary screen the user lands on.
Deliverables the *student* produces (do not do them unasked): commit link of the submitted version, a git tag marking
it as the first version, a ≤ 2 min screen-recorded demo of register + login **for every kind of user**, and README
instructions to navigate the flows. Never create tags, push, or open PRs unless the user explicitly asks.

---

## 2. Working agreement

- The course policy for AI is **collaborative use**: the AI co-creates under active supervision and verification by the
  student. So: work in small, reviewable steps; explain *why* a piece lives in a layer; never dump a giant opaque diff;
  keep the code simple enough that the student can defend it orally.
- Answer the user in the language they write in (Spanish by default). **Code identifiers, comments, commit messages,
  database objects and technical docs are in English** (project rule, see README "Commit & Contribution Standards").
  **User-facing UI strings are in Spanish** (decision recorded in `docs/design/03-design-system.md` §8).
- Conventional Commits: `feat|fix|refactor|test|docs|style|chore(<scope>): <imperative summary>`. Commit only when asked.
- Don't refactor unrelated code. If you spot a violation of this file outside your task, mention it (see §13) instead of
  fixing it silently.
- Never commit secrets. `.env` is git-ignored; `.env.example` documents keys. The app only ever holds the Supabase URL and
  the **publishable** key — never a `service_role` key.
- Run `flutter analyze` and `flutter test` before saying something is done, and report failures honestly.

---

## 3. Stack (allowed and expected)

`flutter_bloc` (Bloc/Cubit, `BlocProvider`, `BlocBuilder`, `BlocListener`), `supabase_flutter` (Auth, PostgREST,
Storage, Realtime), `get_it` (dependency injection), `http` (REST APIs), `image_picker`, `geolocator`,
`flutter_dotenv`, `equatable` (already in `pubspec.yaml`; optional — the course does not use it).
Navigation: **`Navigator` + named routes** (`routes` table). No `go_router`, no Riverpod/Provider/GetX, no code generation.
Anything else: ask first.

---

## 4. Architecture — Clean Architecture with Bloc

**The rule that governs everything: dependencies point inward. Outer layers know inner layers, never the reverse.**

```
 UI (Screen/Widget)  →  Bloc  →  UseCase  →  Repository (abstract contract)
                                                    ▲ implements
                                              RepositoryImpl  →  DataSource  →  SDK / HTTP / device
   ├── ui/ ───────────┴─ (application) ─┘      └─────────── domain/ ───────────┘  └──────── data/ ─────────┘
```

| Layer / piece | Folder | Knows about | Never imports |
|---|---|---|---|
| **Entity** — business object that travels through all layers | `domain/entities/` | nothing | Flutter, Supabase, `http`, Bloc |
| **Repository (abstract)** — the contract: *what* can be asked | `domain/repositories/` | entities | anything in `data/` or `ui/` |
| **UseCase** — one business action, **one responsibility** | `domain/usecases/` | repository *contracts*, entities | Flutter, SDKs, Bloc, `data/` |
| **DataSource** — the only class that talks to the SDK/HTTP/device | `data/datasources/` | SDK, entities/models | `ui/`, Bloc |
| **RepositoryImpl** — fulfils the contract by delegating to data sources | `data/repositories/` | contract, data sources | `ui/` |
| **Model/DTO** (optional) — JSON ↔ entity mapping for a table/endpoint | `data/models/` | entity | `ui/` |
| **Bloc** — receives events, calls UseCases, emits states | `ui/bloc/` | UseCases, entities | Repositories, DataSources, SDKs, widgets, `BuildContext` |
| **Screen / Page / Component** — draws states, turns touches into events | `ui/screens/`, `ui/pages/`, `ui/widgets/` | Bloc, entities | `data/`, SDKs, repositories, use cases |

Feature layout (one folder per feature under `lib/features/`, shared things under `lib/core/`):

```
lib/
├── main.dart                         # Supabase.initialize → initDependencies() → runApp
├── core/                             # config/, constants/ (AppRoutes), di/ (GetIt), theme/, widgets/ (shared components)
└── features/<feature>/
    ├── domain/   entities/ · repositories/ · usecases/
    ├── data/     datasources/ · repositories/ · models/
    └── ui/       bloc/ · screens/ · pages/ · widgets/
```

Naming follows what the repo already uses (`ui/`, plural `repositories/`, `datasources/`). The professor's newest labs
spell some folders in the singular (`domain/repository/`, `data/source/`, `data/repository/`) — equivalent; **don't rename
existing folders**, just stay consistent inside the repo. Files are `snake_case.dart`; one public class per file, except
that Bloc events/states may share the Bloc's file or live in `<name>_event.dart` / `<name>_state.dart` (prefer separate files for new code).

### Layer rules (non-negotiable)

**Domain**
- Pure Dart. A grep for `flutter`, `supabase`, `http` inside `domain/` must return nothing.
- UseCases are plain classes with a `call(...)` method (`await _signUp(...)`), receive the **abstract** repository(ies) by
  constructor, and contain the business rules: validation with a clear message, ordering of steps, filtering, combining
  repositories. Example from the course: `SignUpUseCase` creates the Auth account **first**, then the profile with the
  returned `id`; `PublishPostUseCase` trims/validates length; `SearchProductsUseCase` filters because the API can't.
- A UseCase has no interface/implementation pair — only repositories do.
- When a library type would leak into the domain (`XFile`, `ImageSource`, `Position`, `User` from Supabase), **define the
  domain's own type** with just what it needs (`PickedPhoto { bytes, extension }`) and translate it inside the DataSource.

**Data**
- Only DataSources import SDKs (`supabase_flutter`, `http`, `image_picker`, `geolocator`). They convert SDK responses into
  entities/models so nothing above ever sees a Supabase class. Column names (`full_name`) ↔ field names (`fullName`) are
  translated here and nowhere else.
- Catch SDK exceptions (`AuthException`, `PostgrestException`, `StorageException`) and rethrow `Exception('clear message')`.
  Validate nullable SDK results (`response.user == null` → throw) instead of `user!`.
- RepositoryImpl "doesn't think, it delegates": receives data sources by constructor, may orchestrate several sources
  (network + cache) but contains no business rules. Return entities, never raw `Map`s.

**Application (Bloc)** — see §5. **UI** — see §6. **DI** — see §7.

---

## 5. State management — Bloc (Cubit only for trivial local cases)

The professor teaches `Cubit` first as a stepping stone, and uses **`Bloc` with events** in every Clean Architecture lab.
New feature work uses `Bloc`.

**Mental model (lesson "Introducción a Bloc"):** the view *throws events* (what happened) and the Bloc *emits states* (what to
draw). Exactly two directions, nothing else crosses. The view never changes state; the Bloc never touches a widget.

- **Events** extend an abstract `<Feature>Event` and name *what happened*, not what to do: `RegisterSubmitted`,
  `FeedStarted`, `CategorySelected`, `LikeToggled` — never `ShowSpinner`.
- **States — pick the strategy with this question:** *does the screen keep showing this data while loading or after an error?*
  - **Single state class + `status` enum + `copyWith`** (default for new code, used in Labs 4–6): 
    `enum XStatus { initial, loading, success, failure }`, fields `status`, the data (`List<Track> tracks`,
    `Profile? profile`), `String? errorMessage`; `const` constructor with defaults for the initial state; `copyWith` only
    changes what you pass, so a refresh keeps the old list on screen and a failure doesn't wipe it. To reset a nullable
    field add an explicit flag (`removePhoto: true`) because `??` can't set `null`.
  - **Abstract parent state + subclasses** (`XInitial/XLoading/XSuccess/XFailure`, a `sealed` hierarchy is fine): good for
    one-shot flows like login/register where the screen swaps wholesale. Data the screen always shows goes in the *parent*
    with `required` constructor params (so forgetting it doesn't compile); data only meaningful in one moment
    (`message`) goes in that subclass. Pass `state.xxx` explicitly in every `emit` that must keep it.
- **Handlers:** register in the constructor with `on<Event>(_onEvent)`; handler signature
  `Future<void> _onEvent(Event event, Emitter<State> emit) async`. Typical body:
  `emit(loading)` → `try { result = await _useCase(...); emit(success) } on Exception catch (e) { emit(failure) }`.
  A handler that can run twice concurrently guards itself (`if (state.status == loading) return;`).
- The Bloc receives **UseCases** by constructor (one field per use case) and never a repository or SDK client.
- Streams (Supabase realtime): subscribe in a handler, push results back as a private internal event
  (`_MessagesUpdated`), keep the `StreamSubscription` and cancel it in `close()`.
- User-facing error text: strip the prefix (`e.toString().replaceFirst('Exception: ', '')`) or, better, throw clean messages
  from the data/domain layer.
- No `BuildContext`, `Navigator`, `SnackBar` or `Widget` inside a Bloc. Navigation is the screen's job, triggered by state.

---

## 6. UI rules

**Screen vs Page vs Component** (Lab 2, mandatory vocabulary)
- **Screen** — a full screen you *navigate to*; root is `Scaffold`; lives in `ui/screens/`; has a route.
- **Page** — a piece of UI *hosted* by a Screen (tabs of a `BottomNavigationBar`, steps of an onboarding); root is
  `Column`/`SingleChildScrollView`, **never `Scaffold`**; reports to the host through callbacks; lives in `ui/pages/`.
- **Component** — small reusable widget (`PrimaryButton`, `ErrorMessage`, `ProfileField`): usually `StatelessWidget`, receives
  data and callbacks through the constructor (`const`, `super.key`, `required this.x`), holds no business logic and does not know
  the Bloc. Shared ones go in `core/widgets/`; feature-specific ones in `ui/widgets/`.

**Providing and reading the Bloc** (lesson "Entendiendo BlocProvider y BlocBuilder")
- The `BlocProvider` goes in the **route table, wrapping the Screen**: `'/register': (_) => BlocProvider(create: (_) => sl<RegisterBloc>(), child: const RegisterScreen())`.
  A provider created inside the Screen's own `build` is *above* nothing: `context.read` in that same `build` throws
  `Could not find the correct Provider`. A Bloc needed app-wide (session) is provided once above `MaterialApp`.
- Send events with `context.read<XBloc>().add(...)` from `onPressed`/`onSubmitted`/`initState`. The first load event goes in
  `initState` (screen becomes a `StatefulWidget` only for that and for controllers) or as `..add(...)` in `create`.
- **`BlocBuilder`** draws: `builder` is a pure function *state → widgets*. Put it as low in the tree as possible; use
  `buildWhen` when only one field matters. **Never** call `add`, `Navigator`, or `showSnackBar` inside `builder`.
- **`BlocListener`** (or `BlocConsumer`) runs side effects **once per state**: navigate on `success`, show a SnackBar on
  `failure`. Use `listenWhen` if needed.
- No `setState` for anything that lives in the Bloc. `setState` is fine for ephemeral UI state (password visibility toggle,
  selected tab index in a host Screen, form keys).
- Cheap input checks that need no business knowledge (empty fields, passwords match) may stay in the Screen; **business**
  validation (email rules, ≥ 2 words in the name, length limits) belongs in a UseCase.

**Forms and controllers:** create `TextEditingController`s in the `State` (never inside `build` — it wipes the text on every
rebuild), `dispose()` them. A component that owns input must be a `StatefulWidget`.

**Navigation:** `Navigator.pushNamed`, `pushReplacementNamed`, and `pushNamedAndRemoveUntil(ctx, route, (r) => false)` after
login/registration/logout so there is no back arrow to the previous session state. Route names are constants in
`AppRoutes`. Arguments: `ModalRoute.of(context)!.settings.arguments as T` (cast, don't use `pushNamed<T>` with a route table).
After any `await` that uses `context`, check `mounted`.

**Theme and look:** follow the design system (§6b, `docs/design/03-design-system.md`). Colors, text styles, radii, spacing and
durations come from `lib/core/theme/` (single source); no hex literals or ad-hoc `TextStyle` colors in widgets. Meet WCAG AA
contrast, support text scaling, respect reduced motion, keep tap targets ≥ 48 dp.
Use `const` constructors everywhere possible, `Expanded`/`SingleChildScrollView` to avoid overflow, `ListView.builder` for
lists, `Wrap` where a `Row` could overflow.

---

## 6b. Visual design system — VIGÍA "Sello comunitario" (mandatory)

Every UI change follows the design system in [`docs/design/03-design-system.md`](docs/design/03-design-system.md). **Read it before creating, styling or refactoring any widget**, and open the matching mockup when you need to see the result:
[`docs/design/mockups/screens.html`](docs/design/mockups/screens.html) (screens, light and dark) and [`docs/design/mockups/components.html`](docs/design/mockups/components.html) (components and states). Brand assets: [`docs/design/assets/logo/`](docs/design/assets/logo/).

Non-negotiable rules (details, values and contrast tables are in the document):

1. **Tokens only.** Colors come from `AppColors`/the `ColorScheme`, text from `AppTextStyles`/`TextTheme`, spacing/radii/durations from `AppSpacing`. **No hex literals, ad-hoc `TextStyle` colors or magic numbers in widgets.** A new value is added to the system first (and to the design document), then used.
2. **Light and dark.** Every screen and component must work in both themes through `ThemeData`; never read `Brightness` to pick a hex.
3. **Reuse before creating.** Use the shared widgets in `lib/core/widgets/` (`BrandMark`, `PrimaryButton`, `AppNotice`, `DottedSpinner`, `RankSeal`, …) and the component themes (buttons, inputs, cards, chips, snackbars, app bar). A new shared widget needs: a place in `core/widgets/`, tokens only, a widget test, and an entry in the design document's component table and `components.html`.
4. **Identity.** Flat paper surfaces with a 1 px border, no glass, no gradients, no photo backgrounds. The seal, the dotted ring and monospace data (codes, coordinates, dates, points) are the brand's signature; do not add other decorative motifs.
5. **Color is never the only signal.** Severity = shape + color + text; errors = icon + text + thick border; states always have a text label. Contrast AA at minimum (the calculated pairs in §3.5 of the document are the only approved text/background combinations; mustard and clay-500 have restrictions).
6. **Accessibility.** Touch targets ≥ 48 dp, visible focus, `Semantics` labels on icon-only controls, text that scales to 200 % without truncating, and `MediaQuery.disableAnimations` honored (no scale/rotation, fades only).
7. **Language.** The whole interface is in Spanish (tú, short direct sentences). The copy deck in §8 of the document is the reference for existing strings; new strings follow its voice. Identifiers, comments, commits and docs stay in English.
8. **Brand assets are never redrawn by hand.** The seal in code is the `BrandMark`/`RankSeal` painters, equal to `docs/design/assets/logo/*.svg`. If the logo changes, change both and the document.
9. **Keep the system documented.** Any change to tokens, components or rules updates `docs/design/03-design-system.md` (and the mockups, via `node docs/design/mockups/build.mjs`) in the same change.

Pre-flight before presenting UI: tokens only · works in light and dark · shared widgets reused · contrast pairs from the document · focus, semantics and 48 dp targets · Spanish copy in the system's voice · screenshots of the changed screens in both themes.

---

---

## 7. Dependency injection — GetIt (`lib/core/di/injection_container.dart`)

Lesson "Inyección de dependencias con GetIt". `final sl = GetIt.instance;` and one `initDependencies()` called in `main`
**after** `Supabase.initialize` and **before** `runApp`. Register from the inside out:

```dart
sl.registerLazySingleton<AuthDataSource>(() => AuthDataSource(sl<SupabaseClient>()));      // data sources
sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));                  // under the CONTRACT type
sl.registerLazySingleton(() => SignUpUseCase(sl(), sl()));                                  // use cases
sl.registerFactory(() => RegisterBloc(sl()));                                               // Blocs: new instance per screen
```

- Data sources, repositories, use cases → `registerLazySingleton`. Blocs/Cubits → `registerFactory`.
- Register the implementation **under the abstract type** (`<AuthRepository>`) so consumers can't see the Impl.
- Constructors take their collaborators as parameters (`SignUpUseCase(this._auth, this._profiles)`); they never build them
  (`final r = XImpl();` is the pre-GetIt "sin" the professor tolerated only before this lesson). `sl()` is for the DI file and
  route/`BlocProvider` `create:`, not scattered through domain classes.
- **Check:** no file in `domain/` imports anything from `data/` or `ui/`.
- Tests override registrations (`initDependencies(customAuthRepository: fake)`); mocks and offline fallbacks do **not** belong in
  production DI.
- GetIt errors: `...is not registered inside GetIt` → missing registration, registered under the Impl type, or
  `initDependencies()` not called before `runApp`. Registration lives in `main`, so use **hot restart**, not hot reload.

---

## 8. Supabase essentials (details: `docs/standards/supabase-and-data.md`)

- A user lives in **two places**: Auth (`auth.users`, credentials) and our `user_profile` table; the profile's key
  (`id_user` here) is the Auth UID. The course teaches registration as two steps owned by one UseCase: `signUp` → insert
  profile with the returned id, handling "account created but profile insert failed" in the UseCase, not in the Bloc.
  **Decision (confirmed with the professor): this project follows the course flow.** `SignUpUseCase` creates the Auth account
  and then inserts the `user_profile` row through a `ProfileRepository`. The DB trigger `handle_new_user`, the client-side
  "self-healing" `upsert` and the multi-table fallback queries were removed and are **not** part of the standard: do not bring them back (see
  §13). Working code: `lib/features/auth/domain/usecases/sign_up_usecase.dart`. Generic snippets: `docs/standards/code-templates.md`.
- `signUp` semantics: `user != null && session != null` → created and signed in; `user != null && session == null` → must
  confirm e-mail first; weak password/invalid e-mail → `AuthException`. Login: `signInWithPassword`; logout: `signOut` (always
  call it, otherwise the Supabase session survives while the app shows the login). Current user: `auth.currentUser`.
- Schema changes are **migrations** (`npx supabase migration new <name>` → SQL → `npx supabase db push`); never edit an applied
  migration — add a new one. Every table the app writes needs a `grant … to authenticated` (and RLS policies once enabled),
  otherwise `permission denied for table …`.
- Reads: `from().select()` + filters + `order` + `limit/range` (always `order` before paginating); `.single()` demands exactly
  one row (`.maybeSingle()` if it may not exist); nested `select('*, author:profiles!fk(username)')`; use **one** `.or()` per query.
- Writes: `insert`, `.insert(...).select().single()` to get the row back, `upsert(onConflict: …)`, `update/delete` always with a filter.
- Storage: save the **path** in the table, not the URL; random (UUID) file names so caches never serve a stale image; public
  bucket → fixed URL, private bucket → signed URLs; policies decide who can write.
- Realtime: `from(t).stream(primaryKey: ['id'])` or `channel().onPostgresChanges(...)`; always remove the channel / cancel the
  subscription when the stream is cancelled.

---

## 9. Dart & Flutter style

- Null safety: avoid `!` unless a line above proves non-null; prefer `?.`, `??`, early returns. Use `final` and `const`.
- `async/await` with `try/catch`; `on Exception catch (e)` in Blocs; specific SDK exceptions in data sources.
- `debugPrint`, never `print`. Doc comments `///` in English on public classes and non-obvious methods; no commented-out code.
- Factory constructors (`factory Model.fromJson`) for parsing; `(json['price'] as num).toDouble()` for numbers that can be int
  or double; guard nested JSON access.
- Cascade `..` and records `(a, b)` are fine where the course uses them. Callbacks as constructor params.
- Keep widgets small; extract a component when a build method grows or a block repeats. Don't put logic in `build`.
- Prefer `package:vigia_app/...` imports across folders; don't mass-rewrite existing relative imports.

---

## 10. Testing (the whole point of the layering)

- UseCase tests: fake repository, no Flutter. Bloc tests: give an event, assert the emitted states, with fake UseCases/repositories.
- Data tests: fake/mocked data source or client; model parsing tests.
- Widget tests: provide a `BlocProvider` with a fake Bloc/repository; never hit the network or real Supabase.
- Existing layout: `test/unit/{core,data,domain,presentation}`, `test/widget`, `test/integration`. Keep it. Add tests with every
  new UseCase/Bloc/screen. Commands: `flutter analyze`, `flutter test`, `flutter test test/unit/domain/`.

---

## 11. How to build a new feature (order matters)

The professor's order — **never UI first**:
1. **Entity** + **Repository contract** (domain) — define what the system can do.
2. **DataSource** + **RepositoryImpl** (data) — implement it against Supabase/HTTP.
3. **UseCase(s)** (domain) — the business actions and rules.
4. **Event / State / Bloc** (ui/bloc).
5. **Screen** (BlocBuilder/BlocListener) + **route** with `BlocProvider`.
6. **DI registrations** in `injection_container.dart`.
7. **Tests**, then `flutter analyze` + `flutter test`.
(When the screen already exists with stubs, as in the course labs, wire it from the Bloc inward — but the finished result has
the same shape.) Canonical code for every step: `docs/standards/code-templates.md`.

### Pre-completion checklist (run it, don't just read it)
```bash
grep -rnE "import '.*/(data|ui)/|flutter|supabase|package:http" lib/features/*/domain   # must print nothing
grep -rnE "supabase_flutter|package:http|image_picker|geolocator" lib/features/*/ui     # must print nothing
grep -rnE "UseCase|Repository|DataSource" lib/features/*/ui/screens lib/features/*/ui/pages  # screens talk to Blocs only
grep -rn "BuildContext\|Navigator\|SnackBar" lib/features/*/ui/bloc lib/features/*/ui/cubit  # must print nothing
grep -rnE "\bprint\(" lib                                                                  # must print nothing
```
- [ ] Layers respected (table in §4) and the file lives in the right folder.
- [ ] Bloc: events = what happened, status/`copyWith` or parent-state strategy chosen deliberately, no widgets inside.
- [ ] Screen: `BlocProvider` in the route, `BlocBuilder` pure, side effects in `BlocListener`, controllers disposed, `mounted` checked.
- [ ] New classes registered in GetIt (Blocs as factory); app works after hot **restart**.
- [ ] Errors reach the user as clear messages; no raw SDK exceptions in the UI; loading state prevents double submit.
- [ ] Tests added/updated; `flutter analyze` clean; `flutter test` green.

---

## 12. Reference material

Source of truth for *how the professor does it*: `docs/standards/course-reference.md` (topic → lesson/lab, raw URLs, and how
to refresh the local clones). Docs site: https://domicianorincon.github.io/FlutterApps/ — repo
`https://github.com/DomicianoRincon/FlutterApps` (lessons in `content/*.md`; the site itself can't be scraped, read the repo).
Reference implementations if present next to this repo: `../262App4` (Lab 5 auth with Clean Architecture, "Semana 12, clean"),
`../Apps262Lab2`, `../262App3`. When unsure how something should look, open the matching lesson before inventing a pattern.

---

## 13. Backlog and known limitations

Status after the `feature/auth-course-alignment` branch (audit of Juan David's Sprint 1 code against this file).

**Resolved there** (kept here so nobody reintroduces them): the Cubit became Blocs with events; screens no longer touch use cases, `geolocator` or the DANE catalog; route arguments and Spanish aliases are gone; registration follows the course flow (`SignUpUseCase`: Auth account, then `user_profile` row; the `handle_new_user` trigger is removed by `data model/migrations/001_drop_handle_new_user.sql`); the five-step fallback chain and the empty `catch (_)` blocks are gone; `ProfileModel` uses the real columns; business rules live in `PasswordPolicy`/`RegistrationRules`/use cases; mocks left production DI; the Dart SDK constraint is `^3.12.2`.

**Resolved by the design system branch:** hex colors and magic numbers left the screens (tokens in `lib/core/theme/`), the UI is fully in Spanish, glass/photo/gradients are gone, and `.antigravity/rules` is superseded by §6b.

**Still open**
1. **Account without profile.** If `createProfile` fails after `signUp`, `SignUpUseCase` signs the user out and explains it, but the Auth account remains and the next login fails with "No encontramos tu perfil." A repair path (e.g. a "complete your profile" step) is not implemented (decided: documented limitation).
2. **City by name.** The profile stores the city **name** (`reference_city`), as `schema.sql` defines; there is no city id column. A schema change would be needed if features must join on the city.
3. **`CityRepositoryImpl`** merges the remote `coverage_city` rows with the embedded catalog to add the conurbation calibration. If the table later stores the radii, the local copy becomes only a fallback.
4. **Network errors** outside Auth/PostgREST (e.g. the HTTP client failing) reach the Bloc as raw exceptions; only `AuthRetryableFetchException` is translated.
5. **Design system pieces not built yet** because their features do not exist: severity chips and colors, report cards, map markers and the validation seal (specified in `docs/design/03-design-system.md`). Build them from the document when the feature arrives.
6. **Rank names come from the database** (`civic_rank.name`): projects created before the Spanish interface need `data model/migrations/002_spanish_rank_names.sql`.
7. The old web rules in `.antigravity/rules/` and `GEMINI.md` mentions are obsolete; the folder can be deleted once the team agrees.
