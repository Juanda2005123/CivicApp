# VIGÍA — Civic Road Infrastructure Auditing Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-blueviolet)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Supabase%20%2F%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Tests](https://img.shields.io/badge/Tests-42%20Passed%20(100%25)-success)](test/)
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
7. [Running the Test Suite](#running-the-test-suite)
8. [Commit & Contribution Standards](#commit--contribution-standards)

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
  - Resilient synchronization with `public.usuario` / PostgreSQL profile schema.
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
       │     (UI Screens, Widgets, BLoC/Cubit, Sealed States)   │
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
   - Declares the abstract `AuthRepository` interface contract.
   - Contains single-responsibility callable Use Cases (`LoginUseCase`, `RegisterUseCase`, `LogoutUseCase`, `GetCurrentUserUseCase`).
2. **Data Layer (`lib/features/auth/data/`):**
   - Implements `AuthRepository` via `AuthRepositoryImpl`.
   - `UsuarioModel` DTO maps PostgreSQL schema columns to pure Domain Entities.
   - Interacts with Supabase SDK strictly within isolated Remote Data Sources.
3. **Presentation Layer (`lib/features/auth/presentation/`):**
   - State management powered by `flutter_bloc` (`AuthCubit`).
   - Dart 3 `sealed class AuthState` hierarchy (`AuthInitial`, `AuthLoading`, `Authenticated`, `AuthUnauthenticated`, `AuthError`) guaranteeing compile-time pattern matching exhaustiveness.
   - Strict separation between **Ephemeral State** (form keys, text editing controllers, password visibility toggles managed in `StatefulWidget` and released in `dispose()`) and **Global State** (session and citizen profile managed in `AuthCubit`).
4. **Core Layer (`lib/core/`):**
   - Centralized named routes (`AppRoutes`), institutional Material 3 theme (`AppTheme`), safe environment variable manager (`AppEnv`), and DANE territorial catalog (`DaneCitiesCatalog`).

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
│   ├── main.dart               # App entrypoint & Dependency Injection wiring
│   ├── core/
│   │   ├── config/app_env.dart # Safe environment variable loader
│   │   ├── constants/
│   │   │   ├── app_routes.dart # Centralized named routes map
│   │   │   └── dane_cities.dart# 51 DANE cities + Calibrated Radii Algorithm
│   │   └── theme/app_theme.dart# Material 3 Civic Teal & Warning Amber palette
│   └── features/
│       └── auth/
│           ├── domain/         # Pure business logic
│           │   ├── entities/   # Pure domain entities (Usuario / User)
│           │   ├── repositories/# Abstract repository interface contracts
│           │   └── usecases/   # Callable single-responsibility use cases
│           ├── data/           # Infrastructure & data adaptation
│           │   ├── datasources/# Supabase SDK authentication & city queries
│           │   ├── models/     # DTOs with robust JSON serialization
│           │   └── repositories/# Concrete repository implementations
│           └── presentation/   # UI & State Management
│               ├── cubit/      # AuthCubit & Dart 3 sealed AuthState
│               └── screens/    # LoginScreen, RegisterScreen, DashboardScreen
└── test/
    ├── unit/                   # Isolated unit tests (Domain, Data, Cubit, Geo)
    ├── widget/                 # UI widget interaction & form validation tests
    └── integration/            # End-to-end full authentication flow tests
```

---

## Prerequisites & Environment Setup

### 1. Requirements
* [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.13.0` or higher
* [Dart SDK](https://dart.dev/get-dart) `^3.0.0` or higher
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

> **Security Note:** `.env` is strictly excluded from version control via `.gitignore`. Never commit API keys or production database secrets to Git.

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

## Running the Test Suite

The codebase includes an automated test suite with **42 tests** covering all Clean Architecture layers without requiring an active network connection or emulator:

### 1. Run All Tests
```powershell
flutter test
```
*Expected Output:*
```text
00:03 +42: All tests passed!
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
