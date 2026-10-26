# Course reference map — where the professor teaches each thing

Course: **Aplicaciones Móviles** (Flutter · Dart), professor Domiciano Rincón, Universidad Icesi. The documentation site
(https://domicianorincon.github.io/FlutterApps/) is a React viewer that downloads Markdown from the repository, so it can't be
scraped — **read the repository**: `https://github.com/DomicianoRincon/FlutterApps` (lessons in `content/<file>.md`, table of
contents in `toc.md`).

Raw lesson URL pattern:
`https://raw.githubusercontent.com/DomicianoRincon/FlutterApps/refs/heads/main/content/<file>.md`

Refresh local copies (the professor keeps pushing lessons and lab changes):

```bash
git clone https://github.com/DomicianoRincon/FlutterApps   # first time (read-only reference, keep it OUTSIDE this repo)
git -C FlutterApps pull --ff-only                          # later
git -C ../262App4 pull --ff-only                           # Lab 5 reference implementation (also 262App3, Apps262Lab2)
```

Lesson files contain SVG/Mermaid/`interactive` blocks that are noise when reading as text; the code blocks and prose are the content.

## Architecture and state (read these first)

| Topic | File | What it fixes in your mind |
|---|---|---|
| Clean Architecture con BLoC | `lesson101.md` | The three rings, dependency rule, role of every piece, "who builds the dependencies" |
| Ejemplo: Buscador Deezer | `lesson102.md` | Full feature, step by step: entity → contract → use case → data source → repo impl → bloc → screen → `main.dart` |
| Introducción a Bloc | `lessonG3.md` | Events = what happened; states = what to draw; `add`/`on`/`emit`/`state`; unidirectional flow |
| State Management Strategies | `lesson103.md` | Parent state + subclasses **vs** single state + `copyWith`; what goes in the parent |
| Vista y BLoC: filtrar por categoría | `lesson104.md` | View↔Bloc communication, a component that doesn't know the Bloc, one event → two states |
| Entendiendo BlocProvider y BlocBuilder | `lesson105.md` | Provider placement, `context.read`, `initState`, `builder` rules, `buildWhen`, "could not find the correct Provider" |
| Cubit y estados / Objeto como estado | `lessonG1.md`, `lessonG2.md` | Cubit basics (stepping stone before Bloc) |
| Inyección de dependencias con GetIt | `lessonN1.md` | `sl`, `registerLazySingleton` vs `registerFactory`, register under the contract, hot restart |
| Clean Architecure (Auth) | `lessonH5.md` | Original auth layering (older folder names: `presentation/`) |
| Entendiendo el patrón en el Lab 5 | `lab5concept.md` | Review vs clean version of registration; which layer owns the order of two steps |

## Labs (the graded style)

| Lab | File | Skills |
|---|---|---|
| Lab 1 — UI Basics | `lab1.md` | Stateless components, profile screen, login/register UI |
| Lab 2 — Icesi Beats | `lab2.md`, `lab2concepts.md` | **Screen vs Page**, named routes, `pushNamedAndRemoveUntil`, returning data with `pop`, controller-in-`State` bug |
| Lab 3 — Lists, audio | `lab3.md`, `lab3concepts.md`, `lab3audio.md` | `http`, `jsonDecode`, `ListView.builder`, one shared audio player |
| Cubit lab | `labCubit.md` | Cubit with `ProductsApi`, pagination with records |
| Lab 4 — Deezer / Fake Store | `lab4.md`, `lab4store.md` | Clean + Bloc with `status`/`copyWith`; business rule (search) in the UseCase |
| Lab 5 — Registration & login | `lab5.md`, `lessonH6.md`, `lessonH15.md`, `lessonH2.md` | Two entities / two repos / `SignUpUseCase`, `BlocListener` navigation, Part 2 = login + sign-out + profile |
| Lab 6 — Wall | `lessonH8.md` (+ `lessonH3.md`, `lessonH7.md`) | Posts/likes, nested selects, pagination, upsert, UseCases that validate |
| Lab 7 — Photos | `lessonJ4.md` (+ `lessonJ0.md`, `lessonJ2clean.md`, `lessonJ1.md`, `lessonJ2.md`, `lessonJ3.md`) | Storage, buckets public/private, UUID names, picker behind a DataSource |
| Lab 7 (older) — Chat | `lessonH10.md`, `State Management/readme.md` | Conversations/messages, realtime, build order domain → UI |

## Backend services

`lessonH1.md`, `lessonH1cli.md` (project, CLI, `profiles` migration, auth config) · `lessonH2.md` (auth calls) · `lessonH3.md`
(writes) · `lessonH7.md` (reads) · `lessonI1.md`/`lessonI2.md` (realtime, streams) · `lessonI3.md` (`.or()`) · `lessonH4.md` (profile
table + RLS) · `lessonX5.md` (self-hosted) · `lessonJ*.md` (storage).

## Other course topics (not needed for Sprint 1, needed later)

Google Maps `lessonL0–L3.md` · Push notifications (FCM) `lessonK0–K4.md` (backend is mandatory for sending; never ship the service
account key in the app) · Deploy `lessonM1–M4.md` (AAB/IPA/stores) · Dart basics `lessonA*.md`/`lessonB*.md` · Widgets/layout/navigation
`lessonC*`, `lessonD*`, `lessonE*`, `lessonF*` · Course program, final project, pitch: `lessonZ1.md`, `lessonZ4.md`, `lessonZ2.md`.

## Reference code (sibling repos, if cloned)

- `../262App4` — `moviles_auth`: register flow with `domain/` + `data/` + `ui/bloc`, theme (`AppColors` + `buildTheme()`), components
  (`PrimaryButton` with `isLoading`, `ErrorMessage`, `ProfileField`), route-level `BlocProvider`, Supabase migrations. Mid-way
  between "layers create layers" and GetIt; the final target is constructor injection + GetIt.
- `../262App3` — the Lab 5 starting point (UI + Bloc, no layers). `../Apps262Lab2` — Lab 2 starter, `inventory.md` lists components.

## What the professor's style looks like in practice (quick tells)

- Folder-per-feature, `domain/ data/ ui/`; `core/` or `components/` + `theme/` for shared things.
- UseCases with `call(...)`; DataSources named for the technology (`SupabaseAuthDataSource`, `DeezerDataSource`); Impl classes end in `Impl`.
- Events as past-tense facts (`RegisterSubmitted`, `FeedStarted`, `FeedLikeToggled`); states with `Status` enums and `copyWith`.
- Screens have no `setState` for Bloc data; `BlocListener` navigates; `PrimaryButton(isLoading: …)` prevents double submit.
- Named routes in `main.dart`, `BlocProvider` per route, `Navigator` (never go_router), `Function` callbacks in components.
- Teaches by stubs and TODOs: the student writes the inside of each layer. Mirror that: when the user is *learning*, explain and let them fill in.
- AI policy in the syllabus: "Uso Colaborativo" — AI co-creates with the student's active verification and supervision.
