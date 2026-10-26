# VIGÍA — Civic Road Infrastructure Auditing Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State%20Management-BLoC-blueviolet)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Supabase%20%2F%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Tests](https://img.shields.io/badge/Tests-85%20Passed%20(100%25)-success)](test/)
[![License](https://img.shields.io/badge/License-Academic%20%2F%20MIT-lightgrey)]()

> **VIGÍA** is a cross-platform mobile application designed for civic oversight and participatory road audit. It empowers citizens to detect, report, and monitor potholes and deteriorating road infrastructure across Colombian urban territories, fostering government transparency and community action.

---

## Table of Contents
1. [Sprint 1 Overview & Deliverables](#sprint-1-overview--deliverables)
2. [Architecture & Design Principles](#architecture--design-principles)
3. [Key Engineering Highlights](#key-engineering-highlights)
4. [Project Structure](#project-structure)
5. [Prerequisites & Environment Setup](#prerequisites--environment-setup)
6. [How to Run the Application](#how-to-run-the-application)
7. [Sprint 1 Walkthrough](#sprint-1-walkthrough-registration-login-and-profile-summary)
8. [Running the Test Suite](#running-the-test-suite)
9. [Commit & Contribution Standards](#commit--contribution-standards)

---

## Sprint 1 Overview & Deliverables

The goal of **Sprint 1** is to establish a rock-solid, production-grade foundation adhering strictly to **Clean Architecture** and delivering basic citizen authentication:

- [x] **Citizen Registration & Minimal Onboarding:**
  - Full Name validation (enforcing at least two words, e.g., `"Juan David Quintero"`).
  - RFC-compliant Email format validation.
  - Strict Password complexity validation (minimum 6 characters, at least one uppercase letter, one lowercase letter, and one digit).
  - Closed official DANE territorial catalog covering **51 Colombian urban municipalities** (32 departmental capitals + major cities > 100k inhabitants).
  - Fast GPS-assisted nearest city detection with the **Hierarchical Calibrated Radii Algorithm**.
- [x] **Citizen Login:**
  - Secure credential validation via Supabase Auth (JWT).
  - Loads the citizen profile from `public.user_profile` (joined with `civic_rank`) right after the credentials are validated.
  - User-friendly error handling translating raw server codes into clear civic messages.
- [x] **Civic Profile Summary Dashboard:**
  - Displays authenticated citizen details: Full Name, Email, Residence City, Civic Rank (`Observador - Rank 1`), and Reputation Points (`0 pts`).
  - Prominent secure Logout button with complete navigation backstack purging (`pushNamedAndRemoveUntil`).
- [x] **100% Civic Horizontal Scope:**
  - Pure citizen peer model; no administrative roles in the mobile client. All users begin with Rank 1 (`Observador`).

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
   - Centralized named routes (`AppRoutes`), institutional Material 3 theme (`AppTheme`), safe environment variable manager (`AppEnv`), and the GetIt service locator (`injection_container.dart`) where every dependency is registered once.

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
│   │   ├── theme/app_theme.dart# Material 3 Civic Teal & Warning Amber palette
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
3. **Authentication > Providers > Email:** turn **Confirm email** off. The profile insert needs the session that `signUp` returns.

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

VIGÍA has a single kind of user (the citizen), so there is one flow to demonstrate. Start the app with `flutter run -d chrome` (or any device) with the Supabase setup above done.

1. **Splash:** the app checks for a persisted session. With none, it opens the **Login** screen. With one, it jumps straight to the profile summary (step 5).
2. **Create an account:** on the Login screen tap **Register here**.
3. **Registration form:** fill in
   - *Full Name* with at least two words (e.g. `Ana Gomez`),
   - *Email Address*,
   - *Residence City*: pick it from the list **or** tap **Detect nearest city via GPS**,
   - *Password* (6+ characters with an uppercase letter, a lowercase letter and a number; the chips turn green as each rule is met) and *Confirm Password*.
   
   Tap **Create Civic Account**. The app creates the Auth account and then the `user_profile` row, and lands on the summary.
4. **Errors you can show:** a repeated email, a one-word name, a weak password, mismatched passwords or no city selected all stop the registration with a clear message.
5. **Profile summary:** shows Full Name, Email, Residence City, Civic Rank (`Urban Observer (Rank 1)`) and Reputation Points (`0 pts`).
6. **Log out:** tap **Log Out**. The app returns to Login and the back button no longer reaches the summary.
7. **Log in:** enter the same email and password and tap **Log In**. You land on the summary again. Wrong credentials show *Invalid credentials* and stay on the form.

---

## Running the Test Suite

The codebase includes an automated test suite with **85 tests** covering all Clean Architecture layers without requiring an active network connection or emulator:

### 1. Run All Tests
```powershell
flutter test
```
*Expected Output:*
```text
00:15 +85: All tests passed!
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
