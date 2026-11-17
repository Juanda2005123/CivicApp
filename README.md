# VIGÍA — Civic Road Infrastructure Auditing Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State%20Management-BLoC-blueviolet)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Supabase%20%2F%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Tests](https://img.shields.io/badge/Tests-passing-success)](test/)
[![License](https://img.shields.io/badge/License-Academic%20%2F%20MIT-lightgrey)]()

> **VIGÍA** is a cross-platform mobile application designed for civic oversight and participatory road audit. It empowers citizens to detect, report, and monitor potholes and deteriorating road infrastructure across Colombian urban territories, fostering government transparency and community action.

---

## Table of Contents
1. [Sprint 1 Overview & Deliverables](#sprint-1-overview--deliverables)
2. [Design System](#design-system)
3. [Architecture & Design Principles](#architecture--design-principles)
4. [Key Engineering Highlights](#key-engineering-highlights)
5. [Project Structure](#project-structure)
6. [Prerequisites & Environment Setup](#prerequisites--environment-setup)
7. [How to Run the Application](#how-to-run-the-application)
8. [Sprint 1 Walkthrough](#sprint-1-walkthrough-registration-login-and-profile-summary)
9. [Sprint 2 Walkthrough](#sprint-2-walkthrough-map-community-feed-and-report-wizard)
10. [Running the Test Suite](#running-the-test-suite)
11. [Commit & Contribution Standards](#commit--contribution-standards)

---

## Cómo probar (resumen en español)

1. Copia `.env.example` a `.env` y pon `SUPABASE_URL` y `SUPABASE_ANON_KEY` (la clave publicable del proyecto).
2. En Supabase corre `data model/schema.sql`, `seeds.sql` y las migraciones de `data model/migrations/`, y apaga **Confirm email** (detalle en "Supabase Setup").
3. `flutter pub get` y `flutter run -d chrome` (o un dispositivo Android).
4. Flujo: **Regístrate** → llena el formulario → **Crear cuenta** → llegas a *Mi perfil* → **Cerrar sesión** → **Ingresar** con los mismos datos.
5. VIGÍA tiene un solo tipo de usuario (el ciudadano). Para ver que el flujo sirve para cualquier usuario, repite el registro y el login con una segunda cuenta (otro correo y otra ciudad). El detalle paso a paso está en "Sprint 1 Walkthrough".
6. **Sprint 2:** con la sesión iniciada recorre **Mapa**, **Comunidad** y **Reportar daño** (asistente de 5 pasos). También puedes entrar sin cuenta con **Explorar sin cuenta**. El paso a paso está en "Sprint 2 Walkthrough". No hay cuentas ni contraseñas precargadas: el registro es abierto, crea la tuya (por ejemplo, la contraseña `Vigia2026` cumple las reglas).

---

## Sprint 1 Overview & Deliverables

The goal of **Sprint 1** is to establish a rock-solid, production-grade foundation adhering strictly to **Clean Architecture** and delivering basic citizen authentication:

- [x] **Citizen Registration & Minimal Onboarding:**
  - Full name validation (at least two words, e.g., `"Juan David Quintero"`).
  - RFC-compliant Email format validation.
  - Strict Password complexity validation (minimum 6 characters, at least one uppercase letter, one lowercase letter, and one digit).
  - Closed official DANE territorial catalog covering **51 Colombian urban municipalities** (32 departmental capitals + major cities > 100k inhabitants).
  - Fast GPS-assisted nearest city detection with the **Hierarchical Calibrated Radii Algorithm**.
- [x] **Citizen Login:**
  - Secure credential validation via Supabase Auth (JWT).
  - Loads the citizen profile from `public.user_profile` (joined with `civic_rank`) right after the credentials are validated.
  - User-friendly error handling translating raw server codes into clear civic messages.
- [x] **Civic Profile Summary Dashboard:**
  - Displays the citizen: rank seal, full name, email, residence city, civic rank (`Nivel 1 · Observador Urbano`) and reputation points (`0 pts`).
  - Prominent secure Logout button with complete navigation backstack purging (`pushNamedAndRemoveUntil`).
- [x] **100% Civic Horizontal Scope:**
  - Pure citizen peer model; no administrative roles in the mobile client. All users begin with Rank 1 (`Observador`).

---

## Design System

The interface follows the **Sello comunitario** design system (brand, color with calculated contrast, typography, components, Spanish copy, light and dark themes). Start at [`docs/design/03-design-system.md`](docs/design/03-design-system.md); the mockups in `docs/design/mockups/` open in any browser. Every UI change must follow it (`AGENTS.md` section 6b).

---

## Architecture & Design Principles

The application strictly implements **Uncle Bob's Clean Architecture** with **Inversion of Control (IoC)**, ensuring total decoupling between business logic and framework infrastructure.

```
       ┌────────────────────────────────────────────────────────┐
       │                   Presentation Layer                   │
       │     (Screens, Widgets, Blocs with status/copyWith state) │
       └───────────────────────────┬────────────────────────────┘
                                   │ depends on
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                      Domain Layer                      │
       │     (Pure Entities, Repository Contracts, Use Cases)   │
       │         ★ ZERO external framework dependencies ★       │
       └───────────────────────────▲────────────────────────────┘
                                   │ implements contract
                                   │
       ┌───────────────────────────┴────────────────────────────┐
       │                       Data Layer                       │
       │     (Data Sources, Supabase SDK, Models/DTOs, Repos)   │
       └────────────────────────────────────────────────────────┘
```

### Layer Isolation Rules
1. **Domain Layer (`lib/features/auth/domain/`):**
   - Pure Dart code. Zero imports from `flutter/`, `supabase_flutter/`, or SQL libraries.
   - Entities (`AuthUser`, `Profile`, `City`, `Coordinates`) and the abstract contracts (`AuthRepository`, `ProfileRepository`, `CityRepository`, `LocationRepository`).
   - Single-responsibility callable Use Cases (`SignUpUseCase`, `SignInUseCase`, `SignOutUseCase`, `GetCurrentProfileUseCase`, `GetCitiesUseCase`, `DetectNearestCityUseCase`). `SignUpUseCase` fixes the order of the two registration steps: first the Auth account, then the `user_profile` row with the returned id.
   - `PasswordPolicy` and `RegistrationRules` are the single source of the form rules: the use case enforces them and the screens only reuse them for instant feedback.
2. **Data Layer (`lib/features/auth/data/`):**
   - `AuthRemoteDataSource` (Supabase Auth), `ProfileRemoteDataSource` (`user_profile`), `CityRemoteDataSource` + `CityLocalDataSource` (`coverage_city` and its offline copy), `LocationDataSource` (the only user of `geolocator`).
   - Repository implementations only delegate; SDK failures are translated into clear messages instead of being swallowed.
   - `ProfileModel` maps the `user_profile` columns to the `Profile` entity.
3. **Presentation Layer (`lib/features/*/ui/`):**
   - `flutter_bloc` Blocs with events: `RegisterBloc`, `LoginBloc`, `StartupBloc` (session check on launch) and `ProfileBloc` (summary and logout). Each state is one class with a `status` enum and `copyWith`.
   - Screens only draw the bloc state and dispatch events; navigation is a `BlocListener` reaction. Each route in `AppRoutes` wraps its screen in a `BlocProvider`.
   - Strict separation between **Ephemeral State** (form keys, text editing controllers, password visibility toggles managed in `StatefulWidget` and released in `dispose()`) and **Bloc State** (registration, session and profile).
4. **Core Layer (`lib/core/`):**
   - Centralized named routes (`AppRoutes`), the design system theme (`AppTheme.light` / `AppTheme.dark`, see `docs/design/`), safe environment variable manager (`AppEnv`), and the GetIt service locator (`injection_container.dart`) where every dependency is registered once.

The full engineering standard that guides humans and AI agents in this repository is in [`AGENTS.md`](AGENTS.md).

---

## Key Engineering Highlights

### Hierarchical Calibrated Radii Algorithm (Conurbation Conflict Resolution)
Standard nearest-neighbor Euclidean distance algorithms fail in metropolitan conurbations. For example, a citizen located in southern Cali (Bochalema, Pance, Ciudad Jardín, University campuses) is physically closer to Jamundí's town center (~9.5 km) than to downtown Cali (~13 km), causing standard GPS selectors to misclassify them as residents of Jamundí.

VIGÍA resolves this with a **Two-Tier Calibrated Hierarchy**:
1. **Tier 1 (Satellite Perimeter Check):** Checks if coordinates fall within the strictly bounded urban core of satellite cities (e.g., Jamundí: 3.0 km, Soacha: 4.8 km, Itagüí: 2.8 km, Envigado: 3.2 km, Soledad: 3.6 km).
2. **Tier 2 (Metropolitan Absorption Check):** If outside the satellite core, checks if coordinates fall within the primary capital radius (e.g., Cali: 18.0 km, Bogotá: 22.0 km, Medellín: 11.0 km).
3. **Tier 3 (General Haversine Fallback):** Euclidean geodesic proximity fallback for non-conurbanized territories.

Execution time: **< 1 ms**, with **zero bundle overhead**.

---

## Project Structure

```text
vigia_app/
├── android/                    # Native Android configuration
├── ios/                        # Native iOS configuration
├── web/                        # Flutter Web support
├── windows/                    # Windows Desktop support
├── data model/                 # Relational schema (DDL) and initial seeds
│   ├── schema.sql              # 3NF PostgreSQL database schema
│   └── seeds.sql               # Initial DANE coverage cities and ranks
├── docs/                       # Project specifications and academic docs
├── lib/
│   ├── main.dart               # .env -> Supabase.initialize -> GetIt -> runApp
│   ├── core/
│   │   ├── config/app_env.dart # Safe environment variable loader
│   │   ├── constants/app_routes.dart # Named routes, each wrapped in its BlocProvider
│   │   ├── di/injection_container.dart # GetIt registrations (the only wiring)
│   │   ├── theme/              # Design system tokens: colors, typography, spacing, AppTheme
│   │   └── widgets/            # Shared UI components
│   └── features/
│       ├── auth/
│       │   ├── domain/         # Pure business logic
│       │   │   ├── entities/   # AuthUser, Profile, City, Coordinates
│       │   │   ├── repositories/# Abstract contracts
│       │   │   ├── usecases/   # SignUp, SignIn, SignOut, GetCurrentProfile, cities, GPS
│       │   │   └── validators/ # PasswordPolicy, RegistrationRules
│       │   ├── data/           # Infrastructure & data adaptation
│       │   │   ├── datasources/# Supabase Auth/profile/cities, DANE catalog, location
│       │   │   ├── models/     # ProfileModel (user_profile <-> Profile)
│       │   │   └── repositories/# Implementations that delegate to data sources
│       │   └── ui/
│       │       ├── bloc/       # Register, Login and Startup blocs
│       │       ├── screens/    # Splash, Login, Register
│       │       └── widgets/    # PasswordStrengthChips
│       └── dashboard/
│           └── ui/             # ProfileBloc + DashboardScreen (profile summary)
├── data model/
│   └── migrations/             # SQL to run once per Supabase project
└── test/
    ├── support/                # Shared fakes and bloc test helpers
    ├── unit/                   # Domain, Data, Blocs, GetIt wiring
    ├── widget/                 # Screens over real blocs with fake repositories
    └── integration/            # Full flow through the real routes, blocs and GetIt
```

---

## Prerequisites & Environment Setup

### 1. Requirements
* [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart `^3.12.2` or higher
* A Supabase project (Auth + the schema in `data model/`), see "Supabase setup" below
* Android Studio / VS Code with Flutter extension
* Google Chrome (for rapid web preview)

### 2. Configure Environment Variables
Copy the `.env.example` file to `.env`:

```powershell
cp .env.example .env
```

Open `.env` and configure your Supabase credentials:

```ini
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-publishable-key
```

> **Security Note:** `.env` is strictly excluded from version control via `.gitignore`. Never commit API keys or production database secrets to Git. Without these two values the app shows a "Supabase is not configured" screen instead of starting.

### 3. Supabase Setup
Run once per Supabase project, in this order:
1. **SQL Editor:** run `data model/schema.sql` and then `data model/seeds.sql` (tables, ranks, DANE cities, RLS policies).
2. **SQL Editor:** run `data model/migrations/001_drop_handle_new_user.sql`. Registration is done by the app (account first, profile second), so the old `handle_new_user` trigger must not exist.
3. **SQL Editor:** run `data model/migrations/002_spanish_rank_names.sql` (only if the project was created before the Spanish interface: it renames the four civic ranks).
4. **Authentication > Sign In / Providers > User Signups:** turn **Confirm email** off. The profile insert needs the session that `signUp` returns.

---

## How to Run the Application

### 1. Install Dependencies
```powershell
flutter pub get
```

### 2. Verify Static Analysis
Ensure there are zero lint issues or type warnings:
```powershell
flutter analyze
```
To run everything at once (architecture guards, analysis and tests; works on Linux, macOS and Windows):
```powershell
dart run tool/check.dart
```

### 3. Launch Application
You can run VIGÍA across multiple platforms:

* **Chrome (Instant Web Testing):**
  ```powershell
  flutter run -d chrome
  ```
* **Android (Emulator or Physical Device):**
  ```powershell
  flutter run -d android
  ```
* **Windows Desktop:**
  ```powershell
  flutter run -d windows
  ```

---

## Sprint 1 Walkthrough: Registration, Login and Profile Summary

VIGÍA has a single kind of user (the citizen), so there is one flow to demonstrate; repeat it with a second account (different email and city) to show it works for any user. Start the app with `flutter run -d chrome` (or any device) with the Supabase setup above done.

1. **Splash:** the app checks for a persisted session. With none, it opens the **Login** screen. With one, it jumps straight to the home screen on the **Mapa** tab (the profile summary is the **Mi perfil** tab, step 5).
2. **Create an account:** on the Login screen tap **Regístrate**.
3. **Registration form:** fill in
   - *Nombre completo* with at least two words (e.g. `Ana Gomez`),
   - *Correo electrónico*,
   - *Ciudad de residencia*: pick it from the list **or** tap **Detectar mi ciudad por GPS**,
   - *Password* (6+ characters with an uppercase letter, a lowercase letter and a number; the chips turn green as each rule is met) and *Confirmar contraseña*.
   
   Tap **Crear cuenta**. The app creates the Auth account and then the `user_profile` row, and lands on the **Mapa** tab.
4. **Errors you can show:** a repeated email, a one-word name, a weak password, mismatched passwords or no city selected all stop the registration with a clear message.
5. **Profile summary:** tap **Mi perfil** in the bottom bar. It shows the rank seal, the name, an "active session" chip, reputation points, email, residence city and civic rank (`Nivel 1 · Observador Urbano`).
6. **Log out:** tap **Cerrar sesión**. The app returns to Login and the back button no longer reaches the summary.
7. **Log in:** enter the same email and password and tap **Ingresar**. You land on the **Mapa** tab again. Wrong credentials show an inline notice ("Correo o contraseña incorrectos…") and stay on the form.

---

## Sprint 2 Walkthrough: Map, Community Feed and Report Wizard

No accounts or passwords ship with the app: registration is open (see the Sprint 1 walkthrough). Use any email and a password with 6+ characters, an uppercase letter, a lowercase letter and a number (for example `Vigia2026`). Run with `flutter run -d chrome` (or a device) after the Supabase setup above, **with Confirm email turned off**.

1. **Guest mode (HU-22):** on the Login screen tap **Explorar sin cuenta**. You see **Mapa** and **Comunidad** without credentials. **Reportar daño** and **Mi perfil** invite you to sign in or register instead of running the action.
2. **Map (HU-03, HU-13, HU-14):** after signing in the map asks for the location permission. If it is granted and you are inside a coverage city, the map opens on **that city** and centers on you, even if you registered in another one. Without the permission, or outside coverage, it opens on your last city. Tap a marker (its icon shows the report type, its shape the severity) to open the report detail: code, status, photos, address, coordinates and author. **Centrar en mi ubicación** (top right) takes the map back to your position.
3. **City switcher (HU-21):** tap the city name (top left). The sheet lists your recent cities and shortcuts; type `bogota` (accents and case do not matter) and pick a result. The map and the feed show that city and your saved last city is updated.
4. **Community feed (HU-19):** the **Comunidad** tab lists the reports of the active city, newest first, 20 at a time as you scroll. Each card shows photo (or the type icon), title, neighborhood, author with rank, severity chip, votes and comments. Pull down to refresh.
5. **Report wizard (HU-06 to HU-12):** tap **Reportar daño** (Mapa or Comunidad). The title always shows the step ("Paso 2 de 5"); leaving with data asks for confirmation.
   - **Step 1, location (HU-07, HU-26, HU-27, HU-28):** with GPS the point is yours and the address is proposed. **Seleccionar ubicación** opens a map to move the pin. In *Nomenclatura vial* complete road type, main road (a number for Calle/Carrera/Diagonal/Transversal/Circular; a name is allowed for Avenida/Autopista, e.g. `Autopista Sur`), cross street and neighborhood, or use *Punto de referencia*. **Confirmar ubicación** finds the typed address on the map when you did not pick the point yourself. Points outside Colombia are refused.
   - **Step 2, type and severity (HU-08, HU-09):** pick a category and a severity (Baja, Media, Alta, Crítica: each with its own shape, color and text). **Continuar** without choosing says what is missing. If there are reports of the same type within 150 m the app says "Hay N daño(s) cercano(s)"; **Ver daños** lists them with photo, severity and distance, **Es este** supports that report and ends the flow, **Es otro daño** goes on.
   - **Step 3, photos (HU-10):** up to 3 photos in JPG, PNG or WebP of at most 5 MB (camera or gallery); other formats are refused with a message, the first photo is the main one, and the step can be skipped.
   - **Step 4, description (HU-11):** title (max. 180 characters) and description are required; dimensions are optional.
   - **Step 5, publish (HU-12):** review the summary and tap **Publicar reporte (+100 XP)**. The report gets a unique code (`#VIG-XXXX`), appears on the map and in **Comunidad**, and your **Mi perfil** shows the +100 points.
6. **Report detail (HU-14):** tap a marker or a feed card to see the photo carousel, the community validation bar (`X de 10 apoyos`), the location and the author.

To see the nearby-reports warning (step 2), publish one report first and start a second one at the same place with the same type.

Not part of this delivery (planned for Sprint 3, see `docs/06-sprint-3-backlog.md`): supporting and commenting on reports, privacy and personal data settings, avatar, search and filters, the impact dashboard and push notifications.

### Demo video recorder (optional)

`tool/demo/` has a Playwright script that drives the web build and records the video of the Sprint 2 flows. It needs Node 20+, the web build served on port 8099 and a test account in `tool/demo/.env.local` (`DEMO_EMAIL`, `DEMO_PASSWORD`, git-ignored). See the header of `tool/demo/demo.mjs` for the variables (`DEMO_LAT`, `DEMO_LON`, `HEADED`, `SKIP_WIZARD`).

```bash
flutter build web
(cd build/web && python3 -m http.server 8099) &
cd tool/demo && npm install && npx playwright install chromium
DEMO_LAT=3.4516 DEMO_LON=-76.5320 HEADED=1 node --env-file=.env.local demo.mjs   # run twice: the first publishes the report the second one detects as nearby
```

---

## Running the Test Suite

The codebase includes an automated test suite covering all Clean Architecture layers without requiring an active network connection or emulator:

### 1. Run All Tests
```powershell
flutter test
```
*Expected Output:*
```text
00:15 +N: All tests passed!
```

### 2. Run with Detailed Step-by-Step Output
```powershell
flutter test -r expanded
```

### 3. Run Specific Test Modules
* **End-to-End Civic Auth Flow:**
  ```powershell
  flutter test test/integration/auth_flow_test.dart
  ```
* **UI Widgets & Form Validations:**
  ```powershell
  flutter test test/widget/
  ```
* **Domain Use Cases Isolation:**
  ```powershell
  flutter test test/unit/domain/usecases_test.dart
  ```
* **Conurbation GPS Resolution Algorithm:**
  ```powershell
  flutter test test/unit/core/dane_cities_test.dart
  ```

---

## Commit & Contribution Standards

To maintain industry-standard software engineering practices throughout the project, **all future git commits, code identifiers, database objects, and technical documentation must be authored strictly in English**.

### Conventional Commits Format
Every commit message must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
<type>(<scope>): <short descriptive imperative summary>

[optional body describing technical rationale]
```

#### Allowed Types:
* `feat`: A new user-facing feature.
* `fix`: A bug fix.
* `refactor`: Code changes that neither fix a bug nor add a feature.
* `test`: Adding missing tests or correcting existing tests.
* `docs`: Documentation changes only.
* `style`: Code style formatting (white-space, formatting, semicolons).
* `chore`: Maintenance tasks, dependency updates, build configurations.

#### Examples:
* `feat(auth): add password complexity validator with regex rules`
* `fix(geo): correct Jamundi satellite radius threshold`
* `test(dashboard): verify logout triggers backstack purge`
* `docs(readme): document clean architecture layer isolation`

---

*Academic Project developed for Mobile Application Development — 9th Semester.*
